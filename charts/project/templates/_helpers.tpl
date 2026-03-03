{{/* Chart name + version label value */}}
{{- define "project.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Project namespace: <tenant>-<project> (e.g. acme-inventory) */}}
{{- define "project.projectNamespace" -}}
{{- printf "%s-%s" .Values.tenantName .Values.projectName -}}
{{- end -}}

{{/* Standard labels applied to every resource in the project chart */}}
{{- define "project.labels" -}}
helm.sh/chart: {{ include "project.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
