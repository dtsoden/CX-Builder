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
EOF

    info "Configuration written to $ENV_FILE"
}

# ── Launch ───────────────────────────────────────────────────────────────────
launch() {
    echo ""
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
configure
launch
