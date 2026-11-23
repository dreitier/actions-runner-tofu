# syntax=docker/dockerfile:1

# GitHub Actions runner for the Actions Runner Controller (ARC) with OpenTofu, Terragrunt and the AWS CLI –
# runs the deploy workflows of dreitier/basement in the cluster (docs/ci-deploy.md there). Jobs run directly
# in this image (no container mode, no Docker): as user runner (UID 1001), Pod Security "restricted".
FROM ghcr.io/actions/actions-runner:2.338.2@sha256:6d0b2d80d80f143f77dcb676e50920100bbb547e39e883454d57f45ab8c31300

LABEL org.opencontainers.image.source="https://github.com/dreitier/actions-runner-tofu" \
      org.opencontainers.image.description="GitHub Actions runner (ARC) with OpenTofu, Terragrunt and the AWS CLI" \
      org.opencontainers.image.vendor="dreitier GmbH" \
      org.opencontainers.image.licenses="MIT"

ARG TARGETARCH

# Tool versions (Renovate: comment on the line above). Same minor as on the workstations that apply the same
# units (renovate.json allowedVersions, basement's version constraints): a newer OpenTofu may write states
# that older versions refuse.
# renovate: datasource=github-releases depName=opentofu/opentofu extractVersion=^v(?<version>.*)$
ARG TOFU_VERSION=1.12.12
# renovate: datasource=github-releases depName=gruntwork-io/terragrunt extractVersion=^v(?<version>.*)$
ARG TERRAGRUNT_VERSION=1.1.6
# AWS CLI v1 from PyPI: v2 has no checksum file for its installer (only a PGP signature)
# renovate: datasource=pypi depName=awscli
ARG AWSCLI_VERSION=1.46.3

USER 0
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# DL3008: distribution packages are not pinned; the image is rebuilt on every release and weekly in CI
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl git jq unzip python3-venv \
    && rm -rf /var/lib/apt/lists/*

# OpenTofu and Terragrunt from their GitHub releases, verified against the published SHA256SUMS
WORKDIR /tmp/tools
RUN base="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}" \
    && zip="tofu_${TOFU_VERSION}_linux_${TARGETARCH}.zip" \
    && curl -fsSLO "${base}/${zip}" \
    && curl -fsSLO "${base}/tofu_${TOFU_VERSION}_SHA256SUMS" \
    && grep " ${zip}\$" "tofu_${TOFU_VERSION}_SHA256SUMS" | sha256sum -c - \
    && unzip -q "${zip}" tofu -d /usr/local/bin \
    && base="https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}" \
    && bin="terragrunt_linux_${TARGETARCH}" \
    && curl -fsSLO "${base}/${bin}" \
    && curl -fsSLO "${base}/SHA256SUMS" \
    && grep " ${bin}\$" SHA256SUMS | sha256sum -c - \
    && install -m 0755 "${bin}" /usr/local/bin/terragrunt \
    && rm -rf /tmp/tools

RUN python3 -m venv /opt/awscli \
    && /opt/awscli/bin/pip install --no-cache-dir "awscli==${AWSCLI_VERSION}" \
    && ln -s /opt/awscli/bin/aws /usr/local/bin/aws

# no interactive prompts, no update checks
ENV TF_IN_AUTOMATION=1 \
    TG_NON_INTERACTIVE=true \
    CHECKPOINT_DISABLE=1

# numeric: Kubernetes can only verify runAsNonRoot for a numeric user (runner = 1001 in the base image)
WORKDIR /home/runner
USER 1001
