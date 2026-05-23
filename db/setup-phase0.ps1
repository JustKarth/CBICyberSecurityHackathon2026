# Phase 0: start Postgres (Docker) and apply schema, functions, triggers, seed.
# Run from project root:  .\db\setup-phase0.ps1

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

function Find-Docker {
    $candidates = @(
        "docker",
        "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe",
        "$env:LOCALAPPDATA\Docker\wsl\docker.exe"
    )
    foreach ($c in $candidates) {
        if (Get-Command $c -ErrorAction SilentlyContinue) { return (Get-Command $c).Source }
        if (Test-Path $c) { return $c }
    }
    return $null
}

$docker = Find-Docker
if (-not $docker) {
    Write-Host "Docker not found. Install Docker Desktop, then re-run this script." -ForegroundColor Red
    Write-Host "  https://www.docker.com/products/docker-desktop/" -ForegroundColor Yellow
    exit 1
}

if (-not (Test-Path ".env")) {
    Write-Host "Missing .env at project root. Copy .env.example to .env" -ForegroundColor Red
    exit 1
}

Write-Host "Starting PostgreSQL container..." -ForegroundColor Cyan
& $docker compose -f docker/docker-compose.yaml up -d

Write-Host "Waiting for database to accept connections..." -ForegroundColor Cyan
$ready = $false
for ($i = 0; $i -lt 30; $i++) {
    & $docker exec app_db pg_isready -U postgres 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { $ready = $true; break }
    Start-Sleep -Seconds 2
}
if (-not $ready) {
    Write-Host "Postgres did not become ready in time." -ForegroundColor Red
    exit 1
}

$scripts = @("schema.sql", "functions.sql", "triggers.sql", "seed.sql")
foreach ($name in $scripts) {
    Write-Host "Applying $name ..." -ForegroundColor Cyan
    & $docker exec -i app_db psql -U postgres -d fraud_system -v ON_ERROR_STOP=1 -f "/sql/$name"
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed on $name" -ForegroundColor Red
        exit 1
    }
}

Write-Host "`nVerification:" -ForegroundColor Green
& $docker exec app_db psql -U postgres -d fraud_system -c "\dt"
& $docker exec app_db psql -U postgres -d fraud_system -c "SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS accounts FROM accounts; SELECT COUNT(*) AS transactions FROM transactions;"

Write-Host "`nPhase 0 complete." -ForegroundColor Green
