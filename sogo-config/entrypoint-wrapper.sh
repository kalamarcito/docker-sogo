#!/bin/bash
set -e

echo "Processing YAML templates with environment variables..."
echo "DEBUG: LDAP_HOST=${LDAP_HOST}"
echo "DEBUG: LDAP_BASE_DN=${LDAP_BASE_DN}"
echo "DEBUG: LDAP_BIND_DN=${LDAP_BIND_DN}"
echo "DEBUG: LDAP_BIND_PASSWORD is set: $([ -n \"${LDAP_BIND_PASSWORD}\" ] && echo 'yes' || echo 'no')"

mkdir -p /etc/sogo/sogo.conf.d

for f in /etc/sogo/sogo.conf.d.templates/*.yaml; do
    if [ -f "$f" ]; then
        filename=$(basename "$f")
        echo "  Processing: $filename"
        envsubst < "$f" > "/etc/sogo/sogo.conf.d/$filename"
    fi
done

echo "Templates processed. Resulting config:"
cat /etc/sogo/sogo.conf.d/sogo.yaml
echo "--- END CONFIG ---"
echo "Starting SOGo..."

exec /opt/entrypoint.sh
