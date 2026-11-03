# .github

Shared mise tools/tasks, a shared Renovate preset and CI for `ckoliber` repositories.

## Layout

Named tool configurations and the shared Renovate preset live at the root. All shared tasks
live under `tasks/`, namespaced by stack:

```
.
├── mise.base.toml / mise.ansible.toml / mise.docker.toml / mise.terraform.toml
├── default.json    # shared Renovate preset for all repositories
├── mise.toml       # local configuration for this repository
├── tasks/
│   ├── .config/cliff.toml # shared changelog and release configuration
│   ├── base/      # base:changelog, base:release, base:renovate
│   ├── ansible/   # ansible:test
│   ├── docker/    # docker:build
│   └── terraform/ # terraform:init, terraform:test
└── .github/
    ├── renovate.json
    └── workflows/mise.yml
```

Shared files used by tasks belong in `tasks/.config/` so the task directory
contains its supporting configuration. The hidden directory keeps configuration
TOML files out of mise task discovery.

Each consuming repository includes `mise.base.toml` and the tool configurations for
its stacks, extends the shared Renovate preset, and includes the entire
`tasks/` directory. All task definitions are available, but only the selected tool
configurations declare tools to install. Run tasks explicitly for the repository's
stacks; avoid broad task wildcards that would run unrelated commands.

The reusable workflows live in `.github/workflows/`, since GitHub only loads
workflows from there:

- `mise.yml` — runs a caller-provided Bash script with optional environment variables

## Usage

```toml
# mise.toml
include = [
  "git::https://github.com/ckoliber/.github.git//mise.base.toml?ref=main",
  "git::https://github.com/ckoliber/.github.git//mise.terraform.toml?ref=main",
]
task_config.includes = [
  "git::https://github.com/ckoliber/.github.git//tasks?ref=main",
]
```

```json
// .github/renovate.json
{
  "extends": ["local>ckoliber/.github"]
}
```

The shared `default.json` combines the common update rules with Docker digest
pinning and labels. Repository-specific manager filters can stay in each
repository's `.github/renovate.json`.

Renovate automatically discovers the root `mise.*.toml` files and maintains
their tool versions centrally.

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
          "TG_NON_INTERACTIVE": "true",
          "REPOSITORY": ${{ toJSON(github.repository) }},
          "FILTER": ${{ toJSON(github.event_name == 'push' && format('[{0}...{1}]', github.event.before, github.sha) || '*') }}
        }
      secret-envs: |
        {
          "SOPS_AGE_KEY": "SOPS_AGE_KEY",
          "TF_TOKEN_app_terraform_io": "TF_TOKEN_APP_TERRAFORM_IO"
        }
      cache-tools: terraform
      script: |
        mise run terraform:init
        mise run terraform:test
```

The workflow accepts `envs`, `secret-envs`, `script`, `fetch-depth` and `cache-tools`, in that order.
`fetch-depth` defaults to `1` (`actions/checkout`'s default); pass `0` for jobs that need full
history and tags, such as `base:release`.
`script` is required and runs with Bash error checking (`-euo pipefail`). `envs` defaults to
`{}` and accepts a JSON object of environment variable names and string values, applied at
the script step only (not to checkout or mise setup). No matrix is required. GitHub reusable workflow inputs cannot accept native YAML
objects, so serialize dynamic objects with `toJSON(...)` or use JSON as above. Wrap expression
values in `toJSON(...)` so quotes and newlines stay valid JSON.

`secret-envs` maps environment variable names to secret names, for example
`{"TF_TOKEN_app_terraform_io": "TF_TOKEN_APP_TERRAFORM_IO"}`, and exports only those secrets
(missing secrets become empty). It needs `secrets: inherit`, because `with:` cannot read secrets
and a generic workflow cannot declare every secret name.
See [GitHub's workflow syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#onworkflow_callinputsinput_idtype).

`cache-tools` defaults to empty and enables tool caches by name as a comma-separated list without
spaces (`uv`, `ansible`, `npm`, `renovate`, `terraform`), for example `terraform,npm`. Each enabled cache is shared by every job in the repository: each job restores
the latest one and saves a new one after it succeeds.

## Caching

Every tool keeps its default cache location, locally and in CI. On GitHub, `mise.yml` has one
`actions/cache` step per tool, enabled by name in `cache-tools`:

| Name        | Path                   |
| ----------- | ---------------------- |
| `uv`        | `~/.cache/uv`          |
| `ansible`   | `~/.ansible`           |
| `npm`       | `~/.npm`               |
| `renovate`  | `/tmp/renovate/cache`  |
| `terraform` | `.terraform/providers` |

mise keeps its own cache and tool installs at their defaults, cached by mise-action.
When adding a stack, add a cache step for its tools' default cache paths.

`mise.yml` declares no `permissions`, so its token gets exactly what the calling job grants.
Grant only what the script needs (for example `contents: write` for `base:release`).

Pass secrets with `secrets: inherit` and choose which to export with `secret-envs`; they take
precedence over matching `envs` keys. The execution
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
      script: mise run base:renovate
```

The reusable workflow exports inherited secrets as env vars (except the automatic `github_token`). `mise run base:release` tags and publishes a GitHub release from
[Conventional Commits](https://www.conventionalcommits.org/) (`fix` → patch, `feat` → minor, `!` → major).
