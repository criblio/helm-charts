{{- define "outpost.pod" -}}
{{- if or .Values.serviceAccount.create (and (not .Values.serviceAccount.create) .Values.serviceAccount.name) }}
serviceAccountName: {{ include "outpost.serviceAccountName" . }}
{{- end }}

{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- if .Values.podSecurityContext }}
securityContext:
  {{- toYaml .Values.podSecurityContext | nindent 2 }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.criblImage.repository }}:{{ .Values.criblImage.tag | default .Chart.AppVersion }}{{ if .Values.criblImage.wolfiImage }}-wolfi{{ end }}"
    imagePullPolicy: {{ .Values.criblImage.pullPolicy }}
    {{- if .Values.securityContext }}
    securityContext:
    {{- range $key, $value := .Values.securityContext }}
    {{- if or (eq $key "runAsUser") (eq $key "runAsGroup") (eq $key "fsGroup")}}
      {{ $key }}: {{ $value | int }}
    {{- else if kindIs "map" $value }}
      {{ $key }}:
        {{- toYaml $value | nindent 8 }}
    {{- else }}
      {{ $key }}: {{ $value }}
    {{- end }}
    {{- end }}
    {{- end }}
    {{- if .Values.cribl.probes }}
    {{- with .Values.cribl.livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.cribl.readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- end }}
    env:
      - name: CRIBL_DIST_LEADER_URL
        valueFrom:
          secretKeyRef:
            {{- if ((.Values.cribl).existingSecretForLeader) }}
            name: {{ .Values.cribl.existingSecretForLeader }}
            {{- else }}
            name: {{ include "outpost.fullname" . }}-cribl-settings
            {{- end }}
            key: CRIBL_DIST_LEADER_URL
      - name: CRIBL_HOME
        value: {{ .Values.cribl.home }}
      - name: CRIBL_DIST_MODE
        value: outpost
      {{- if .Values.cribl.listener }}
      - name: CRIBL_OUTPOST_LISTENER_URL
        value: {{ .Values.cribl.listener | quote }}
      {{- end }}
      {{- if .Values.cribl.config }}
      - name: CRIBL_BOOTSTRAP
        valueFrom:
          secretKeyRef:
            {{- if ((.Values.cribl).existingSecretForConfig) }}
            name: {{ .Values.cribl.existingSecretForConfig }}
            {{- else }}
            name: {{ include "outpost.fullname" . }}-cribl-settings
            {{- end }}
            key: CRIBL_BOOTSTRAP
      {{- end }}
      # Self-Signed Certs
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "{{ .Values.cribl.rejectSelfSignedCerts }}"
      {{- range $key, $value := .Values.extraEnv }}
      - name: {{ tpl $key $ }}
        value: "{{ tpl (print $value) $ }}"
      {{- end }}
      {{ if .Values.envValueFrom }}
      {{ toYaml .Values.envValueFrom | nindent 6  }}
      {{- end }}
      {{- range $key, $value := .Values.env }}
      - name: {{ tpl $key $ }}
        value: "{{ tpl (print $value) $ }}"
      {{- end }}
    {{- if .Values.extraEnvFrom }}
    envFrom:
      {{- toYaml .Values.extraEnvFrom | nindent 6 }}
    {{- end }}

    volumeMounts:
      {{- if ((.Values.cribl.listenerTLS).existingSecret) }}
      - name: listener-tls-certs
        mountPath: {{ .Values.cribl.listenerTLS.mountPath | default "/etc/cribl/certs" }}
        readOnly: true
      {{- end }}
      {{- range .Values.extraConfigmapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
        readOnly: {{ .readOnly }}
      {{- end }}
      {{- range .Values.extraSecretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
        readOnly: {{ .readOnly }}
      {{- end }}
      {{- range .Values.extraVolumeMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        {{- if .subPath }}
        subPath: {{ .subPath }}
        {{- end }}
        {{- if .subPathExpr }}
        subPathExpr: {{ .subPathExpr }}
        {{- end }}
        readOnly: {{ .readOnly }}
      {{- end }}

    ports: 
      {{-  range .Values.service.ports }}
      - name: {{ .name }}
        containerPort: {{ .port }}
        protocol: {{ .protocol | default "TCP" }}
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 12 }}

{{- with .Values.extraContainers }}
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml .  | nindent 2 }}
{{- end }}

{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}

{{- with .Values.extraPodConfigs }}
{{ toYaml . }}
{{- end }}

volumes: 
  {{- if ((.Values.cribl.listenerTLS).existingSecret) }}
  - name: listener-tls-certs
    secret:
      secretName: {{ .Values.cribl.listenerTLS.existingSecret }}
  {{- end }}
  {{- range .Values.extraVolumeMounts }}
  - name: {{ .name }}
    {{- if .existingClaim }}
    persistentVolumeClaim:
      claimName: {{ .existingClaim }}
    {{- else if .hostPath }}
    hostPath:
      path: {{ .hostPath }}
    {{- else }}
    emptyDir: {}
    {{- end }}
  {{- end }}
  {{- range .Values.extraConfigmapMounts }}
  - name: {{ .name }}
    configMap:
      name: {{ .configMap }}
  {{- end }}
  {{- range .Values.extraSecretMounts }}
  {{- if .secretName }}
  - name: {{ .name }}
    secret:
      secretName: {{ .secretName }}
      defaultMode: {{ .defaultMode }}
  {{- else if .projected }}
  - name: {{ .name }}
    projected: {{- toYaml .projected | nindent 6 }}
  {{- else if .csi }}
  - name: {{ .name }}
    csi: {{- toYaml .csi | nindent 6 }}
  {{- end }}
  {{- end }}

{{- if .Values.terminationGracePeriodSeconds }}
terminationGracePeriodSeconds: {{ .Values.terminationGracePeriodSeconds }}
{{- end }}

{{- end }}

