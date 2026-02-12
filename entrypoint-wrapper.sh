#!/bin/bash
set -e

mkdir -p /etc/sogo/sogo.conf.d

for f in /etc/sogo/sogo.conf.d.templates/*.yaml; do
    [ -f "$f" ] || continue
    out="/etc/sogo/sogo.conf.d/$(basename "$f")"
    envsubst < "$f" > "$out"
    if [ ! -s "$out" ]; then
        echo "ERROR: envsubst produced empty file for $f"
        exit 1
    fi
done

exec /opt/entrypoint.sh
