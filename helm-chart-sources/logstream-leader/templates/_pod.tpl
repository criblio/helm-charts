{{- define "leader.pod" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 8 }}
{{- end }}
{{- if .Values.podSecurityContext }}
securityContext:
{{- range $key, $value := .Values.podSecurityContext }}
{{- if or (eq $key "runAsUser") (eq $key "runAsGroup") (eq $key "fsGroup")}}
  {{ $key }}: {{ $value | int }}
{{- else }}
  {{ $key }}: {{ $value }}
{{- end }}
{{- end }}
{{- end }}
containers:
  - name: {{ .Chart.Name }}
    image: "{{ .Values.criblImage.repository }}:{{ .Values.criblImage.tag | default .Chart.AppVersion }}"
    imagePullPolicy: {{ .Values.criblImage.pullPolicy }}
    {{- if .Values.securityContext }}
    securityContext:
    {{- range $key, $value := .Values.securityContext }}
    {{- if or (eq $key "runAsUser") (eq $key "runAsGroup") (eq $key "fsGroup")}}
      {{ $key }}: {{ $value | int }}
    {{- else }}
      {{ $key }}: {{ $value }}
    {{- end }}
    {{- end }}
    {{- end }}
    volumeMounts:
    - name: config-storage
      mountPath: {{ .Values.config.criblHome }}/config-volume
    {{- if  or .Values.config.license ( or .Values.config.adminPassword .Values.config.groups ) }}
    - name: initial-config
      mountPath: /var/tmp/config_bits
    {{- end }}
    {{- if or .Values.securityContext .Values.podSecurityContext }}
    - name: gitconfig
      mountPath: /.gitconfig
      subPath: .gitconfig
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
      readOnly: {{ .readOnly }}
      subPath: {{ .subPath | default "" }}
    {{- end }}
    {{- range .Values.extraVolumeMounts }}
    - name: {{ .name }}
      mountPath: {{ .mountPath }}
      subPath: {{ .subPath | default "" }}
      readOnly: {{ .readOnly }}
    {{- end }}

    ports:
      {{-  range .Values.service.ports }}
      - name: {{ .name }}
        containerPort: {{ .port }}
        protocol: {{ .protocol | default "TCP" }}
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
    resources:
      {{- toYaml .Values.resources | nindent 6 }}
    env:
      # Self-Signed Certs
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "{{ .Values.config.rejectSelfSignedCerts }}"
      - name: CRIBL_HOME
        value: {{ .Values.config.criblHome | quote }}
      {{- if .Values.config.token }}
      - name: CRIBL_DIST_MODE
        value: leader
      - name: CRIBL_DIST_MASTER_URL
        value: "tcp://{{ .Values.config.token }}@{{ .Values.config.bindHost }}:4200"
      - name: CRIBL_DIST_LEADER_URL
        value: "tcp://{{ .Values.config.token }}@{{ .Values.config.bindHost }}:4200"
      {{- end }}
      # Single Volume for persistence (CRIBL-3848)
      - name: CRIBL_VOLUME_DIR
        value: {{ .Values.config.criblHome }}/config-volume
      {{ if .Values.envValueFrom }}
      {{ toYaml .Values.envValueFrom | nindent 6  }}
      {{- end }}
      {{- range $key, $value := .Values.env }}
      - name: {{ $key }}
        value: {{ $value | quote }}
      {{- end }}
      {{- $b_iter := 1 -}}
      {{- if .Values.config.license }}
      - name: CRIBL_BEFORE_START_CMD_{{ $b_iter }}
        value: "if [ ! -e $CRIBL_VOLUME_DIR/local/cribl/licenses.yml ]; then mkdir -p $CRIBL_VOLUME_DIR/local/cribl ; cp /var/tmp/config_bits/licenses.yml $CRIBL_VOLUME_DIR/local/cribl/licenses.yml; fi"
        {{- $b_iter = add $b_iter 1 }}
      {{- end }}
      {{- if .Values.config.groups }}
      - name: CRIBL_BEFORE_START_CMD_{{ $b_iter }}
        value: "if [ ! -e $CRIBL_VOLUME_DIR/local/cribl/mappings.yml ]; then mkdir -p $CRIBL_VOLUME_DIR/local/cribl;  cp /var/tmp/config_bits/groups.yml $CRIBL_VOLUME_DIR/local/cribl/groups.yml; cp /var/tmp/config_bits/mappings.yml $CRIBL_VOLUME_DIR/local/cribl/mappings.yml; fi"
        {{- $b_iter = add $b_iter 1 }}
      {{- end }}
     {{- $a_iter := 1 -}}
     {{- if .Values.config.adminPassword }}
      - name: CRIBL_AFTER_START_CMD_{{ $a_iter }}
        value: "[ ! -f $CRIBL_VOLUME_DIR/users_imported ] && sleep 20 && cp /var/tmp/config_bits/users.json $CRIBL_VOLUME_DIR/local/cribl/auth/users.json && touch $CRIBL_VOLUME_DIR/users_imported"
        {{- $a_iter = add $a_iter 1 }}
     {{- end }}
{{- with .Values.extraContainers }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.extraInitContainers .Values.consolidate_volumes }}
initContainers:
{{- with .Values.extraInitContainers }}
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if  (and .Release.IsUpgrade .Values.consolidate_volumes)  }}
  - name: pre-upgrade-volume-coalescence
    image: "alpine:3.3"
    command: ["/bin/ash","-c"]
    args:
      - for dir in local data state groups; do
          if [ ! -d {{ .Values.config.criblHome }}/config-volume/$dir ]; then
            (cd {{ .Values.config.criblHome }}; tar cf - --exclude lost+found .) | (cd {{ .Values.config.criblHome }}/config-volume; tar xf -);
          fi
        done
    volumeMounts:
      - name: config-storage
        mountPath: {{ .Values.config.criblHome }}/config-volume
      - name: local-storage
        mountPath: {{ .Values.config.criblHome }}/local
      - name: data-storage
        mountPath: {{ .Values.config.criblHome }}/data
      - name: state-storage
        mountPath: {{ .Values.config.criblHome }}/state
      - name: groups-storage
        mountPath: {{ .Values.config.criblHome }}/group
{{- end }}
{{- end }}
volumes:
  {{- if  or .Values.config.license ( or .Values.config.adminPassword .Values.config.groups ) }}
  - name: initial-config
    secret:
      secretName: logstream-leader-config-{{ include "logstream-leader.fullname" . }}
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
  - name: config-storage
    {{- if .Values.persistence.enabled }}
    persistentVolumeClaim:
      claimName: {{ coalesce .Values.persistence.claimName (include "logstream-leader.fullname" .) }}
    {{- else }}
    emptyDir: {}
    {{- end }}
  {{- if (and .Release.IsUpgrade .Values.consolidate_volumes) }}
  - name: local-storage
    persistentVolumeClaim:
      claimName: local-claim
  - name: data-storage
    persistentVolumeClaim:
      claimName: data-claim
  - name: state-storage
    persistentVolumeClaim:
      claimName: state-claim
  - name: groups-storage
    persistentVolumeClaim:
      claimName: groups-claim
{{- end }}
{{- if or .Values.securityContext .Values.podSecurityContext }}
  - name: gitconfig
    configMap:
      name: {{ include "logstream-leader.fullname" . }}-gitconfig
      items:
        - key: .gitconfig
          path: .gitconfig
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
{{- with .Values.nodeSelector }}
nodeSelector:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
