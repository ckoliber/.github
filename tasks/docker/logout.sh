#!/usr/bin/env bash
#MISE description="Log out of GHCR_REGISTRY"

set -euo pipefail

docker logout $GHCR_REGISTRY
