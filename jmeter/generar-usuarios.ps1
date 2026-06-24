param(
    [int]$Count = 100,
    [string]$Output = (Join-Path $PSScriptRoot "usuarios.csv"),
    [string]$GatewayUrl = "http://localhost:8080"
)

$ErrorActionPreference = "Stop"
function Log($m) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $m" }

function Get-Json($url, $method, $body, $token) {
    $headers = @{ "Accept" = "application/json" }
    if ($token) { $headers["Authorization"] = "Bearer $token" }
    try {
        $params = @{ Uri = $url; Method = $method; Headers = $headers }
        if ($body) { $params["Body"] = $body; $params["ContentType"] = "application/json" }
        return Invoke-RestMethod @params
    } catch { return $null }
}

# --- Login para obtener token ---
$token = $null
Log "Obteniendo token de auth desde $GatewayUrl/auth/login ..."
$login = Get-Json "$GatewayUrl/auth/login" POST (@{ username = "test"; password = "test" } | ConvertTo-Json)
if ($login -and $login.accessToken) {
    $token = $login.accessToken
    Log "OK token obtenido"
} else {
    Log "[WARN] No se pudo autenticar. Ubicaciones usaran defaults."
}

# --- Obtener ubicaciones reales desde la API ---
Log "Obteniendo ubicaciones desde $GatewayUrl/api/mascotas/v1/Ubicacion/comunas ..."
$ubicaciones = Get-Json "$GatewayUrl/api/mascotas/v1/Ubicacion/comunas" GET $null $token
if ($ubicaciones -and $ubicaciones.Count -gt 0) {
    Log "OK $($ubicaciones.Count) grupos de ubicacion cargados"
} else {
    Log "[WARN] No se pudieron obtener ubicaciones. Usando defaults."
    $ubicaciones = @(
        @{ region = "Metropolitana"; ciudad = "Santiago";   comunas = @("Providencia", "Las Condes", "Nunoa", "Vitacura", "Maipu") }
        @{ region = "Valparaiso";    ciudad = "Valparaiso";  comunas = @("Vina del Mar", "Valparaiso", "Quilpue") }
        @{ region = "Biobio";        ciudad = "Concepcion";  comunas = @("Concepcion", "Talcahuano", "Chiguayante") }
    )
}

# --- Enums fijos (no hay endpoints para estos) ---
$animalTypes = @("Perro", "Gato")
$razaTypes   = @("Bonito", "Feo")
$colors      = @("Negro", "Cafe", "Blanco", "Gris", "Dorado")
$petNames    = @("Luna", "Toby", "Pelusa", "Max", "Mia", "Rocky", "Coco", "Nala", "Simba", "Canela",
                 "Bruno", "Kiara", "Chloe", "Thor", "Lola", "Zeus", "Molly", "Odin", "Ruby", "Leo")

# --- Generar CSV ---
$headers = "username,password,email,mascotaNombre,mascotaTipo,mascotaRaza,mascotaColor,region,ciudad,comuna"
$lines = @()

for ($i = 1; $i -le $Count; $i++) {
    $uname = "load_$([Guid]::NewGuid().ToString('N').Substring(0,8))"
    $pass = "test$i"
    $email = "load_$([Guid]::NewGuid().ToString('N').Substring(0,6))@test.cl"

    $grupo = $ubicaciones | Get-Random
    $comuna = $grupo.comunas | Get-Random

    $lines += @(
        $uname,
        $pass,
        $email,
        ($petNames | Get-Random),
        ($animalTypes | Get-Random),
        ($razaTypes | Get-Random),
        ($colors | Get-Random),
        $grupo.region,
        $grupo.ciudad,
        $comuna
    ) -join ','
}

$headerLine = $headers -join ','
$content = @($headerLine) + $lines
Set-Content -Path $Output -Value ($content -join "`r`n") -Encoding UTF8
Log "Generados $Count usuarios en $Output"
