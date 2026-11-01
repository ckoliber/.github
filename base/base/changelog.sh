#!/usr/bin/env bash

#MISE description="Regenerate CHANGELOG.md from conventional commits without releasing"

set -euo pipefail

git-cliff --config "$(dirname "${BASH_SOURCE[0]}")/.cliff.toml" --output CHANGELOG.md "$@"

echo "CHANGELOG.md updated."
