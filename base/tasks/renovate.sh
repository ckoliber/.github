#!/usr/bin/env bash

#MISE description="Run Renovate against this repository (or the repositories passed as arguments)"

set -euo pipefail

# Renovate reads RENOVATE_TOKEN itself; CI provides GITHUB_REPOSITORY.
renovate "${@:-${GITHUB_REPOSITORY:?set GITHUB_REPOSITORY or pass repositories}}"
