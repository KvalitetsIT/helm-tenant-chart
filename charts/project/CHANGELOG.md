# Changelog — project

All notable changes to the project chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

## [2.1.0] - 2026-05-29

### Added
- `auditlog` — optional audit log ConfigMap support. When `auditlog.enabled: true`, renders a `vector-audit-rules` ConfigMap in the project namespace containing a complete Vector pipeline config (HTTP source, validation VRL, kubernetes enrichment, aggregator sink). Consumed by the `kitapp` chart's Vector sidecar via `--watch-config`. Schema is fully declarative — supports `required`, `enum`, `format` (email/uuid), and `requiredKeys` constraints per field. Override entirely per project; no merging.

## [2.0.0] - 2026-05-28

### Breaking Changes
- `waypoint.enabled` defaults to `true`. Upgrading from 1.x will deploy Istio Waypoint resources into **all** project namespaces automatically. Requires Istio ambient mesh to be installed in the cluster. Disable globally via `projectDefaults.waypoint.enabled: false` in the tenant chart, or per project via `projects.<name>.waypoint.enabled: false`.
- Default network policies have moved from `templates.networkPolicies` / `templates.ciliumNetworkPolicies` to the new `defaultNetworkPolicies` bundle. Existing overrides under `templates.networkPolicies.default-deny`, `templates.networkPolicies.allow-within-namespace`, and `templates.ciliumNetworkPolicies.allow-kube-dns` must be migrated to `defaultNetworkPolicies.networkPolicies.*` and `defaultNetworkPolicies.ciliumNetworkPolicies.*`. The `templates` subchart is now for user-defined extra resources only.

### Added
- `waypoint.enabled` (default: `true`) — deploys Istio Waypoint ambient-mesh resources into each project namespace:
  - `ConfigMap` `waypoint-options` — topology spread constraints, HPA (min 2 / max 5), and PDB (minAvailable 1) for the waypoint pods
  - `Gateway` `waypoint` — Istio waypoint gateway (`gatewayClassName: istio-waypoint`, `istio.io/waypoint-for: service`)
  - `NetworkPolicy` `waypoint` — restricts waypoint pod ingress/egress to ingressgateway (HBONE), Prometheus scraping, istiod xDS, same-namespace pods, and kube-dns
  - `NetworkPolicy` `ingressgateway-acme-solver` — allows cert-manager ACME HTTP-01 solver pods to receive traffic from the ingressgateway
- `defaultNetworkPolicies` bundle (default: `enabled: true`) — replaces the previous `templates.*` defaults with first-class project chart values:
  - `NetworkPolicy` `default-deny` — deny-all ingress and egress
  - `NetworkPolicy` `allow-within-namespace` — allow pod-to-pod traffic within the namespace
  - `CiliumNetworkPolicy` / `NetworkPolicy` `allow-kube-dns` — DNS egress to kube-dns; rendered as a `CiliumNetworkPolicy` when `cilium.io/v2` is available, otherwise falls back to a plain `NetworkPolicy` with ipBlock rules. Each entry supports `enabled: false` for individual opt-out.
- `templates.networkPolicies` and `templates.ciliumNetworkPolicies` remain available for user-defined extra policies.

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
