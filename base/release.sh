#!/usr/bin/env bash

#MISE description="Tag and publish a GitHub release from conventional commits, on release/prerelease branches"
#MISE tools.git-cliff="2"
#MISE tools.gh="2"

set -euo pipefail

# mise clones this whole repo for remote tasks, so .cliff.toml sits next to this file.
CLIFF_CONFIG="$(dirname "${BASH_SOURCE[0]}")/.cliff.toml"

# git-cliff reads GITHUB_TOKEN for the contributors section; CI provides GH_TOKEN.
export GITHUB_TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"

# Current ref as "branch/<name>" or "tag/<name>", from GitHub/GitLab CI variables or local git.
function get_ref() {
  TYPE="branch"
  if [ "${GITHUB_REF_TYPE:-}" = "tag" ]; then
    TYPE="tag"
  elif [ -n "${CI_COMMIT_TAG:-}" ]; then
    TYPE="tag"
  elif git describe --tags --exact-match >/dev/null 2>&1; then
    TYPE="tag"
  fi

  if [ -n "${GITHUB_REF_NAME:-}" ]; then
    echo "$TYPE/$GITHUB_REF_NAME"
  elif [ -n "${CI_COMMIT_REF_NAME:-}" ]; then
    echo "$TYPE/$CI_COMMIT_REF_NAME"
  else
    echo "$TYPE/$(git symbolic-ref --quiet --short HEAD || git describe --tags --exact-match 2>/dev/null || git rev-parse --short HEAD)"
  fi
}

# Release branches (main/master) and prerelease branches (alpha/beta/rc/next).
if [[ "$(get_ref)" =~ ^branch/(main|master|alpha|beta|rc|next)$ ]]; then
  VERSION=$(git cliff --offline --config "$CLIFF_CONFIG" --unreleased --bumped-version)
  CURRENT=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
  if [ "$VERSION" = "$CURRENT" ]; then
    echo "No release-worthy changes since $CURRENT, skipping release."
  else
    git cliff --config "$CLIFF_CONFIG" --unreleased --tag "$VERSION" --output CHANGELOG.md
    gh release create "$VERSION" --title "$VERSION" --target "$(git rev-parse HEAD)" --notes-file CHANGELOG.md
  fi
else
  echo "Not a release or pre-release branch, skipping release."
fi
