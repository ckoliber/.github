#!/usr/bin/env bash
#MISE description="Check Terraform formatting and validate the configuration"
#MISE dir="{{ cwd }}"

set -euo pipefail

terraform fmt -check
terraform validate -no-color
