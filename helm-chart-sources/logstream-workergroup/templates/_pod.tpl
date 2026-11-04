{{- define "workergroup.pod" -}}
{{- if or .Values.serviceAccount.create (and (not .Values.serviceAccount.create) .Values.serviceAccount.name) }}
serviceAccountName: {{ include "logstream-workergroup.serviceAccountName" . }}
{{- end }}

{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- if .Values.config.hostNetwork }}
hostNetwork: true
{{- end }}
{{- with (include "logstream-workergroup.podSecurityContext" .) }}
securityContext:
  {{- . | nindent 2 }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.criblImage.repository }}:{{ .Values.criblImage.tag | default .Chart.AppVersion }}{{ if .Values.criblImage.wolfiImage }}-wolfi{{ end }}"
    imagePullPolicy: {{ .Values.criblImage.pullPolicy }}
    {{- with (include "logstream-workergroup.containerSecurityContext" .) }}
    securityContext:
      {{- . | nindent 6 }}
    {{- end }}
    {{- if .Values.config.probes }}
    {{- with .Values.config.livenessProbe }}
    livenessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.config.readinessProbe }}
    readinessProbe:
      {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- end }}
    env:
      {{- if not .Values.config.useExistingSecret }}
      - name: CRIBL_DIST_MASTER_URL
        valueFrom:
          secretKeyRef:
            name: logstream-config-{{ include "logstream-workergroup.fullname" . }}
            key: url-master
      {{- end }}
      # Self-Signed Certs
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "{{ .Values.config.rejectSelfSignedCerts }}"
      {{ if .Values.envValueFrom }}
      {{ toYaml .Values.envValueFrom | nindent 6  }}
      {{- end }}
      {{- range $key, $value := .Values.env }}
      - name: {{ $key }}
        value: {{ $value | quote }}
      {{- end }}
      {{- if include "logstream-workergroup.nonRootVolumeDir" . }}
      # The image refuses to start as non-root without a writable CRIBL_VOLUME_DIR.
      - name: CRIBL_VOLUME_DIR
        value: {{ include "logstream-workergroup.nonRootVolumeDir" . }}
      {{- end }}

    volumeMounts:
      {{- with (include "logstream-workergroup.nonRootVolumeDir" .) }}
      - name: cribl-volume-dir
        mountPath: {{ . }}
      {{- end }}
      {{- range .Values.extraConfigmapMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        readOnly: {{ .readOnly }}
      {{- end }}
      {{- range .Values.extraSecretMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        readOnly: {{ .readOnly }}
      {{- end }}
      {{- range .Values.extraVolumeMounts }}
      - name: {{ .name }}
        mountPath: {{ .mountPath }}
        subPath: {{ .subPath | default "" }}
        subPathExpr: {{ .subPathExpr | default "" }}
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
  {{- if include "logstream-workergroup.nonRootVolumeDir" . }}
  - name: cribl-volume-dir
    emptyDir: {}
  {{- end }}
  {{- if (ne .Values.deployment "statefulset") -}}
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
