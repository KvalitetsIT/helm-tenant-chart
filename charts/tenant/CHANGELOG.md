# Changelog — tenant

All notable changes to the tenant chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

## [1.1.0] - 2026-03-06

### Added
- `argoNamespace` value (default: `argocd`) to allow overriding the namespace where ArgoCD is installed. AppProject resources must live in the ArgoCD root namespace, which is not always `argocd`.
