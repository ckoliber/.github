#!/usr/bin/env bash
#MISE description="Run Renovate against this repository (or the repositories passed as arguments)"
#MISE dir="{{ cwd }}"

set -euo pipefail

export RENOVATE_TOKEN=${RENOVATE_TOKEN:-$(gh auth token)}
export RENOVATE_PLATFORM=github
export RENOVATE_REPOSITORIES=$(git remote get-url origin | sed -E 's#(\.git)?/?$##; s#.*[:/]([^:/]+/[^:/]+)$#\1#')
renovate "$@"
