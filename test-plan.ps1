param(
    [switch]$SkipUnitTests,
    [switch]$SkipIntegrationTests,
    [switch]$SkipCoverage
)

$ErrorActionPreference = "Continue"
$root = Split-Path -Parent $PSScriptRoot
$infra = Join-Path $root "sanos-salvos-infrastructure"
$reportDir = Join-Path $infra "jmeter\report"
$resultsDir = Join-Path $infra "test-results"
$timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null

$results = @()

function Write-Step($msg) {
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "  $msg" -ForegroundColor White
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Result($name, $ok, $detail) {
    $icon = if ($ok) { "[PASS]" } else { "[FAIL]" }
    $color = if ($ok) { "Green" } else { "Red" }
    Write-Host "${icon} ${name}  ${detail}" -ForegroundColor $color
    $global:results += [PSCustomObject]@{
        Name = $name
        Status = if ($ok) { "PASS" } else { "FAIL" }
        Detail = $detail
    }
}

function Run-Test($name, [ScriptBlock]$scriptBlock) {
    Write-Step $name
    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $ok = $false
    $detail = ""
    try {
        & $scriptBlock
        $ok = ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null)
        $sw.Stop()
        $secs = $sw.Elapsed.TotalSeconds.ToString("F1")
        if ($ok) {
            $detail = "${secs}s"
        } else {
            $detail = "Exit code $LASTEXITCODE | ${secs}s"
        }
    } catch {
        $sw.Stop()
        $secs = $sw.Elapsed.TotalSeconds.ToString("F1")
        $detail = "$($_.Exception.Message) | ${secs}s"
        $ok = $false
    }
    Write-Result $name $ok $detail
}

# =====================
# PHASE 0: PREREQUISITES
# =====================
Write-Step "FASE 0: Verificando herramientas"

$toolsOk = $true
$required = @(
    @{Name="dotnet"; Cmd="dotnet --version"}
    @{Name="node"; Cmd="node --version"}
    @{Name="npm"; Cmd="npm --version"}
    @{Name="java"; Cmd="java -version 2>&1 | Select-String 'version'"}
    @{Name="mvn"; Cmd="mvn --version 2>&1 | Select-String 'Apache Maven'"}
    @{Name="cmake"; Cmd="cmake --version"}
    @{Name="g++"; Cmd="g++ --version"}
    @{Name="docker"; Cmd="docker --version"}
)
foreach ($t in $required) {
    try {
        $v = Invoke-Expression $t.Cmd 2>&1 | Select-Object -First 1
        Write-Result $t.Name $true "$v"
    } catch {
        Write-Result $t.Name $false "NOT FOUND"
        $toolsOk = $false
    }
}

if (-not $toolsOk) {
    Write-Host "`n[FATAL] Faltan herramientas. Abortando." -ForegroundColor Red
    exit 1
}

# =====================
# PHASE 1: UNIT TESTS
# =====================
if (-not $SkipUnitTests) {
    Write-Step "FASE 1: Tests Unitarios"
    
    # 1a. mascotas-service (.NET / xUnit)
    Run-Test "mascotas-service (dotnet test)" {
        Push-Location (Join-Path $root "mascotas-service")
        dotnet test tests/mascotas-service.tests.csproj --collect "XPlat Code Coverage" --settings codecover.runsettings --results-directory "$resultsDir/mascotas-coverage" 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "dotnet test failed" }
        Pop-Location
    }

    # 1b. sanos-gateway (Java / Maven)
    Run-Test "sanos-gateway (mvn test)" {
        Push-Location (Join-Path $root "sanos-gateway")
        .\mvnw.cmd clean test -q 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "mvn test failed" }
        Pop-Location
    }

    # 1c. coincidencias-service (Java / Maven)
    Run-Test "coincidencias-service (mvn test)" {
        Push-Location (Join-Path $root "coincidencias-service")
        .\mvnw.cmd clean test -q 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "mvn test failed" }
        Pop-Location
    }

    # 1d. notification-service (Java / Maven)
    Run-Test "notification-service (mvn test)" {
        Push-Location (Join-Path $root "notification-service")
        .\mvnw.cmd clean test -q 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "mvn test failed" }
        Pop-Location
    }

    # 1e. message-service (Java / Quarkus / Maven)
    Run-Test "message-service (mvn test)" {
        Push-Location (Join-Path $root "message-service")
        .\mvnw.cmd clean test -q 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "mvn test failed" }
        Pop-Location
    }

    # 1f. frontend (React / Vitest)
    Run-Test "sanos-salvos-front (npm test)" {
        Push-Location (Join-Path $root "sanos-salvos-front")
        npm run test:coverage 2>&1 | Out-Host
        if ($LASTEXITCODE -ne 0) { throw "npm test failed" }
        Pop-Location
    }

    # 1g. user-service (C++ / Doctest) — via Docker
    Run-Test "user-service (docker build + tests)" {
        Push-Location $infra
        docker compose build --build-arg RUN_TESTS=true --build-arg GENERATE_COVERAGE=true user-service 2>&1 | Out-Host
        docker compose run --rm user-service 2>&1 | Out-Host
        Pop-Location
    }
}
else {
    Write-Host "  Saltando tests unitarios (--SkipUnitTests)" -ForegroundColor Yellow
}

# =====================
# PHASE 2: INTEGRATION TESTS
# =====================
if (-not $SkipIntegrationTests) {
    Write-Step "FASE 2: Tests de Integracion"

    # 2a. Start full stack
    Write-Step "2a. Iniciando stack completo"
    Push-Location $infra
    docker compose up -d 2>&1 | Out-Host
    Pop-Location

    # 2b. Wait for services to be healthy
    Write-Step "2b. Esperando servicios..."
    $maxWait = 120
    $waited = 0
    $healthy = $false
    while ($waited -lt $maxWait) {
        try {
            $resp = curl.exe -s -o /dev/null -w "%{http_code}" http://localhost:8080/auth/login -X POST -H "Content-Type: application/json" -d '{"username":"test","password":"test"}'
            if ($resp -eq "200") {
                Write-Host "  Gateway healthy despues de ${waited}s" -ForegroundColor Green
                $healthy = $true
                break
            }
        } catch {}
        Start-Sleep -Seconds 2
        $waited += 2
        Write-Host "  Esperando gateway... ${waited}s" -NoNewline
    }
    
    if (-not $healthy) {
        Write-Host "  Gateway no respondio luego de ${maxWait}s" -ForegroundColor Red
    }

    # 2c. Run JMeter integration test
    Write-Step "2c. JMeter - Test de carga (100 usuarios)"
    if ($healthy) {
        Push-Location $infra
        Run-Test "JMeter integration test" {
            # Register test user if not exists
            curl.exe -s -X POST http://localhost:8080/api/users/auth/register -H "Content-Type: application/json" -d '{"username":"test","email":"test@test.cl","password":"test","firstName":"Test","lastName":"User"}' 2>&1 | Out-Null
            
            # Clean old JMeter results
            Remove-Item -LiteralPath "$infra/jmeter/results.jtl" -ErrorAction SilentlyContinue
            Remove-Item -LiteralPath "$infra/jmeter/report" -Recurse -ErrorAction SilentlyContinue
            
            # Run JMeter
            docker compose run --rm --entrypoint jmeter jmeter -n -t /tests/sanos-plan.jmx -l /tests/results.jtl -e -o /tests/report/ -j /tests/jmeter.log 2>&1 | Out-Host
            if ($LASTEXITCODE -ne 0) { throw "JMeter test failed" }
        }
        Pop-Location
    } else {
        Write-Result "JMeter integration test" $false "Gateway no disponible"
    }

    # 2d. Stop stack
    Write-Step "2d. Deteniendo stack"
    Push-Location $infra
    docker compose down 2>&1 | Out-Host
    Pop-Location
}
else {
    Write-Host "  Saltando tests de integracion (--SkipIntegrationTests)" -ForegroundColor Yellow
}

# =====================
# PHASE 3: SUMMARY
# =====================
Write-Step "FASE 3: Resumen de Resultados"

Write-Host ""
Write-Host "Resultados:" -ForegroundColor Cyan
Write-Host ("-" * 60)

$passed = 0
$failed = 0
foreach ($r in $results) {
    $icon = if ($r.Status -eq "PASS") { "[PASS]" } else { "[FAIL]" }
    $color = if ($r.Status -eq "PASS") { "Green" } else { "Red" }
    Write-Host "  ${icon} $($r.Name)" -ForegroundColor $color
    Write-Host "       $($r.Detail)"
    if ($r.Status -eq "PASS") { $passed++ } else { $failed++ }
}

Write-Host ("-" * 60)
$total = $passed + $failed
Write-Host "  Total: $total | Pasados: $passed | Fallados: $failed" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
Write-Host "  Reportes: $resultsDir" -ForegroundColor Gray

if ($failed -gt 0) {
    exit 1
}
