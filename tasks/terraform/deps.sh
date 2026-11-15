#!/usr/bin/env bash
#MISE description="Initialize the Terraform working directory"
#MISE dir="{{ cwd }}"

set -euo pipefail

terraform init
