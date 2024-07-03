{{- define "common.extras" -}}
{{- range .Values.extraObjects }}
---
{{- if typeIs "string" . }}
  {{ . | nindent 0 }}
{{- else }}
  {{- toYaml . | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}