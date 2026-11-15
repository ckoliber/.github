#!/usr/bin/env bash
#MISE description="Validate the Renovate config of this repository (or the config files passed as arguments)"
#MISE dir="{{ cwd }}"

set -euo pipefail

renovate-config-validator --strict --no-global "$@"
