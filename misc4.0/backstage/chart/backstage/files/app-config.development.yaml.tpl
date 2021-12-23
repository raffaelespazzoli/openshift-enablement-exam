backend:
  lighthouseHostname: {{ include "lighthouse.serviceName" . | quote }}
  listen:
      port: {{ .Values.appConfig.backend.listen.port | default 7000 }}
  database:
    client: {{ .Values.appConfig.backend.database.client | quote }}
    connection:
      host: {{ include "backend.postgresql.host" . | quote }}
      port: {{ include "backend.postgresql.port" . | quote }}
      user: {{ include "backend.postgresql.user" . | quote }}
      database: {{ .Values.appConfig.backend.database.connection.database | quote }}
      ssl:
        rejectUnauthorized: {{ .Values.appConfig.backend.database.connection.ssl.rejectUnauthorized | quote }}
        ca: {{ include "backstage.backend.postgresCaFilename" . | quote }}

catalog:
{{- if .Values.backend.demoData }}
  locations:
    # Backstage example components
    - type: url
      target: https://github.com/backstage/backstage/blob/master/packages/catalog-model/examples/all-components.yaml
    # Example component for github-actions
    - type: url
      target: https://github.com/backstage/backstage/blob/master/plugins/github-actions/examples/sample.yaml
    # Example component for techdocs
    - type: url
      target: https://github.com/backstage/backstage/blob/master/plugins/techdocs-backend/examples/documented-component/catalog-info.yaml
    # Backstage example APIs
    - type: url
      target: https://github.com/backstage/backstage/blob/master/packages/catalog-model/examples/all-apis.yaml
    # Backstage example templates
    - type: url
      target: https://github.com/backstage/backstage/blob/master/plugins/scaffolder-backend/sample-templates/all-templates.yaml
{{- else }}
  locations: []
{{- end }}

auth:
  providers:
    microsoft: null

scaffolder:
  azure: null


sentry:
  organization: {{ .Values.appConfig.sentry.organization | quote }}

techdocs:
  generator: 
    runIn: 'local'

integrations:
  github:
    - host: github.com
      token: {{ .Values.auth.githubToken }}