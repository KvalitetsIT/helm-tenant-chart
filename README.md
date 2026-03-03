# helm-tenant-chart

Helm charts for ArgoCD multi-tenancy. Two charts work together to provision fully isolated tenant
environments on a shared ArgoCD installation.

## Charts

| Chart | Description |
|-------|-------------|
| [tenant](charts/tenant/) | Provisions the full tenant structure: namespace, AppProjects, and one project Application per team |
| [project](charts/project/) | Provisions per-project infrastructure: namespace, AppProject, app-of-apps, quotas, and network policies |

The **tenant chart** is installed once per tenant (customer / business unit). It manages project
chart deployments via ArgoCD Applications — the project chart is never installed manually.

## Architecture

```
Tenant (e.g. acme)
├── Namespace:   acme
├── AppProject:  acme-projects         governs project chart Applications
├── AppProject:  acme-apps             governs app-of-apps Applications
└── per project (e.g. inventory, reporting, data)
    └── Application: <project>-project  ──► project chart
            ├── Namespace:    acme-<project>
            ├── AppProject:   acme-<project>
            ├── Application:  <project>-apps  ──► your git repo
            ├── ResourceQuota
            └── NetworkPolicies (default-deny, allow-kube-dns, allow-within-namespace)
```

See the [tenant chart README](charts/tenant/README.md) for full details on AppProject hierarchy,
RBAC roles, and configuration options.

## Development

### Prerequisites

- Docker (for `make docs` and `make lint`)
- Helm 3 (for manual dependency management)

### Generate docs

Regenerate the `README.md` for both charts from their `README.md.gotmpl` templates:

```bash
make docs
```

The tenant chart merges `values.yaml` with `values-docs.yaml` before generating docs.
`values-docs.yaml` documents the per-project keys that belong to the `projects.<name>` map and
cannot be expressed in `values.yaml` directly.

### Lint

Run chart-testing lint against all charts:

```bash
make lint
```

Run both docs and lint:

```bash
make
```

## Releasing

Each chart is released independently by pushing a tag with the pattern `<chart>-v<version>`:

```bash
git tag tenant-v1.2.0 && git push origin tenant-v1.2.0
git tag project-v1.2.0 && git push origin project-v1.2.0
```

The [release workflow](.github/workflows/release.yaml) then automatically:

1. Detects the chart and version from the tag
2. Packages the chart (with `helm dependency update`)
3. Publishes it to [KvalitetsIT/helm-repo](https://github.com/KvalitetsIT/helm-repo)
4. Creates a GitHub Release with auto-generated notes

## CI

Pull requests are validated by the [PR workflow](.github/workflows/pr.yaml):

- Lints all charts with `ct lint`
- Installs all charts into a KinD cluster with `ct install`
- Required CRDs (ArgoCD, SealedSecrets, Cilium) are installed before the install step
