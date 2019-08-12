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
{{- if .Values.aadIdentityName }}
aadpodidbinding: {{ .Values.aadIdentityName }}
{{- end }}
{{- if .Values.draft }}
draft: {{ .Values.draft }}
{{- end }}
{{- end -}}

{{/*
All the common annotations needed for the annotations sections of the definitions.
*/}}
{{- define "annotations" }}
{{- if .Values.prometheus.enabled }}
prometheus.io/scrape: "true"
prometheus.io/path: {{ .Values.prometheus.path | quote }}
prometheus.io/port: {{ .Values.applicationPort | quote }}
{{- end }}
{{- if .Values.buildID }}
buildID: {{ .Values.buildID }}
{{- end }}
{{- end -}}

{{/*
The bit of templating needed to create the flex-Volume keyvault for mounting
*/}}
{{- define "secretVolumes" }}
{{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
{{- $globals := .Values.global }}
{{- $keyVaults := .Values.keyVaults }}
{{- $aadIdentityName := .Values.aadIdentityName }}
volumes:
{{- range $vault, $info := .Values.keyVaults }}
- name: {{ $vault }}
  flexVolume:
    driver: "azure/kv"
    {{- if not $aadIdentityName }}
    secretRef:
      name: {{ default "kvcreds" $keyVaults.secretRef }}
    {{- end}}
    options:
      usepodidentity: "{{ if $aadIdentityName }}true{{ else }}false{{ end}}"
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
{{- if and .Values.keyVaults .Values.global.enableKeyVaults }}
volumeMounts:
{{- range $vault, $info := .Values.keyVaults }}
  - name: {{ $vault | quote }}
    mountPath: "/mnt/secrets/{{ $vault }}"
    readOnly: true
{{- end }}
{{- end }}
{{- end }}

{{/*
Adding in the helper here where we can use a secret object to include secrets to for the deployed service.
The key or "environment variable" must be uppercase and contain only numbers or "_".
Example format:
"
 ENVIRONMENT_VAR:
    secretRef: secret-vault 
    key: connectionString
    disabled: false
"
*/}}
{{- define "nodejs.secrets" -}}

  {{- if .Values.secrets -}}
    {{- range $key, $val := .Values.secrets }}
      {{- if and $val (not $val.disabled) }}
- name: {{ if $key | regexMatch "^[^.-]+$" -}}
          {{- $key }}
        {{- else -}}
            {{- fail (join "Environment variables can not contain '.' or '-' Failed key: " ($key|quote)) -}}
        {{- end }}
  valueFrom:
    secretKeyRef:
      name: {{  tpl (required "Each item in \"secrets:\" needs a secretRef member" $val.secretRef) $ }}
      key: {{ required "Each item in \"secrets:\" needs a key member" $val.key }}
      {{- end }}
    {{- end }}
  {{- end -}}
{{- end }}
