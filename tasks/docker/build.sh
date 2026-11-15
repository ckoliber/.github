#!/usr/bin/env bash
#MISE dir="{{ cwd }}"
#USAGE flag "--version <version>" help="Tag to push the image as" env="VERSION" required=#true
#USAGE flag "--platform <platforms>" help="Comma-separated platforms to build for" env="DOCKER_PLATFORMS" default="linux/amd64,linux/arm64"

set -euo pipefail
metadata=$(mktemp)
trap 'rm -f "$metadata"' EXIT

# Image name: repo name at the git root, else the current dir name
if [[ -z "$(git rev-parse --show-prefix)" ]]; then
  NAME=$(basename -s .git "$(git remote get-url origin)")
else
  NAME=$(basename "$PWD")
fi

# QEMU emulators for cross-platform builds: Linux hosts with a local builder only (Docker Desktop ships them)
if [ "$(uname -s)" = Linux ] && [ -z "${BUILDKIT_HOST:-}" ]; then
  docker run --privileged --rm tonistiigi/binfmt --install all >&2
fi

DRIVER=$([ -n "${BUILDKIT_HOST:-}" ] && echo "remote $BUILDKIT_HOST" || echo "docker-container")
$BUILDX use buildkit 2>/dev/null >&2 || $BUILDX create --use --name buildkit --driver $DRIVER >&2
$BUILDX build -f Dockerfile -t "$GHCR_REGISTRY/ckoliber/$NAME:${usage_version?}" \
  --cache-from type=registry,ref=$GHCR_REGISTRY/ckoliber/$NAME:cache \
  --cache-to type=registry,ref=$GHCR_REGISTRY/ckoliber/$NAME:cache,mode=max \
  --platform "${usage_platform?}" --metadata-file "$metadata" --push . >&2

jq -r '."containerimage.digest"' "$metadata"
