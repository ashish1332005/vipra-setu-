# Service Worker Backend

Express + MongoDB API for three user roles:

- `service_provider`
- `service_taker`
- `admin`

## Setup

```bash
cd server
npm install
cp .env.example .env
npm run dev
```

Create first admin:

```bash
npm run seed
```

Set `ADMIN_PHONE` and `ADMIN_PASSWORD` first. In production the admin password
must be at least 12 characters. Automatic admin seeding is disabled unless
`SEED_ADMIN_ON_START=true`.

## Production Environment

Required:

- `NODE_ENV=production`
- `MONGO_URI`
- `JWT_SECRET`
- `CLIENT_URL` / `CLIENT_URLS`

Optional:

- SMTP settings for transactional email.

## Main Routes

- `POST /api/auth/register`
- `POST /api/auth/login`
- `GET /api/auth/me`
- `GET /api/providers`
- `GET /api/providers/me`
- `PUT /api/providers/me`
- `POST /api/providers/me/services`
- `GET /api/service-takers/me/requests`
- `POST /api/service-takers/me/requests`
- `GET /api/admin/dashboard`
- `GET /api/admin/users`
- `PATCH /api/admin/users/:id/status`
- `PATCH /api/admin/providers/:id/approve`

## Local role smoke test

For local verification only, seed deterministic admin, provider, and service-taker accounts:

```bash
npm run seed:local
npm run smoke:roles
```

The smoke test verifies login, `/auth/me`, category loading, admin dashboard access, provider request access, service-taker request access, and rejection of an incorrect role. Override `ADMIN_PHONE`, `ADMIN_PASSWORD`, `DEV_PROVIDER_PHONE`, `DEV_PROVIDER_PASSWORD`, `DEV_TAKER_PHONE`, and `DEV_TAKER_PASSWORD` when needed. Do not use these local defaults in production.