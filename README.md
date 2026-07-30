# CX-Builder™

**AI Agent Development Platform**

Build AI agents, chatbots, and RAG pipelines visually with a drag-and-drop interface. CX-Builder has pgvector PostgreSQL integration, custom branding, and a production Docker deployment.

CX-Builder is an independent fork of [Flowise](https://github.com/FlowiseAI/Flowise), tracking its final release, v3.1.4.

> **Flowise was discontinued by its original team in July 2026.** Active development stopped on 27 July 2026, the upstream repository is being archived on 10 August 2026, and upstream npm packages and Docker images are being marked deprecated on the same date. Support from the original team ends 31 August 2026. See the [sunset notice](https://flowiseai.com/sunset).
>
> This does not affect CX-Builder. The code is Apache 2.0 and CX-Builder builds entirely from source in this repository, so nothing here depends on upstream packages continuing to be published. CX-Builder is maintained independently from this point on.

## Quick Start (One-Liner)

The fastest way to run CX-Builder. Just Docker, nothing else required. No git clone, no manual config. The installer generates all secrets automatically and starts the stack.

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
       |     - Stores uploads/secrets in /home/node/.flowise
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

This uses `docker/Dockerfile.local` which runs `pnpm install` and `pnpm build` inside the container, so no local Node.js setup is required.

## Development

### Prerequisites

- Node.js >= 24 (Flowise 3.1.x requires Node 24; see `.nvmrc`)
- pnpm >= 10.26.0

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
  landing/                    # cx-builder.com source (deployed to Cloudflare Pages)
  packages/
    server/                   # Express API + oclif CLI
    ui/                       # React + MUI frontend (Vite)
    components/               # LangChain node definitions
    agentflow/                # @flowiseai/agentflow SDK, skipped by pnpm build:docker
    observe/                  # @flowiseai/observe SDK, skipped by pnpm build:docker
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

The published image is multi-architecture: `linux/amd64` for PCs and Intel Macs,
`linux/arm64` for Apple Silicon. Docker picks the right one automatically, so there
is one tag, `latest`.

Multi-arch requires the `docker-container` buildx driver. The default `docker` driver
can only produce one architecture and cannot emit a manifest list. Create the builder
once:

```bash
docker buildx create --name multiarch --driver docker-container --use
docker buildx inspect multiarch --bootstrap
```

Then build and push. Note this uses the root `Dockerfile`, not `docker/Dockerfile.local`:

```bash
docker buildx build --builder multiarch \
  --platform linux/amd64,linux/arm64 \
  -t dsoden/cx-builder:latest \
  --push .
```

`--push` is required. buildx cannot load a multi-platform image into the local daemon,
so there is no local image to `docker push` afterwards, and nothing reaches Docker Hub
until every architecture has finished building.

Verify what landed:

```bash
docker manifest inspect dsoden/cx-builder:latest
```

Expect `linux/amd64` and `linux/arm64`. Any `unknown/unknown` entries are SBOM and
provenance attestations, not architectures.

### Notes

- **arm64 builds under QEMU emulation on an x86 host and is roughly 10-15x slower.**
  A build that takes 50s for amd64 takes ~11 minutes for arm64. Budget 20-30 minutes
  end to end including the upload.
- **Before testing a fresh pull, delete the local copy** with
  `docker rmi dsoden/cx-builder:latest`. Otherwise Docker reuses the stale local image
  and the test proves nothing.
- **pnpm 10 blocks postinstall scripts** for `canvas`, `sharp`, `puppeteer` and others.
  This is expected and does not affect startup, but it is the first place to look if
  image processing or screenshot nodes misbehave.
- **`docker compose` gives shell environment variables precedence over `.env`.** If
  `PORT` is exported in your shell, compose binds that instead of the value in
  `docker/.env`. Check with `echo $PORT` before deploying, or pass `PORT=... ` inline.

## License

This project is a fork of [Flowise](https://github.com/FlowiseAI/Flowise), licensed under [Apache License 2.0](LICENSE.md). Attribution to FlowiseAI, Inc. is retained as the licence requires, and remains in force after the upstream project's sunset. Forking is explicitly permitted by the sunset notice: "the Apache 2.0 licensed code is yours to keep building on."

Note that not all of the inherited source is Apache 2.0. Files under `packages/server/src/enterprise/`, and individual files carrying their own copyright notice, are covered by a separate commercial licence. See [LICENSE.md](LICENSE.md) for the exact terms.
