#!/bin/sh
set -e

CERT_PATH="/etc/letsencrypt/live/tekka.ug/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/tekka.ug/privkey.pem"
HTTPS_CONFIG="/etc/nginx/nginx.conf"
HTTP_CONFIG="/etc/nginx/nginx-http-only.conf"

echo "=== Tekka Nginx Entrypoint ==="

# Check if SSL certificates exist and are valid
if [ -f "$CERT_PATH" ] && [ -f "$KEY_PATH" ] && [ -s "$CERT_PATH" ] && [ -s "$KEY_PATH" ]; then
    echo "SSL certificates found. Starting with HTTPS enabled."
    CONFIG_FILE="$HTTPS_CONFIG"
else
    echo "SSL certificates NOT found. Starting in HTTP-only mode."
    echo "Run Certbot to obtain certificates, then reload Nginx."
    CONFIG_FILE="$HTTP_CONFIG"
fi

# Test the configuration
echo "Testing nginx configuration..."
nginx -t -c "$CONFIG_FILE"

# Start nginx with the appropriate config
echo "Starting Nginx with: $CONFIG_FILE"
exec nginx -c "$CONFIG_FILE" -g "daemon off;"
