# CX-Builder™

**AI Agent Development Platform**

Build AI agents, chatbots, and RAG pipelines visually with a drag-and-drop interface. CX-Builder is built on [Flowise](https://github.com/FlowiseAI/Flowise) v3.0.12 with custom branding, pgvector PostgreSQL integration, and production-ready Docker deployment.

## Quick Start (One-Liner)

The fastest way to run CX-Builder. Just Docker — nothing else required. No git clone, no manual config. The installer generates all secrets automatically and starts the stack.

**Linux / macOS:**

```bash
curl -fsSL https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.sh | bash
```

**Windows (PowerShell):**

```powershell
irm https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.ps1 | iex
```

CX-Builder will be available at **http://localhost:9800** once both services are healthy.

## Quick Start (Manual)

If you prefer to configure everything yourself:

### 1. Clone the repo

```bash
git clone https://github.com/dtsoden/CX-Builder.git
cd CX-Builder
```

### 2. Run the installer interactively

```bash
# Linux / macOS
./install.sh

# Windows
powershell -ExecutionPolicy Bypass -File install.ps1
```

Choose option **2** when prompted to enter your own values for passwords, ports, and JWT secrets.

### 3. Or configure manually

```bash
cd docker
cp .env.example .env
```

Edit `.env` and replace ALL placeholder values before starting:

| Variable                   | What to change                         |
| -------------------------- | -------------------------------------- |
| `DATABASE_PASSWORD`        | Strong database password               |
| `POSTGRES_PASSWORD`        | Must match `DATABASE_PASSWORD`         |
| `JWT_AUTH_TOKEN_SECRET`    | Random secret (`openssl rand -hex 32`) |
| `JWT_REFRESH_TOKEN_SECRET` | Different random secret                |
| `CORS_ORIGINS`             | Your domain(s), comma-separated        |

Then start the stack:

```bash
docker compose up -d
```

### 4. Verify

```bash
# Check service health
docker compose ps

# Test API
curl http://localhost:9800/api/v1/ping
```

## Docker Images

| Image                      | Description                           |
| -------------------------- | ------------------------------------- |
| `dsoden/cx-builder:latest` | CX-Builder application                |
| `pgvector/pgvector:pg17`   | PostgreSQL 17 with pgvector extension |

The pgvector extension enables vector embeddings storage and cosine similarity searches directly in PostgreSQL, supporting RAG workflows, document store queries, and semantic search across your AI agents.

## Architecture

```
docker compose up -d
       |
       +-- cx-builder (port 9800)
       |     - Express + React UI
       |     - Connects to postgres via DATABASE_HOST
       |     - Stores uploads/secrets in /root/.flowise
       |
       +-- postgres (internal, port 5432)
             - pgvector/pgvector:pg17
             - Vector similarity search (cosine, L2, inner product)
             - Persistent volume: postgres_data
```

## Build from Source

To build the Docker image locally instead of pulling from Docker Hub:

```bash
cd docker
cp .env.example .env   # edit passwords/secrets
docker compose -f docker-compose.local.yml up -d --build
```

This uses `docker/Dockerfile.local` which runs `pnpm install` and `pnpm build` inside the container — no local Node.js setup required.

## Development

### Prerequisites

- Node.js >= 18.15.0 (< 19) or >= 20
- pnpm >= 9

### Local development setup

```bash
pnpm install
pnpm build
pnpm dev
```

The UI dev server runs on port 5173, API on port 3000.

### Docker dev mode (hot reload)

```bash
cd docker
docker compose -f docker-compose.dev.yml up
```

Mounts source code as a volume for live UI changes at http://localhost:5173.

## Project Structure

```
CX-Builder/
  install.sh                  # One-liner installer (Linux/macOS)
  install.ps1                 # One-liner installer (Windows)
  docker/
    docker-compose.yml        # Production: pulls dsoden/cx-builder + pgvector
    docker-compose.local.yml  # Build from source + pgvector
    docker-compose.dev.yml    # Dev mode with hot reload
    Dockerfile.local          # Multi-stage build from source
    .env.example              # Environment template (copy to .env)
  packages/
    server/                   # Express API + oclif CLI
    ui/                       # React + MUI frontend (Vite)
    components/               # LangChain node definitions
    api-documentation/        # API docs
  Dockerfile                  # Optimized production build
```

## Environment Variables

See [`docker/.env.example`](docker/.env.example) for the full list with descriptions. Key variables:

| Variable                | Default     | Description                                      |
| ----------------------- | ----------- | ------------------------------------------------ |
| `PORT`                  | `9800`      | Application port                                 |
| `DATABASE_TYPE`         | `postgres`  | Database type (postgres, sqlite, mysql, mariadb) |
| `DATABASE_HOST`         | `postgres`  | Database hostname (matches Docker service name)  |
| `DATABASE_PORT`         | `5432`      | Database port                                    |
| `DATABASE_NAME`         | `cxbuilder` | Database name                                    |
| `DATABASE_USER`         | `cxbuilder` | Database username                                |
| `DATABASE_PASSWORD`     | -           | Database password (required)                     |
| `JWT_AUTH_TOKEN_SECRET` | -           | JWT signing secret (required)                    |
| `CORS_ORIGINS`          | `*`         | Allowed CORS origins                             |

## Pushing to Docker Hub

To build and push a new image:

```bash
docker buildx build \
  -t dsoden/cx-builder:latest \
  -t dsoden/cx-builder:cx-builder \
  -f docker/Dockerfile.local .

docker push dsoden/cx-builder --all-tags
```

## License

This project is based on [Flowise](https://github.com/FlowiseAI/Flowise), licensed under [Apache License 2.0](LICENSE.md).
