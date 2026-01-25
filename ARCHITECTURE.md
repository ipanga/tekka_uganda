# Tekka Platform Architecture

## Overview

Tekka is a C2C fashion marketplace platform built with a subdomain-based architecture for clear separation of concerns.

## Subdomain Structure

| Subdomain | Service | Port | Description |
|-----------|---------|------|-------------|
| `tekka.ug` | user-dashboard | 3002 | Customer-facing marketplace |
| `admin.tekka.ug` | admin-dashboard | 3001 | Admin dashboard for moderation |
| `api.tekka.ug` | tekka-api | 3000 | Backend REST API |

## Project Structure

```
tekka/
├── docker-compose.yml          # All services orchestration
├── .env.example                # Environment template
├── ARCHITECTURE.md             # This file
│
├── tekka-api/                  # Backend API (NestJS)
│   ├── Dockerfile
│   ├── src/
│   ├── prisma/
│   └── ...
│
└── tekka-website/
    ├── admin-dashboard/        # Admin panel (Next.js)
    │   ├── Dockerfile
    │   ├── src/
    │   └── ...
    │
    └── user-dashboard/         # User marketplace (Next.js)
        ├── Dockerfile
        ├── src/
        └── ...
```

## Technology Stack

### Backend (tekka-api)
- **Framework**: NestJS
- **Database**: PostgreSQL (via Prisma ORM)
- **Cache**: Redis
- **Authentication**: Firebase Auth (token verification only)
- **Language**: TypeScript

### Frontend (admin-dashboard & user-dashboard)
- **Framework**: Next.js 16
- **Styling**: Tailwind CSS 4
- **State**: Zustand
- **Auth**: Firebase Client SDK
- **Language**: TypeScript

### Infrastructure
- **Containerization**: Docker
- **Database**: PostgreSQL (cloud-hosted)

## Development Setup

### Prerequisites
- Docker & Docker Compose
- Node.js 20+
- npm or yarn

### Quick Start

1. **Clone and setup environment**
   ```bash
   cp .env.example .env
   # Edit .env with your credentials (Firebase, DATABASE_URL for cloud PostgreSQL, etc.)
   ```

2. **Start API**
   ```bash
   cd apps/api
   npm install
   npx prisma migrate dev
   npm run start:dev
   ```

3. **Start Admin Dashboard**
   ```bash
   cd apps/admin
   npm install
   npm run dev
   ```

4. **Start User Dashboard**
   ```bash
   cd apps/user
   npm install
   npm run dev
   ```

### Access Points (Development)
- API: http://localhost:3000
- API Docs: http://localhost:3000/api/docs
- Admin Dashboard: http://localhost:3001
- User Dashboard: http://localhost:3002

## Production Deployment

### Build All Services
```bash
docker-compose build
```

### Deploy
```bash
docker-compose up -d
```

### Environment Variables

All services require environment variables. See `.env.example` for the complete list.

Key variables:
- `FIREBASE_*`: Firebase Admin SDK credentials (backend)
- `NEXT_PUBLIC_FIREBASE_*`: Firebase Client SDK credentials (frontends)
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: JWT signing key

## Security Considerations

### Authentication
- **User Dashboard**: Phone + OTP via Firebase
- **Admin Dashboard**: Email + Password via Firebase (stricter access)
- All auth tokens verified by backend

### CORS
- Configured per subdomain
- API only accepts requests from `tekka.ug` and `admin.tekka.ug`

### Network Isolation
- Each service runs in its own container
- Internal communication via Docker network
- Only necessary ports exposed

## Scaling

Each service can be scaled independently:

```bash
docker-compose up -d --scale api=3
```

For production, consider:
- Load balancer (nginx/Traefik) for subdomain routing
- CDN for static assets

## Monitoring

Recommended tools:
- **Logging**: Structured JSON logs, aggregate with ELK/Loki
- **Metrics**: Prometheus + Grafana
- **APM**: Sentry for error tracking

## Staging Environment

Use subdomain prefixes for staging:
- `staging.tekka.ug`
- `admin.staging.tekka.ug`
- `api.staging.tekka.ug`

Configure via environment variables in separate `.env.staging` file.
