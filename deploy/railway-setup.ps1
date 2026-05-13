# Railway Setup Script for PneumaticWorkflow
# Usage: .\deploy\railway-setup.ps1
# Prerequisites: railway CLI installed and logged in (railway login)

param(
    [string]$ProjectName = "pneumatic-workflow",
    [string]$FrontendDomain = "",  # Will be auto-generated if empty
    [string]$BackendDomain = ""    # Will be auto-generated if empty
)

Write-Host "=== PneumaticWorkflow Railway Setup ===" -ForegroundColor Cyan

# 1. Create project
Write-Host "`n[1/7] Creating project..." -ForegroundColor Yellow
railway init --name $ProjectName

# 2. Add Postgres
Write-Host "`n[2/7] Adding Postgres..." -ForegroundColor Yellow
railway add --plugin postgresql

# 3. Add Redis
Write-Host "`n[3/7] Adding Redis..." -ForegroundColor Yellow
railway add --plugin redis

# Wait for services to initialize
Start-Sleep 10

# 4. Get connection strings from Railway
Write-Host "`n[4/7] Retrieving connection info..." -ForegroundColor Yellow
$pgHost = "postgres.railway.internal"
$pgPort = "5432"
$redisHost = "redis.railway.internal"
$redisPort = "6379"

# Note: Get actual credentials from Railway Dashboard > Postgres/Redis > Variables
# Replace these placeholder values with actual ones after first deploy
Write-Host "  >> IMPORTANT: After setup, get POSTGRES_PASSWORD and REDIS_PASSWORD" -ForegroundColor Red
Write-Host "  >> from Dashboard > Postgres/Redis > Variables tab" -ForegroundColor Red

# 5. Set Backend variables
Write-Host "`n[5/7] Setting Backend variables..." -ForegroundColor Yellow
$backendVars = @(
    # Django
    "ENVIRONMENT=Production",
    "DJANGO_SECRET_KEY=$(New-Guid)-$(New-Guid)",
    "DJANGO_SETTINGS_MODULE=src.settings",
    "DJANGO_DEBUG=no",
    "PYTHONUNBUFFERED=1",
    "LANGUAGE_CODE=en",
    "RELEASE=1.0.0",
    "ADMIN_PATH=admin",

    # Postgres (UPDATE PASSWORD after setup!)
    "POSTGRES_HOST=$pgHost",
    "POSTGRES_PORT=$pgPort",
    "POSTGRES_DB=railway",
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=CHANGE_ME",
    "POSTGRES_REPLICA_HOST=$pgHost",
    "POSTGRES_REPLICA_PORT=$pgPort",
    "POSTGRES_REPLICA_DB=railway",
    "POSTGRES_REPLICA_USER=postgres",
    "POSTGRES_REPLICA_PASSWORD=CHANGE_ME",

    # Redis (UPDATE PASSWORD after setup!)
    "CACHE_REDIS_URL=redis://:CHANGE_ME@${redisHost}:${redisPort}/0",
    "AUTH_REDIS_URL=redis://:CHANGE_ME@${redisHost}:${redisPort}/1",
    "CHANNELS_REDIS_URL=redis://:CHANGE_ME@${redisHost}:${redisPort}/2",
    "SESSION_REDIS_URL=redis://:CHANGE_ME@${redisHost}:${redisPort}/3",
    "CELERY_BROKER_URL=redis://:CHANGE_ME@${redisHost}:${redisPort}/4",

    # Features (all disabled by default)
    "BILLING=no",
    "ANALYTICS=no",
    "CAPTCHA=no",
    "EMAIL=no",
    "PUSH=no",
    "STORAGE=no",
    "AI=no",
    "GOOGLE_AUTH=no",
    "MS_AUTH=no",
    "SSO_AUTH=no",
    "SIGNUP=yes",
    "VERIFICATION_CHECK=no",
    "ENABLE_LOGGING=no",

    # CORS
    "CORS_ALLOW_CREDENTIALS=yes",
    "CORS_ORIGIN_ALLOW_ALL=yes"
)

foreach ($var in $backendVars) {
    railway variable set $var --service Backend --skip-deploys 2>$null
}
Write-Host "  Backend: $($backendVars.Count) variables set" -ForegroundColor Green

# 6. Set Frontend variables
Write-Host "`n[6/7] Setting Frontend variables..." -ForegroundColor Yellow
$frontendVars = @(
    "NODE_ENV=production",
    "SIGNUP=yes",
    "BILLING=no",
    "CAPTCHA=no",
    "GOOGLE_AUTH=no",
    "MS_AUTH=no",
    "SSO_AUTH=no"
)

foreach ($var in $frontendVars) {
    railway variable set $var --service Frontend --skip-deploys 2>$null
}
Write-Host "  Frontend: $($frontendVars.Count) variables set" -ForegroundColor Green

# 7. Generate domains and update URLs
Write-Host "`n[7/7] Generating domains..." -ForegroundColor Yellow
Write-Host "  >> Generate domains in Dashboard for Backend and Frontend" -ForegroundColor Red
Write-Host "  >> Then update these variables:" -ForegroundColor Red
Write-Host "  >> Backend: FRONTEND_URL, FORMS_URL, BACKEND_URL, ALLOWED_HOSTS, CORS_ORIGIN_WHITELIST" -ForegroundColor Red
Write-Host "  >> Frontend: BACKEND_URL, WSS_URL" -ForegroundColor Red

Write-Host "`n=== Setup Complete ===" -ForegroundColor Cyan
Write-Host @"

Next steps:
  1. Dashboard > Postgres > Variables > copy POSTGRES_PASSWORD
  2. Dashboard > Redis > Variables > copy REDIS_PASSWORD
  3. Run: railway variable set POSTGRES_PASSWORD=<actual> --service Backend
  4. Update all CHANGE_ME values with actual passwords
  5. Dashboard > Backend > Settings > Dockerfile Path = Dockerfile.railway
  6. Dashboard > Frontend > Settings > Dockerfile Path = Dockerfile.railway
  7. Generate domains for Backend and Frontend
  8. Update FRONTEND_URL, BACKEND_URL, etc with actual domains
  9. Deploy!

"@
