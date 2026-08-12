{{/* Validate a single DNS-1123 label and fail with a clear message.
     Call with a list: (list $value "fieldName") */}}
{{- define "tenant.validateDNS1123Label" -}}
{{- $value := index . 0 -}}
{{- $field := index . 1 -}}
{{- if not (regexMatch "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" $value) -}}
  {{- fail (printf "%s %q is not a valid DNS-1123 label: must consist of lowercase alphanumerics and hyphens, and start and end with an alphanumeric character" $field $value) -}}
{{- end -}}
{{- end -}}

{{/* Tenant name — defaults to release name, validated against DNS-1123 */}}
{{- define "tenant.name" -}}
{{- $name := default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- include "tenant.validateDNS1123Label" (list $name "tenant name") -}}
{{- $name -}}
{{- end -}}

{{/* Tenant namespace — defaults to tenant name, overrideable via tenantNamespace.name */}}
{{- define "tenant.tenantNamespace" -}}
{{- $ns := default (include "tenant.name" .) .Values.tenantNamespace.name -}}
{{- include "tenant.validateDNS1123Label" (list $ns "tenantNamespace.name") -}}
{{- $ns -}}
{{- end -}}

{{/* Project namespace: defaults to <tenant>-<project>, overrideable via an optional third element.
     Call with a list: (list $tenantName $projectName)
                    or (list $tenantName $projectName $namespaceOverride) */}}
{{- define "tenant.projectNamespace" -}}
{{- $tenantName := index . 0 -}}
{{- $projectName := index . 1 -}}
{{- $override := index . 2 | default "" -}}
{{- if $override -}}
  {{- include "tenant.validateDNS1123Label" (list $override "namespace.name") -}}
  {{- $override -}}
{{- else -}}
  {{- include "tenant.validateDNS1123Label" (list $projectName "project key") -}}
  {{- $ns := printf "%s-%s" $tenantName $projectName -}}
  {{- if gt (len $ns) 63 -}}
    {{- fail (printf "combined namespace %q exceeds the 63-character DNS-1123 limit (%d chars)" $ns (len $ns)) -}}
  {{- end -}}
  {{- $ns -}}
{{- end -}}
{{- end -}}

{{/* Fail if a resolved project namespace collides with the tenant admin namespace.
     Call with: (dict "projectName" $name "projectNs" $projNs "adminNs" $adminNs) */}}
{{- define "tenant.validateNoNamespaceConflict" -}}
{{- if eq .projectNs .adminNs -}}
  {{- fail (printf "project %q: resolved namespace %q conflicts with the tenant admin namespace - use a different namespace.name" .projectName .projectNs) -}}
{{- end -}}
{{- end -}}

{{/* Chart name + version label value */}}
{{- define "tenant.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Standard labels applied to every resource in the tenant chart */}}
{{- define "tenant.labels" -}}
helm.sh/chart: {{ include "tenant.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/* Validate that disallowed fields are not set in projectDefaults.
     Call with: (include "tenant.validateProjectDefaults" .Values.projectDefaults) */}}
{{- define "tenant.validateProjectDefaults" -}}
{{- if dig "application" "source" "path" "" . -}}
  {{- fail "projectDefaults.application.source.path is not allowed — path must be set per project" -}}
{{- end -}}
{{- end -}}

{{/* AppProject name for the tenant level: <tenant>-apps (e.g. acme-apps) */}}
{{- define "tenant.tenantAppProjectName" -}}
{{- printf "%s-apps" (include "tenant.name" .) -}}
{{- end -}}

{{/* AppProject name for the project level: <tenant>-projects (e.g. acme-projects) */}}
{{- define "tenant.projectAppProjectName" -}}
{{- printf "%s-projects" (include "tenant.name" .) -}}
{{- end -}}

{{/* Deep-merge two dicts, override takes priority.
     Expects: (dict "defaults" $defaults "override" $override) */}}
{{- define "tenant.merge" -}}
{{- $merged := mergeOverwrite (deepCopy (.defaults | default dict)) (deepCopy (.override | default dict)) -}}
{{- toYaml $merged -}}
{{- end -}}

{{/* Build the complete valuesObject passed to the project chart Application.
     Expects: (dict "root" $ "name" $name "p" $p)
     where $p = fromYaml (include "tenant.merge" (dict "defaults" $.Values.projectDefaults "override" $project))
     Only projectApplication is stripped (tenant-internal); everything else flows through.
     Identity fields (tenantName, projectName, tenantAppProjectName) always override user-supplied values.
     Injects a `global` block (tenantName, tenantNamespace, plus projectName/projectNamespace when
     name is set) so the project's templates subchart can read `.Values.global.*`.
     appProject is rebuilt with roleGroups as the lowest-precedence base. */}}
{{- define "tenant.buildValuesObject" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $p := .p -}}
{{- $tenantName := include "tenant.name" $root -}}
{{- $tenantNamespace := include "tenant.tenantNamespace" $root -}}
{{- $valuesObject := deepCopy (omit $p "projectApplication") -}}
{{- $global := dict "tenantName" $tenantName "tenantNamespace" $tenantNamespace -}}
{{- if $name -}}
  {{- $_ := set $global "projectName" $name -}}
  {{- $_ := set $global "projectNamespace" (include "tenant.projectNamespace" (list $tenantName $name (($p.namespace).name))) -}}
{{- end -}}
{{- $valuesObject = mergeOverwrite $valuesObject (dict
  "tenantName" $tenantName
  "projectName" $name
  "tenantAppProjectName" (include "tenant.tenantAppProjectName" $root)
  "argoNamespace" $root.Values.argoNamespace
  "tenantNamespace" $tenantNamespace
  "global" $global
) -}}
{{- if or $root.Values.roleGroups $p.appProject -}}
  {{- $roleGroupOverrides := dict -}}
  {{- range $roleName, $groups := $root.Values.roleGroups -}}
    {{- $_ := set $roleGroupOverrides $roleName (dict "groups" $groups) -}}
  {{- end -}}
  {{- $valuesObject = mergeOverwrite $valuesObject (dict "appProject" (mergeOverwrite (deepCopy (dict "roles" $roleGroupOverrides)) ($p.appProject | default dict))) -}}
{{- end -}}
{{- toYaml $valuesObject -}}
{{- end -}}

{{/* Unique app-of-apps repoURLs: the projectDefaults default plus any per-project overrides. Yields a YAML list. */}}
{{- define "tenant.applicationSourceRepos" -}}
{{- $repos := list -}}
{{- with .Values.projectDefaults.application.source.repoURL -}}
  {{- $repos = append $repos . -}}
{{- end -}}
{{- range $name, $project := .Values.projects -}}
  {{- $p := fromYaml (include "tenant.merge" (dict "defaults" $.Values.projectDefaults "override" $project)) -}}
  {{- $url := $p.application.source.repoURL -}}
  {{- if and $url (not (has $url $repos)) -}}
    {{- $repos = append $repos $url -}}
  {{- end -}}
{{- end -}}
{{- toYaml $repos -}}
{{- end -}}

{{/* Unique project-chart (OCI) repoURLs: the projectDefaults default plus any per-project overrides. Yields a YAML list. */}}
{{- define "tenant.projectSourceRepos" -}}
{{- $repos := list -}}
{{- with .Values.projectDefaults.projectApplication.source.repoURL -}}
  {{- $repos = append $repos . -}}
{{- end -}}
{{- range $name, $project := .Values.projects -}}
  {{- $p := fromYaml (include "tenant.merge" (dict "defaults" $.Values.projectDefaults "override" $project)) -}}
  {{- $url := $p.projectApplication.source.repoURL -}}
  {{- if and $url (not (has $url $repos)) -}}
    {{- $repos = append $repos $url -}}
  {{- end -}}
{{- end -}}
{{- toYaml $repos -}}
{{- end -}}

{{/* Admin base valuesObject (JSON) for the ApplicationSet: buildValuesObject of projectDefaults, without projectName or tenant source (merged in per-item at runtime). */}}
{{- define "tenant.applicationSetBase" -}}
{{- include "tenant.validateProjectDefaults" .Values.projectDefaults -}}
{{- $p := fromYaml (include "tenant.merge" (dict "defaults" .Values.projectDefaults "override" dict)) -}}
{{- include "tenant.buildValuesObject" (dict "root" . "name" "" "p" $p) | fromYaml | toJson -}}
{{- end -}}

{{/* Admin projects map (JSON), projectApplication stripped — the per-project override source for the ApplicationSet (matched by name, admin wins). */}}
{{- define "tenant.applicationSetOverrides" -}}
{{- $out := dict -}}
{{- range $name, $project := .Values.projects -}}
  {{- $_ := set $out $name (omit $project "projectApplication") -}}
{{- end -}}
{{- $out | toJson -}}
{{- end -}}
