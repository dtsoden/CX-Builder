# CX-Builder

**AI Agent Development Platform** - Build AI agents, chatbots, and RAG pipelines visually with drag-and-drop.

CX-Builder is built on [Flowise](https://github.com/FlowiseAI/Flowise) with custom branding, pgvector PostgreSQL integration, and production-ready Docker deployment.

## Quick Start

CX-Builder runs as a two-container stack: the app + pgvector PostgreSQL.

### 1. Get the compose file

```bash
git clone https://github.com/dtsoden/CX-Builder.git
cd CX-Builder/docker
```

### 2. Configure environment

```bash
cp .env.example .env
```

Edit `.env` and set secure values for:

| Variable | What to set |
|---|---|
| `DATABASE_PASSWORD` | Strong database password |
| `POSTGRES_PASSWORD` | Must match `DATABASE_PASSWORD` |
| `JWT_AUTH_TOKEN_SECRET` | Random secret (`openssl rand -hex 32`) |
| `JWT_REFRESH_TOKEN_SECRET` | Different random secret |

### 3. Start

```bash
docker compose up -d
```

CX-Builder will be available at **http://localhost:9800**.

### 4. Verify

```bash
docker compose ps          # Both services should be healthy
curl localhost:9800/api/v1/ping  # Should return OK
```

## Architecture

```
docker compose up -d
       |
       +-- cx-builder (port 9800)
       |     - Express + React UI
       |     - Connects to postgres via DATABASE_HOST
       |
       +-- postgres (internal, port 5432)
             - pgvector/pgvector:pg17
             - Vector similarity search
             - Persistent volume: postgres_data
```

## Supported Platforms

| Architecture | Platform |
|---|---|
| `linux/amd64` | Intel/AMD (x86_64) |
| `linux/arm64` | Apple Silicon (M1/M2/M3/M4), AWS Graviton |

## Important

**This image requires PostgreSQL with pgvector.** Do not run it standalone - use the [docker-compose.yml](https://github.com/dtsoden/CX-Builder/blob/master/docker/docker-compose.yml) from the GitHub repo which sets up both services together.

## Links

- **Source**: [github.com/dtsoden/CX-Builder](https://github.com/dtsoden/CX-Builder)
- **Compose files**: [docker/](https://github.com/dtsoden/CX-Builder/tree/master/docker)
- **Environment template**: [.env.example](https://github.com/dtsoden/CX-Builder/blob/master/docker/.env.example)

## Environment Variables

| Variable | Default | Description |
|---|---|---|
| `PORT` | `9800` | Application port |
| `DATABASE_TYPE` | `postgres` | Database type |
| `DATABASE_HOST` | `postgres` | Database hostname (Docker service name) |
| `DATABASE_PORT` | `5432` | Database port |
| `DATABASE_NAME` | `cxbuilder` | Database name |
| `DATABASE_USER` | `cxbuilder` | Database username |
| `DATABASE_PASSWORD` | - | Database password (required) |
| `JWT_AUTH_TOKEN_SECRET` | - | JWT signing secret (required) |
| `CORS_ORIGINS` | `*` | Allowed CORS origins |

## License

Based on [Flowise](https://github.com/FlowiseAI/Flowise), licensed under [Apache License 2.0](https://github.com/dtsoden/CX-Builder/blob/master/LICENSE.md).
