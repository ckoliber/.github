#!/usr/bin/env bash
#MISE description="Release a new version from commits"
#MISE dir="{{ cwd }}"
#USAGE flag "--dry-run" help="Print the version without releasing"

set -euo pipefail

# Branch: from CI vars, else git
[ "${GITHUB_REF_TYPE:-}" != branch ] || BRANCH=$GITHUB_REF_NAME
BRANCH=${BRANCH:-${CI_COMMIT_BRANCH:-$(git symbolic-ref -q --short HEAD || true)}}

# Tag prefix: none at the repo root, else the dir name
PREFIX=$(git rev-parse --show-prefix)
PREFIX=${PREFIX:+$(basename "$PWD")/}

# Tags: print the version and stop
if [ -z "$BRANCH" ] && TAG=$(git describe --tags --exact-match --match "$PREFIX[0-9]*" 2>/dev/null); then
  echo "${TAG#"$PREFIX"}"
  exit 0
fi

export GIT_CLIFF_CONFIG="$(cd "$(dirname "$0")" && pwd)/.cliff.toml" GIT_CLIFF_OFFLINE=true RUST_LOG=error
export GIT_CLIFF_TAG_PATTERN="^${PREFIX}v?[0-9]+\.[0-9]+\.[0-9]+\$" GIT_CLIFF__BUMP__INITIAL_TAG=${PREFIX}0.1.0
export GITHUB_REPO=${GITHUB_REPOSITORY:-$(git remote get-url origin | sed -E 's#(\.git)?/?$##; s#.*[:/]([^:/]+/[^:/]+)$#\1#')}

# Next version and number of release-worthy commits; outside main, bump at least a patch
read -r VERSION COUNT <<<"$(git cliff -u --bump --strip all --body '{{ version }} {{ commits | length }}')"
[ "$COUNT" != 0 ] || [[ $BRANCH =~ ^(main|master)$ ]] || VERSION=$(git cliff -u --bump patch --bumped-version)

# Tag format per branch
case $BRANCH in
main | master) TAG=$VERSION ;;
alpha | beta | next | rc)
  TAG=$VERSION-$BRANCH.$COUNT PRERELEASE=true
  GIT_CLIFF_TAG_PATTERN="^${PREFIX}v?[0-9]+\.[0-9]+\.[0-9]+(-.+)?\$"
  ;;
*) TAG=$VERSION-build.$(git rev-list --count HEAD).g$(git rev-parse --short HEAD) COUNT=0 ;;
esac

# Print, release, or skip
if [ "${usage_dry_run:-false}" = true ]; then
  echo "${TAG#"$PREFIX"}"
elif [ "$COUNT" != 0 ] && ! git rev-parse -q --verify "refs/tags/$TAG" >/dev/null; then
  NOTES=$(git cliff -u --tag "$TAG" --strip all)
  gh release create "$TAG" --target "$(git rev-parse HEAD)" --notes "$NOTES" --prerelease="${PRERELEASE:-false}"
else
  echo "Nothing to release on ${BRANCH:-HEAD}" >&2
fi
