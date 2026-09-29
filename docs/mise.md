# mise

This repo publishes a shared `mise` task catalog so every `ckoliber` repository gets the same
`release` / `changelog` / `setup` commands without reimplementing them, and without needing a
local `cliff.toml` or `release.sh`.

## Consuming it in a project repo

Add to the project's `mise.toml`:

```toml
[tools]
gh = "latest"
git-cliff = "latest"
git-lfs = "latest"

[task_config]
includes = [
  "git::https://github.com/ckoliber/.github.git//mise/tasks?ref=main",
]
```

Pin `ref` to a tag (e.g. `v1`) once this repo starts tagging releases, instead of tracking `main`,
so a change here can't silently break every repo at once.

Do not define a local `[tasks.release]` — the included one wins by name. Keep only genuinely
project-specific tasks locally (`test`, `init`, `build`, etc).

Then in the project:

```sh
mise run setup
mise run changelog
mise run release
```

## Adding a task

Tasks live in [`mise/tasks/`](../mise/tasks). Each task is a self-contained executable script that
declares the tools it needs via `#MISE tools.<tool>="<version>"` comments, so it doesn't rely on the
consuming repo's `[tools]` block.

## Shared shell helpers

[`mise/lib/ref.sh`](../mise/lib/ref.sh) has the `get_ref` / `is_release` / `is_prerelease` /
`is_tag` branch-classification helpers used by `mise/tasks/release`. A project script that needs
the same classification (e.g. an image-build script tagging `latest` only on release branches) can
curl and source it instead of re-implementing it:

```sh
curl -fsSL https://raw.githubusercontent.com/ckoliber/.github/main/mise/lib/ref.sh -o /tmp/ref.sh
source /tmp/ref.sh
is_release && echo "on a release branch"
```
