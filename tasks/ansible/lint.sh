#!/usr/bin/env bash
#MISE description="Lint the Ansible role"
#MISE dir="{{ cwd }}"

set -euo pipefail

ansible-lint .
