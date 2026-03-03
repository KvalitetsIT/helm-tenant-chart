# project

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

Deploys project infrastructure (Namespace, AppProject, app-of-apps Application, ResourceQuota, LimitRange, NetworkPolicy) for a tenant project

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| KvalitetsIT | <kithosting@kvalitetsit.dk> | <https://github.com/KvalitetsIT/helm-repo> |

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ | templates | 1.0.0 |

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| tenantName | string | "" | Injected by the tenant chart. Name of the tenant. |
| projectName | string | "" | Injected by the tenant chart. Name of the project. |
| tenantAppProjectName | string | "" | Injected by the tenant chart. Name of the tenant AppProject. |
| namespace.labels | object | `{}` | Optional. Additional labels for the project Namespace. |
| namespace.annotations | object | `{}` | Optional. Additional annotations for the project Namespace. |
| appProject | object | See below | Configuration for the per-project AppProject (`<tenant>-<project>`). Supports `{tenant}` and `{project}` placeholder substitution in descriptions, groups, and policies. Override per project via `projects.<name>.appProject` in the tenant chart. |
| appProject.namespaceResourceWhitelist | list | `[{"group":"*","kind":"*"}]` | Optional. Kubernetes resource kinds allowed in the project namespace. Wildcard allows all — tighten per project as needed. |
| appProject.namespaceResourceBlacklist | list | `[{"group":"rbac.authorization.k8s.io","kind":"Role"},{"group":"rbac.authorization.k8s.io","kind":"RoleBinding"},{"group":"","kind":"ResourceQuota"},{"group":"","kind":"LimitRange"}]` | Optional. Kubernetes resource kinds explicitly denied in the project namespace. Prevents tenants from managing resources that are owned by the tenant chart. |
| appProject.roles | object | See below | Optional. RBAC roles for the AppProject. Supports `{tenant}` and `{project}` placeholder substitution. Override or extend per project via `projects.<name>.appProject.roles` in the tenant chart. |
| appProject.roles.viewer | object | `{"description":"Read-only access to {project} workloads","groups":["{tenant}-viewer"],"policies":["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow"]}` | Optional. Read-only role — grants view and log access to project workloads. |
| appProject.roles.viewer.groups | list | `["{tenant}-viewer"]` | Optional. AD/OIDC groups granted the viewer role. |
| appProject.roles.viewer.policies | list | `["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the viewer role. |
| appProject.roles.developer | object | `{"description":"Can sync and all actions on {project} workloads","groups":["{tenant}-developer"],"policies":["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenant}/*, allow","applications, update/*, {project}/{tenant}/*, allow","applications, delete, {project}/{tenant}/*, allow","applications, delete/*, {project}/{tenant}/*, allow","applications, sync, {project}/{tenant}/*, allow","applications, action/*, {project}/{tenant}/*, allow"]}` | Optional. Developer role — grants full sync and action access to project workloads. |
| appProject.roles.developer.groups | list | `["{tenant}-developer"]` | Optional. AD/OIDC groups granted the developer role. |
| appProject.roles.developer.policies | list | `["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenant}/*, allow","applications, update/*, {project}/{tenant}/*, allow","applications, delete, {project}/{tenant}/*, allow","applications, delete/*, {project}/{tenant}/*, allow","applications, sync, {project}/{tenant}/*, allow","applications, action/*, {project}/{tenant}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the developer role. |
| application | object | See below | Configuration for the app-of-apps Application (`<project>-apps`). `source.repoURL`, `source.path`, and `source.targetRevision` are injected by the tenant chart. Override per project via `projects.<name>.application` in the tenant chart. |
| application.source.repoURL | string | `""` | Required. Git repository URL for the app-of-apps. Injected by the tenant chart. |
| application.source.path | string | `""` | Required. Path to the app-of-apps directory. Injected by the tenant chart. |
| application.source.targetRevision | string | `""` | Required. Git branch, tag, or commit SHA. Injected by the tenant chart. |
| application.source.helm.valueFiles | list | [values.yaml] | Optional. Helm value files passed to the app-of-apps Application. |
| application.syncPolicy | object | `{"automated":{"prune":true}}` | Optional. Sync policy for the app-of-apps Application. |
| resourceQuota.enabled | bool | `true` | Optional. Enable or disable the ResourceQuota resource. |
| resourceQuota.spec | object | `{}` | Required when enabled. ResourceQuota hard limits. Set via `projectDefaults.resourceQuota.spec` in the tenant chart. See [Kubernetes ResourceQuota](https://kubernetes.io/docs/concepts/policy/resource-quotas/). |
| limitRange.enabled | bool | `false` | Optional. Enable or disable the LimitRange resource. |
| limitRange.spec | object | `{"limits":[{"default":{"cpu":"50m","memory":"64Mi"},"defaultRequest":{"cpu":"25m","memory":"32Mi"},"type":"Container"}]}` | Optional. LimitRange limits spec. See [Kubernetes LimitRange](https://kubernetes.io/docs/concepts/policy/limit-range/). |
| templates | object | See below | Optional. Values passed to the `templates` subchart. Set `enabled: false` to disable the subchart entirely — no NetworkPolicies are rendered at all. Add entries to `networkPolicies` or `ciliumNetworkPolicies` to create extra policies (e.g. cross-namespace connectivity). |
| templates.enabled | bool | `true` | Optional. Enable or disable the `templates` subchart. When false, no NetworkPolicies (default or custom) are rendered. |
| templates.networkPolicies.default-deny | object | `{"podSelector":{},"policyTypes":["Ingress","Egress"]}` | Default deny-all policy. Blocks all ingress and egress by default. |
| templates.networkPolicies.allow-within-namespace | object | `{"egress":[{"to":[{"podSelector":{}}]}],"ingress":[{"from":[{"podSelector":{}}]}],"podSelector":{},"policyTypes":["Ingress","Egress"]}` | Allow pod-to-pod communication within the same namespace. |
| templates.ciliumNetworkPolicies.allow-kube-dns | object | `{"egress":[{"toEndpoints":[{"matchLabels":{"k8s:io.kubernetes.pod.namespace":"kube-system","k8s:k8s-app":"kube-dns"}}],"toPorts":[{"ports":[{"port":"53","protocol":"ANY"}],"rules":{"dns":[{"matchPattern":"*"}]}}]}],"endpointSelector":{}}` | Allow DNS egress to kube-dns. Required for Cilium FQDN-based policies. |

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
| `NetworkPolicy` | `default-deny` | `templates.enabled` |
| `CiliumNetworkPolicy` | `allow-kube-dns` | `templates.enabled` |
| `NetworkPolicy` | `allow-within-namespace` | `templates.enabled` |
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
      repoURL: https://github.com/example/tenant-repo
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
which renders extra `NetworkPolicy` and `CiliumNetworkPolicy` resources from a values map.
Use it to express cross-namespace connectivity on top of the default policies.

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
