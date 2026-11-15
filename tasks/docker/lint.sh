#!/usr/bin/env bash
#MISE dir="{{ cwd }}"

set -euo pipefail

DRIVER=$([ -n "${BUILDKIT_HOST:-}" ] && echo "remote $BUILDKIT_HOST" || echo "docker-container")
$BUILDX use buildkit 2>/dev/null >&2 || $BUILDX create --use --name buildkit --driver $DRIVER >&2
$BUILDX build --check -f Dockerfile .
