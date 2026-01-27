#!/bin/bash
# =============================================================================
# Tekka SSL Initialization Script
# =============================================================================
# This script initializes SSL certificates for the Tekka production stack.
# It creates dummy certificates first (so Nginx can start), then obtains
# real Let's Encrypt certificates using Certbot.
#
# Usage: ./init-ssl.sh [--staging]
#   --staging: Use Let's Encrypt staging environment (for testing)
#
# Prerequisites:
#   - Docker and Docker Compose installed
#   - DNS records pointing to this server for all domains
#   - Ports 80 and 443 open
# =============================================================================

set -e

# Configuration
DOMAINS="tekka.ug www.tekka.ug api.tekka.ug admin.tekka.ug"
EMAIL="ipanga@outlook.fr"
COMPOSE_FILE="infra/docker/docker-compose.prod.yml"
RSA_KEY_SIZE=4096

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check for staging flag
STAGING_ARG=""
if [ "$1" == "--staging" ]; then
    STAGING_ARG="--staging"
    echo -e "${YELLOW}Using Let's Encrypt STAGING environment${NC}"
fi

echo -e "${GREEN}=== Tekka SSL Initialization ===${NC}"

# Step 1: Create required directories and dummy certificates
echo -e "\n${GREEN}[1/5] Creating directory structure and dummy certificates...${NC}"

# Create directories
docker compose -f $COMPOSE_FILE run --rm --entrypoint "" certbot sh -c "
    mkdir -p /etc/letsencrypt/live/tekka.ug
    mkdir -p /var/www/certbot
"

# Check if real certificates already exist
if docker compose -f $COMPOSE_FILE run --rm --entrypoint "" certbot sh -c "test -f /etc/letsencrypt/live/tekka.ug/fullchain.pem && test -s /etc/letsencrypt/live/tekka.ug/fullchain.pem" 2>/dev/null; then
    echo -e "${YELLOW}Existing certificates found. Skipping dummy certificate creation.${NC}"
else
    echo "Creating dummy certificates for initial Nginx startup..."
    docker compose -f $COMPOSE_FILE run --rm --entrypoint "" certbot sh -c "
        openssl req -x509 -nodes -newkey rsa:${RSA_KEY_SIZE} -days 1 \
            -keyout /etc/letsencrypt/live/tekka.ug/privkey.pem \
            -out /etc/letsencrypt/live/tekka.ug/fullchain.pem \
            -subj '/CN=tekka.ug'
        cp /etc/letsencrypt/live/tekka.ug/fullchain.pem /etc/letsencrypt/live/tekka.ug/chain.pem
    "
    echo -e "${GREEN}Dummy certificates created.${NC}"
fi

# Step 2: Start Nginx with dummy certificates
echo -e "\n${GREEN}[2/5] Starting Nginx...${NC}"
docker compose -f $COMPOSE_FILE up -d nginx

# Wait for Nginx to be healthy
echo "Waiting for Nginx to start..."
sleep 5

# Verify Nginx is running
if ! docker compose -f $COMPOSE_FILE ps nginx | grep -q "Up"; then
    echo -e "${RED}ERROR: Nginx failed to start. Check logs:${NC}"
    docker compose -f $COMPOSE_FILE logs nginx
    exit 1
fi
echo -e "${GREEN}Nginx is running.${NC}"

# Step 3: Delete dummy certificates
echo -e "\n${GREEN}[3/5] Removing dummy certificates...${NC}"
docker compose -f $COMPOSE_FILE run --rm --entrypoint "" certbot sh -c "
    rm -rf /etc/letsencrypt/live/tekka.ug
    rm -rf /etc/letsencrypt/archive/tekka.ug
    rm -rf /etc/letsencrypt/renewal/tekka.ug.conf
"

# Step 4: Request real certificates from Let's Encrypt
echo -e "\n${GREEN}[4/5] Requesting certificates from Let's Encrypt...${NC}"

# Build domain arguments
DOMAIN_ARGS=""
for domain in $DOMAINS; do
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
done

docker compose -f $COMPOSE_FILE run --rm certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    $STAGING_ARG \
    $DOMAIN_ARGS

# Step 5: Reload Nginx with real certificates
echo -e "\n${GREEN}[5/5] Reloading Nginx with real certificates...${NC}"
docker compose -f $COMPOSE_FILE exec nginx nginx -s reload

echo -e "\n${GREEN}=== SSL Initialization Complete ===${NC}"
echo -e "Your sites are now accessible via HTTPS:"
echo -e "  - https://tekka.ug"
echo -e "  - https://www.tekka.ug"
echo -e "  - https://api.tekka.ug"
echo -e "  - https://admin.tekka.ug"

if [ -n "$STAGING_ARG" ]; then
    echo -e "\n${YELLOW}NOTE: You used staging certificates. Run without --staging for production.${NC}"
fi

echo -e "\n${GREEN}Certificate renewal:${NC}"
echo -e "  docker compose -f $COMPOSE_FILE run --rm certbot renew"
echo -e "  docker compose -f $COMPOSE_FILE exec nginx nginx -s reload"
