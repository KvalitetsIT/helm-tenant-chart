# tenant

![Version: 1.0.0](https://img.shields.io/badge/Version-1.0.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for creating a new tenant in the Kithosting platform

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
| nameOverride | string | `""` | Optional. Name override for the tenant. |
| roleGroups | object | `{}` | Optional. Map of role name → AD/OIDC group list applied globally to all AppProjects. Acts as the lowest-precedence default — per-project `appProject.roles.<name>.groups` always wins. |
| tenantNamespace.labels | object | `{}` | Optional. Additional labels for the tenant namespace. |
| tenantNamespace.annotations | object | `{}` | Optional. Additional annotations for the tenant namespace. |
| projectDefaults | object | See below | Shared defaults applied to every project. All keys are deep-merged with `projects.<name>` — project values win. See the [project chart values](../project/README.md#values) for the full schema, including `limitRange`, `templates`, `appProject`, and `namespace`. |
| projectDefaults.projectApplication | object | See below | Default deployment config for `<project>-project` Applications (runs the project chart). Governed by the `<tenant>-projects` AppProject. Per-project override: `projects.<name>.projectApplication`. |
| projectDefaults.projectApplication.source.repoURL | string | `"https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/"` | Required. OCI/Helm repository URL for the project chart. |
| projectDefaults.projectApplication.source.chart | string | `"project"` | Required. Chart name within the repository. |
| projectDefaults.projectApplication.source.targetRevision | string | `"1.*"` | Required. Chart version to deploy. Supports semver ranges. |
| projectDefaults.projectApplication.syncPolicy | object | `{"automated":{"prune":true,"selfHeal":true}}` | Optional. Sync policy applied to all project Applications. |
| projectDefaults.application | object | See below | Default config for `<project>-apps` Applications (app-of-apps). Governed by the `<tenant>-apps` AppProject. `source.path` cannot be set here — it must be provided per project. Per-project override: `projects.<name>.application`. |
| projectDefaults.application.source.repoURL | string | `""` | Required. Default git repository URL for the app-of-apps. |
| projectDefaults.application.source.targetRevision | string | `""` | Required. Default git branch, tag, or commit SHA. |
| projectDefaults.application.source.helm | object | `{"valueFiles":["values.yaml"]}` | Optional. Default Helm value files passed to the app-of-apps Application. Per-project overrides replace this list entirely. |
| projectDefaults.resourceQuota | object | See below | Default ResourceQuota passed to every project via the project chart. `limits.cpu`, `limits.memory`, and `requests.storage` have no project chart defaults — they must be set here or per project. Per-project override: `projects.<name>.resourceQuota`. |
| projectDefaults.resourceQuota.spec.hard."limits.cpu" | string | `""` | Required |
| projectDefaults.resourceQuota.spec.hard."limits.memory" | string | `""` | Required |
| projectDefaults.resourceQuota.spec.hard."requests.storage" | string | `""` | Required |
| projects | object | See below | Map of tenant projects to create. Each key becomes a project named `<tenant>-<key>`. See the [project chart values](../project/README.md#values) for the full schema and the default values. |
| projects.\<project-name>.namespace | object | `{"annotations":{},"labels":{}}` | Optional. Labels and annotations for the project namespace. Overrides `projectDefaults.namespace`. |
| projects.\<project-name>.projectApplication.source.targetRevision | string | `"1.*"` | Optional. Pin a specific project chart version for this project. Overrides `projectDefaults.projectApplication.source.targetRevision`. |
| projects.\<project-name>.appProject | object | See below | Optional. Additional RBAC roles for the per-project AppProject. Merged on top of the project chart's default roles (viewer, developer). Supports `{tenant}` and `{project}` placeholder substitution. Overrides `projectDefaults.appProject`. |
| projects.\<project-name>.appProject.namespaceResourceWhitelist | list | `[{"group":"*","kind":"*"}]` | Optional. Kubernetes resource kinds allowed in the project namespace. Wildcard allows all — tighten per project as needed. Overrides `projectDefaults.appProject.namespaceResourceWhitelist`. |
| projects.\<project-name>.appProject.namespaceResourceBlacklist | list | `[{"group":"rbac.authorization.k8s.io","kind":"Role"},{"group":"rbac.authorization.k8s.io","kind":"RoleBinding"},{"group":"","kind":"ResourceQuota"},{"group":"","kind":"LimitRange"}]` | Optional. Kubernetes resource kinds explicitly denied in the project namespace. Prevents tenants from managing resources that are owned by the tenant chart. Overrides `projectDefaults.appProject.namespaceResourceBlacklist`. |
| projects.\<project-name>.appProject.roles | object | See below | Optional. RBAC roles for the AppProject. Supports `{tenant}` and `{project}` placeholder substitution. Overrides `projectDefaults.appProject.roles`. |
| projects.\<project-name>.appProject.roles.viewer | object | `{"description":"Read-only access to {project} workloads","groups":["{tenant}-viewer"],"policies":["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow"]}` | Optional. Read-only role — grants view and log access to project workloads. |
| projects.\<project-name>.appProject.roles.viewer.groups | list | `["{tenant}-viewer"]` | Optional. AD/OIDC groups granted the viewer role. |
| projects.\<project-name>.appProject.roles.viewer.policies | list | `["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the viewer role. |
| projects.\<project-name>.appProject.roles.developer | object | `{"description":"Can sync and all actions on {project} workloads","groups":["{tenant}-developer"],"policies":["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenant}/*, allow","applications, update/*, {project}/{tenant}/*, allow","applications, delete, {project}/{tenant}/*, allow","applications, delete/*, {project}/{tenant}/*, allow","applications, sync, {project}/{tenant}/*, allow","applications, action/*, {project}/{tenant}/*, allow"]}` | Optional. Developer role — grants full sync and action access to project workloads. |
| projects.\<project-name>.appProject.roles.developer.groups | list | `["{tenant}-developer"]` | Optional. AD/OIDC groups granted the developer role. |
| projects.\<project-name>.appProject.roles.developer.policies | list | `["applications, get, {project}/{tenant}/*, allow","logs, get, {project}/*, allow","applications, update, {project}/{tenant}/*, allow","applications, update/*, {project}/{tenant}/*, allow","applications, delete, {project}/{tenant}/*, allow","applications, delete/*, {project}/{tenant}/*, allow","applications, sync, {project}/{tenant}/*, allow","applications, action/*, {project}/{tenant}/*, allow"]` | Optional. ArgoCD RBAC policy strings for the developer role. |
| projects.\<project-name>.application.source.path | string | `"<project>/apps"` | Required. Path to the app-of-apps directory in the git repository. |
| projects.\<project-name>.application.source.repoURL | string | `"https://github.com/example/tenant-repo"` | Optional. Git repository URL. Overrides `projectDefaults.application.source.repoURL`. |
| projects.\<project-name>.application.source.targetRevision | string | `"main"` | Optional. Git branch, tag, or commit SHA. Overrides `projectDefaults.application.source.targetRevision`. |
| projects.\<project-name>.application.source.helm.valueFiles | list | `["values.yaml"]` | Optional. Helm value files. Overrides `projectDefaults.application.source.helm.valueFiles`. |
| projects.\<project-name>.resourceQuota | object | `{"spec":{"hard":{"limits.cpu":"","limits.memory":"","requests.storage":""}}}` | Required if not set in projectDefaults. ResourceQuota hard limits. Overrides `projectDefaults.resourceQuota`. |
| projects.\<project-name>.limitRange | object | `{"enabled":false,"spec":{"limits":[{"default":{"cpu":"50m","memory":"64Mi"},"defaultRequest":{"cpu":"25m","memory":"32Mi"},"type":"Container"}]}}` | Optional. LimitRange configuration. Overrides `projectDefaults.limitRange`. |
| projects.\<project-name>.templates | object | `{"enabled":true}` | Optional. Enable or disable the `templates` subchart for this project. When false, no NetworkPolicies (default or custom) are rendered. Overrides `projectDefaults.templates`. |

## Architecture

The tenant chart sets up the full ArgoCD multi-tenancy structure for one tenant. It creates two
tenant-level AppProjects, a tenant namespace, and one `<project>-project` Application per project.
Each `<project>-project` Application deploys the [project chart](../project/) which creates the
per-project infrastructure.

### What the Tenant Chart Creates

| Resource | Name | Description |
|----------|------|-------------|
| `Namespace` | `<tenant>` | Tenant namespace — all Applications live here |
| `AppProject` | `<tenant>-apps` | Governs app-of-apps Applications |
| `AppProject` | `<tenant>-projects` | Governs project chart deployments |
| `Application` | `<project>-project` | Deploys the project chart (one per project) |
| `SealedSecret` | `<key>` (extra) | Optional ArgoCD repo secrets via `templates.sealedSecrets` |

### What the Project Chart Creates (per project)

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

### AppProject Hierarchy

Three AppProjects govern the system at different levels:

```
<tenant>-projects   — allows project chart Applications to create Namespaces
<tenant>-apps       — allows app-of-apps Applications to deploy into <tenant>
<tenant>-<project>  — allows workload Applications to deploy into <tenant>-<project>
```

The per-project AppProject (`<tenant>-<project>`) is created by the project chart. Its RBAC roles
default to `viewer` and `developer` and support `{tenant}` / `{project}` placeholder substitution,
where `{project}` resolves to the full project namespace `<tenant>-<project>`.

## Projects

Each entry under `projects` provisions a complete project setup. The minimum required per project
is `application.source.path`. All other fields either have defaults in `projectDefaults` or are
optional project chart values.

Values flow: `projectDefaults` is deep-merged with `projects.<name>` — project values win.
The merged result (minus `projectApplication`) is passed to the project chart as `valuesObject`.

## Examples

### Minimal

Single project with required fields only. `repoURL` and `targetRevision` are shared across all
projects in `projectDefaults`; only the git path is set per project.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"  # shared across all projects
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "8"
        limits.memory: "16Gi"
        requests.storage: "200Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"  # only required per-project field
```

---

### Multiple Projects

Multiple projects sharing global defaults, with per-project resource quota overrides for
projects that need more or fewer resources.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"        # default quota applied to all projects
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"

  reporting:
    application:
      source:
        path: "reporting/apps"
    resourceQuota:
      spec:
        hard:
          limits.cpu: "8"        # override the default quota for this project
          limits.memory: "16Gi"
          requests.storage: "200Gi"

  data:
    application:
      source:
        path: "data/apps"
    resourceQuota:
      spec:
        hard:
          limits.cpu: "16"
          limits.memory: "32Gi"
          requests.storage: "500Gi"
```

---

### Custom Role Groups

Override the default `{tenant}-viewer` / `{tenant}-developer` AD groups globally across all
AppProjects using `roleGroups`. Per-project `appProject.roles.<name>.groups` always takes
precedence over `roleGroups`.

```yaml
roleGroups:
  viewer:
    - tenant-readers@company.com    # replaces the default {tenant}-viewer group
  developer:
    - tenant-devs@company.com       # replaces the default {tenant}-developer group

projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"
```

---

### Per-project Custom RBAC Role

Add a custom `ops` role to one project's AppProject, in addition to the default viewer and
developer roles. Supports `{tenant}` and `{project}` placeholder substitution.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"
    appProject:
      roles:
        ops:
          description: "Ops access to {project}"
          groups:
            - inventory-ops@company.com
          policies:
            - "applications, *, {project}/{tenant}/*, allow"  # {project} → <tenant>-<project>
            - "logs, get, {project}/*, allow"
```

---

### Customize Network Policies

Disable all NetworkPolicies for a project that requires unrestricted connectivity, while keeping
them enabled for all other projects via `projectDefaults`. Setting `templates.enabled: false`
disables the `templates` subchart entirely — no default or custom NetworkPolicies are rendered.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"

  legacy:
    application:
      source:
        path: "legacy/apps"
    templates:
      enabled: false  # disables the templates subchart — no NetworkPolicies rendered at all
```

---

### Pin Project Chart Version

Pin a specific project chart version for one project while leaving others on the floating
`projectDefaults` version. Useful when rolling out a new project chart version incrementally.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"
    projectApplication:
      source:
        targetRevision: "1.2.0"  # pin project chart version; others use the projectDefaults version

  reporting:
    application:
      source:
        path: "reporting/apps"
```

---

### Declarative ArgoCD Repositories

Register git repositories and credential templates with ArgoCD using SealedSecrets. SealedSecrets
are decrypted in-cluster by the [Sealed Secrets](https://github.com/bitnami-labs/sealed-secrets)
controller and picked up automatically by ArgoCD. Encrypt values with:

```bash
echo -n 'my-token' | kubeseal --raw --scope cluster-wide --namespace argocd --name <secret-name>
```

A **repository secret** registers one specific git repository. A **repo-creds template** matches
all repositories under a URL prefix — useful when a tenant has many repositories under the same
organization.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  inventory:
    application:
      source:
        path: "inventory/apps"

# Register git repositories and credential templates with ArgoCD.
# SealedSecrets are decrypted in-cluster by the Sealed Secrets controller and picked up by ArgoCD.
templates:
  sealedSecrets:

    # Repository secret — registers one specific git repository.
    acme-tenant-repo:
      metadata:
        namespace: argocd       # must be argocd namespace regardless of release namespace
      encryptedData:
        password: AgB...        # encrypt: kubeseal --raw --scope cluster-wide --namespace argocd
      template:
        metadata:
          labels:
            argocd.argoproj.io/secret-type: repository
        data:
          type: git
          url: https://github.com/example/tenant-repo
          username: git

    # Repo-creds template — matches all repositories under a URL prefix.
    # ArgoCD automatically applies these credentials to any repo whose URL starts with the prefix.
    acme-repo-creds:
      metadata:
        namespace: argocd
      encryptedData:
        password: AgB...
      template:
        metadata:
          labels:
            argocd.argoproj.io/secret-type: repo-creds
        data:
          type: git
          url: https://github.com/example/  # prefix — matches all repos under this org
          username: git
```

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
