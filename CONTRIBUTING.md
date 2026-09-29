# Contributing

Thanks for taking the time to contribute.

## Commit messages

This organization uses [Conventional Commits](https://www.conventionalcommits.org/) for every repository. The
type prefix (`feat:`, `fix:`, `chore:`, ...) drives changelog generation and release versioning, so please use it
consistently, e.g.:

```
feat(auth): add support for refresh tokens
fix(api): handle empty response body
```

## Local setup

Most repositories in this organization use [mise](https://mise.jdx.dev) to manage tools and tasks:

```sh
mise install
mise run setup
```

## Development tasks

Common tasks are shared across repositories from [ckoliber/.github](https://github.com/ckoliber/.github):

```sh
mise run lint
mise run test
mise run changelog
mise run release
```

## Pull requests

- Keep PRs focused on a single change.
- Make sure `mise run lint` and `mise run test` pass locally before opening a PR.
- Fill in the pull request template.
