#!/bin/bash
# this script is intended to be used by periodic kubernetes liveness probes to ensure that the container
# (and all its dependent services) is healthy
{{ range .Values.livenessTests.commands -}}
{{ . }} && \
{{- end }}
echo "All healthy"
