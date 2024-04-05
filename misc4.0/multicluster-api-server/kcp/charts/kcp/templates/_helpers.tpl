{{- define "kcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kcp.chartName" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kcp.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "kcp.version" -}}
{{- if .Values.kcp.tag -}}
{{- .Values.kcp.tag -}}
{{- else -}}
v{{- .Chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{- define "frontproxy.fullname" -}}
{{- $trimmedName := printf "%s" (include "kcp.fullname" .) | trunc 52 | trimSuffix "-" -}}
{{- printf "%s-front-proxy" $trimmedName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "frontproxy.version" -}}
{{- if .Values.kcpFrontProxy.tag -}}
{{- .Values.kcpFrontProxy.tag -}}
{{- else -}}
v{{- .Chart.AppVersion -}}
{{- end -}}
{{- end -}}

{{- define "etcd.fullname" -}}
{{- $trimmedName := printf "%s" (include "kcp.fullname" .) | trunc 58 | trimSuffix "-" -}}
{{- printf "%s-etcd" $trimmedName | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "common.labels" -}}
app.kubernetes.io/name: {{ template "kcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ include "kcp.chartName" . }}
{{- end -}}

{{- define "common.labels.selector" -}}
app.kubernetes.io/name: {{ template "kcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}
