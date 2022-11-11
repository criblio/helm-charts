{{- define "common.secret" -}}
{{- if or (not ((.Values.cribl).existingSecretForLeader)) ((.Values.cribl).config) }}
---
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: {{ include "common.fullname" . }}-cribl-settings
stringData:
  {{- if or (not ((.Values.cribl).existingSecretForLeader)) ((.Values.cribl).leader) }}
  CRIBL_DIST_LEADER_URL: {{ required "A valid CRIBL_DIST_MASTER_URL is required to be defined in the cribl.leader value!" (.Values.cribl).leader }}
  {{- end }}
  {{- if .Values.cribl.config }}
  CRIBL_BOOTSTRAP: |
  {{- .Values.cribl.config | nindent 4 }}
  {{- end }}
{{- end }}
{{- end }}