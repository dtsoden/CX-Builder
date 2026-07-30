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
DATABASE_PATH=/home/node/.flowise
SECRETKEY_PATH=/home/node/.flowise
LOG_PATH=/home/node/.flowise/logs
BLOB_STORAGE_PATH=/home/node/.flowise/storage

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
HTTP_SECURITY_CHECK=
HTTP_DENY_LIST=
"@

    Set-Content -Path $EnvFile -Value $envContent -Encoding UTF8
    Write-Info "Configuration written to $EnvFile"
}

# ── Orphaned data volumes ────────────────────────────────────────────────────
# Docker volumes outlive both containers and the project folder. If the folder
# (and its .env) was deleted while the volumes remained, the installer would
# generate a NEW database password that the surviving database will reject,
# producing a crash loop whose error never mentions volumes. Detect that here.
#
# The encryption key lives in the cxbuilder_data volume as encryption.key, not
# in .env, so keeping the data is safe: only the Postgres password has to be
# reconciled.
$script:ResetDbPassword = $false

function Test-OrphanedVolumes {
    $pg  = docker volume ls -q --filter "name=^cx-builder_postgres_data$" 2>$null
    $app = docker volume ls -q --filter "name=^cx-builder_cxbuilder_data$" 2>$null
    if (-not $pg -and -not $app) { return }          # clean machine, nothing to do
    if (Test-Path $EnvFile)      { return }          # .env present, credentials still paired

    Write-Host ""
    Write-Warn "Existing CX-Builder data was found, but its configuration is gone."
    Write-Host ""
    Write-Host "  Docker volumes survive deleting containers AND deleting the folder."
    Write-Host "  These still exist on this machine:"
    if ($pg)  { Write-Host "    cx-builder_postgres_data   (your database)" }
    if ($app) { Write-Host "    cx-builder_cxbuilder_data  (uploads, encryption key)" }
    Write-Host ""
    Write-Host "  The database still expects the OLD password, which was in the .env"
    Write-Host "  file you deleted. A new install would generate a new password and"
    Write-Host "  fail to connect."
    Write-Host ""
    Write-Host "  1) Keep my existing data  (recommended)"
    Write-Host "     Updates the database to accept the new password. Flows,"
    Write-Host "     credentials and uploads are preserved."
    Write-Host ""
    Write-Host "  2) Start completely fresh"
    Write-Host "     DELETES both volumes. Everything is lost and cannot be undone."
    Write-Host ""
    Write-Host "  3) Cancel"
    Write-Host "     Stop so you can back up or restore your old .env first."
    Write-Host ""

    $choice = Read-Host "  Choose [1]"
    if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "1" }

    switch ($choice) {
        "1" {
            $script:ResetDbPassword = $true
            Write-Info "Keeping existing data. The database password will be updated to match."
        }
        "2" {
            Write-Host ""
            Write-Warn "This permanently deletes your database and uploads."
            $confirm = Read-Host "  Type DELETE to confirm"
            if ($confirm -ne "DELETE") { Write-Err "Not confirmed. Nothing was changed."; exit 1 }
            docker volume rm cx-builder_postgres_data cx-builder_cxbuilder_data 2>&1 | Out-Null
            Write-Info "Volumes removed. Starting fresh."
        }
        default {
            Write-Host ""
            Write-Info "Cancelled. Nothing was changed."
            Write-Host "  Your data is still in the Docker volumes listed above."
            Write-Host "  Restore the old docker/.env to use it, or re-run and choose 1."
            exit 0
        }
    }
}

# ── Launch ───────────────────────────────────────────────────────────────────
function Start-CXBuilder {
    Write-Host ""

    # Read the port we actually configured in .env.
    $configuredPort = (Select-String -Path $EnvFile -Pattern '^PORT=(.+)$').Matches.Groups[1].Value

    # Docker Compose gives shell environment variables precedence over the .env
    # file.  PORT is a common variable to have exported, and if it is set to
    # something else the stack silently binds the wrong port, or fails outright
    # when that port is taken.  Force the environment to agree with .env.
    if ($env:PORT -and $env:PORT -ne $configuredPort) {
        Write-Host "[WARN]  PORT is set to '$env:PORT' in your shell." -ForegroundColor Yellow
        Write-Host "        Docker Compose would use that instead of the $configuredPort in .env." -ForegroundColor Yellow
        Write-Host "        Overriding it to $configuredPort for this install." -ForegroundColor Yellow
        Write-Host ""
    }
    $env:PORT = $configuredPort

    # If the configured port is taken, pick the next free one rather than dying with
    # a raw Docker bind error. Never touch whatever already owns the busy port.
    $inUse = Get-NetTCPConnection -LocalPort ([int]$configuredPort) -State Listen -ErrorAction SilentlyContinue
    if ($inUse) {
        $owner = (Get-Process -Id $inUse[0].OwningProcess -ErrorAction SilentlyContinue).ProcessName
        Write-Host "[WARN]  Port $configuredPort is already in use by '$owner' (PID $($inUse[0].OwningProcess))." -ForegroundColor Yellow

        # Search upward, staying well clear of the Windows ephemeral range (49152+).
        $candidate = [int]$configuredPort + 1
        while ($candidate -lt 49000 -and (Get-NetTCPConnection -LocalPort $candidate -State Listen -ErrorAction SilentlyContinue)) {
            $candidate++
        }
        if ($candidate -ge 49000) {
            Write-Err "Could not find a free port. Set PORT manually in $EnvFile and re-run."
            exit 1
        }

        Write-Host "        Using port $candidate instead. Nothing on $configuredPort was changed." -ForegroundColor Yellow
        Write-Host ""
        (Get-Content $EnvFile) -replace "^PORT=.*", "PORT=$candidate" | Set-Content -Path $EnvFile -Encoding UTF8
        $configuredPort = "$candidate"
        $env:PORT = $configuredPort
    }

    Write-Info "Pulling images and starting CX-Builder..."
    Write-Host ""

    # Reconcile the surviving database with the newly generated password before
    # the app container tries to connect. Postgres only applies POSTGRES_PASSWORD
    # when initialising an empty data directory, so an existing volume keeps the
    # old password and must be altered directly.
    if ($script:ResetDbPassword) {
        $pgpw = (Select-String -Path $EnvFile -Pattern '^POSTGRES_PASSWORD=(.+)$').Matches.Groups[1].Value
        $dbu  = (Select-String -Path $EnvFile -Pattern '^POSTGRES_USER=(.+)$').Matches.Groups[1].Value
        $dbn  = (Select-String -Path $EnvFile -Pattern '^POSTGRES_DB=(.+)$').Matches.Groups[1].Value
        Write-Info "Starting the database to update its password..."
        docker compose -f $ComposeFile up -d postgres | Out-Null
        for ($i = 0; $i -lt 60; $i++) {
            $h = docker inspect --format '{{.State.Health.Status}}' cx-builder-postgres-1 2>$null
            if ($h -eq "healthy") { break }
            Start-Sleep -Seconds 2
        }
        docker exec -e NEWPW="$pgpw" cx-builder-postgres-1 sh -c "psql -v ON_ERROR_STOP=1 -U $dbu -d $dbn -c \"ALTER USER $dbu WITH PASSWORD '`$NEWPW';\"" | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Info "Database password updated. Your data is intact." }
        else { Write-Err "Could not update the database password. Restore your old .env, or re-run and choose option 2."; exit 1 }
        Write-Host ""
    }

    # Docker Compose writes progress to stderr, which PowerShell treats as a
    # terminating error when $ErrorActionPreference is "Stop".  Temporarily
    # relax the preference so progress messages don't abort the script.
    $saved = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    docker compose -f $ComposeFile up -d
    $ErrorActionPreference = $saved

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
Test-OrphanedVolumes
Set-Configuration
Start-CXBuilder
