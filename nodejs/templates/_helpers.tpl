{{/*
ref: https://github.com/helm/charts/blob/master/stable/postgresql/templates/_helpers.tpl
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
*/}}
{{- define "hmcts.releaseName" -}}
{{- if .Values.releaseNameOverride -}}
{{- .Values.releaseNameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

---
{{/*
All the common lables needed for the lables sections of the definitions.
*/}}
{{- define "labels" }}
app.kubernetes.io/name: {{ template "hmcts.releaseName" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ template "hmcts.releaseName" . }}
{{- end -}}

{{- define "vault" }}
  {{- if eq .Values.subscriptionId "bf308a5c-0624-4334-8ff8-8dca9fd43783"}}
  {{- "infra-vault-sandbox" -}}
  {{- else }}
  {{- "infra-vault-prod" -}}
  {{- end }}
{{- end }}

{{- define "resourcegroup" }}
  {{- if eq .Values.subscriptionId "bf308a5c-0624-4334-8ff8-8dca9fd43783"}}
  {{- "cnp-core-infra" -}}
  {{- else }}
  {{- "core-infra-prod" -}}
  {{- end }}
{{- end }}


