{{/*
  project.auditlog.vrl.string
  VRL assertions for a string field.
  Call with: (list $fieldName $fieldConfig)
*/}}
{{- define "project.auditlog.vrl.string" -}}
{{- $field  := index . 0 -}}
{{- $config := index . 1 -}}

{{- if $config.required }}
if !exists(.{{ $field }}) || is_nullish(.{{ $field }}) {
  abort "missing/invalid: {{ $field }}"
}
.{{ $field }} = strip_whitespace(string!(.{{ $field }}))
if .{{ $field }} == "" {
  abort "missing/invalid: {{ $field }}"
}
{{- end }}

{{- if $config.enum }}
{{- if $config.required }}
if !includes({{ $config.enum | toJson }}, .{{ $field }}) {
  abort "invalid: {{ $field }} must be one of {{ $config.enum | join ", " }}"
}
{{- else }}
if exists(.{{ $field }}) && !includes({{ $config.enum | toJson }}, .{{ $field }}) {
  abort "invalid: {{ $field }} must be one of {{ $config.enum | join ", " }}"
}
{{- end }}
{{- end }}

{{- if eq ($config.format | default "") "email" }}
{{- if $config.required }}
if !match(string!(.{{ $field }}), r'^[^\s@]+@[^\s@]+\.[^\s@]+$') {
  abort "invalid: {{ $field }} must be a valid email address"
}
{{- else }}
if exists(.{{ $field }}) && !match(string!(.{{ $field }}), r'^[^\s@]+@[^\s@]+\.[^\s@]+$') {
  abort "invalid: {{ $field }} must be a valid email address"
}
{{- end }}
{{- end }}

{{- if eq ($config.format | default "") "uuid" }}
{{- if $config.required }}
if !match(string!(.{{ $field }}), r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
  abort "invalid: {{ $field }} must be a valid UUID"
}
{{- else }}
if exists(.{{ $field }}) && !match(string!(.{{ $field }}), r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
  abort "invalid: {{ $field }} must be a valid UUID"
}
{{- end }}
{{- end }}

{{- end }}


{{/*
  project.auditlog.vrl.object
  VRL assertions for an object field.
  Call with: (list $fieldName $fieldConfig)
*/}}
{{- define "project.auditlog.vrl.object" -}}
{{- $field  := index . 0 -}}
{{- $config := index . 1 -}}

{{- if $config.required }}
if !exists(.{{ $field }}) || is_nullish(.{{ $field }}) {
  abort "missing/invalid: {{ $field }}"
}
{{- end }}
if exists(.{{ $field }}) && !is_object(.{{ $field }}) {
  abort "invalid: {{ $field }} must be an object"
}

{{- if $config.requiredKeys }}
if exists(.{{ $field }}) {
{{- range $config.requiredKeys }}
  if is_nullish(.{{ $field }}.{{ . }}) {
    abort "missing/invalid: {{ $field }}.{{ . }}"
  }
{{- end }}
}
{{- end }}

{{- end }}


{{/*
  project.auditlogValidationVRL
  Dispatches each field in .Values.auditlog.schema to the appropriate type helper
  and returns the combined VRL assertions.
*/}}
{{- define "project.auditlogValidationVRL" -}}
{{- range $field, $config := .Values.auditlog.schema -}}
{{- $type := $config.type | default "string" -}}
{{- if eq $type "string" -}}
{{ include "project.auditlog.vrl.string" (list $field $config) }}
{{- else if eq $type "object" -}}
{{ include "project.auditlog.vrl.object" (list $field $config) }}
{{- end -}}
{{- end -}}
{{- end }}
