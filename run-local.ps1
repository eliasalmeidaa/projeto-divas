# ============================================================
# run-local.ps1 — Sobe o Projeto Divas com credenciais reais
# Preencha .env.local antes de rodar
# ============================================================

$root = Split-Path -Parent $MyInvocation.MyCommand.Definition
$backend = Join-Path $root "projeto-divas-backend"
$envFile = Join-Path $root ".env.local"

# Carrega .env.local
if (-not (Test-Path $envFile)) {
    Write-Host "[ERRO] Arquivo .env.local nao encontrado. Crie-o com as credenciais." -ForegroundColor Red
    exit 1
}

$env_vars = @{}
Get-Content $envFile | Where-Object { $_ -notmatch "^\s*#" -and $_ -match "=" } | ForEach-Object {
    $parts = $_ -split "=", 2
    $env_vars[$parts[0].Trim()] = $parts[1].Trim()
}

# Valida preenchimento
$placeholder = $env_vars.Values | Where-Object { $_ -match "^seu_|^SEU_|^uma_chave" }
if ($placeholder) {
    Write-Host "[ERRO] .env.local ainda tem valores de exemplo. Preencha com as credenciais reais." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "=== PROJETO DIVAS ===" -ForegroundColor Cyan
Write-Host "[1/2] Subindo backend na porta 8080..." -ForegroundColor Yellow

# Monta o comando com as variáveis de ambiente
$envArgs = ($env_vars.GetEnumerator() | ForEach-Object { "`$env:$($_.Key)='$($_.Value)'" }) -join "; "
$backendCmd = "$envArgs; cd '$backend'; .\mvnw.cmd spring-boot:run"

Start-Process powershell -ArgumentList "-NoExit", "-Command", $backendCmd -WindowStyle Normal

Write-Host "   Aguarde ~30s para o backend inicializar..." -ForegroundColor Gray
Start-Sleep -Seconds 30

Write-Host "[2/2] Subindo frontend na porta 5500..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root'; npx --yes http-server -p 5500 -c-1 ." -WindowStyle Normal

Start-Sleep -Seconds 4
Start-Process "http://localhost:5500"

Write-Host ""
Write-Host "Pronto!" -ForegroundColor Green
Write-Host "  Frontend : http://localhost:5500" -ForegroundColor White
Write-Host "  Backend  : http://localhost:8080" -ForegroundColor White
Write-Host ""
