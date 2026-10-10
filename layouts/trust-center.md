# {{ .Params.heading }}

> {{ .Params.lead }}

## How Blowhorn handles your data
{{ range .Params.glance }}
### {{ .title }}

{{ .text }} [{{ .linkText }}]({{ .link | absURL }})
{{ end }}
## Policies
{{ range .Params.policies }}
- [{{ .title }}]({{ if strings.HasPrefix .url "https://" }}{{ .url }}{{ else }}{{ .url | absURL }}{{ end }}){{ with .status }} ({{ . }}){{ end }}: {{ .summary }}
{{- end }}

{{ .RenderShortcodes }}
