# Renovate

The org-wide default preset lives at [`default.json`](../default.json): `config:recommended` +
dependency dashboard + weekly schedule, `automerge: true`, and grouped GitHub Actions / mise
updates. Optional presets live under [`renovate/`](../renovate) (currently just `docker.json` —
pinned-digest conventions for repos managing a Dockerfile).

## Consuming it in a project repo

`renovate.json`:

```json
{
  "extends": ["local>ckoliber/.github"]
}
```

`local>` resolves against whichever platform Renovate is running on, so the same syntax works if
this convention is later mirrored to `.gitlab` / `.gitea` repos in other orgs.

Add project-specific `enabledManagers` and `packageRules` after the extend — that's the only thing
that should differ between repos. For example, a Terraform repo:

```json
{
  "$schema": "https://docs.renovatebot.com/renovate-schema.json",
  "extends": ["local>ckoliber/.github"],
  "enabledManagers": ["mise", "terraform", "github-actions"],
  "packageRules": [
    {
      "description": "Group terraform provider updates together",
      "matchManagers": ["terraform"],
      "groupName": "Terraform provider updates"
    },
    {
      "description": "Tag terraform provider major updates as feat so they trigger a release",
      "matchManagers": ["terraform"],
      "matchUpdateTypes": ["major"],
      "semanticCommitType": "feat"
    }
  ]
}
```

To pull in the optional Docker preset as well:

```json
{
  "extends": ["local>ckoliber/.github", "local>ckoliber/.github//renovate/docker"]
}
```

## Opting out of full automerge

The default automerges everything once checks pass. A repo that wants manual review (e.g. a
public-facing site or a published image) can override it locally — the repo's own top-level
properties win over what `extends` brings in:

```json
{
  "extends": ["local>ckoliber/.github"],
  "automerge": false,
  "packageRules": [
    {
      "matchUpdateTypes": ["minor", "patch"],
      "automerge": true
    },
    {
      "matchManagers": ["github-actions"],
      "automerge": true
    }
  ]
}
```
