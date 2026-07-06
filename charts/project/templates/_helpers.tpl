{{/* Chart name + version label value */}}
{{- define "project.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Validate a single DNS-1123 label and fail with a clear message.
     Call with a list: (list $value "fieldName") */}}
{{- define "project.validateDNS1123Label" -}}
{{- $value := index . 0 -}}
{{- $field := index . 1 -}}
{{- if not (regexMatch "^[a-z0-9]([a-z0-9-]*[a-z0-9])?$" $value) -}}
  {{- fail (printf "%s %q is not a valid DNS-1123 label: must consist of lowercase alphanumerics and hyphens, and start and end with an alphanumeric character" $field $value) -}}
{{- end -}}
{{- end -}}

{{/* Project namespace: defaults to <tenant>-<project>, overrideable via namespace.name.
     Validates the result against DNS-1123 label rules. */}}
{{- define "project.projectNamespace" -}}
{{- if .Values.namespace.name -}}
  {{- include "project.validateDNS1123Label" (list .Values.namespace.name "namespace.name") -}}
  {{- .Values.namespace.name -}}
{{- else -}}
  {{- include "project.validateDNS1123Label" (list .Values.tenantName "tenantName") -}}
  {{- include "project.validateDNS1123Label" (list .Values.projectName "projectName") -}}
  {{- $ns := printf "%s-%s" .Values.tenantName .Values.projectName -}}
  {{- if gt (len $ns) 63 -}}
    {{- fail (printf "combined namespace %q exceeds the 63-character DNS-1123 limit (%d chars)" $ns (len $ns)) -}}
  {{- end -}}
  {{- $ns -}}
{{- end -}}
{{- end -}}

{{/* Return the given resource value map (deep-copied) with metadata.namespace
     defaulted to the project namespace, so helper-rendered resources land in
     <tenant>-<project> rather than the release namespace. An explicitly-set
     metadata.namespace is preserved. Call with (dict "root" $ "value" $value);
     pipe the result through fromYaml. */}}
{{- define "project.withProjectNamespace" -}}
{{- $ns := include "project.projectNamespace" .root -}}
{{- $v := deepCopy .value -}}
{{- $meta := $v.metadata | default dict -}}
{{- $_ := set $meta "namespace" (default $ns $meta.namespace) -}}
{{- $_ := set $v "metadata" $meta -}}
{{- $v | toYaml -}}
{{- end -}}

{{/* Standard labels applied to every resource in the project chart */}}
{{- define "project.labels" -}}
helm.sh/chart: {{ include "project.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
