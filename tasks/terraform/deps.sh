#!/usr/bin/env bash
#MISE description="Initialize Terraform"
#MISE dir="{{ cwd }}"

set -euo pipefail

terraform init
