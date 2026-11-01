# .github

Shared mise tools/tasks, Renovate presets and CI for `ckoliber` repositories.

## Layout

One folder per stack, plus `base/` for every repo:

```
<stack>/
├── mise.toml       # envs, tools, pulled in with `include`
├── *.sh            # base tasks, pulled in with `task_config.includes`
├── <stack>/*.sh    # namespaced stack tasks, e.g. ansible:test
└── renovate.json   # Renovate preset
```

Stacks: `base`, `docker`, `ansible`, `terraform`. The reusable workflows live in `.github/workflows/`,
since GitHub only loads workflows from there:

- `mise.yml` — runs a caller-provided Bash script with optional environment variables

## Usage

```toml
# mise.toml
include = [
  "git::https://github.com/ckoliber/.github.git//base/mise.toml?ref=main",
  "git::https://github.com/ckoliber/.github.git//terraform/mise.toml?ref=main",
]
task_config.includes = [
  "git::https://github.com/ckoliber/.github.git//base?ref=main",
  "git::https://github.com/ckoliber/.github.git//terraform?ref=main",
]
```

```json
// .github/renovate.json
{
  "extends": ["local>ckoliber/.github//base/renovate", "local>ckoliber/.github//terraform/renovate"]
}
```

```yaml
# .github/workflows/cicd.yml
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  cicd:
    uses: ckoliber/.github/.github/workflows/mise.yml@main
    secrets: inherit
    permissions:
      issues: write
      contents: write
      pull-requests: write
    with:
      envs: |
        {
          "BUILD_MODE": "release",
          "REGISTRY": "ghcr.io",
          "CUSTOM_VAR": "hello"
        }
      cache: |
        {
          "path": ".cache",
          "key": "ci-${{ github.sha }}",
          "restore-keys": "ci-"
        }
      script: |
        mise run terraform:init
        mise run terraform:test
```

The workflow accepts `envs`, `cache`, and `script`, in that order.
`script` is required and runs with Bash error checking (`-euo pipefail`). `envs` defaults to
`{}` and accepts a JSON object of environment variable names and string values, applied at
job scope. No matrix is required. GitHub reusable workflow inputs cannot accept native YAML
objects, so serialize dynamic objects with `toJSON(...)` or use JSON as above.
See [GitHub's workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_callinputsinput_idtype).

`cache` defaults to `{}` (disabled). To enable it, provide a JSON object with `path` and
`key`, plus optional `restore-keys`. Use newline-separated strings for multiple paths
or restore keys. The cache is restored before the script and saved after a successful job.

Pass secrets with `secrets: inherit`, separately from `envs`. Inherited secrets are exported
as environment variables and take precedence over matching input variables. The execution
step supplies `SCRIPT`, `GITHUB_TOKEN` and `PR_NUMBER` itself. The workflow uses a
GitHub-hosted `ubuntu-latest` runner, sets up mise with
[jdx/mise-action](https://github.com/jdx/mise-action), and runs the script from the repository root.
Use `cd` in the script when commands need a different directory.

```yaml
# .github/workflows/renovate.yml
on:
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:

jobs:
  renovate:
    uses: ckoliber/.github/.github/workflows/mise.yml@main
    secrets: inherit
    permissions:
      issues: write
      contents: write
      pull-requests: write
    with:
      script: mise run renovate
```

The reusable workflow exports inherited secrets as env vars (except the automatic `github_token`). `mise run release` tags and publishes a GitHub release from
[Conventional Commits](https://www.conventionalcommits.org/) (`fix` → patch, `feat` → minor, `!` → major).
