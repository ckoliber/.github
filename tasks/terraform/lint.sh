#!/usr/bin/env bash
#MISE description="Check Terraform format and config"
#MISE dir="{{ cwd }}"

set -euo pipefail

terraform fmt -check
terraform validate -no-color
