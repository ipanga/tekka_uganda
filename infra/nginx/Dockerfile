FROM nginx:alpine

# Remove default config
RUN rm /etc/nginx/conf.d/default.conf

# Create directories for ACME challenges and SSL
RUN mkdir -p /var/www/certbot /etc/letsencrypt

# Copy nginx configurations
# - tekka.conf: Full HTTPS config (used when certificates exist)
# - nginx-http-only.conf: HTTP-only config (used for initial setup)
COPY tekka.conf /etc/nginx/nginx.conf
COPY nginx-http-only.conf /etc/nginx/nginx-http-only.conf

# Copy and setup entrypoint script
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

EXPOSE 80 443

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
