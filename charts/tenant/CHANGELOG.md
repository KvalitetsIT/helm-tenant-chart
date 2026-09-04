# Changelog — tenant

All notable changes to the tenant chart are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

---

## [Unreleased]

### Changed
- **Breaking:** the `loki-group-mapping` ConfigMap is renamed to `tenant-group-mapping` and its single `groups` key is split into one key per role (`viewer`, `developer`). The old key merged both role group lists, which is fine for Loki but discards the role distinction that consumers such as Dependency-Track express through per-role permissions. Consumers still discover it cluster-wide by the `tenant.kitkube.dk/name` label; they must now read the role keys they care about, ignore unknown keys, and treat a group listed under two roles as holding the more privileged one. `loki-scope-proxy` needs updating for the new name and to union every key.

### Fixed
- `tenant-group-mapping` ConfigMap (then named `loki-group-mapping`) was always created in a namespace named after the tenant, ignoring the `tenantNamespace.name` override. It now uses the `tenant.tenantNamespace` helper, consistent with other tenant resources.

## [3.1.0] - 2026-08-12

### Fixed
- Changed sync-wave of ApplicationSet to run before the project Application to make the ApplicationSet take over the Application instead of recreating.

### Added
- `global.*` injection: the tenant chart now injects a flat Helm `global` block into every project Application it creates, so a project's `templates` subchart resources can reference tenant/project identity and namespaces via `tpl`: `{{ .Values.global.tenantName }}`, `{{ .Values.global.tenantNamespace }}`, `{{ .Values.global.projectName }}`, `{{ .Values.global.projectNamespace }}`. Works for both the static `projects` loop and the self-service ApplicationSet (project-level keys are filled per item at sync time; under an ApplicationSet the project namespace is always `<tenant>-<project>`). `projectNamespace` follows any `projects.<name>.namespace.name` override. Existing values files are unaffected.
- `tenantNamespace.name` — optional override for the tenant admin namespace name. Defaults to the tenant name when unset, preserving existing behaviour. Use this to decouple the physical namespace from the tenant identity, e.g. set to `acme-admin` while keeping the tenant name `acme`. All AppProject `sourceNamespaces`, `destinations`, and admin Application `namespace` fields follow this value via the new `tenant.tenantNamespace` helper.
- `projects.<name>.namespace.name` — optional override for a project's namespace name. Defaults to `<tenant>-<project>` when unset. Use this to give a project a namespace that does not follow the default convention, e.g. `acme` instead of `acme-acme`. The resolved name is used for the AppProject destination and the Application destination, and is forwarded to the project chart.
- Validation guard: `helm template` now fails with a clear error if any project's resolved namespace equals the tenant admin namespace, preventing admin Application objects and workloads from sharing a namespace. Note: this guard only applies to the static `projects` loop — the ApplicationSet path cannot be validated at template time since projects are resolved from git at runtime.

## [3.0.2] - 2026-06-23

### Changed
- Removed title case transformation for Grafana Org


## [3.0.1] - 2026-06-23

### Changed
- Fixed wrong parentGroupRef for `<tenant>-developer` and `<tenant>-viewer` Keycloak groups.

## [3.0.0] - 2026-06-22

### Added
- Added `loki-group-mapping` configmap to the tenant chart, which can be consumed by `loki-scope-proxy` to map tenant namespaces to Loki groups for tenant-isolated log access. The configmap is rendered with a `groups` key containing a YAML mapping of tenant namespaces to Loki group names, derived from the `tenants` map in the chart values. This allows dynamic group mapping based on the defined tenants without hardcoding namespace-to-group mappings in the proxy configuration.

### Changed
- Changed `grafanaOrg.datasources.prometheus.url` default from `http://kube-prometheus-stack-prometheus.monitoring.svc.cluster.local:9090` to `http://prom-label-proxy.monitoring.svc.cluster.local:8080` to reflect the new recommended cluster-local endpoint for tenant-isolated Prometheus access via the prom-label-proxy. Tenants using the old default must update their datasource URL to continue accessing Prometheus after upgrading.
- `projectDefaults.projectApplication.syncPolicy` - added `syncOptions: [Prune=confirm, Delete=confirm]` and declared `automated.enabled: true` explicitly. The `<project>-project` Applications still auto-sync and self-heal, but pruning a project resource or cascade-deleting the Application now requires manual confirmation in the ArgoCD UI, so tenant/project structure is never destroyed by accident. Declaring `automated.enabled` means turning auto-sync off in the UI shows as drift instead of being silently ignored. Requires ArgoCD 3.1+ for `automated.enabled`; `Prune=confirm` / `Delete=confirm` require 2.14+.

## [2.2.0] - 2026-06-18

### Added
- `kyvernoPolicyExceptions` — opt-in Kyverno `PolicyException` (`policies.kyverno.io/v1alpha1`) support. Configure exceptions per project under `projects.<name>.kyvernoPolicyExceptions` or share a base set via `projectDefaults.kyvernoPolicyExceptions`. Each exception specifies `policyRefs` (referencing `ValidatingPolicy` or `ClusterPolicy` by name) and CEL `matchConditions`. Resource names are automatically prefixed with the project namespace to prevent collisions in the `kyverno` namespace. Individual exceptions can be temporarily disabled with `enabled: false` without removing them from the map. Exceptions are rendered directly by the tenant chart (not the project chart) so they can be created in the `kyverno` namespace, which is outside the scope of the per-project AppProject.
- Opt-in `applicationSet` self-service projects. When `applicationSet.enabled: true`, projects are discovered from a tenant-owned git repo (a `projects` map in a single file) via an ArgoCD ApplicationSet instead of the in-chart `projects` loop. The rendered project set is the **union** of the tenant repo's `projects` map and the admin `projects` map in this chart's values, so admins can both define their own projects and override tenant-created ones (matched by name, admin wins) — while tenants may only set the per-project `application` block. `projectDefaults` supplies the rest, and an unauthorized `application.source.repoURL` is rejected by the `<tenant>-apps` AppProject. The `<tenant>-projects` AppProject uses a `<tenant>-*` destination wildcard in this mode. The ApplicationSet is created in the tenant namespace, so the applicationset-controller must run with `--applicationset-namespaces=*` (and `--enable-scm-providers=false`, required alongside it).
- ApplicationSet sync-safety defaults (`applicationSet.syncPolicy`): `applicationsSync: create-update` and `preserveResourcesOnDeletion: true`. These prevent a broken or empty tenant `projects.yaml` (generator returning zero results) from deleting existing projects and cascade-destroying their namespaces. With `create-update`, removing a project becomes a deliberate admin action rather than an automatic effect of editing the tenant file.
- `grafanaOrg` — opt-in Grafana organisation provisioning. When `grafanaOrg.enabled: true` and the `grafana-org-operator` CRD (`grafana-org-operator.kubitus-project.gitlab.io/v1beta1`) is present, renders a `GrafanaOrg` and one `GrafanaOrgDatasource` per entry in `grafanaOrg.datasources` in the `tenants` namespace. Loki and Prometheus datasources are pre-configured with standard cluster-local endpoints; `secureJsonData.httpHeaderValue1` auto-defaults to the release namespace for tenant-isolation headers. `orgName` defaults to the title-cased tenant name. `grafanaInstanceRef` defaults to `monitoring/grafana`.
- `keycloakGroup` — opt-in Keycloak group provisioning. When `keycloakGroup.enabled: true` and the `keycloak-operator` CRD (`keycloak.hostzero.com/v1beta1`) is present, renders a `KeycloakGroup` in the `auth` namespace nested under the configured `parentGroupRef` (default: `tenants`) in the configured realm (default: `infrastructure`). Group name is always the tenant name.

### Changed
- Bumped `project` chart dependency from `2.1.*` to `2.2.*` to track the latest project chart minor release.
- Remove waypoint dns network policy as this is globally, in the namespace, controlled by the `allow-kube-dns`policy

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
