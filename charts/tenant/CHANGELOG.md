# Changelog — tenant

All notable changes to the tenant chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

## [1.1.2] - 2026-03-06

### Changed
- Default `projectDefaults.projectApplication.source.targetRevision` bumped from `1.0.*` to `1.1.*` to track the latest project chart minor release.

## [1.1.1] - 2026-03-06

### Fixed
- Release workflow now includes only the current version's changelog section in the GitHub release notes instead of the full file. No chart changes.

## [1.1.0] - 2026-03-06

### Added
- `argoNamespace` value (default: `argocd`) to allow overriding the namespace where ArgoCD is installed. AppProject resources must live in the ArgoCD root namespace, which is not always `argocd`.
