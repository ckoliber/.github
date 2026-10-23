#!/usr/bin/env bash

#MISE description="Lint the Ansible role"

set -euo pipefail

ansible-lint .
