# Changelog — tenant

All notable changes to the tenant chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Added
- `keycloakGroup` — opt-in Keycloak group provisioning. When `keycloakGroup.enabled: true` and the `keycloak-operator` CRD (`keycloak.hostzero.com/v1beta1`) is present, renders a `KeycloakGroup` in the `auth` namespace nested under the configured `parentGroupRef` (default: `tenants`) in the configured realm (default: `infrastructure`). Group name is always the tenant name.
- Opt-in `applicationSet` self-service projects. When `applicationSet.enabled: true`, projects are discovered from a tenant-owned git repo (a `projects` map in a single file) via an ArgoCD ApplicationSet instead of the in-chart `projects` loop. The rendered project set is the **union** of the tenant repo's `projects` map and the admin `projects` map in this chart's values, so admins can both define their own projects and override tenant-created ones (matched by name, admin wins) — while tenants may only set `application.source.{path,targetRevision,helm}` per project. `projectDefaults` supplies the rest. The `<tenant>-projects` AppProject uses a `<tenant>-*` destination wildcard in this mode.
- ApplicationSet sync-safety defaults (`applicationSet.syncPolicy`): `applicationsSync: create-update` and `preserveResourcesOnDeletion: true`. These prevent a broken or empty tenant `projects.yaml` (generator returning zero results) from deleting existing projects and cascade-destroying their namespaces. `applicationsSync` requires the applicationset-controller `--enable-policy-override` flag to take effect; `preserveResourcesOnDeletion` is always honored. With `create-update`, removing a project becomes a deliberate admin action rather than an automatic effect of editing the tenant file.

## [2.1.0] - 2026-05-29

### Changed
- Bumped `project` chart dependency from `2.0.*` to `2.1.*` to track the latest project chart minor release. No tenant-specific changes.

## [2.0.0] - 2026-05-28

### Breaking Changes
- Bumped `project` chart dependency from `1.3.*` to `2.0.*`. See [project chart 2.0.0 release notes](../project/CHANGELOG.md) for the full list. Summary of action required on upgrade:
  - Istio Waypoint resources are now deployed in all project namespaces by default. Requires Istio ambient mesh. Disable globally via `projectDefaults.waypoint.enabled: false`.
  - Default network policies have moved from `templates.networkPolicies` / `templates.ciliumNetworkPolicies` to `defaultNetworkPolicies.*`. Migrate any per-project or global overrides of `templates.networkPolicies.default-deny`, `templates.networkPolicies.allow-within-namespace`, or `templates.ciliumNetworkPolicies.allow-kube-dns` to the new keys.

### Changed
- Bumped `templates` chart dependency from `2.1.1` to `2.2.0`.
- `projectDefaults.projectApplication.source.targetRevision` updated from `1.3.*` to `2.0.*`.

## [1.2.0] - 2026-05-21

### Changed
- Bumped `project` chart dependency from `1.1.*` to `1.2.*`.
- Bumped `templates` chart dependency from `1.1.2` to `2.1.1`.

## [1.1.3] - 2026-03-06

### Changed
- Bumped `templates` chart dependency from `1.1.1` to `1.1.2`.

## [1.1.2] - 2026-03-06

### Changed
- Default `projectDefaults.projectApplication.source.targetRevision` bumped from `1.0.*` to `1.1.*` to track the latest project chart minor release.

## [1.1.1] - 2026-03-06

### Fixed
- Release workflow now includes only the current version's changelog section in the GitHub release notes instead of the full file. No chart changes.

## [1.1.0] - 2026-03-06

### Added
- `argoNamespace` value (default: `argocd`) to allow overriding the namespace where ArgoCD is installed. AppProject resources must live in the ArgoCD root namespace, which is not always `argocd`.
