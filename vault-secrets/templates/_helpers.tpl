{{/*
Expand the name of the chart.
*/}}
{{- define "vault-secrets.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "vault-secrets.fullname" -}}
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
{{- define "vault-secrets.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "vault-secrets.labels" -}}
helm.sh/chart: {{ include "vault-secrets.chart" . }}
{{ include "vault-secrets.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "vault-secrets.selectorLabels" -}}
app.kubernetes.io/name: {{ include "vault-secrets.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "vault-secrets.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "vault-secrets.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Vault config with dynamic values
*/}}
{{- define "vault-secrets.vaultConfigHCL" -}}
{{ .Values.vaultConfig }}

api_addr     = "http://$(POD_IP):8200"
cluster_addr = "http://$(HOSTNAME).{{ include "vault-secrets.fullname" . }}-headless:8201"

storage "raft" {
  path    = "{{ .Values.raft.path }}" 
  node_id = "$(HOSTNAME)"
  // For HA, retry_join configuration would be added here if needed
  {{- if gt (int .Values.replicaCount) 1 }}
  {{- $fullName := include "vault-secrets.fullname" . }}
  {{- $namespace := .Release.Namespace }}
  {{- $headlessService := printf "%s-headless.%s.svc" $fullName $namespace }}
  {{- range $i, $e := until (int .Values.replicaCount) }}
  retry_join {
    leader_api_addr = "http://{{ $fullName }}-{{ $i }}.{{ $headlessService }}:8200"
    // TODO: Use CA and TLS later
    // leader_ca_cert_file = "/path/to/ca.pem" // If using TLS
    // leader_client_cert_file = "/path/to/client.pem" // If using TLS
    // leader_client_key_file = "/path/to/client-key.pem" // If using TLS
  }
  {{- end }}
  {{- end }}
}
{{- end -}}
