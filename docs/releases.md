# CI & Releases

## CI/CD workflow

Project repos call one reusable workflow that runs their mise tasks and then releases:

```yaml
# .github/workflows/cicd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
  workflow_dispatch:

jobs:
  cicd:
    uses: ckoliber/.github/.github/workflows/cicd.yml@main
    with:
      tasks: "test" # space-separated mise tasks to run, e.g. "init test build"
    secrets:
      GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

Optional inputs:

- `cache-path` / `cache-key` — adds an `actions/cache` step (e.g. Terraform's `.terraform/` dir).
- `mise-version` — pin a specific mise CLI version (defaults to a recent one).

The reusable workflow always checks out full history and installs mise via the shared
[`actions/setup`](../actions/setup) composite action, runs each task in `tasks` in order, and
finally — only on `push` — runs `mise run release` (see below).

### When a project needs steps this can't express

Some repos (container builds, static-site deploys) need steps interleaved that a `workflow_call`
can't express (docker login, LaTeX build, gh-pages deploy, etc.). Those repos don't call the
reusable workflow at all — they write a normal job and use the shared
[`ckoliber/.github/actions/setup@main`](../actions/setup) composite action just for the
checkout+mise step, then add whatever steps they need, then run `mise run release` themselves at
the end (guarded by `if: github.event_name == 'push'`). See `envcontainer` or `ckoliber.github.io`
for examples.

## Releases

`mise run release` is defined in [`mise/tasks/release`](../mise/tasks/release). It doesn't
require any project-local config — it self-fetches `git-cliff/cliff.toml` and `mise/lib/ref.sh`
from this repo at run time. On each push it:

1. Classifies the current ref as a release branch (`main`/`master`), a prerelease branch
   (`alpha`/`beta`/`rc`/`next`), or neither — anything else is skipped.
2. Computes the next version from conventional commits via `git-cliff`.
3. Skips if there are no release-worthy commits since the last tag.
4. Regenerates `CHANGELOG.md` and publishes a GitHub release (`gh release create`), which also
   creates the tag.

`mise run changelog` (in [`mise/tasks/changelog`](../mise/tasks/changelog)) regenerates
`CHANGELOG.md` locally without releasing, useful for previewing.

Pin the `@main` refs above (and the `REF` in the mise tasks) to a tag once this repo starts
tagging releases, instead of tracking `main`, so a change here can't silently break every repo at
once.
