# ─────────────────────────────────────────────────────────────────────────────
# CX-Builder™ Installer (Windows PowerShell)
# ─────────────────────────────────────────────────────────────────────────────
# Local:     powershell -ExecutionPolicy Bypass -File install.ps1
# One-liner: irm https://raw.githubusercontent.com/dtsoden/CX-Builder/master/install.ps1 | iex
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"

$GitHubRaw = "https://raw.githubusercontent.com/dtsoden/CX-Builder/master"

# Determine working directory — use script location if run from a file,
# otherwise fall back to current directory (piped one-liner via irm | iex).
if ($MyInvocation.MyCommand.Definition -and (Test-Path $MyInvocation.MyCommand.Definition -ErrorAction SilentlyContinue)) {
    $ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
} else {
    $ScriptDir = Join-Path (Get-Location).Path "cx-builder"
}

$DockerDir   = Join-Path $ScriptDir "docker"
$EnvFile     = Join-Path $DockerDir ".env"
$ComposeFile = Join-Path $DockerDir "docker-compose.yml"

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Banner {
    Write-Host ""
    Write-Host "+" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 44) -NoNewline -ForegroundColor Cyan
    Write-Host "+" -ForegroundColor Cyan
    Write-Host "|" -NoNewline -ForegroundColor Cyan
    Write-Host "         CX-Builder  Installer            " -NoNewline -ForegroundColor White
    Write-Host "|" -ForegroundColor Cyan
    Write-Host "+" -NoNewline -ForegroundColor Cyan
    Write-Host ("=" * 44) -NoNewline -ForegroundColor Cyan
    Write-Host "+" -ForegroundColor Cyan
    Write-Host ""
}

function Write-Info  { param([string]$Msg) Write-Host "[INFO]  $Msg" -ForegroundColor Green }
function Write-Warn  { param([string]$Msg) Write-Host "[WARN]  $Msg" -ForegroundColor Yellow }
function Write-Err   { param([string]$Msg) Write-Host "[ERROR] $Msg" -ForegroundColor Red }

function New-HexString {
    param([int]$Bytes = 32)
    $rng    = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = New-Object byte[] $Bytes
    $rng.GetBytes($buffer)
    return ($buffer | ForEach-Object { $_.ToString("x2") }) -join ''
}

function New-Password {
    param([int]$Length = 24)
    $chars  = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_"
    $rng    = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $buffer = New-Object byte[] $Length
    $rng.GetBytes($buffer)
    $pw = -join ($buffer | ForEach-Object { $chars[$_ % $chars.Length] })
    return $pw
}

function Read-Value {
    param([string]$Prompt, [string]$Default = "")
    if ($Default) {
        $input = Read-Host "  $Prompt [$Default]"
        if ([string]::IsNullOrWhiteSpace($input)) { return $Default }
        return $input
    } else {
        return Read-Host "  $Prompt"
    }
}

# ── Download compose file if running standalone ──────────────────────────────
function Get-ComposeFile {
    if (Test-Path $ComposeFile) { return }

    Write-Info "Compose file not found locally - downloading from GitHub..."
    if (-not (Test-Path $DockerDir)) {
        New-Item -ItemType Directory -Path $DockerDir -Force | Out-Null
    }

    try {
        Invoke-WebRequest -Uri "$GitHubRaw/docker/docker-compose.yml" -OutFile $ComposeFile -UseBasicParsing
    } catch {
        Write-Err "Failed to download docker-compose.yml from GitHub."
        Write-Err $_.Exception.Message
        exit 1
    }

    Write-Info "Downloaded docker-compose.yml to $DockerDir"
}

# ── Pre-flight checks ───────────────────────────────────────────────────────
function Test-Preflight {
    $dockerCmd = Get-Command docker -ErrorAction SilentlyContinue
    if (-not $dockerCmd) {
        Write-Err "Docker is not installed or not in PATH."
        Write-Host "  Install Docker: https://docs.docker.com/get-docker/"
        exit 1
    }

    $null = docker info 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Docker daemon is not running. Please start Docker Desktop and try again."
        exit 1
    }

    # Check for docker compose v2
    $null = docker compose version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Err "Docker Compose is not available. Please update Docker Desktop."
        exit 1
    }

    Write-Info "Docker found: $(docker --version)"
    Write-Info "Compose found: $(docker compose version)"

    # Fetch compose file if not present (standalone / one-liner mode)
    Get-ComposeFile
}

# ── Configuration ────────────────────────────────────────────────────────────
function Set-Configuration {
    if (Test-Path $EnvFile) {
        Write-Warn "An existing .env file was found at: $EnvFile"
        $overwrite = Read-Host "  Overwrite it? (y/N)"
        if ($overwrite -notmatch '^[Yy]$') {
            Write-Info "Keeping existing .env file."
            return
        }
    }

    Write-Host ""
    Write-Host "How would you like to configure CX-Builder?" -ForegroundColor White
    Write-Host ""
    Write-Host "  1) Auto-generate all secrets (recommended)"
    Write-Host "  2) Enter values manually"
    Write-Host ""
    $mode = Read-Host "  Choose [1]"
    if ([string]::IsNullOrWhiteSpace($mode)) { $mode = "1" }

    $port           = "9800"
    $dbName         = "cxbuilder"
    $dbUser         = "cxbuilder"
    $dbPassword     = ""
    $jwtAuthSecret  = ""
    $jwtRefreshSecret = ""

    if ($mode -eq "2") {
        Write-Host ""
        Write-Info "Enter your configuration (press Enter to accept defaults):"
        Write-Host ""
        $port   = Read-Value "Application port" "9800"
        $dbName = Read-Value "Database name" "cxbuilder"
        $dbUser = Read-Value "Database user" "cxbuilder"

        Write-Host ""
        Write-Warn "Avoid special characters (!@#`$%) in passwords - they can break"
        Write-Warn "Docker's .env parser. Use alphanumeric + underscores."
        Write-Host ""

        $dbPassword = Read-Value "Database password" ""
        while ([string]::IsNullOrWhiteSpace($dbPassword)) {
            Write-Err "Password cannot be empty."
            $dbPassword = Read-Value "Database password" ""
        }

        $jwtAuthSecret = Read-Value "JWT auth secret (hex string, Enter to auto-generate)" ""
        if ([string]::IsNullOrWhiteSpace($jwtAuthSecret)) {
            $jwtAuthSecret = New-HexString -Bytes 32
            Write-Info "Auto-generated JWT auth secret."
        }

        $jwtRefreshSecret = Read-Value "JWT refresh secret (hex string, Enter to auto-generate)" ""
        if ([string]::IsNullOrWhiteSpace($jwtRefreshSecret)) {
            $jwtRefreshSecret = New-HexString -Bytes 32
            Write-Info "Auto-generated JWT refresh secret."
        }
    } else {
        Write-Info "Auto-generating all secrets..."
        $dbPassword       = New-Password -Length 24
        $jwtAuthSecret    = New-HexString -Bytes 32
        $jwtRefreshSecret = New-HexString -Bytes 32
    }

    $envContent = @"
# =============================================================================
# CX-Builder Environment Configuration  (auto-generated by install.ps1)
# =============================================================================

PORT=$port

# DATABASE (pgvector PostgreSQL)
DATABASE_TYPE=postgres
DATABASE_HOST=postgres
DATABASE_PORT=5432
DATABASE_NAME=$dbName
DATABASE_USER=$dbUser
DATABASE_PASSWORD=$dbPassword

POSTGRES_DB=$dbName
POSTGRES_USER=$dbUser
POSTGRES_PASSWORD=$dbPassword

# STORAGE PATHS
DATABASE_PATH=/root/.flowise
SECRETKEY_PATH=/root/.flowise
LOG_PATH=/root/.flowise/logs
BLOB_STORAGE_PATH=/root/.flowise/storage

# AUTHENTICATION (JWT)
JWT_AUTH_TOKEN_SECRET=$jwtAuthSecret
JWT_REFRESH_TOKEN_SECRET=$jwtRefreshSecret
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
"@

    Set-Content -Path $EnvFile -Value $envContent -Encoding UTF8
    Write-Info "Configuration written to $EnvFile"
}

# ── Launch ───────────────────────────────────────────────────────────────────
function Start-CXBuilder {
    Write-Host ""
    Write-Info "Pulling images and starting CX-Builder..."
    Write-Host ""

    docker compose -f $ComposeFile up -d

    if ($LASTEXITCODE -ne 0) {
        Write-Err "Failed to start CX-Builder. Check Docker logs for details."
        exit 1
    }

    $port = (Select-String -Path $EnvFile -Pattern '^PORT=(.+)$').Matches.Groups[1].Value

    Write-Host ""
    Write-Host ("=" * 46) -ForegroundColor Green
    Write-Host "  CX-Builder is starting!" -ForegroundColor Green
    Write-Host ("=" * 46) -ForegroundColor Green
    Write-Host ""
    Write-Host "  Open: " -NoNewline
    Write-Host "http://localhost:$port" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  Useful commands:"
    Write-Host "    Logs:    docker compose -f $ComposeFile logs -f"
    Write-Host "    Stop:    docker compose -f $ComposeFile down"
    Write-Host "    Restart: docker compose -f $ComposeFile restart"
    Write-Host ""
}

# ── Main ─────────────────────────────────────────────────────────────────────
Write-Banner
Test-Preflight
Set-Configuration
Start-CXBuilder
