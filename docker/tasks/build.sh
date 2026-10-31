#!/usr/bin/env bash

#MISE description="Build and push a multi-arch image to $GHCR_IMAGE and $DOCKER_IMAGE, tagged from conventional commits"

# Opt-in (not in base/, so it isn't included everywhere). Include docker/mise.toml and docker/tasks
# from a project (see README). Expects GHCR_IMAGE and DOCKER_IMAGE, and git-cliff from base/mise.toml.

set -euo pipefail

# mise clones this whole repo for remote tasks, so ../../base/.cliff.toml is available.
CLIFF_CONFIG="$(dirname "${BASH_SOURCE[0]}")/../../base/.cliff.toml"

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

REF=$(get_ref)
if [[ $REF =~ ^tag/(.*)$ ]]; then
  VERSION=${BASH_REMATCH[1]}
elif [[ $REF =~ ^branch/(main|master|alpha|beta|rc|next)$ ]]; then
  VERSION=$(git cliff --offline --config "$CLIFF_CONFIG" --unreleased --bumped-version)
else
  VERSION=$(git cliff --offline --config "$CLIFF_CONFIG" --unreleased --bumped-version)-build.$(git rev-parse --short HEAD)
fi

TAGS=(-t "$GHCR_IMAGE:$VERSION" -t "$DOCKER_IMAGE:$VERSION")
if [[ $REF =~ ^branch/(main|master)$ ]]; then
  TAGS+=(-t "$GHCR_IMAGE:latest" -t "$DOCKER_IMAGE:latest")
fi

BUILDX=docker-cli-plugin-docker-buildx
$BUILDX use buildkit 2>/dev/null || $BUILDX create --use --name buildkit --driver docker-container
$BUILDX build "${TAGS[@]}" --platform linux/amd64,linux/arm64 --push .
