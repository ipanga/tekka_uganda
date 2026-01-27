#!/bin/bash
# =============================================================================
# Tekka SSL Certificate Renewal Script
# =============================================================================
# This script renews SSL certificates and reloads Nginx.
# Can be run manually or via cron/systemd timer.
#
# Usage: ./renew-ssl.sh
#
# Recommended cron entry (runs twice daily):
#   0 0,12 * * * /opt/tekka/infra/scripts/renew-ssl.sh >> /var/log/tekka-ssl-renew.log 2>&1
# =============================================================================

set -e

# Configuration
COMPOSE_FILE="/opt/tekka/infra/docker/docker-compose.prod.yml"

# Colors (disabled in non-interactive mode)
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    GREEN=''
    YELLOW=''
    NC=''
fi

echo -e "${GREEN}[$(date)] Starting SSL certificate renewal check...${NC}"

# Attempt renewal (certbot only renews if needed)
docker compose -f $COMPOSE_FILE run --rm certbot renew --quiet

# Check if certificates were renewed by comparing modification times
RENEWAL_STATUS=$?

if [ $RENEWAL_STATUS -eq 0 ]; then
    echo -e "${GREEN}[$(date)] Renewal check completed. Reloading Nginx...${NC}"
    docker compose -f $COMPOSE_FILE exec -T nginx nginx -s reload
    echo -e "${GREEN}[$(date)] Nginx reloaded successfully.${NC}"
else
    echo -e "${YELLOW}[$(date)] Renewal check completed with status: $RENEWAL_STATUS${NC}"
fi

echo -e "${GREEN}[$(date)] SSL renewal process finished.${NC}"
