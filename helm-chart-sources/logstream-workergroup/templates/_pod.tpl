{{- define "workergroup.pod" -}}
{{- if .Values.rbac.create }}
serviceAccountName: {{ include "logstream-workergroup.fullname" . }}
{{- end }}

{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- with .Values.extraInitContainers }}
initContainers:
  {{- toYaml . | nindent 8 }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.criblImage.repository }}:{{ .Values.criblImage.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.criblImage.pullPolicy }}
    {{- if .Values.securityContext }}
    command: 
    - bash
    - -c 
    - |
      set -x 
      apt update; apt-get install -y gosu
      useradd -d /opt/cribl -g "{{- .Values.securityContext.runAsGroup }}" -u "{{- .Values.securityContext.runAsUser }}" cribl
      chown  -R   "{{- .Values.securityContext.runAsUser }}:{{- .Values.securityContext.runAsGroup }}" /opt/cribl
      gosu "{{- .Values.securityContext.runAsUser }}:{{- .Values.securityContext.runAsGroup }}" /sbin/entrypoint.sh cribl
    {{- end }}
    livenessProbe:
      httpGet:
        path: /api/v1/health
        port: {{ .Values.config.healthPort }}
        {{- if .Values.config.healthScheme }}
        scheme: {{ .Values.config.healthScheme }}
        {{- end }}
      failureThreshold: 3
      initialDelaySeconds: 20
    readinessProbe:
      httpGet:
        path: /api/v1/health
        port: {{ .Values.config.healthPort }}
        {{- if .Values.config.healthScheme }}
        scheme: {{ .Values.config.healthScheme }}
        {{- end }}
      failureThreshold: 3
      initialDelaySeconds: 20
    env:
      - name: CRIBL_DIST_MASTER_URL
        valueFrom:
          secretKeyRef:
            name: logstream-config-{{ include "logstream-workergroup.fullname" . }}
            key: url-master
      # Self-Signed Certs
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "{{ .Values.config.rejectSelfSignedCerts }}"
      {{ if .Values.envValueFrom }}
      {{ toYaml .Values.envValueFrom | nindent 6  }}
      {{- end }}
      {{- range $key, $value := .Values.env }}
      - name: "{{ tpl $key $ }}"
        value: "{{ tpl (print $value) $ }}"
      {{- end }}

    volumeMounts:
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
      {{- end }}
    resources:
      {{- toYaml .Values.resources | nindent 12 }}

{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml .  | nindent 2 }}
{{- end }}

volumes:
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

{{- end }}



