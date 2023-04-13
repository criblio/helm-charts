{{/*
Expand the name of the chart.
*/}}
{{- define "appscope.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "appscope.fullname" -}}
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
{{- define "appscope.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "appscope.labels" -}}
helm.sh/chart: {{ include "appscope.chart" . }}
{{ include "appscope.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "appscope.selectorLabels" -}}
app.kubernetes.io/name: {{ include "appscope.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "appscope.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "appscope.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Extract the path from File or Unix variant
*/}}
{{- define "appscope.extractUnixFilePath" -}}
{{- $input_cfg := index . 0 -}}
{{- $filePath := split "://" $input_cfg -}}
{{- print $filePath._1 }}
{{- end -}}

{{/*
Extract the port from TCP, UDP or TLS variant
*/}}
{{- define "appscope.extractPort" -}}
{{- $input_cfg := index . 0 -}}
{{- $netPath := split "://" $input_cfg -}}
{{- $host_port := split ":" $netPath._1 -}}
{{- print $host_port._1 }}
{{- end -}}

{{/*
Extract the host from TCP, UDP or TLS variant
*/}}
{{- define "appscope.extractHost" -}}
{{- $input_cfg := index . 0 -}}
{{- $netPath := split "://" $input_cfg -}}
{{- $host_port := split ":" $netPath._1 -}}
{{- print $host_port._0 }}
{{- end -}}
