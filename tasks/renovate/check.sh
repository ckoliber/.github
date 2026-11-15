#!/usr/bin/env bash
#MISE description="Validate the Renovate config"
#MISE dir="{{ cwd }}"

set -euo pipefail

renovate-config-validator --strict --no-global "$@"
