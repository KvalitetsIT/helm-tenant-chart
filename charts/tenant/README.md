# tenant

![Version: 2.1.0](https://img.shields.io/badge/Version-2.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.0.0](https://img.shields.io/badge/AppVersion-1.0.0-informational?style=flat-square)

A Helm chart for creating a new tenant in the Kithosting platform

**Homepage:** <https://github.com/KvalitetsIT>

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| KvalitetsIT | <kithosting@kvalitetsit.dk> | <https://github.com/KvalitetsIT/helm-repo> |

## Source Code

* <https://github.com/KvalitetsIT/helm-tenant-chart>
* <https://github.com/KvalitetsIT/helm-tenant-chart/tree/main/charts/tenant>

## Requirements

| Repository | Name | Version |
|------------|------|---------|
| https://raw.githubusercontent.com/KvalitetsIT/helm-repo/master/ | templates | 2.2.0 |

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

## Self-Service Projects (ApplicationSet)

Set `applicationSet.enabled: true` to let a tenant create their own projects from a
tenant-owned git repo, instead of an admin editing `projects` here. In this mode the in-chart
`projects` loop is **replaced** by an ArgoCD `ApplicationSet` whose generator reads a single
file (default `projects.yaml`) holding the same name-keyed `projects` map:

```yaml
# tenant repo: projects.yaml
projects:
  inventory:
    application:
      source:
        path: inventory/apps
  reporting:
    application:
      source:
        path: reporting/apps
```

The tenant may set **only** the per-project `application` block — every other field (quota,
roles, chart version) is read from `projectDefaults` and the admin `projects.<name>` map in this
values file, which **wins** on any conflict. The ApplicationSet template only ever reads the
tenant's `application` block, so quota and roles can't be set by tenants. An
`application.source.repoURL` does flow through, but an unauthorized one is **rejected by the
`<tenant>-apps` AppProject** `sourceRepos` at sync time — the AppProject is the enforcement
layer, so no extra guard is needed in the template.

The rendered project set is the **union** of the tenant file's `projects` map and the admin
`projects` map here. So an admin can also **define** a project (give it
`application.source.path` in this values file and it is created even if the tenant file omits
it) and **override** a tenant-created project (same name → merged, admin wins). Project
existence comes from either side; per-project values merge as:

`projectDefaults` → tenant `application` → admin `projects.<name>` (wins).

The `<tenant>-projects` AppProject uses a `<tenant>-*` destination wildcard in this mode (project
names are not known at render time). Validate the tenant's `projects.yaml` in that repo's CI
(DNS-1123 names) as a user-facing guard; the project chart's own DNS-1123 check is the in-cluster
backstop. The ApplicationSet is created in the tenant namespace, so the applicationset-controller
must run with `--applicationset-namespaces=*` (and `--enable-scm-providers=false` alongside it).

**Pruning safety.** `applicationSet.syncPolicy` defaults to `applicationsSync: create-update` and
`preserveResourcesOnDeletion: true`, so a broken or empty `projects.yaml` cannot delete existing
projects (and their namespaces). With `create-update`, a project dropped from the generator is
**not** auto-deleted — removal is a deliberate admin action. Set `applicationsSync: ""` to allow
automatic deletion of dropped projects.

```yaml
applicationSet:
  enabled: true
  generator:
    git:
      repoURL: "https://github.com/example/tenant-repo.git"
      revision: main
      files:
        - path: "projects.yaml"

projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo.git"
      targetRevision: "main"
  resourceQuota:
    spec:
      hard:
        limits.cpu: "4"
        limits.memory: "8Gi"
        requests.storage: "100Gi"

projects:
  reporting:
    application:
      source:
        path: reporting/apps
  inventory:
    resourceQuota:
      spec:
        hard:
          limits.cpu: "16"
          limits.memory: "32Gi"
          requests.storage: "500Gi"
```

## Examples

### Minimal

Single project with required fields only. `repoURL` and `targetRevision` are shared across all
projects in `projectDefaults`; only the git path is set per project.

```yaml
projectDefaults:
  application:
    source:
      repoURL: "https://github.com/example/tenant-repo.git"  # shared across all projects
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
      repoURL: "https://github.com/example/tenant-repo.git"
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
        namespace: argocd       # must be argocd root namespace regardless of release namespace
      encryptedData:
        password: AgB...        # encrypt: kubeseal --raw --scope cluster-wide --namespace argocd
      template:
        metadata:
          labels:
            argocd.argoproj.io/secret-type: repository
        data:
          type: git
          url: https://github.com/example/tenant-repo.git
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
