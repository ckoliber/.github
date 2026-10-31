# .github

Shared mise tools/tasks, Renovate presets and CI for `ckoliber` repositories.

## Layout

One folder per stack, plus `base/` for every repo:

```
<stack>/
├── mise.toml       # envs, tools, pulled in with `include`
├── tasks/          # mise tasks, pulled in with `task_config.includes`
└── renovate.json   # Renovate preset
```

Stacks: `base`, `docker`, `ansible`, `terraform`. The reusable workflows live in `.github/workflows/`,
since GitHub only loads workflows from there:

- `mise.yml` — runs one mise `task`; the task branches on `GITHUB_EVENT_NAME` itself
- `renovate.yml` — runs `mise run renovate` (from `base/tasks`)

## Usage

```toml
# mise.toml
include = [
  "git::https://github.com/ckoliber/.github.git//base/mise.toml?ref=main",
  "git::https://github.com/ckoliber/.github.git//terraform/mise.toml?ref=main",
]

[task_config]
includes = [
  "git::https://github.com/ckoliber/.github.git//base/tasks?ref=main",
  "git::https://github.com/ckoliber/.github.git//terraform/tasks?ref=main",
]
```

```json
// .github/renovate.json
{
  "extends": ["github>ckoliber/.github//base/renovate", "github>ckoliber/.github//terraform/renovate"]
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
      task: cicd
```

```yaml
# .github/workflows/renovate.yml
on:
  schedule:
    - cron: "0 2 * * *"
  workflow_dispatch:

jobs:
  renovate:
    uses: ckoliber/.github/.github/workflows/renovate.yml@main
    secrets: inherit
```

Both workflows export every inherited secret as an env var. `mise run release` tags and publishes a GitHub release from
[Conventional Commits](https://www.conventionalcommits.org/) (`fix` → patch, `feat` → minor, `!` → major).
