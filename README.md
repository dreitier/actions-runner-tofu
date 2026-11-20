# actions-runner-tofu

[![CI](https://github.com/dreitier/actions-runner-tofu/actions/workflows/ci.yml/badge.svg)](https://github.com/dreitier/actions-runner-tofu/actions/workflows/ci.yml)

GitHub Actions runner image for the [Actions Runner Controller](https://github.com/actions/actions-runner-controller)
(ARC) with the tools for OpenTofu deployments: the official `ghcr.io/actions/actions-runner` plus

- [OpenTofu](https://opentofu.org) (`tofu`)
- [Terragrunt](https://terragrunt.gruntwork.io)
- AWS CLI v1 (`aws`), git, jq, curl, unzip

It runs the deploy workflows of `dreitier/basement` in the cluster (see `docs/ci-deploy.md` there).

- Image: `ghcr.io/dreitier/actions-runner-tofu`, linux/amd64
- Tags: `x.y.z`, `x.y`, `x`, `latest` (no `v` prefix); changes in [CHANGELOG.md](CHANGELOG.md)
- Signed with cosign (keyless, GitHub OIDC), build provenance attested; SBOM in Dependency-Track

## Runtime

- Runs as the user `runner` (UID 1001), like the upstream image; no root, no sudo needed.
- No Docker or container mode: workflow steps run directly in this image (`runs-on` the scale set, no
  `container:`), so the runner pod needs no privileges and works under Pod Security "restricted".
- `TF_IN_AUTOMATION=1`, `TG_NON_INTERACTIVE=true`, `CHECKPOINT_DISABLE=1`.

## Versions

Pinned as `ARG`s in the [Dockerfile](Dockerfile) and kept up to date by Renovate (each update is a patch
release). OpenTofu and Terragrunt stay on the minor version of the workstations that apply the same units
(currently OpenTofu 1.12, Terragrunt 1.1 – `allowedVersions` in [renovate.json](renovate.json), checked by the
version constraints in basement): a newer OpenTofu may write states that older versions refuse. Upgrade the
workstations first, then raise `allowedVersions`.

The downloads of OpenTofu and Terragrunt are verified against the SHA256SUMS of their GitHub releases.

## Development

```sh
make build   # local image
make test    # build + smoke test (.github/ci/smoke-test.sh)
make hooks   # pre-commit hooks
```

PRs are squash-merged; the PR title (Conventional Commit) decides the next version.
