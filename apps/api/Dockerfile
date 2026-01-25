# Build stage
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci

# Copy source code
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production

# Create non-root user
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nestjs

# Copy package files and install production-only dependencies
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
RUN npm ci --omit=dev && npx prisma generate

# Copy built application
COPY --from=builder /app/dist ./dist

# Set ownership
RUN chown -R nestjs:nodejs /app

USER nestjs

EXPOSE 4000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD node -e "const net = require('net'); const s = net.connect(4000, 'localhost', () => { s.destroy(); process.exit(0); }); s.on('error', () => process.exit(1));"

CMD ["node", "dist/main"]
