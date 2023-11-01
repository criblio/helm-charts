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