#!/usr/bin/env bash
#MISE description="Log in to the container registry"

set -euo pipefail

gh auth token | docker login $GHCR_REGISTRY -u "${GITHUB_ACTOR:-$(gh api user --jq .login)}" --password-stdin
