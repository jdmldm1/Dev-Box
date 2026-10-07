{{- define "dev-box.name" -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "dev-box.labels" -}}
app.kubernetes.io/name: dev-box
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
{{- end -}}

{{- define "dev-box.selectorLabels" -}}
app.kubernetes.io/name: dev-box
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "dev-box.secretName" -}}
{{- default (include "dev-box.name" .) .Values.existingSecret -}}
{{- end -}}
