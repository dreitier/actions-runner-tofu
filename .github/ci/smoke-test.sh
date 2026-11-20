#!/usr/bin/env bash
# Checks the tools of the image and that it runs as the unprivileged runner user.
# Usage: .github/ci/smoke-test.sh <image>
set -euo pipefail
image=${1:?image}

run() { docker run --rm --entrypoint "" "$image" "$@"; }

run tofu version
run terragrunt --version
run aws --version
run git --version
run jq --version

uid=$(run id -u)
if [ "$uid" != "1001" ]; then
  echo "::error::expected UID 1001 (runner), got $uid"
  exit 1
fi

# the runner itself (ARC starts /home/runner/run.sh)
run test -x /home/runner/run.sh
echo "smoke test passed"
