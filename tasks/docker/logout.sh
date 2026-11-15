#!/usr/bin/env bash
#MISE description="Log out of the container registry"

set -euo pipefail

docker logout $GHCR_REGISTRY
