# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Shared infrastructure for all Devman services. Provides databases, search engines, reverse proxy with automatic SSL, and network isolation via Docker Compose on a single VPS.

## Structure

```
infrastructure/
├── docker-compose.yml           # All 6 services
├── .env.example                 # Template for required secrets
├── .github/workflows/deploy.yml # CI/CD pipeline
├── init/
│   ├── postgres/01-init.sql     # Creates ragaas database
│   └── mysql/01-mautic.sql      # Creates mautic database + user
├── traefik/
│   ├── traefik.yml              # Static config (entrypoints, providers, ACME)
│   └── dynamic.yml              # Dynamic config (middlewares, chains)
├── README.md
└── .gitignore
```

## Services

| Service | Image | Container | Port | Purpose |
|---------|-------|-----------|------|---------|
| Traefik | traefik:v3.6 | traefik | 80, 443 | Reverse proxy, SSL (Let's Encrypt ACME) |
| PostgreSQL | postgres:16-alpine | infra_postgres | 127.0.0.1:5432 | RAGaaS database |
| MySQL | mysql:8.0 | infra_mysql | 127.0.0.1:3306 | Mautic database |
| Redis | redis:7-alpine | infra_redis | 127.0.0.1:6379 | Cache and sessions |
| Elasticsearch | elasticsearch:8.17.0 | infra_elasticsearch | 100.103.254.26:9200 | Full-text + kNN search (Tailscale only) |
| ChromaDB | chromadb/chroma:0.6.3 | infra_chromadb | 100.103.254.26:8001 | Vector store (Tailscale only) |

All services run on `infra_network` (bridge). Application containers (agent-hub, ragaas, devman-site) join this network and reference services by container name.

ES and ChromaDB are bound to Tailscale IP for private access only. Postgres, MySQL, and Redis are bound to localhost.

## Network

The `infra_network` bridge is the shared network for all services:
- Infrastructure services define it
- Application containers join it as an external network
- Service discovery by container name (e.g., `infra_postgres`, `infra_elasticsearch`)

## Traefik Configuration

**Static** (`traefik.yml`): Entrypoints (HTTP/80, HTTPS/443), Docker provider, file provider, Let's Encrypt ACME resolver, dashboard at `traefik.devman.me`.

**Dynamic** (`dynamic.yml`): Reusable middleware chains:
- `default-chain`: security headers + compress + rate limit (100 req/s)
- `mautic-chain`: security headers + compress + 64MB body limit
- `redirect-boutique`: fallback redirect for non-API traffic
- `www-redirect`: www → non-www permanent redirect

Application containers configure routing via Docker labels:
```yaml
labels:
  - "traefik.http.routers.my-app.rule=Host(`example.com`)"
  - "traefik.http.routers.my-app.middlewares=default-chain@file"
```

## Deployment

**Trigger**: Push to `main` or `workflow_dispatch`
**Runner**: Self-hosted on VPS
**Deploy path**: `/opt/infrastructure`

Pipeline:
1. Sync files to `/opt/infrastructure` (excludes `.git`, `.env`)
2. Generate `.env` from GitHub Secrets
3. `docker compose up -d --remove-orphans`
4. Wait for Postgres readiness (`pg_isready`)
5. Sync Postgres password (`ALTER USER` to match current secret)
6. Show container status

**Password sync**: The deploy workflow ALTERs the Postgres user password after container start to ensure it matches the `POSTGRES_PASSWORD` secret. This is needed because the data volume preserves the password from initial `initdb`, which may differ from the current secret.

## Init Scripts

Scripts in `init/` run automatically on first container startup (mounted to `/docker-entrypoint-initdb.d/`):

- **`postgres/01-init.sql`**: Creates `ragaas` database if not exists
- **`mysql/01-mautic.sql`**: Creates `mautic` database and user with utf8mb4

## Environment Variables (GitHub Secrets)

| Secret | Used By |
|--------|---------|
| `POSTGRES_USER` | PostgreSQL |
| `POSTGRES_PASSWORD` | PostgreSQL |
| `MYSQL_ROOT_PASSWORD` | MySQL |
| `REDIS_PASSWORD` | Redis |
| `TRAEFIK_DASHBOARD_AUTH` | Traefik (htpasswd format) |

## Persistent Volumes

`postgres_data`, `mysql_data`, `redis_data`, `es_data`, `chroma_data`, `traefik_certs`

## Connected Applications

| Application | Repo | Services Used |
|-------------|------|---------------|
| agent-hub | `devman-me/agent-hub` | Traefik (routing) |
| ragaas | `devman-me/agent-hub` (packages/ragaas) | Postgres, Elasticsearch, ChromaDB, Traefik |
| devman-site | `devman-me/devman-site` | Traefik (routing) |
