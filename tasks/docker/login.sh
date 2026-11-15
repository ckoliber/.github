#!/usr/bin/env bash
#MISE description="Log in to GHCR_REGISTRY with the gh token (needs write:packages locally)"

set -euo pipefail

gh auth token | docker login $GHCR_REGISTRY -u "${GITHUB_ACTOR:-$(gh api user --jq .login)}" --password-stdin
