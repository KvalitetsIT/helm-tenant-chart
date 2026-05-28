# Changelog — tenant

All notable changes to the tenant chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

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
