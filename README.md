# .github

Shared configuration and tooling for `ckoliber` repositories: `mise` tasks and Renovate presets
grouped per stack, a reusable CI/CD workflow, and default community health files (CONTRIBUTING,
SECURITY, issue/PR templates).

## Layout

```
.
├── base/                         # every repo: mise tasks (release, changelog) + _.json Renovate preset + .cliff.toml
├── terraform/, ansible/          # groups: mise tasks (init, test) + _.json Renovate preset
├── docker/                       # group: mise task (build) + _.json Renovate preset
├── .github/workflows/cicd.yml    # reusable CI/CD workflow (workflow_call)
├── .github/renovate.json         # this repo's own Renovate config
├── .github/PULL_REQUEST_TEMPLATE.md, .github/ISSUE_TEMPLATE/
└── CONTRIBUTING.md, SECURITY.md
```

## Usage

A Terraform repo, for example:

```toml
# mise.toml
[tools]
terraform = "1.16.6"

[task_config]
includes = ["git::https://github.com/ckoliber/.github.git//base?ref=main", "git::https://github.com/ckoliber/.github.git//terraform?ref=main"]
```

```json
// .github/renovate.json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["github>ckoliber/.github//base/_", "github>ckoliber/.github//terraform/_"]
}
```

```yaml
# .github/workflows/cicd.yml
jobs:
  cicd:
    uses: ckoliber/.github/.github/workflows/cicd.yml@main
    permissions:
      contents: write
    with:
      tasks: "init test"
      cache-path: .terraform/
      cache-hash: .terraform.lock.hcl
```

Notes:

- Group tasks use the tool versions from the repo's own `[tools]`; `base/` tasks declare their own
  (`gh`, `git-cliff`) via `#MISE tools` headers, which only apply to included tasks, not
  `[tasks.x] file = "git::..."`.
- An included task wins over a local task of the same name, so a repo that needs a different `test`
  skips the group and defines its tasks locally.
- Renovate reads the last path segment as a file name, so the `/_` in `//terraform/_` is required.
  Every repo extends `//base/_` itself, plus its group's `_.json`; group presets don't extend the
  base. Presets hold only `packageRules` / `hostRules` — no `enabledManagers`, so Renovate updates
  every manager it detects.
- `mise run release` (on push to `main`/`master`, or prerelease branches `alpha`/`beta`/`rc`/`next`)
  bumps the version from Conventional Commits per [`base/.cliff.toml`](base/.cliff.toml) — only
  `fix` (patch), `feat` (minor) and breaking `!` / `BREAKING CHANGE` (major) count; every other type
  is left out of the version and the changelog — and publishes a GitHub release. Renovate commits
  production dependencies as `fix(deps)` (releases) and everything else as `chore(deps)` (doesn't).
  `mise run changelog` previews `CHANGELOG.md`.
- Repos that need extra CI steps (docker login, pages deploy) write their own job with
  `actions/checkout` + `jdx/mise-action` and call `mise run release` at the end on `push`.
- Pin `@main` / `?ref=main` to a tag once this repo is tagged, so one bad push can't break every repo.

## Design principle

Shared repo owns behavior (how to release, how to generate changelogs, CI orchestration, dependency
policy); project repos own configuration (which tools/tasks they need, project-specific
package rules). A project's CI should mostly say "install mise, run these tasks, release" — not
reimplement release logic.
