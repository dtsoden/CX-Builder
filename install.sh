#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# CX-Builder™ Installer (Linux / macOS)
# ─────────────────────────────────────────────────────────────────────────────
# Local:     chmod +x install.sh && ./install.sh
# One-liner: curl -fsSL https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.sh | bash
# ─────────────────────────────────────────────────────────────────────────────

GITHUB_RAW="https://raw.githubusercontent.com/dtsoden/CX-Builder/master"
STANDALONE=false

# Determine working directory — use script location if run from a file,
# otherwise fall back to current directory (piped one-liner).
if [ -n "${BASH_SOURCE[0]:-}" ] && [ "${BASH_SOURCE[0]}" != "bash" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    SCRIPT_DIR="$(pwd)/cx-builder"
    STANDALONE=true
fi

DOCKER_DIR="$SCRIPT_DIR/docker"
ENV_FILE="$DOCKER_DIR/.env"
COMPOSE_FILE="$DOCKER_DIR/docker-compose.yml"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# When piped (curl | bash), stdin is the pipe — redirect reads from terminal.
if [ ! -t 0 ]; then
    exec 3</dev/tty
else
    exec 3<&0
fi

banner() {
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║         CX-Builder™  Installer          ║${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

info()    { echo -e "${GREEN}[INFO]${NC}  $1"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $1"; }
error()   { echo -e "${RED}[ERROR]${NC} $1"; }

# ── Helpers ──────────────────────────────────────────────────────────────────
generate_hex() {
    # Generate a random hex string (length = $1 bytes → $1*2 hex chars)
    local bytes="${1:-32}"
    if command -v openssl &>/dev/null; then
        openssl rand -hex "$bytes"
    elif [ -r /dev/urandom ]; then
        head -c "$bytes" /dev/urandom | od -An -tx1 | tr -d ' \n'
    else
        # Pure-bash fallback (unlikely path)
        local hex=""
        for ((i = 0; i < bytes; i++)); do
            hex+="$(printf '%02x' $((RANDOM % 256)))"
        done
        echo "$hex"
    fi
}

generate_password() {
    # Alphanumeric + underscore, 24 chars (safe for Docker .env parsing)
    local chars='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_'
    if command -v openssl &>/dev/null; then
        openssl rand -base64 32 | tr -dc "$chars" | head -c 24
    elif [ -r /dev/urandom ]; then
        head -c 48 /dev/urandom | base64 | tr -dc "$chars" | head -c 24
    else
        local pw=""
        for ((i = 0; i < 24; i++)); do
            pw+="${chars:RANDOM % ${#chars}:1}"
        done
        echo "$pw"
    fi
}

prompt_value() {
    local prompt="$1" default="$2" value
    if [ -n "$default" ]; then
        read -rp "  $prompt [$default]: " value <&3
        echo "${value:-$default}"
    else
        read -rp "  $prompt: " value <&3
        echo "$value"
    fi
}

# ── Download compose file if running standalone ──────────────────────────────
fetch_compose() {
    if [ -f "$COMPOSE_FILE" ]; then
        return
    fi

    info "Compose file not found locally — downloading from GitHub..."
    mkdir -p "$DOCKER_DIR"

    if command -v curl &>/dev/null; then
        curl -fsSL "$GITHUB_RAW/docker/docker-compose.yml" -o "$COMPOSE_FILE"
    elif command -v wget &>/dev/null; then
        wget -q "$GITHUB_RAW/docker/docker-compose.yml" -O "$COMPOSE_FILE"
    else
        error "curl or wget is required to download the compose file."
        exit 1
    fi

    info "Downloaded docker-compose.yml to $DOCKER_DIR"
}

# ── Pre-flight checks ───────────────────────────────────────────────────────
preflight() {
    if ! command -v docker &>/dev/null; then
        error "Docker is not installed or not in PATH."
        echo "  Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    fi

    if ! docker info &>/dev/null 2>&1; then
        error "Docker daemon is not running. Please start Docker and try again."
        exit 1
    fi

    # Check for docker compose (v2 plugin or standalone)
    if docker compose version &>/dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &>/dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        error "Docker Compose is not available."
        echo "  Install Docker Compose: https://docs.docker.com/compose/install/"
        exit 1
    fi

    info "Docker found: $(docker --version)"
    info "Compose found: $($COMPOSE_CMD version 2>/dev/null || echo 'available')"

    # Fetch compose file if not present (standalone / one-liner mode)
    fetch_compose
}

# ── Configuration ────────────────────────────────────────────────────────────
configure() {
    if [ -f "$ENV_FILE" ]; then
        warn "An existing .env file was found at: $ENV_FILE"
        read -rp "  Overwrite it? (y/N): " overwrite <&3
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            info "Keeping existing .env file."
            return
        fi
    fi

    echo ""
    echo -e "${BOLD}How would you like to configure CX-Builder?${NC}"
    echo ""
    echo "  1) Auto-generate all secrets (recommended)"
    echo "  2) Enter values manually"
    echo ""
    read -rp "  Choose [1]: " mode <&3
    mode="${mode:-1}"

    # Defaults
    local port="9800"
    local db_name="cxbuilder"
    local db_user="cxbuilder"
    local db_password
    local jwt_auth_secret
    local jwt_refresh_secret

    if [ "$mode" = "2" ]; then
        echo ""
        info "Enter your configuration (press Enter to accept defaults):"
        echo ""
        port=$(prompt_value "Application port" "9800")
        db_name=$(prompt_value "Database name" "cxbuilder")
        db_user=$(prompt_value "Database user" "cxbuilder")

        echo ""
        warn "Avoid special characters (!@#\$%) in passwords — they can break"
        warn "Docker's .env parser. Use alphanumeric + underscores."
        echo ""
        db_password=$(prompt_value "Database password" "")
        while [ -z "$db_password" ]; do
            error "Password cannot be empty."
            db_password=$(prompt_value "Database password" "")
        done

        jwt_auth_secret=$(prompt_value "JWT auth secret (hex string)" "")
        if [ -z "$jwt_auth_secret" ]; then
            jwt_auth_secret=$(generate_hex 32)
            info "Auto-generated JWT auth secret."
        fi

        jwt_refresh_secret=$(prompt_value "JWT refresh secret (hex string)" "")
        if [ -z "$jwt_refresh_secret" ]; then
            jwt_refresh_secret=$(generate_hex 32)
            info "Auto-generated JWT refresh secret."
        fi
    else
        info "Auto-generating all secrets..."
        db_password=$(generate_password)
        jwt_auth_secret=$(generate_hex 32)
        jwt_refresh_secret=$(generate_hex 32)
    fi

    # Write .env
    cat > "$ENV_FILE" <<EOF
# =============================================================================
# CX-Builder Environment Configuration  (auto-generated by install.sh)
# =============================================================================

PORT=${port}

# DATABASE (pgvector PostgreSQL)
DATABASE_TYPE=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=${db_name}
DATABASE_USER=${db_user}
DATABASE_PASSWORD=${db_password}

POSTGRES_DB=${db_name}
POSTGRES_USER=${db_user}
POSTGRES_PASSWORD=${db_password}

# STORAGE PATHS
DATABASE_PATH=/home/node/.flowise
SECRETKEY_PATH=/home/node/.flowise
LOG_PATH=/home/node/.flowise/logs
BLOB_STORAGE_PATH=/home/node/.flowise/storage

# AUTHENTICATION (JWT)
JWT_AUTH_TOKEN_SECRET=${jwt_auth_secret}
JWT_REFRESH_TOKEN_SECRET=${jwt_refresh_secret}
JWT_ISSUER=CX-Builder
JWT_AUDIENCE=CX-Builder
JWT_TOKEN_EXPIRY_IN_MINUTES=360
JWT_REFRESH_TOKEN_EXPIRY_IN_MINUTES=43200

# CORS
CORS_ORIGINS=*

# OPTIONAL (blank = sensible defaults)
DATABASE_SSL=
DATABASE_SSL_KEY_BASE64=
SECRETKEY_STORAGE_TYPE=
FLOWISE_SECRETKEY_OVERWRITE=
DEBUG=
LOG_LEVEL=
STORAGE_TYPE=
SHOW_COMMUNITY_NODES=
IFRAME_ORIGINS=
HTTP_SECURITY_CHECK=
HTTP_DENY_LIST=
EOF

    info "Configuration written to $ENV_FILE"
}

# ── Orphaned data volumes ────────────────────────────────────────────────────
# Docker volumes outlive both containers and the project folder. If the folder
# (and its .env) was deleted while the volumes remained, the installer would
# generate a NEW database password that the surviving database rejects,
# producing a crash loop whose error never mentions volumes. Detect that here.
#
# The encryption key lives in the cxbuilder_data volume as encryption.key, not
# in .env, so keeping the data is safe: only the Postgres password has to be
# reconciled.
RESET_DB_PASSWORD=0

check_orphaned_volumes() {
    local pg app
    pg=$(docker volume ls -q --filter "name=^cx-builder_postgres_data$" 2>/dev/null)
    app=$(docker volume ls -q --filter "name=^cx-builder_cxbuilder_data$" 2>/dev/null)
    [ -z "$pg" ] && [ -z "$app" ] && return 0     # clean machine
    [ -f "$ENV_FILE" ] && return 0                # .env present, still paired

    echo ""
    warn "Existing CX-Builder data was found, but its configuration is gone."
    echo ""
    echo "  Docker volumes survive deleting containers AND deleting the folder."
    echo "  These still exist on this machine:"
    [ -n "$pg" ]  && echo "    cx-builder_postgres_data   (your database)"
    [ -n "$app" ] && echo "    cx-builder_cxbuilder_data  (uploads, encryption key)"
    echo ""
    echo "  The database still expects the OLD password, which was in the .env"
    echo "  file you deleted. A new install would generate a new password and"
    echo "  fail to connect."
    echo ""
    echo "  1) Keep my existing data  (recommended)"
    echo "     Updates the database to accept the new password. Flows,"
    echo "     credentials and uploads are preserved."
    echo ""
    echo "  2) Start completely fresh"
    echo "     DELETES both volumes. Everything is lost and cannot be undone."
    echo ""
    echo "  3) Cancel"
    echo "     Stop so you can back up or restore your old .env first."
    echo ""
    printf "  Choose [1]: "
    read -r choice < /dev/tty
    [ -z "$choice" ] && choice=1

    case "$choice" in
        1)
            RESET_DB_PASSWORD=1
            info "Keeping existing data. The database password will be updated to match."
            ;;
        2)
            echo ""
            warn "This permanently deletes your database and uploads."
            printf "  Type DELETE to confirm: "
            read -r confirm < /dev/tty
            if [ "$confirm" != "DELETE" ]; then error "Not confirmed. Nothing was changed."; exit 1; fi
            docker volume rm cx-builder_postgres_data cx-builder_cxbuilder_data >/dev/null 2>&1
            info "Volumes removed. Starting fresh."
            ;;
        *)
            echo ""
            info "Cancelled. Nothing was changed."
            echo "  Your data is still in the Docker volumes listed above."
            echo "  Restore the old docker/.env to use it, or re-run and choose 1."
            exit 0
            ;;
    esac
}

# ── Launch ───────────────────────────────────────────────────────────────────
launch() {
    echo ""

    # Read the port we actually configured in .env.
    local configured_port
    configured_port=$(grep -E '^PORT=' "$ENV_FILE" | head -1 | cut -d= -f2)

    # Docker Compose gives shell environment variables precedence over the .env
    # file. PORT is a common variable to have exported, and if it is set to
    # something else the stack silently binds the wrong port, or fails outright
    # when that port is taken. Force the environment to agree with .env.
    if [ -n "${PORT:-}" ] && [ "${PORT}" != "$configured_port" ]; then
        warn "PORT is set to '${PORT}' in your shell."
        warn "Docker Compose would use that instead of the $configured_port in .env."
        warn "Overriding it to $configured_port for this install."
        echo ""
    fi
    export PORT="$configured_port"

    # If the configured port is taken, pick the next free one rather than dying with
    # a raw Docker bind error. Never touch whatever already owns the busy port.
    port_busy() {
        if command -v lsof >/dev/null 2>&1; then
            lsof -iTCP:"$1" -sTCP:LISTEN -t >/dev/null 2>&1
        elif command -v ss >/dev/null 2>&1; then
            ss -ltn "sport = :$1" 2>/dev/null | grep -q LISTEN
        else
            return 1   # cannot tell; let Docker decide
        fi
    }

    if port_busy "$configured_port"; then
        warn "Port $configured_port is already in use."
        candidate=$((configured_port + 1))
        while [ "$candidate" -lt 49000 ] && port_busy "$candidate"; do
            candidate=$((candidate + 1))
        done
        if [ "$candidate" -ge 49000 ]; then
            error "Could not find a free port. Set PORT manually in $ENV_FILE and re-run."
            exit 1
        fi
        warn "Using port $candidate instead. Nothing on $configured_port was changed."
        echo ""
        sed -i.bak "s/^PORT=.*/PORT=$candidate/" "$ENV_FILE" && rm -f "$ENV_FILE.bak"
        configured_port="$candidate"
        export PORT="$configured_port"
    fi

    # Reconcile the surviving database with the newly generated password before
    # the app container tries to connect. Postgres only applies POSTGRES_PASSWORD
    # when initialising an empty data directory.
    if [ "$RESET_DB_PASSWORD" = "1" ]; then
        local pgpw dbu dbn h
        pgpw=$(grep -E '^POSTGRES_PASSWORD=' "$ENV_FILE" | head -1 | cut -d= -f2-)
        dbu=$(grep -E '^POSTGRES_USER=' "$ENV_FILE" | head -1 | cut -d= -f2-)
        dbn=$(grep -E '^POSTGRES_DB=' "$ENV_FILE" | head -1 | cut -d= -f2-)
        info "Starting the database to update its password..."
        $COMPOSE_CMD -f "$COMPOSE_FILE" up -d postgres >/dev/null 2>&1
        for _ in $(seq 1 60); do
            h=$(docker inspect --format '{{.State.Health.Status}}' cx-builder-postgres-1 2>/dev/null)
            [ "$h" = "healthy" ] && break
            sleep 2
        done
        if docker exec -e NEWPW="$pgpw" cx-builder-postgres-1 sh -c              "psql -v ON_ERROR_STOP=1 -U $dbu -d $dbn -c \"ALTER USER $dbu WITH PASSWORD '\$NEWPW';\"" >/dev/null 2>&1; then
            info "Database password updated. Your data is intact."
        else
            error "Could not update the database password."
            echo "  Restore your old docker/.env, or re-run and choose option 2."
            exit 1
        fi
        echo ""
    fi

    info "Pulling images and starting CX-Builder..."
    echo ""

    $COMPOSE_CMD -f "$COMPOSE_FILE" up -d

    echo ""
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo -e "${GREEN}${BOLD}  CX-Builder is starting!${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════${NC}"
    echo ""

    local port
    port=$(grep '^PORT=' "$ENV_FILE" | cut -d= -f2)
    echo -e "  Open: ${CYAN}http://localhost:${port}${NC}"
    echo ""
    echo "  Useful commands:"
    echo "    Logs:    $COMPOSE_CMD -f $COMPOSE_FILE logs -f"
    echo "    Stop:    $COMPOSE_CMD -f $COMPOSE_FILE down"
    echo "    Restart: $COMPOSE_CMD -f $COMPOSE_FILE restart"
    echo ""
}

# ── Main ─────────────────────────────────────────────────────────────────────
banner
preflight
check_orphaned_volumes
configure
launch
