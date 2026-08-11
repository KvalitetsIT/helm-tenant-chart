# project

![Version: 3.0.2](https://img.shields.io/badge/Version-3.0.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Deploys project infrastructure (Namespace, AppProject, app-of-apps Application, ResourceQuota, LimitRange, NetworkPolicy, Istio Waypoint) for a tenant project

**Homepage:** <https://github.com/KvalitetsIT>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| KvalitetsIT | <kithosting@kvalitetsit.dk> | <https://github.com/KvalitetsIT/helm-repo> |

## Source Code

* <https://github.com/KvalitetsIT/helm-tenant-chart>
* <https://github.com/KvalitetsIT/helm-tenant-chart/tree/main/charts/project>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ | templates | 2.2.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tenantName | string | "" | Injected by the tenant chart. Name of the tenant. |
| projectName | string | "" | Injected by the tenant chart. Name of the project. |
| tenantAppProjectName | string | "" | Injected by the tenant chart. Name of the tenant AppProject. |
| argoNamespace | string | argocd | Injected by the tenant chart. Namespace where ArgoCD is installed. |
| namespace.name | string | `""` | Optional. Override the project namespace name. Defaults to <tenantName>-<projectName>. Use this to decouple the physical namespace from the default naming convention, e.g. set to "acme" instead of "acme-acme". |
| namespace.labels | object | `{}` | Optional. Additional labels for the project Namespace. |
| namespace.annotations | object | `{}` | Optional. Additional annotations for the project Namespace. |
| appProject | object | See [values.yaml](values.yaml) | Configuration for the per-project AppProject (`<tenant>-<project>`). Supports `{tenant}`, `{tenantNamespace}`, and `{project}` placeholder substitution in descriptions, groups, and policies. Override per project via `projects.<name>.appProject` in the tenant chart. |
| appProject.sourceRepos | list | `[]` | Optional. Additional source repositories allowed in the AppProject. `application.source.repoURL` and `https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/` are always included automatically. Entries with an `oci://` prefix are added twice — once with the prefix and once without — as a workaround for ArgoCD's inconsistent OCI URL matching against `sourceRepos`. Override or extend per project via `projects.<name>.appProject.sourceRepos` in the tenant chart. |
| appProject.clusterResourceWhitelist | list | `[]` | Optional. Cluster-scoped resource kinds allowed in the AppProject. Empty by default — only add entries when projects need to manage cluster-scoped resources. |
| appProject.namespaceResourceWhitelist | list | `[{"group":"*","kind":"*"}]` | Optional. Kubernetes resource kinds allowed in the project namespace. Wildcard allows all — tighten per project as needed. |
| appProject.namespaceResourceBlacklist | list | See [values.yaml](values.yaml) | Optional. Kubernetes resource kinds explicitly denied in the project namespace. Prevents tenants from managing resources that are owned by the tenant chart. |
| appProject.roles | object | See [values.yaml](values.yaml) | Optional. RBAC roles for the AppProject. Supports `{tenant}`, `{tenantNamespace}`, and `{project}` placeholder substitution. `{tenant}` is the tenant identity (use in descriptions and group names). `{tenantNamespace}` is the namespace Applications actually live in - use it for the namespace segment of policy strings, since it can differ from `{tenant}` when `tenantNamespace.name` is overridden. Override or extend per project via `projects.<name>.appProject.roles` in the tenant chart. |
| appProject.roles.viewer | object | `{"description":"Read-only access to {project} workloads","groups":["{tenant}-viewer"],"policies":["applications, get, {project}/{tenantNamespace}/*, allow","logs, get, {project}/*, allow"]}` | Optional. Read-only role — grants view and log access to project workloads. |
| appProject.roles.viewer.groups | list | `["{tenant}-viewer"]` | Optional. AD/OIDC groups granted the viewer role. |
| appProject.roles.viewer.policies | list | `["applications, get, {project}/{tenantNamespace}/*, allow","logs, get, {project}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the viewer role. |
| appProject.roles.developer | object | `{"description":"Can sync and all actions on {project} workloads","groups":["{tenant}-developer"],"policies":["applications, get, {project}/{tenantNamespace}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenantNamespace}/*, allow","applications, update/*, {project}/{tenantNamespace}/*, allow","applications, delete, {project}/{tenantNamespace}/*, allow","applications, delete/*, {project}/{tenantNamespace}/*, allow","applications, sync, {project}/{tenantNamespace}/*, allow","applications, action/*, {project}/{tenantNamespace}/*, allow"]}` | Optional. Developer role — grants full sync and action access to project workloads. |
| appProject.roles.developer.groups | list | `["{tenant}-developer"]` | Optional. AD/OIDC groups granted the developer role. |
| appProject.roles.developer.policies | list | `["applications, get, {project}/{tenantNamespace}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenantNamespace}/*, allow","applications, update/*, {project}/{tenantNamespace}/*, allow","applications, delete, {project}/{tenantNamespace}/*, allow","applications, delete/*, {project}/{tenantNamespace}/*, allow","applications, sync, {project}/{tenantNamespace}/*, allow","applications, action/*, {project}/{tenantNamespace}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the developer role. |
| application | object | See [values.yaml](values.yaml) | Configuration for the app-of-apps Application (`<project>-apps`). `source.repoURL`, `source.path`, and `source.targetRevision` are injected by the tenant chart. Override per project via `projects.<name>.application` in the tenant chart. |
| application.source.repoURL | string | `""` | Required. Git repository URL for the app-of-apps. Injected by the tenant chart. |
| application.source.path | string | `""` | Required. Path to the app-of-apps directory. Injected by the tenant chart. |
| application.source.targetRevision | string | `""` | Required. Git branch, tag, or commit SHA. Injected by the tenant chart. |
| application.source.helm.valueFiles | list | See [values.yaml](values.yaml) | Optional. Helm value files passed to the app-of-apps Application. |
| application.syncPolicy | object | `{"automated":{"enabled":false},"syncOptions":["PruneLast=true"]}` | Optional. Sync policy for the `<project>-apps` app-of-apps. Auto-sync is off (`enabled: false`) so manual child-app overrides survive commits; sync the parent manually to roll out child-app changes. `enabled` is declared so a UI toggle shows as drift (ArgoCD 3.1+). |
| resourceQuota.enabled | bool | `true` | Optional. Enable or disable the ResourceQuota resource. |
| resourceQuota.spec | object | `{}` | Required when enabled. ResourceQuota hard limits. Set via `projectDefaults.resourceQuota.spec` in the tenant chart. See [Kubernetes ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/). |
| limitRange.enabled | bool | `false` | Optional. Enable or disable the LimitRange resource. |
| limitRange.spec | object | `{"limits":[{"default":{"cpu":"50m","memory":"64Mi"},"defaultRequest":{"cpu":"25m","memory":"32Mi"},"type":"Container"}]}` | Optional. LimitRange limits spec. See [Kubernetes LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/). |
| waypoint | object | See [values.yaml](values.yaml) | Optional. Configuration for the Istio Waypoint proxy resources deployed in the project namespace. When enabled, renders all entries in `waypoint.resources` and `waypoint.networkPolicies`. Disable per project via `projects.<name>.waypoint.enabled: false` in the tenant chart. |
| waypoint.enabled | bool | `true` | Optional. Enable or disable all Istio Waypoint resources. |
| waypoint.resources | object | See [values.yaml](values.yaml) | Optional. Map of arbitrary Kubernetes resources to render when `waypoint.enabled` is true. Each key becomes the default `metadata.name`. Rendered via `templates.resource`. |
| waypoint.resources.waypoint-options | object | See [values.yaml](values.yaml) | ConfigMap passed to the Gateway parametersRef. Controls topology spread, HPA, and PDB for waypoint pods. |
| waypoint.resources.waypoint | object | See [values.yaml](values.yaml) | Istio Waypoint Gateway resource. |
| waypoint.networkPolicies | object | See [values.yaml](values.yaml) | Optional. Map of NetworkPolicy resources to render when `waypoint.enabled` is true. Each key becomes the NetworkPolicy name. Rendered via `templates.networkPolicy`. |
| waypoint.networkPolicies.waypoint | object | See [values.yaml](values.yaml) | NetworkPolicy for waypoint pods. Allows HBONE ingress, Prometheus scraping, and egress to istiod, and same-namespace pods. |
| waypoint.networkPolicies.ingressgateway-acme-solver | object | See [values.yaml](values.yaml) | NetworkPolicy allowing ingressgateway to reach cert-manager ACME HTTP-01 solver pods. |
| defaultNetworkPolicies | object | See [values.yaml](values.yaml) | Optional. Default network policies deployed in every project namespace. Rendered directly by the project chart via the `templates` named-template defines. Disable the whole bundle with `enabled: false`, or opt out of individual entries with `enabled: false` on the entry. |
| defaultNetworkPolicies.enabled | bool | `true` | Optional. Enable or disable all default network policies. |
| defaultNetworkPolicies.networkPolicies | object | See [values.yaml](values.yaml) | Optional. Default NetworkPolicy resources. Each key becomes the resource name. Keys that also exist in `ciliumNetworkPolicies` are treated as fallbacks: rendered only when `cilium.io/v2` is not available. |
| defaultNetworkPolicies.networkPolicies.default-deny | object | See [values.yaml](values.yaml) | Default deny-all policy. Blocks all ingress and egress by default. |
| defaultNetworkPolicies.networkPolicies.allow-within-namespace | object | See [values.yaml](values.yaml) | Allow pod-to-pod communication within the same namespace. |
| defaultNetworkPolicies.networkPolicies.allow-kube-dns | object | See [values.yaml](values.yaml) | Fallback DNS egress policy used when `cilium.io/v2` is not available. Ignored when Cilium is present — `ciliumNetworkPolicies.allow-kube-dns` is used instead. |
| defaultNetworkPolicies.ciliumNetworkPolicies | object | See [values.yaml](values.yaml) | Optional. Default CiliumNetworkPolicy resources. Each key becomes the resource name. When `cilium.io/v2` is not available, the matching `networkPolicies` entry is rendered instead. |
| defaultNetworkPolicies.ciliumNetworkPolicies.allow-kube-dns | object | See [values.yaml](values.yaml) | DNS egress policy to kube-dns. Rendered as a CiliumNetworkPolicy when Cilium is available, falls back to `networkPolicies.allow-kube-dns` otherwise. |
| auditlog | object | See [values.yaml](values.yaml) | Optional. Audit log sidecar configuration. When enabled, renders a `vector-audit-rules` ConfigMap containing the complete Vector pipeline config. The kitapp sidecar mounts this ConfigMap by the hardcoded name `vector-audit-rules`. Set via `projectDefaults.auditlog` in the tenant chart to apply the same rules to all projects. |
| auditlog.enabled | bool | `false` | Enable or disable the audit log ConfigMap. |
| auditlog.tenantName | string | `""` | Optional. Name of the tenant, injected by the tenant chart. Used in the Vector pipeline for metadata enrichment and validation. |
| auditlog.config.httpPort | int | `9001` | Port the Vector HTTP source listens on. Must match the kitapp audit.config.httpPort. |
| auditlog.config.aggregatorAddress | string | `"vector-audit-aggregator.logging.svc.cluster.local:6000"` | Address of the Vector Aggregator. |
| auditlog.config.sinkVersion | string | `"2"` | Vector sink protocol version. |
| auditlog.schema | object | `{"action":{"required":true,"type":"string"},"actor":{"required":true,"type":"string"},"data":{"required":false,"type":"object"},"message":{"required":true,"type":"string"}}` | Validation schema. Each key is an audit event field. Supported field properties: type (string|object), required, enum, format (email|uuid), requiredKeys (object only). Override entirely in projectDefaults.auditlog.schema — no merging. |
| kyvernoPolicyExceptions | object | See [values.yaml](values.yaml) | Optional. Kyverno PolicyException resources for this project. `PolicyException` resources (`policies.kyverno.io/v1alpha1`) support both `ValidatingPolicy` and legacy `ClusterPolicy` policyRefs, and are evaluated with CEL matchConditions. Exceptions are created in the Kyverno namespace. Resource names are automatically prefixed with the project namespace (`<tenant>-<project>`) to prevent naming collisions across projects. Set via `projectDefaults.kyvernoPolicyExceptions` in the tenant chart to share a base set across all projects, then override or extend per project. See https://kyverno.io/docs/guides/exceptions/ for details. |
| kyvernoPolicyExceptions.enabled | bool | `false` | Optional. Enable or disable all PolicyException resources for this project. |
| kyvernoPolicyExceptions.exceptions | object | {} | Optional. Map of PolicyException resources. Each key becomes the resource name. PolicyExceptions are created in the project namespace (`<tenant>-<project>`). Kyverno must be configured with `exceptionNamespace: "*"` to pick them up. Set `enabled: false` on an individual entry to skip it without removing it from the map. |
| templates | object | See [values.yaml](values.yaml) | Optional. Values passed to the `templates` subchart for additional resources. Use `networkPolicies` and `ciliumNetworkPolicies` to add extra policies beyond the project defaults (e.g. cross-namespace connectivity). Set `enabled: false` to disable the subchart entirely. |
| templates.enabled | bool | `true` | Optional. Enable or disable the `templates` subchart. When false, no additional resources are rendered and the named-template defines are unavailable. |
| templates.networkPolicies | object | `{}` | Optional. Additional NetworkPolicy resources. Each key becomes the resource name. |
| templates.ciliumNetworkPolicies | object | `{}` | Optional. Additional CiliumNetworkPolicy resources. Each key becomes the resource name. |
| templates.sealedSecrets | object | `{}` | Optional. Additional SealedSecret resources. Each key becomes the resource name. |
| templates.resources | object | `{}` | Optional. Additional arbitrary resources rendered via `templates.resource`. Each key becomes the default `metadata.name`. |

## Overview

The `project` chart deploys the per-project infrastructure for a tenant project. It is not intended
to be installed manually — it is deployed as a `<project>-project` ArgoCD Application governed by
the `<tenant>-projects` AppProject, ensuring values are injected and controlled by the tenant chart.

### Resources Deployed

| Resource | Name | Controlled by |
|----------|------|---------------|
| `Namespace` | `<tenant>-<project>` | always |
| `AppProject` | `<tenant>-<project>` | always |
| `Application` | `<project>-apps` | always |
| `ResourceQuota` | `resource-quota` | `resourceQuota.enabled` |
| `LimitRange` | `limit-range` | `limitRange.enabled` |
| `ConfigMap` | `waypoint-options` | `waypoint.enabled` |
| `Gateway` | `waypoint` | `waypoint.enabled` |
| `NetworkPolicy` | `waypoint` | `waypoint.enabled` |
| `NetworkPolicy` | `ingressgateway-acme-solver` | `waypoint.enabled` |
| `NetworkPolicy` | `default-deny` | `defaultNetworkPolicies.enabled` + `defaultNetworkPolicies.networkPolicies.default-deny.enabled` |
| `NetworkPolicy` | `allow-within-namespace` | `defaultNetworkPolicies.enabled` + `defaultNetworkPolicies.networkPolicies.allow-within-namespace.enabled` |
| `CiliumNetworkPolicy` or `NetworkPolicy` | `allow-kube-dns` | `defaultNetworkPolicies.enabled` + `defaultNetworkPolicies.ciliumNetworkPolicies.allow-kube-dns.enabled` (type chosen at render time based on `cilium.io/v2` API availability) |
| `NetworkPolicy` | `<key>` (extra) | `templates.networkPolicies` |
| `CiliumNetworkPolicy` | `<key>` (extra) | `templates.ciliumNetworkPolicies` |

## Usage in the Tenant Chart

Values are injected via `helm.valuesObject` in the [tenant chart](../tenant/).
The project chart's own defaults apply for any key not overridden.

Override values globally for all projects via `projectDefaults`:

```yaml
projectDefaults:
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"
  application:
    source:
      repoURL: https://github.com/example/tenant-repo.git
      targetRevision: main
```

Override per project via `projects.<name>`:

```yaml
projects:
  reporting:
    resourceQuota:
      spec:
        hard:
          limits.cpu: "8"
          limits.memory: "16Gi"
          requests.storage: "200Gi"
    appProject:
      roles:
        ops:
          description: "Ops access to {project}"
          groups:
            - "{project}-ops"          # {project} → <tenant>-<project> at runtime
          policies:
            - "applications, *, {project}/{tenant}/*, allow"
```

## Cross-namespace NetworkPolicies

The project chart includes the [`templates`](../../helm-templates/charts/templates/) subchart
for adding extra `NetworkPolicy` and `CiliumNetworkPolicy` resources beyond the project defaults.
Use it to express cross-namespace connectivity.

Configure extra policies under the `templates` key. Each map key becomes the resource name.

### Share a service

Allow another namespace to reach specific pods in this namespace (adds an Ingress rule):

```yaml
templates:
  networkPolicies:
    share-api:
      podSelector:
        matchLabels:
          app: my-api
      policyTypes:
        - Ingress
      ingress:
        - from:
            - namespaceSelector:
                matchLabels:
                  kubernetes.io/metadata.name: consumer-namespace  # exact namespace name
              podSelector:                # namespaceSelector AND podSelector in same list item
                matchLabels:
                  app: consumer
          ports:
            - port: 8080
```

### Consume a service

Allow pods in this namespace to reach specific pods in another namespace (adds an Egress rule):

```yaml
templates:
  networkPolicies:
    consume-database:
      podSelector: {}
      policyTypes:
        - Egress
      egress:
        - to:
            - namespaceSelector:         # namespaceSelector AND podSelector in same list item
                matchLabels:
                  kubernetes.io/metadata.name: database-namespace
              podSelector:
                matchLabels:
                  app: postgres
          ports:
            - port: 5432
```

### FQDN egress (Cilium)

Allow specific pods to reach external services by domain name. Requires `templates.enabled: true`
so that the `allow-kube-dns` CiliumNetworkPolicy is present for FQDN resolution.

```yaml
templates:
  ciliumNetworkPolicies:
    allow-external-api:
      endpointSelector:
        matchLabels:
          app: my-app
      egress:
        - toFQDNs:
            - matchName: "api.example.com"       # exact hostname
            - matchPattern: "*.storage.azure.com" # wildcard pattern
          toPorts:
            - ports:
                - port: "443"
                  protocol: TCP
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
