{{/*
  project.auditlog.vrl.str
  Renders a value as a VRL string literal. VRL treats `{{` inside string literals as a
  template, so it is escaped alongside backslashes, quotes and newlines.
*/}}
{{- define "project.auditlog.vrl.str" -}}
"{{ . | toString | replace "\\" "\\\\" | replace "\"" "\\\"" | replace "\n" "\\n" | replace "{{" "\\{{" }}"
{{- end }}


{{/*
  project.auditlog.vrl.field
  VRL assertions for one schema field, recursing into object `properties`.
  Call with: (dict "path" <list of field names from the event root> "config" <field config>)

  Required fields must be present and not nullish. Every other check only runs when the field
  is present and not null, so children of an absent optional object are skipped.
*/}}
{{- define "project.auditlog.vrl.field" -}}
{{- $segments := .path -}}
{{- $config := .config | default dict -}}
{{- $name := join "." $segments -}}
{{- $type := $config.type | default "string" -}}
{{- $options := dict
      "string"  (list "enum" "format" "pattern" "minLength" "maxLength")
      "number"  (list "enum" "minimum" "maximum")
      "integer" (list "enum" "minimum" "maximum")
      "boolean" (list)
      "object"  (list "properties" "requiredKeys") -}}

{{- if not (regexMatch "^[A-Za-z0-9_-]+$" (last $segments)) -}}
{{- fail (printf "auditlog.schema: field name %q may only contain letters, digits, '_' and '-'" $name) -}}
{{- end -}}
{{- if not (hasKey $options $type) -}}
{{- fail (printf "auditlog.schema.%s: unsupported type %q, must be one of string, number, integer, boolean, object" $name $type) -}}
{{- end -}}
{{- range $key, $_ := $config -}}
{{- if not (or (has $key (list "type" "required")) (has $key (get $options $type))) -}}
{{- fail (printf "auditlog.schema.%s: %q is not supported for type %s" $name $key $type) -}}
{{- end -}}
{{- end -}}

{{- $path := "" -}}
{{- range $segments -}}
{{- $path = printf "%s.%q" $path . -}}
{{- end -}}

{{- if $config.required }}
if !exists({{ $path }}) || is_nullish({{ $path }}) {
  abort {{ include "project.auditlog.vrl.str" (printf "missing/invalid: %s" $name) }}
}
{{- end }}
if exists({{ $path }}) && !is_null({{ $path }}) {

{{- if eq $type "string" }}
  if !is_string({{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be a string" $name) }}
  }
{{- if $config.required }}
  {{ $path }} = strip_whitespace(string!({{ $path }}))
{{- end }}

{{- with $config.enum }}
{{- $items := list -}}
{{- range . -}}
{{- $items = append $items (include "project.auditlog.vrl.str" .) -}}
{{- end }}
  if !includes([{{ join ", " $items }}], {{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be one of %s" $name (join ", " .)) }}
  }
{{- end }}

{{- with $config.format }}
{{- if eq . "email" }}
  if !match(string!({{ $path }}), r'^[^\s@]+@[^\s@]+\.[^\s@]+$') {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be a valid email address" $name) }}
  }
{{- else if eq . "uuid" }}
  if !match(string!({{ $path }}), r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$') {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be a valid UUID" $name) }}
  }
{{- else }}
{{- fail (printf "auditlog.schema.%s: unsupported format %q, must be email or uuid" $name .) }}
{{- end }}
{{- end }}

{{- with $config.pattern }}
{{- /* Fails the render on an invalid pattern. Go RE2 and Rust regex syntax are close enough
       that a pattern compiling here almost always compiles in Vector. */ -}}
{{- $_ := mustRegexMatch (toString .) "" }}
  if !match(string!({{ $path }}), r'{{ toString . | replace "'" "\\'" }}') {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must match pattern %s" $name (toString .)) }}
  }
{{- end }}

{{- if hasKey $config "minLength" }}
  if strlen(string!({{ $path }})) < {{ int $config.minLength }} {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be at least %d characters" $name (int $config.minLength)) }}
  }
{{- end }}
{{- if hasKey $config "maxLength" }}
  if strlen(string!({{ $path }})) > {{ int $config.maxLength }} {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be at most %d characters" $name (int $config.maxLength)) }}
  }
{{- end }}

{{- else if or (eq $type "number") (eq $type "integer") }}
{{- if eq $type "integer" }}
  if !is_integer({{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be an integer" $name) }}
  }
{{- else }}
  if !is_integer({{ $path }}) && !is_float({{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be a number" $name) }}
  }
{{- end }}

{{- with $config.enum }}
{{- range . -}}
{{- if not (or (kindIs "float64" .) (kindIs "int64" .) (kindIs "int" .)) -}}
{{- fail (printf "auditlog.schema.%s: enum value %v must be a number" $name .) -}}
{{- end -}}
{{- end }}
  if !includes({{ toJson . }}, {{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be one of %s" $name (join ", " .)) }}
  }
{{- end }}

{{- if hasKey $config "minimum" }}
  if to_float!({{ $path }}) < {{ printf "%f" (float64 $config.minimum) }} {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be >= %s" $name (toJson $config.minimum)) }}
  }
{{- end }}
{{- if hasKey $config "maximum" }}
  if to_float!({{ $path }}) > {{ printf "%f" (float64 $config.maximum) }} {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be <= %s" $name (toJson $config.maximum)) }}
  }
{{- end }}

{{- else if eq $type "boolean" }}
  if !is_boolean({{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be a boolean" $name) }}
  }

{{- else if eq $type "object" }}
  if !is_object({{ $path }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "invalid: %s must be an object" $name) }}
  }

{{- /* Deprecated: requiredKeys entries are required children of any type. Use properties. */ -}}
{{- range $config.requiredKeys }}
{{- if not (regexMatch "^[A-Za-z0-9_-]+$" .) -}}
{{- fail (printf "auditlog.schema.%s.requiredKeys: %q may only contain letters, digits, '_' and '-'" $name .) -}}
{{- end }}
  if !exists({{ $path }}.{{ printf "%q" . }}) || is_nullish({{ $path }}.{{ printf "%q" . }}) {
    abort {{ include "project.auditlog.vrl.str" (printf "missing/invalid: %s.%s" $name .) }}
  }
{{- end }}

{{- range $child, $childConfig := $config.properties }}
{{ include "project.auditlog.vrl.field" (dict "path" (append $segments $child) "config" $childConfig) | indent 2 }}
{{- end }}
{{- end }}
}
{{- end }}


{{/*
  project.auditlogValidationVRL
  Renders the VRL assertions for every field in .Values.auditlog.schema.
*/}}
{{- define "project.auditlogValidationVRL" -}}
{{- range $field, $config := .Values.auditlog.schema }}
{{ include "project.auditlog.vrl.field" (dict "path" (list $field) "config" $config) }}
{{- end }}
{{- end }}
