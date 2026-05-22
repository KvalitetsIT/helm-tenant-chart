# Changelog — project

All notable changes to the project chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

## [1.2.1] - 2026-05-22

### Changed
- `appProject.sourceRepos` now always includes `https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/` by default, and entries with an `oci://` prefix are automatically duplicated without the prefix to work around ArgoCD's inconsistent OCI URL matching against `sourceRepos`.

## [1.2.0] - 2026-05-21

### Added
- `appProject.sourceRepos` — optional list of additional source repositories for the per-project AppProject. `application.source.repoURL` is always included automatically.

### Changed
- Bumped `templates` chart dependency from `1.1.2` to `2.1.1`.

## [1.1.2] - 2026-03-06

### Changed
- Bumped `templates` chart dependency from `1.1.1` to `1.1.2`.

## [1.1.1] - 2026-03-06

### Fixed
- Release workflow now includes only the current version's changelog section in the GitHub release notes instead of the full file. No chart changes.

## [1.1.0] - 2026-03-06

### Added
- `argoNamespace` value (default: `argocd`) — injected by the tenant chart; controls the namespace of the per-project AppProject resource.
