#!/bin/bash
# =============================================================================
# Tekka SSL Initialization Script
# =============================================================================
# This script obtains SSL certificates from Let's Encrypt.
# The Nginx container automatically starts in HTTP-only mode when no
# certificates exist, then switches to HTTPS mode after reload.
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
echo -e "${YELLOW}Note: Environment variable warnings can be ignored during SSL setup.${NC}"

# Step 1: Ensure nginx is running (will auto-start in HTTP-only mode)
echo -e "\n${GREEN}[1/4] Starting Nginx in HTTP-only mode...${NC}"
docker compose -f $COMPOSE_FILE up -d --no-deps nginx

# Wait for Nginx to start
echo "Waiting for Nginx to start..."
sleep 5

# Verify Nginx is running
if ! docker compose -f $COMPOSE_FILE ps nginx 2>/dev/null | grep -q "Up\|running"; then
    echo -e "${RED}ERROR: Nginx failed to start. Check logs:${NC}"
    docker compose -f $COMPOSE_FILE logs nginx
    exit 1
fi
echo -e "${GREEN}Nginx is running in HTTP-only mode.${NC}"

# Step 2: Verify HTTP is accessible
echo -e "\n${GREEN}[2/4] Verifying HTTP access...${NC}"
if curl -s -o /dev/null -w "%{http_code}" http://localhost/ | grep -q "200\|301\|302"; then
    echo -e "${GREEN}HTTP is accessible.${NC}"
else
    echo -e "${YELLOW}Warning: HTTP check returned unexpected status. Continuing anyway...${NC}"
fi

# Step 3: Request certificates from Let's Encrypt
echo -e "\n${GREEN}[3/4] Requesting certificates from Let's Encrypt...${NC}"

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
    $STAGING_ARG \
    $DOMAIN_ARGS

# Check if certificates were created
if docker compose -f $COMPOSE_FILE run --rm --entrypoint "" certbot \
    test -f /etc/letsencrypt/live/tekka.ug/fullchain.pem 2>/dev/null; then
    echo -e "${GREEN}Certificates obtained successfully!${NC}"
else
    echo -e "${RED}ERROR: Failed to obtain certificates. Check the output above.${NC}"
    exit 1
fi

# Step 4: Restart Nginx to switch to HTTPS mode
echo -e "\n${GREEN}[4/4] Restarting Nginx with HTTPS enabled...${NC}"
docker compose -f $COMPOSE_FILE restart nginx

# Wait for restart
sleep 3

echo -e "\n${GREEN}=== SSL Initialization Complete ===${NC}"

if [ -n "$STAGING_ARG" ]; then
    echo -e "\n${YELLOW}NOTE: You used STAGING certificates (not trusted by browsers).${NC}"
    echo -e "${YELLOW}To get production certificates:${NC}"
    echo -e "  1. Remove staging certs: docker compose -f $COMPOSE_FILE run --rm --entrypoint '' certbot rm -rf /etc/letsencrypt/live/tekka.ug"
    echo -e "  2. Run again without --staging: ./infra/scripts/init-ssl.sh"
fi

echo -e "\n${GREEN}Your sites are now accessible via HTTPS:${NC}"
echo -e "  - https://tekka.ug"
echo -e "  - https://www.tekka.ug"
echo -e "  - https://api.tekka.ug"
echo -e "  - https://admin.tekka.ug"

echo -e "\n${GREEN}Next steps:${NC}"
echo -e "1. Add DNS records for api.tekka.ug and admin.tekka.ug if not done"
echo -e "2. Start the full application stack: docker compose -f $COMPOSE_FILE up -d"
echo -e "3. Set up automatic renewal (add to crontab):"
echo -e "   0 0,12 * * * /opt/tekka/infra/scripts/renew-ssl.sh >> /var/log/tekka-ssl-renew.log 2>&1"
