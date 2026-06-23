<#
.SYNOPSIS
    Ejecuta pruebas unitarias de todos los servicios y envía cobertura a SonarQube.
.DESCRIPTION
    Recorre cada microservicio del proyecto, ejecuta sus pruebas con cobertura,
    y envía los reportes a SonarQube para análisis de calidad de código.
    Por defecto corre en local (host). Con -Docker delega al contenedor test-runner via compose.
.PARAMETER Docker
    Ejecuta las pruebas dentro del contenedor test-runner (docker compose --profile test).
.PARAMETER SkipSonar
    Omite el análisis de SonarQube (solo ejecuta pruebas).
.PARAMETER SkipInfra
    Omite la verificación/inicio de infraestructura (SonarQube, DBs).
.PARAMETER SonarToken
    Token de acceso a SonarQube.
.PARAMETER SonarUrl
    URL del servidor SonarQube (local) o nombre del servicio (Docker).
.PARAMETER Service
    Ejecuta solo un servicio específico (nombre del directorio). Solo en modo local.
.PARAMETER Parallel
    Ejecuta pruebas de servicios independientes en paralelo (experimental). Solo en modo local.
.PARAMETER CoverageOnly
    Solo genera cobertura sin enviar a SonarQube.
.EXAMPLE
    ./run-tests.ps1
    Ejecuta todo: tests + SonarQube en el host.

    ./run-tests.ps1 -Docker
    Construye y ejecuta el contenedor test-runner.

    ./run-tests.ps1 -SkipSonar
    Solo ejecuta pruebas, sin SonarQube.

    ./run-tests.ps1 -Service mascotas-service
    Ejecuta solo el servicio de mascotas en local.
#>

[CmdletBinding()]
param(
    [switch]$Docker,
    [switch]$SkipSonar,
    [switch]$SkipInfra,
    [string]$SonarToken = "sqp_32876bd725f1eb79ef70224758f42a09e93a2ff4",
    [string]$SonarUrl = "http://localhost:9000",
    [string]$Service,
    [switch]$Parallel,
    [switch]$CoverageOnly
)

$RootDir = $PSScriptRoot
$InfraDir = Join-Path $RootDir "sanos-salvos-infrastructure"
$StartTime = Get-Date
$Results = @()

$Colors = @{
    Info    = "Cyan"
    Success = "Green"
    Warning = "Yellow"
    Error   = "Red"
    Step    = "Magenta"
    Banner  = "DarkCyan"
}

function Write-Banner {
    param([string]$Text)
    $line = "─" * 60
    Write-Host "`n$line" -ForegroundColor $Colors.Banner
    Write-Host "  $Text" -ForegroundColor $Colors.Banner
    Write-Host "$line`n" -ForegroundColor $Colors.Banner
}

function Write-Step {
    param([string]$Text)
    Write-Host "→ $Text" -ForegroundColor $Colors.Step
}

function Write-Result {
    param([string]$Service, [bool]$Success, [int]$DurationMs)
    $icon = if ($Success) { "✓" } else { "✗" }
    $color = if ($Success) { $Colors.Success } else { $Colors.Error }
    $duration = if ($DurationMs -ge 1000) { "{0:N2}s" -f ($DurationMs / 1000) } else { "{0}ms" -f $DurationMs }
    Write-Host "  $icon $Service — ${duration}" -ForegroundColor $color
}

$serviceDefs = @(
    @{
        Name     = "sanos-gateway"
        Dir      = "sanos-gateway"
        Type     = "maven"
    }
    @{
        Name     = "coincidencias-service"
        Dir      = "coincidencias-service"
        Type     = "maven"
    }
    @{
        Name     = "notification-service"
        Dir      = "notification-service"
        Type     = "maven"
    }
    @{
        Name     = "message-service"
        Dir      = "message-service"
        Type     = "maven"
    }
    @{
        Name     = "mascotas-service"
        Dir      = "mascotas-service"
        Type     = "dotnet"
    }
    @{
        Name     = "user-service"
        Dir      = "user-service"
        Type     = "cmake"
    }
    @{
        Name     = "sanos-salvos-front"
        Dir      = "sanos-salvos-front"
        Type     = "npm"
    }
)

if ($Service) {
    $matched = $serviceDefs | Where-Object { $_.Name -eq $Service -or $_.Dir -eq $Service }
    if (-not $matched) {
        Write-Host "Servicio '$Service' no encontrado." -ForegroundColor $Colors.Error
        Write-Host "Servicios disponibles:" -ForegroundColor $Colors.Info
        $serviceDefs | ForEach-Object { Write-Host "  - $($_.Name)" }
        exit 1
    }
    $serviceDefs = $matched
}

function Test-Prerequisites {
    Write-Banner "VERIFICANDO PRERREQUISITOS"
    $missing = @()

    $javaVer = (& java -version 2>&1) -join "`n"
    if ($javaVer -match '"(\d+)') {
        $jVer = [int]$Matches[1]
        if ($jVer -ge 21) {
            Write-Host "  ✓ Java $jVer encontrado" -ForegroundColor $Colors.Success
        } else {
            Write-Host "  ⚠ Java $jVer encontrado (se requiere >= 21)" -ForegroundColor $Colors.Warning
            $missing += "Java 21+"
        }
    } else {
        Write-Host "  ✗ Java no encontrado" -ForegroundColor $Colors.Error
        $missing += "Java 21+"
    }

    $dotnetVer = & dotnet --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $dotnetVer) {
        Write-Host "  ✓ .NET SDK $dotnetVer encontrado" -ForegroundColor $Colors.Success
    } else {
        Write-Host "  ✗ .NET SDK no encontrado" -ForegroundColor $Colors.Error
        $missing += ".NET SDK 10.0"
    }

    $nodeVer = & node --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $nodeVer) {
        Write-Host "  ✓ Node.js $nodeVer encontrado" -ForegroundColor $Colors.Success
    } else {
        Write-Host "  ✗ Node.js no encontrado" -ForegroundColor $Colors.Error
        $missing += "Node.js 20+"
    }

    $cmakeVer = & cmake --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $cmakeVer -match 'cmake (\S+)') {
        Write-Host "  ✓ CMake $($Matches[1]) encontrado" -ForegroundColor $Colors.Success
    } else {
        Write-Host "  ✗ CMake no encontrado" -ForegroundColor $Colors.Error
        $missing += "CMake 3.5+"
    }

    $dockerVer = & docker --version 2>&1
    if ($LASTEXITCODE -eq 0 -and $dockerVer) {
        Write-Host "  ✓ Docker encontrado" -ForegroundColor $Colors.Success
    } else {
        Write-Host "  ⚠ Docker no encontrado (infraestructura manual)" -ForegroundColor $Colors.Warning
    }

    if (-not $SkipSonar) {
        $scannerVer = & sonar-scanner --version 2>&1
        if ($LASTEXITCODE -eq 0 -and $scannerVer) {
            Write-Host "  ✓ SonarScanner CLI encontrado" -ForegroundColor $Colors.Success
        } else {
            Write-Host "  ⚠ SonarScanner CLI no encontrado (solo servicios Maven enviarán a SonarQube)" -ForegroundColor $Colors.Warning
        }
    }

    if ($missing.Count -gt 0) {
        Write-Host "`nFaltan herramientas:" -ForegroundColor $Colors.Warning
        $missing | ForEach-Object { Write-Host "  - $_" }
        $choice = Read-Host "`n¿Continuar de todas formas? (s/N)"
        if ($choice -notin @("s", "S", "si", "SI")) {
            exit 1
        }
    }
}

function Start-SonarQube {
    if ($SkipInfra -or $CoverageOnly) { return }

    Write-Banner "INFRAESTRUCTURA — SonarQube"
    $sonarRunning = $false

    $containers = & docker ps --filter "name=sonarqube" --format "{{.Names}}" 2>&1
    if ($containers -match "sonarqube") {
        $sonarRunning = $true
        Write-Host "  ✓ SonarQube ya está corriendo" -ForegroundColor $Colors.Success
        return
    }

    Write-Step "Iniciando SonarQube + PostgreSQL..."
    Push-Location $InfraDir
    try {
        & docker compose up -d sonarqube-db sonarqube 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ✗ Error al iniciar SonarQube" -ForegroundColor $Colors.Error
            return
        }
        Write-Host "  ✓ Contenedores iniciados, esperando que SonarQube esté listo..." -ForegroundColor $Colors.Success

        $maxRetries = 30
        for ($i = 0; $i -lt $maxRetries; $i++) {
            Start-Sleep -Seconds 5
            try {
                $response = Invoke-WebRequest -Uri "$SonarUrl/api/system/status" -TimeoutSec 5 -UseBasicParsing
                $status = ($response.Content | ConvertFrom-Json).status
                if ($status -eq "UP") {
                    Write-Host "  ✓ SonarQube está UP ($((Get-Date -Format 'HH:mm:ss')))" -ForegroundColor $Colors.Success
                    return
                }
            } catch {
                Write-Host "  . esperando $((($i+1)*5))s..." -ForegroundColor $Colors.Info
            }
        }
        Write-Host "  ⚠ SonarQube no respondió después de $($maxRetries*5)s" -ForegroundColor $Colors.Warning
        Write-Host "    Ver con: docker compose logs sonarqube" -ForegroundColor $Colors.Info
    } finally {
        Pop-Location
    }
}

function Invoke-Tests {
    param($Def)
    $svcDir = Join-Path $RootDir $Def.Dir

    if (-not (Test-Path $svcDir)) {
        return $false
    }

    Push-Location $svcDir
    try {
        switch ($Def.Type) {
            "maven" {
                Write-Step "mvnw.cmd clean test..."
                & ".\mvnw.cmd" clean test
                return $LASTEXITCODE -eq 0
            }
            "dotnet" {
                Write-Step "dotnet test con coverlet..."
                & dotnet test tests/mascotas-service.tests.csproj --collect "XPlat Code Coverage" --settings codecover.runsettings
                return $LASTEXITCODE -eq 0
            }
            "cmake" {
                Write-Step "cmake -B build -DENABLE_COVERAGE=ON..."
                & cmake -B build -DENABLE_COVERAGE=ON
                if ($LASTEXITCODE -ne 0) { return $false }

                Write-Step "cmake --build build..."
                & cmake --build build -j 4
                if ($LASTEXITCODE -ne 0) { return $false }

                Write-Step "./build/user-service-tests..."
                $testExe = Join-Path (Get-Location) "build" "user-service-tests"
                if (-not (Test-Path $testExe)) {
                    Write-Host "  ✗ build/user-service-tests no encontrado" -ForegroundColor $Colors.Error
                    return $false
                }
                & $testExe
                $testsOk = $LASTEXITCODE -eq 0

                Write-Step "gcovr → build/coverage.xml..."
                & gcovr -r (Get-Location) --exclude "external/.*" --exclude "test/.*" --exclude "main.cc" --exclude ".*\.h" --cobertura -o build/coverage.xml
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "  ✓ coverage.xml generado" -ForegroundColor $Colors.Success
                }

                return $testsOk
            }
            "npm" {
                Write-Step "npm run test:coverage..."
                & npm run test:coverage
                return $LASTEXITCODE -eq 0
            }
        }
    } finally {
        Pop-Location
    }
}

function Invoke-SonarAnalysis {
    param($Def)
    if ($CoverageOnly) { return $true }

    $svcDir = Join-Path $RootDir $Def.Dir
    Push-Location $svcDir
    try {
        switch ($Def.Type) {
            "maven" {
                Write-Step "mvnw.cmd sonar:sonar..."
                & ".\mvnw.cmd" sonar:sonar "-Dsonar.projectKey=$($Def.Name)" "-Dsonar.host.url=$SonarUrl" "-Dsonar.login=$SonarToken" "-Dsonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml"
                return $LASTEXITCODE -eq 0
            }
            default {
                $propsPath = Join-Path $svcDir "sonar-project.properties"
                if (-not (Test-Path $propsPath)) {
                    Write-Host "  ⚠ saltando (falta sonar-project.properties)" -ForegroundColor $Colors.Warning
                    return $false
                }
                Write-Step "sonar-scanner..."
                & sonar-scanner "-Dsonar.host.url=$SonarUrl" "-Dsonar.login=$SonarToken"
                return $LASTEXITCODE -eq 0
            }
        }
    } finally {
        Pop-Location
    }
}

function Invoke-DockerTestRunner {
    Write-Banner "MODO DOCKER — test-runner"

    $infraDir = Join-Path $PSScriptRoot "sanos-salvos-infrastructure"
    if (-not (Test-Path $infraDir)) {
        Write-Host "  ✗ No se encontró $infraDir" -ForegroundColor $Colors.Error
        exit 1
    }

    Push-Location $infraDir
    try {
        Write-Step "Construyendo imagen test-runner..."
        & docker compose --profile test build test-runner
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ✗ Error al construir la imagen" -ForegroundColor $Colors.Error
            exit 1
        }

        Write-Step "Ejecutando test-runner (logs en tiempo real)..."
        & docker compose --profile test up test-runner --abort-on-container-exit
        $exitCode = $LASTEXITCODE

        Write-Step "Limpiando contenedor..."
        & docker compose --profile test rm -f test-runner 2>&1 | Out-Null

        if ($exitCode -eq 0) {
            Write-Host "`n  ✓ test-runner completado exitosamente" -ForegroundColor $Colors.Success
        } else {
            Write-Host "`n  ⚠ test-runner finalizó con código $exitCode" -ForegroundColor $Colors.Warning
        }
    } finally {
        Pop-Location
    }
}

function Main {
    if ($Docker) {
        Invoke-DockerTestRunner
        return
    }

    Write-Banner "SANOS Y SALVOS — Suite de Pruebas"
    Write-Host "  Inicio: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Colors.Info
    Write-Host "  Servicios a ejecutar: $($serviceDefs.Count)" -ForegroundColor $Colors.Info
    if (-not $SkipSonar) { Write-Host "  SonarQube: $SonarUrl" -ForegroundColor $Colors.Info }
    Write-Host ""

    Test-Prerequisites

    if (-not $CoverageOnly) {
        Start-SonarQube
    }

    Write-Banner "EJECUTANDO PRUEBAS"
    $runResults = @()

    foreach ($def in $serviceDefs) {
        Write-Host ""
        Write-Host "════════════════════════════════════════════════" -ForegroundColor $Colors.Banner
        Write-Host "  [$($def.Type.ToUpper())] $($def.Name)" -ForegroundColor $Colors.Banner
        Write-Host "════════════════════════════════════════════════" -ForegroundColor $Colors.Banner

        $svcStart = Get-Date
        $testsOk = Invoke-Tests $def
        $duration = [math]::Round(((Get-Date) - $svcStart).TotalMilliseconds)

        $runResults += @{ Service = $def.Name; TestsPass = $testsOk; DurationMs = $duration }
        Write-Result -Service $def.Name -Success $testsOk -DurationMs $duration

        if ($testsOk -and -not $SkipSonar) {
            Invoke-SonarAnalysis $def | Out-Null
        } elseif (-not $testsOk) {
            Write-Host "  – SonarQube omitido (tests fallaron)" -ForegroundColor $Colors.Warning
        }
    }

    Write-Banner "RESUMEN"
    $total = $runResults.Count
    $passed = ($runResults | Where-Object { $_.TestsPass }).Count
    $failed = $total - $passed
    $totalDuration = [math]::Round(((Get-Date) - $StartTime).TotalSeconds)

    foreach ($r in $runResults) {
        Write-Result -Service $r.Service -Success $r.TestsPass -DurationMs $r.DurationMs
    }

    Write-Host ""
    if ($failed -eq 0) {
        Write-Host "  ✓ $passed de $total servicios OK" -ForegroundColor $Colors.Success
    } else {
        Write-Host "  ⚠ $passed de $total OK — $failed fallaron" -ForegroundColor $Colors.Warning
    }
    Write-Host "  Tiempo total: ${totalDuration}s" -ForegroundColor $Colors.Info
    if (-not $SkipSonar -and -not $CoverageOnly) {
        Write-Host "  SonarQube: $SonarUrl" -ForegroundColor $Colors.Info
    }
    Write-Host "  Fin: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor $Colors.Info
    Write-Banner "HECHO"
}

Main
