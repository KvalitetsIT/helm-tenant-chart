# Changelog — project

All notable changes to the project chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Changed
- `application.syncPolicy` (the `<project>-apps` app-of-apps) — now defaults to `selfHeal: false` with `syncOptions: [PruneLast=true]`. `selfHeal: false` is a deliberate break-glass: an operator can pause or override a child app in the UI without the app-of-apps reverting it. `PruneLast` removes leaf apps only after the rest of the sync succeeds.
- Project `Namespace` — added `argocd.argoproj.io/sync-options: Prune=false` so ArgoCD never prunes the namespace (its deletion would cascade to every workload and PVC inside), even when the `<project>-project` Application otherwise allows pruning. The existing `helm.sh/resource-policy: keep` only governs `helm uninstall`, not ArgoCD pruning.
- `appProject.namespaceResourceBlacklist` — `GrafanaInstance`, `GrafanaOrg`, and `GrafanaOrgDatasource` from `grafana-org-operator.kubitus-project.gitlab.io` are now blacklisted by default. Tenants can only deploy `GrafanaOrgDashboard` resources from the Grafana org operator into their project namespaces.
- `appProject.namespaceResourceBlacklist` — all `keycloak.hostzero.com` resource kinds except `KeycloakClient` are now blacklisted by default. Tenants can only deploy `KeycloakClient` resources from the Keycloak operator into their project namespaces.
- `auditlog.tenantName` value added — allows the tenant chart to inject the tenant name via `projectDefaults.auditlog.tenantName`, falling back to the top-level `tenantName` if not set.
- Removed `pod_ip` from the Vector sidecar VRL — it was never used as a Loki label and is not forwarded to the aggregator.

## [2.1.2] - 2026-06-01

### Fixed
- Audit egress `NetworkPolicy` selector updated from `name: vector` to `name: vector-audit` to match the renamed Vector aggregator.

## [2.1.1] - 2026-05-29

### Added
- `NetworkPolicy` `allow-audit-egress-to-aggregator` — rendered when `auditlog.enabled: true`. Allows egress from pods with `audit.kitkube.dk/vector-sidecar: "true"` to the Vector aggregator (`component: Aggregator`) in the `logging` namespace on the configured aggregator port.

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
