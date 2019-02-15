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
All the common labels needed for the labels sections of the definitions.
*/}}
{{- define "labels" }}
app.kubernetes.io/name: {{ template "hmcts.releaseName" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/instance: {{ template "hmcts.releaseName" . }}
{{- end -}}

{{/*
The bit of templating needed to create the flex-Volume keyvault for mounting
*/}}
{{- define "secretVolumes" }}
{{- if .Values.keyVaults }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
volumes:
{{- range $vault, $info := .Values.keyVaults }}
- name: {{ $vault }}
  flexVolume:
    driver: "azure/kv"
    secretRef:
      name: {{ default "kvcreds" $keyVaults.secretRef }}
    options:
      usepodidentity: "false"
      subscriptionid: {{ $globals.subscriptionId | quote }}
      tenantid: {{ $globals.tenantId | quote }}
      keyvaultname: "{{ $vault }}{{ if not (default $info.excludeEnvironmentSuffix false) }}-{{ $globals.environment }}{{ end }}"
      resourcegroup: "{{ required " .keyVaults.VAULT requires a .resourceGroup" $info.resourceGroup  }}{{ if not (default $info.excludeEnvironmentSuffix false) }}-{{ $globals.environment }}{{ end }}"
      keyvaultobjectnames: "{{range $index, $secret := $info.secrets }}{{if $index}};{{end}}{{ $secret }}{{ end }}"
      keyvaultobjecttypes: "{{range $index, $secret := $info.secrets }}{{if $index}};{{end}}secret{{ end }}"
{{- end }}
{{- end }}
{{- end }}

{{/*
Mount the Key vaults on /mnt/secrets
*/}}
{{- define "secretMounts" -}}
{{- if .Values.keyVaults }}
volumeMounts:
{{- range $vault, $info := .Values.keyVaults }}
  - name: {{ $vault | quote }}
    mountPath: "/mnt/secrets/{{ $vault }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}
