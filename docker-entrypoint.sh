#!/bin/sh
set -e

# Generate /etc/nginx/.htpasswd from environment variables if not already present
if [ ! -f /etc/nginx/.htpasswd ]; then
    USER=${BASIC_AUTH_USER:-admin}
    PASS=${BASIC_AUTH_PASS:-CadVR2026!}
    echo "[Entrypoint] Generating .htpasswd for user: $USER"
    htpasswd -bc /etc/nginx/.htpasswd "$USER" "$PASS"
    chmod 644 /etc/nginx/.htpasswd
fi

exec "$@"
