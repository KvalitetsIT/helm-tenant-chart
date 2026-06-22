# Sync and prune safety - worked example

The platform stacks ArgoCD Applications in layers (app-of-apps): each layer creates the
Applications of the next. This example shows the recommended sync/prune policy at every
layer, scaled by **blast radius**:

- **Top layers** can delete a whole tenant or project - prune and cascade-delete stay
  automatic but **pause for a manual confirmation**.
- **Leaf workloads** are a single app - they **prune and self-heal freely**.
- **Data** is **pinned** and never pruned or cascade-deleted.

Names (`tenant-a`, `web`, `example-org`) are placeholders - replace with your own.

## Layer chain

Each layer creates the one nested beneath it:

```text
L0  Bootstrap - one Application per tenant
  L1  Provisioning - creates the project: namespace, quota, AppProject
    L2  App-of-apps - points at the tenant's app repo
      L3  Leaf - one Application per workload
        L4  Workload resources + data
```

## Policy by layer

| Layer | You set it in | enabled | prune | selfHeal | syncOptions |
|-------|---------------|:-------:|:-----:|:--------:|-------------|
| **L0** Bootstrap | your argocd-apps values | yes | yes | yes | `Prune=confirm`, `Delete=confirm` |
| **L1** Provisioning | tenant-chart default | yes | yes | yes | `Prune=confirm`, `Delete=confirm` |
| **L2** App-of-apps | tenant-chart default | yes | yes | no | `PruneLast=true` |
| **L3** Leaf | your argocd-apps values | yes | yes | yes | (none) |
| **L4** Data | resource annotation | n/a | n/a | n/a | `Prune=false[,Delete=false]` |

- **confirm** - prune and cascade-delete wait for an explicit click in the UI: nothing
  structural is deleted by accident, but intentional teardown still works.
- **no selfHeal at L2** - the break-glass: an operator can pause or override a child app
  in the UI and the app-of-apps will not revert it.
- **enabled** - `automated.enabled` is declared in git (not just `prune`/`selfHeal`) so that
  turning auto-sync off on a child app in the UI shows as drift on the parent instead of being
  silently ignored. Needs ArgoCD 3.1+.
- L1 and L2 are tenant-chart defaults; you write only L0, L3 and L4.

## Files

The two folders mirror the two repos you keep - a **bootstrap repo** and a tenant's
**app repo**.

### L0 - [tenant-bootstrap-repo/tenant-apps/values.yaml](tenant-bootstrap-repo/tenant-apps/values.yaml)

```yaml
# Layer 0 - Bootstrap. One ArgoCD Application per tenant, rendered by argocd-apps.
# Highest blast radius (a whole tenant): auto-sync, but every prune and cascade-delete
# pauses for a manual confirmation in the UI.

# Sync policy anchor. `automated.enabled` (ArgoCD 3.1+) is declared so a UI auto-sync
# toggle shows as drift, not ignored.
_syncPolicy: &syncPolicy
  automated:
    enabled: true
    prune: true
    selfHeal: true
  syncOptions:
    - Prune=confirm
    - Delete=confirm

# Application defaults anchor.
_appDefaults: &appDefaults
  namespace: tenants
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  project: tenants

# Tenant-bootstrap repository source anchor.
_source: &source
  repoURL: https://github.com/example-org/tenant-bootstrap.git
  targetRevision: main

# In-cluster destination server anchor.
_inClusterServer: &inClusterServer https://kubernetes.default.svc

argocd-apps:
  applications:
    # One entry per tenant; all inherit the anchors above. Override syncPolicy per app.
    tenant-a:
      <<: *appDefaults
      syncPolicy: *syncPolicy
      source:
        <<: *source
        path: tenant-a                 # dir holding this tenant's `tenant` values (Layer 1/2)
        helm:
          valueFiles:
            - values.yaml
      destination:
        namespace: tenant-a
        server: *inClusterServer
```

### L1 + L2 - [tenant-bootstrap-repo/tenant-a/values.yaml](tenant-bootstrap-repo/tenant-a/values.yaml)

Loaded by a small wrapper chart, [tenant-a/Chart.yaml](tenant-bootstrap-repo/tenant-a/Chart.yaml).

```yaml
# Layer 1 + 2 - values for the `tenant` chart (rendered by the Layer 0 Application).
# The L1/L2 sync policy ships as the tenant-chart default, so you only declare your
# projects. Override per project under `projects.<name>.application.syncPolicy`.
tenant:
  projectDefaults:
    application:
      source:
        repoURL: https://github.com/example-org/app-repo.git   # your app repo (Layer 3)
        targetRevision: main
    resourceQuota:
      spec:
        hard:
          limits.cpu: "8"
          limits.memory: 16Gi
          requests.storage: 50Gi
  projects:
    web:
      application:
        source: {path: web/apps}                               # dir in the app repo
```

### L3 - [application-repo/web/apps/values.yaml](application-repo/web/apps/values.yaml)

```yaml
# Layer 3 - Leaf workloads, rendered by argocd-apps. One Application per workload.
# Lowest blast radius, so be aggressive: prune + self-heal. Override syncPolicy per app.

# Sync policy anchor. `automated.enabled` (ArgoCD 3.1+) is declared so a UI auto-sync
# toggle shows as drift, not ignored.
_syncPolicy: &syncPolicy
  automated:
    enabled: true
    prune: true
    selfHeal: true

# Application defaults anchor.
_appDefaults: &appDefaults
  namespace: tenant-a
  finalizers:
    - resources-finalizer.argocd.argoproj.io
  project: tenant-a-web

# App repository source anchor.
_source: &source
  repoURL: https://github.com/example-org/app-repo.git
  targetRevision: main

# In-cluster destination server anchor.
_inClusterServer: &inClusterServer https://kubernetes.default.svc

argocd-apps:
  applications:
    web-frontend:                      # stateless - base policy
      <<: *appDefaults
      syncPolicy: *syncPolicy
      source:
        <<: *source
        path: web/frontend
      destination:
        namespace: tenant-a-web
        server: *inClusterServer

    web-database:                      # stateful - extend base, drop self-heal
      <<: *appDefaults
      syncPolicy:
        <<: *syncPolicy
        automated:
          enabled: true
          prune: true
          selfHeal: false
      source:
        <<: *source
        path: web/database
      destination:
        namespace: tenant-a-web
        server: *inClusterServer
```

### L4 - [application-repo/web/database/pvc.yaml](application-repo/web/database/pvc.yaml)

```yaml
# Layer 4 - Stateful data (tenant-owned; not enforced by the platform).
# Pin data so ArgoCD never prunes or cascade-deletes it, while the workload around it
# still prunes freely.
#   Prune=false  - survives removal from git
#   Delete=false - survives a cascade delete of the parent Application
# Use both for volumes with no backup; Prune=false alone is enough for backed-up databases.
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: web-database-data
  annotations:
    argocd.argoproj.io/sync-options: Prune=false,Delete=false
spec:
  accessModes: [ReadWriteOnce]
  resources:
    requests:
      storage: 10Gi
```

The workload that uses the volume keeps the aggressive Layer 3 policy - only the PVC opts
out. See the full file for the accompanying `StatefulSet`.

## Requirements

- `automated.enabled` (L0-L3) requires ArgoCD 3.1+. On older versions the field is dropped from
  the live object, leaving a permanent OutOfSync - omit `enabled` if you must run < 3.1.
- `Prune=confirm` / `Delete=confirm` (L0, L1) require ArgoCD 2.14+.
