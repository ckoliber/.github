# .github

Shared CI workflow, Mise profiles, and Renovate preset.

## Projects

Include the shared profiles and tasks in the project's `mise.toml`:

```toml
include = [
  "git::https://github.com/ckoliber/.github.git//always.toml?ref=main",
  "git::https://github.com/ckoliber/.github.git//docker.toml?ref=main",
]
task_config.includes = [
  "git::https://github.com/ckoliber/.github.git//tasks?ref=main",
]
```

Profiles: `always`, `ansible`, `docker`, `terraform`.

CI workflow and Renovate preset:

```yaml
jobs:
  cicd:
    uses: ckoliber/.github/.github/workflows/mise.yml@main
    with:
      script: mise run docker:build --version 1.0.0
```

```json
{ "extends": ["local>ckoliber/.github"] }
```
