{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "logstream-workergroup.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logstream-workergroup.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "logstream-workergroup.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logstream-workergroup.labels" -}}
helm.sh/chart: {{ include "logstream-workergroup.chart" . }}
{{ include "logstream-workergroup.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- range $key, $val := .Values.extraLabels }}
{{ $key }}: {{ $val | quote -}}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "logstream-workergroup.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logstream-workergroup.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logstream-workergroup.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logstream-workergroup.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Allows for overriding the default RBAC naming scheme
*/}}
{{- define "logstream-workergroup.rbacName" }}
{{- if .Values.rbac.name }}
{{- .Values.rbac.name | quote }}
{{- else }}
{{- printf "%s:%s:%s" (include "logstream-workergroup.fullname" .) "logstream-workergroup" .Release.Namespace | quote }}
{{- end }}
{{- end }}

{{/*
Pod-level securityContext. When nonRoot.enabled is true, the defaults needed to
run under the Pod Security Standards "restricted" profile are merged under
.Values.podSecurityContext, so anything set explicitly there still wins.
*/}}
{{- define "logstream-workergroup.podSecurityContext" -}}
{{- $ctx := deepCopy (.Values.podSecurityContext | default dict) }}
{{- if (.Values.nonRoot).enabled }}
  {{- $defaults := dict "runAsNonRoot" true "seccompProfile" (dict "type" "RuntimeDefault") }}
  {{- range $key := list "runAsUser" "runAsGroup" "fsGroup" }}
    {{- $id := index $.Values.nonRoot $key }}
    {{- if not (kindIs "invalid" $id) }}
      {{- $_ := set $defaults $key $id }}
    {{- end }}
  {{- end }}
  {{- if hasKey $defaults "fsGroup" }}
    {{- $_ := set $defaults "fsGroupChangePolicy" "OnRootMismatch" }}
  {{- end }}
  {{- $ctx = mergeOverwrite $defaults $ctx }}
  {{- include "logstream-workergroup.assertNonRootUser" (list $ctx "podSecurityContext") }}
{{- end }}
{{- include "logstream-workergroup.intIds" $ctx }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Container-level securityContext, with the same merge rules as the pod level.
*/}}
{{- define "logstream-workergroup.containerSecurityContext" -}}
{{- $ctx := deepCopy (.Values.securityContext | default dict) }}
{{- if (.Values.nonRoot).enabled }}
  {{- $defaults := dict "runAsNonRoot" true "allowPrivilegeEscalation" false "capabilities" (dict "drop" (list "ALL")) }}
  {{- $ctx = mergeOverwrite $defaults $ctx }}
  {{- include "logstream-workergroup.assertNonRootUser" (list $ctx "securityContext") }}
{{- end }}
{{- include "logstream-workergroup.intIds" $ctx }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Fail early, instead of at pod admission, when nonRoot is combined with UID 0.
*/}}
{{- define "logstream-workergroup.assertNonRootUser" -}}
{{- $ctx := index . 0 }}
{{- if and (hasKey $ctx "runAsUser") (not (kindIs "invalid" $ctx.runAsUser)) }}
  {{- if eq (int $ctx.runAsUser) 0 }}
    {{- fail (printf "nonRoot.enabled is true but %s.runAsUser is 0" (index . 1)) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
Writable CRIBL_VOLUME_DIR that the chart provides in nonRoot mode. Renders
nothing when nonRoot is off or when the user already sets CRIBL_VOLUME_DIR
through env or envValueFrom.
*/}}
{{- define "logstream-workergroup.nonRootVolumeDir" -}}
{{- if (.Values.nonRoot).enabled }}
  {{- $userSet := hasKey (.Values.env | default dict) "CRIBL_VOLUME_DIR" }}
  {{- range (.Values.envValueFrom | default list) }}
    {{- if eq .name "CRIBL_VOLUME_DIR" }}{{ $userSet = true }}{{ end }}
  {{- end }}
  {{- if not $userSet }}
    {{- "/opt/cribl/config-volume" }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
runAsUser, runAsGroup and fsGroup have always been accepted as strings (the
README asks for strings), so convert them to integers in place before the
context is rendered.
*/}}
{{- define "logstream-workergroup.intIds" -}}
{{- range $key := list "runAsUser" "runAsGroup" "fsGroup" }}
  {{- if and (hasKey $ $key) (not (kindIs "invalid" (index $ $key))) }}
    {{- $_ := set $ $key (int64 (index $ $key)) }}
  {{- end }}
{{- end }}
{{- end }}
