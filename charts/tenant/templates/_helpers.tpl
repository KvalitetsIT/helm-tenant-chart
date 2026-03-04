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

{{/* Project namespace: <tenant>-<project> validated against DNS-1123 + 63-char limit.
     Call with a list: (list $tenantName $projectName) */}}
{{- define "tenant.projectNamespace" -}}
{{- $tenantName := index . 0 -}}
{{- $projectName := index . 1 -}}
{{- include "tenant.validateDNS1123Label" (list $projectName "project key") -}}
{{- $ns := printf "%s-%s" $tenantName $projectName -}}
{{- if gt (len $ns) 63 -}}
  {{- fail (printf "combined namespace %q exceeds the 63-character DNS-1123 limit (%d chars)" $ns (len $ns)) -}}
{{- end -}}
{{- $ns -}}
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
     appProject is rebuilt with roleGroups as the lowest-precedence base. */}}
{{- define "tenant.buildValuesObject" -}}
{{- $root := .root -}}
{{- $name := .name -}}
{{- $p := .p -}}
{{- $tenantName := include "tenant.name" $root -}}
{{- $valuesObject := deepCopy (omit $p "projectApplication") -}}
{{- $valuesObject = mergeOverwrite $valuesObject (dict
  "tenantName" $tenantName
  "projectName" $name
  "tenantAppProjectName" (include "tenant.tenantAppProjectName" $root)
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

{{/* Collect unique application repoURLs across all projects (app-of-apps).
     Iterates projects, merges per-project overrides, deduplicates.
     Yields a YAML list of strings. */}}
{{- define "tenant.applicationSourceRepos" -}}
{{- $repos := list -}}
{{- range $name, $project := .Values.projects -}}
  {{- $p := fromYaml (include "tenant.merge" (dict "defaults" $.Values.projectDefaults "override" $project)) -}}
  {{- $url := $p.application.source.repoURL -}}
  {{- if and $url (not (has $url $repos)) -}}
    {{- $repos = append $repos $url -}}
  {{- end -}}
{{- end -}}
{{- toYaml $repos -}}
{{- end -}}

{{/* Collect unique projectApplication repoURLs across all projects (project chart OCI).
     Iterates projects, merges per-project overrides, deduplicates.
     Yields a YAML list of strings. */}}
{{- define "tenant.projectSourceRepos" -}}
{{- $repos := list -}}
{{- range $name, $project := .Values.projects -}}
  {{- $p := fromYaml (include "tenant.merge" (dict "defaults" $.Values.projectDefaults "override" $project)) -}}
  {{- $url := $p.projectApplication.source.repoURL -}}
  {{- if and $url (not (has $url $repos)) -}}
    {{- $repos = append $repos $url -}}
  {{- end -}}
{{- end -}}
{{- toYaml $repos -}}
{{- end -}}
