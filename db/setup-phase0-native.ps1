# Phase 0 (local dev): PostgreSQL without Docker.
# Run from project root:  .\db\setup-phase0-native.ps1
# Optional env: $env:PGPASSWORD = "your_password"

$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $ProjectRoot

function Find-Psql {
    if (Get-Command psql -ErrorAction SilentlyContinue) {
        return (Get-Command psql).Source
    }
    # Prefer 17 on default port 5432 (matches backend/.env DATABASE_URL)
    $versions = @(17, 16, 15, 18)
    foreach ($v in $versions) {
        $path = "C:\Program Files\PostgreSQL\$v\bin\psql.exe"
        if (Test-Path $path) { return $path }
    }
    return $null
}

$psql = Find-Psql
if (-not $psql) {
    Write-Host "psql not found. Install PostgreSQL 17:" -ForegroundColor Red
    Write-Host '  winget install -e --id PostgreSQL.PostgreSQL.17 --accept-package-agreements --accept-source-agreements' -ForegroundColor Yellow
    exit 1
}

$pgUser = if ($env:POSTGRES_USER) { $env:POSTGRES_USER } else { "postgres" }
$dbName = if ($env:POSTGRES_DB) { $env:POSTGRES_DB } else { "fraud_system" }

Write-Host "Using psql: $psql" -ForegroundColor Cyan
Write-Host "User: $pgUser  Database: $dbName" -ForegroundColor Cyan

$exists = & $psql -U $pgUser -d postgres -tAc "SELECT 1 FROM pg_database WHERE datname='$dbName'" 2>$null
if ($exists -ne "1") {
    Write-Host "Creating database $dbName ..." -ForegroundColor Cyan
    & $psql -U $pgUser -d postgres -c "CREATE DATABASE $dbName;"
}

$scripts = @("schema.sql", "functions.sql", "triggers.sql", "seed.sql")
foreach ($name in $scripts) {
    $file = Join-Path $ProjectRoot "db\$name"
    Write-Host "Applying $name ..." -ForegroundColor Cyan
    & $psql -U $pgUser -d $dbName -v ON_ERROR_STOP=1 -f $file
}

Write-Host "`nVerification:" -ForegroundColor Green
& $psql -U $pgUser -d $dbName -c "\dt"
& $psql -U $pgUser -d $dbName -c "SELECT COUNT(*) AS users FROM users; SELECT COUNT(*) AS accounts FROM accounts; SELECT COUNT(*) AS transactions FROM transactions;"

Write-Host "`nPhase 0 (native PostgreSQL) complete." -ForegroundColor Green
