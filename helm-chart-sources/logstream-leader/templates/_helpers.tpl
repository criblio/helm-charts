{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "logstream-leader.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "logstream-leader.fullname" -}}
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
{{- define "logstream-leader.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "logstream-leader.labels" -}}
helm.sh/chart: {{ include "logstream-leader.chart" . }}
{{ include "logstream-leader.selectorLabels" . }}
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
{{- define "logstream-leader.selectorLabels" -}}
app.kubernetes.io/name: {{ include "logstream-leader.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "logstream-leader.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "logstream-leader.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
  Join annotations passed in from values.yaml for Services
*/}}
{{- define "logstream-leader.service.annotations" -}}
{{- if eq .templateType "internal" }}
{{- $intAnnotations := (merge .Values.service.annotations .Values.service.internalAnnotations) -}}
{{ toYaml $intAnnotations }}
{{- end }}
{{- if eq .templateType "external" }}
{{- $extAnnotations := (merge .Values.service.annotations .Values.service.externalAnnotations) -}}
{{ toYaml $extAnnotations }}
{{- end }}
{{- end }}

{{/*
Pod-level securityContext. When nonRoot.enabled is true, the defaults needed to
run under the Pod Security Standards "restricted" profile are merged under
.Values.podSecurityContext, so anything set explicitly there still wins.
*/}}
{{- define "logstream-leader.podSecurityContext" -}}
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
  {{- include "logstream-leader.assertNonRootUser" (list $ctx "podSecurityContext") }}
{{- end }}
{{- include "logstream-leader.intIds" $ctx }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Container-level securityContext, with the same merge rules as the pod level.
*/}}
{{- define "logstream-leader.containerSecurityContext" -}}
{{- $ctx := deepCopy (.Values.securityContext | default dict) }}
{{- if (.Values.nonRoot).enabled }}
  {{- $defaults := dict "runAsNonRoot" true "allowPrivilegeEscalation" false "capabilities" (dict "drop" (list "ALL")) }}
  {{- $ctx = mergeOverwrite $defaults $ctx }}
  {{- include "logstream-leader.assertNonRootUser" (list $ctx "securityContext") }}
{{- end }}
{{- include "logstream-leader.intIds" $ctx }}
{{- if $ctx }}
{{- toYaml $ctx }}
{{- end }}
{{- end }}

{{/*
Fail early, instead of at pod admission, when nonRoot is combined with UID 0.
*/}}
{{- define "logstream-leader.assertNonRootUser" -}}
{{- $ctx := index . 0 }}
{{- if and (hasKey $ctx "runAsUser") (not (kindIs "invalid" $ctx.runAsUser)) }}
  {{- if eq (int $ctx.runAsUser) 0 }}
    {{- fail (printf "nonRoot.enabled is true but %s.runAsUser is 0" (index . 1)) }}
  {{- end }}
{{- end }}
{{- end }}

{{/*
runAsUser, runAsGroup and fsGroup have always been accepted as strings (the
README asks for strings), so convert them to integers in place before the
context is rendered.
*/}}
{{- define "logstream-leader.intIds" -}}
{{- range $key := list "runAsUser" "runAsGroup" "fsGroup" }}
  {{- if and (hasKey $ $key) (not (kindIs "invalid" (index $ $key))) }}
    {{- $_ := set $ $key (int64 (index $ $key)) }}
  {{- end }}
{{- end }}
{{- end }}
