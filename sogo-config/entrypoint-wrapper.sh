#!/bin/bash
# Procesa los templates YAML sustituyendo variables de entorno
# y luego ejecuta el entrypoint original de SOGo

set -e

echo "Processing YAML templates with environment variables..."

mkdir -p /etc/sogo/sogo.conf.d

for f in /etc/sogo/sogo.conf.d.templates/*.yaml; do
    if [ -f "$f" ]; then
        filename=$(basename "$f")
        echo "  Processing: $filename"
        envsubst < "$f" > "/etc/sogo/sogo.conf.d/$filename"
    fi
done

echo "Templates processed. Starting SOGo..."

exec /opt/entrypoint.sh
