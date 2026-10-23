#!/usr/bin/env bash

#MISE description="Regenerate CHANGELOG.md from conventional commits without releasing"
#MISE tools.git-cliff="2"

set -euo pipefail

# git-cliff reads GITHUB_TOKEN for the contributors section; CI provides GH_TOKEN.
export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

git-cliff --config "$(dirname "${BASH_SOURCE[0]}")/.cliff.toml" --output CHANGELOG.md "$@"

echo "CHANGELOG.md updated."
