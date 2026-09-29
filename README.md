# .github

Organization-wide shared configuration and tooling for `ckoliber` repositories: a reusable
CI/CD workflow + composite setup action, a Renovate preset, a `mise` task catalog (release,
changelog, setup), `git-cliff` release-notes config, and default community health files
(CONTRIBUTING, SECURITY, issue/PR templates).

## Layout

```
.
├── default.json                  # Renovate preset (org default)
├── renovate/                     # optional additional Renovate presets
├── mise/
│   ├── tasks/                    # shared mise tasks (release, changelog, setup)
│   └── lib/ref.sh                # shared branch/tag classification helpers
├── git-cliff/cliff.toml          # changelog/release-notes config
├── actions/setup/                # composite action: checkout + mise-action
├── .github/workflows/cicd.yml    # reusable CI/CD workflow (workflow_call)
├── workflow-templates/           # "New workflow" picker templates for org repos
├── profile/README.md             # org homepage
├── CONTRIBUTING.md, SECURITY.md, PULL_REQUEST_TEMPLATE.md, ISSUE_TEMPLATE/
└── docs/                         # how to consume all of the above
```

See [`docs/mise.md`](docs/mise.md), [`docs/renovate.md`](docs/renovate.md), and
[`docs/releases.md`](docs/releases.md) for how a project repo wires into this one.

## Design principle

Shared repo owns behavior (how to release, how to generate changelogs, CI orchestration, dependency
policy); project repos own configuration (which tools/tasks they need, project-specific
package rules). A project's CI should mostly say "install mise, run these tasks, release" — not
reimplement release logic.
