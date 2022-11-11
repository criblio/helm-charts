{{- define "common.extras" }}
{{ range .Values.extraObjects }}
---
{{ tpl (toYaml .) $ }}
{{ end }}
{{- end }}