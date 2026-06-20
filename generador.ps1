param(
    [string]$GatewayUrl = "http://localhost:8080",
    [string]$ImagesDir = (Join-Path $PSScriptRoot "seed-images")
)

$ErrorActionPreference = "Stop"

# helpers

function Log($msg) { Write-Host "[$([DateTime]::Now.ToString('HH:mm:ss'))] $msg" }

function JsonReq($method, $url, $body, $token) {
    $headers = @{ "Content-Type" = "application/json" }
    if ($token) { $headers["Authorization"] = "Bearer $token" }
    try {
        return Invoke-RestMethod -Uri $url -Method $method -Body ($body | ConvertTo-Json -Depth 5) -Headers $headers
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) { return $null }
        Log "[WARN] $($_.Exception.Message)"
        return $null
    }
}

function Get-RandomImage() {
    if (-not (Test-Path $ImagesDir)) { return $null }
    $imgs = @(Get-ChildItem -LiteralPath $ImagesDir -Include @("*.jpg","*.jpeg","*.png","*.webp","*.gif") -File)
    if ($imgs.Count -eq 0) { return $null }
    return $imgs | Get-Random
}

function Send-MultiPart($url, $fields, $token, $fileFields) {
    Add-Type -AssemblyName System.Net.Http
    $client = New-Object System.Net.Http.HttpClient
    $content = New-Object System.Net.Http.MultipartFormDataContent

    foreach ($kv in $fields.GetEnumerator()) {
        $sc = New-Object System.Net.Http.StringContent ($kv.Value)
        $content.Add($sc, $kv.Key)
    }

    if ($fileFields) {
        foreach ($ff in $fileFields) {
            $path = $ff.Path
            if (-not (Test-Path $path)) { continue }
            $name = $ff.Name
            $fileName = [System.IO.Path]::GetFileName($path)
            $fileBytes = [System.IO.File]::ReadAllBytes($path)
            $fc = New-Object System.Net.Http.ByteArrayContent (,$fileBytes)
            $fc.Headers.ContentDisposition = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"
            $fc.Headers.ContentDisposition.Name = "`"$name`""
            $fc.Headers.ContentDisposition.FileName = "`"$fileName`""
            $content.Add($fc, $name, $fileName)
        }
    }

    $client.DefaultRequestHeaders.Remove("Authorization")
    if ($token) { $client.DefaultRequestHeaders.Add("Authorization", "Bearer $token") }

    try {
        $resp = $client.PostAsync($url, $content).GetAwaiter().GetResult()
        $body = $resp.Content.ReadAsStringAsync().GetAwaiter().GetResult()
        if ($resp.IsSuccessStatusCode) {
            return $body | ConvertFrom-Json
        } else {
            Log "[WARN] HTTP $($resp.StatusCode) para $url"
            return $null
        }
    } catch {
        Log "[WARN] $($_.Exception.Message)"
        return $null
    } finally {
        $client.Dispose()
        $content.Dispose()
    }
}

# users

$Users = @(
    @{ username = "maria"; password = "test123"; email = "maria@test.cl"; firstName = "Maria"; lastName = "Gonzalez" }
    @{ username = "pedro"; password = "test123"; email = "pedro@test.cl"; firstName = "Pedro"; lastName = "Lopez" }
    @{ username = "ana";   password = "test123"; email = "ana@test.cl";   firstName = "Ana";   lastName = "Martinez" }
    @{ username = "carlos"; password = "test123"; email = "carlos@test.cl"; firstName = "Carlos"; lastName = "Rojas" }
    @{ username = "valeria"; password = "test123"; email = "valeria@test.cl"; firstName = "Valeria"; lastName = "Munoz" }
)

$TokenCache = @{}
$UserIdCache = @{}

Log "--- Registrando / verificando usuarios ---"
foreach ($u in $Users) {
    $login = JsonReq POST "$GatewayUrl/auth/login" @{ username = $u.username; password = $u.password }
    if ($login -and $login.accessToken) {
        Log "  OK $($u.username) -- login exitoso"
        $TokenCache[$u.username] = $login.accessToken
        if ($login.user -and $login.user.id) { $UserIdCache[$u.username] = $login.user.id }
        continue
    }
    $reg = JsonReq POST "$GatewayUrl/api/users/auth/register" $u
    if ($reg) {
        Log "  OK $($u.username) -- registrado"
    }
    $login2 = JsonReq POST "$GatewayUrl/auth/login" @{ username = $u.username; password = $u.password }
    if ($login2 -and $login2.accessToken) {
        Log "  OK $($u.username) -- login post-registro"
        $TokenCache[$u.username] = $login2.accessToken
        if ($login2.user -and $login2.user.id) { $UserIdCache[$u.username] = $login2.user.id }
    } else {
        Log "  [SKIP] $($u.username) -- no se pudo autenticar"
    }
}

if ($TokenCache.Count -eq 0) { Log "No hay usuarios. Abortando."; exit 1 }
$AllUsers = $TokenCache.Keys | Where-Object { $_ }

# fotos de perfil

Log "`n--- Subiendo fotos de perfil ---"
foreach ($uname in $AllUsers) {
    $token = $TokenCache[$uname]
    $img = Get-RandomImage
    if (-not $img) {
        Log "  [SKIP] $uname -- no hay imagenes disponibles"
        continue
    }
    $fields = @{}
    $fileFields = @(@{ Name = "file"; Path = $img.FullName })
    $resp = Send-MultiPart "$GatewayUrl/api/users/v1/users/foto" $fields $token $fileFields
    if ($resp -and $resp.profilePictureUrl) {
        Log "  OK $uname -> foto de perfil subida ($($resp.profilePictureUrl))"
    } else {
        Log "  [WARN] $uname -> fallo al subir foto de perfil"
    }
}

# mascotas

$Animals = @("Perro", "Gato")
$Colors  = @("Negro", "Cafe", "Blanco", "Gris", "Dorado")
$Breeds  = @("Bonito", "Feo")
$MascotaNames = @("Luna", "Toby", "Pelusa", "Max", "Mia", "Rocky", "Coco", "Nala", "Simba", "Canela")

$MascotaIds = @{}

Log "`n--- Creando mascotas ---"
foreach ($uname in $AllUsers) {
    $token = $TokenCache[$uname]
    $count = Get-Random -Min 2 -Max 4
    $used = @{}
    $MascotaIds[$uname] = @()
    for ($i = 0; $i -lt $count; $i++) {
        $name = $MascotaNames | Where-Object { -not $used.ContainsKey($_) } | Get-Random
        if (-not $name) {
            $name = "Mascota$(Get-Random -Max 999)"
        }
        $used[$name] = $true
        $fields = [ordered]@{
            Nombre     = $name
            NumeroChip = if ((Get-Random -Max 2) -eq 0) { "" } else { "CHIP$([Guid]::NewGuid().ToString('N').Substring(0,8).ToUpper())" }
            TipoAnimal = $Animals | Get-Random
            TipoRaza   = $Breeds | Get-Random
            Color      = $Colors | Get-Random
        }
        $img = Get-RandomImage
        $fileFields = if ($img) { @(@{ Name = "Imagen"; Path = $img.FullName }) } else { $null }
        $resp = Send-MultiPart "$GatewayUrl/api/mascotas/v1/Mascota" $fields $token $fileFields
        if ($resp -and $resp.id) {
            $MascotaIds[$uname] += $resp.id
            $imgInfo = if ($img) { " + img" } else { "" }
            Log "  OK $uname -> mascota '$name' (id $($resp.id)$imgInfo)"
        } else {
            Log "  [ERR] $uname -> mascota '$name' fallo"
        }
    }
}

# reportes perdida

$Ciudades = @("Santiago", "Valparaiso", "Concepcion", "Vina del Mar", "La Serena")
$Comunas  = @("Providencia", "Las Condes", "Nunoa", "Vitacura", "Maipu")

Log "`n--- Creando reportes de perdida ---"
foreach ($uname in $AllUsers) {
    $token = $TokenCache[$uname]
    $ids = $MascotaIds[$uname]
    if ($ids.Count -eq 0) { continue }
    $count = [Math]::Min((Get-Random -Min 1 -Max 3), $ids.Count)
    for ($i = 0; $i -lt $count; $i++) {
        $mid = $ids | Get-Random
        $fields = [ordered]@{
            MascotaId   = "$mid"
            Descripcion = "Se perdio en la tarde, responde al nombre. Cualquier info contactar."
            Ciudad      = $Ciudades | Get-Random
            Comuna      = $Comunas | Get-Random
        }
        $img = Get-RandomImage
        $fileFields = if ($img) { @(@{ Name = "Imagenes"; Path = $img.FullName }) } else { $null }
        $resp = Send-MultiPart "$GatewayUrl/api/mascotas/v1/Reporte/perdida" $fields $token $fileFields
        if ($resp -and $resp.id) {
            Log "  OK $uname -> perdida mascota $mid (reporte $($resp.id))"
        } else {
            Log "  [ERR] $uname -> perdida fallo"
        }
    }
}

# reportes avistamiento

Log "`n--- Creando reportes de avistamiento ---"
foreach ($uname in $AllUsers) {
    $token = $TokenCache[$uname]
    $count = Get-Random -Min 1 -Max 3
    for ($i = 0; $i -lt $count; $i++) {
        $obsName = $MascotaNames | Get-Random
        $fields = [ordered]@{
            "MascotaObservada.Nombre"     = $obsName
            "MascotaObservada.NumeroChip" = if ((Get-Random -Max 2) -eq 0) { "" } else { "CHIP$([Guid]::NewGuid().ToString('N').Substring(0,8).ToUpper())" }
            "MascotaObservada.TipoAnimal" = $Animals | Get-Random
            "MascotaObservada.TipoRaza"   = $Breeds | Get-Random
            "MascotaObservada.Color"      = $Colors | Get-Random
            Descripcion                   = "Vi un $($obsName) que parece perdido cerca de la plaza."
            Ciudad                        = $Ciudades | Get-Random
            Comuna                        = $Comunas | Get-Random
        }
        $img = Get-RandomImage
        $fileFields = if ($img) { @(@{ Name = "Imagenes"; Path = $img.FullName }) } else { $null }
        $resp = Send-MultiPart "$GatewayUrl/api/mascotas/v1/Reporte/avistamiento" $fields $token $fileFields
        if ($resp -and $resp.id) {
            Log "  OK $uname -> avistamiento '$obsName' (reporte $($resp.id))"
        } else {
            Log "  [ERR] $uname -> avistamiento fallo"
        }
    }
}

# mensajes

Log "`n--- Enviando mensajes entre usuarios ---"
$Pairs = @()
for ($i = 0; $i -lt $AllUsers.Count; $i++) {
    for ($j = $i + 1; $j -lt $AllUsers.Count; $j++) {
        $Pairs += @{ from = $AllUsers[$i]; to = $AllUsers[$j] }
    }
}
$Pairs = $Pairs | Sort-Object { Get-Random }

$SampleMessages = @(
    "Hola! Vi tu reporte, creo que tengo informacion.",
    "Gracias por contactarme. Has visto a mi mascota?",
    "Si, vi un perro con esas caracteristicas en el parque.",
    "Podemos reunirnos manana en la plaza para ver si es el.",
    "Claro, a que hora te parece bien?",
    "Tienes alguna foto mas de tu mascota?",
    "Si, te puedo enviar mas fotos por aqui.",
    "Genial, ojala sea tu perro. Se via asustado.",
    "Muchas gracias por la ayuda!",
    "De nada, espero que lo encuentres pronto."
)

$pairCount = $Pairs.Count
if ($pairCount -gt 4) { $pairCount = 4 }
for ($i = 0; $i -lt $pairCount; $i++) {
    $p = $Pairs[$i]
    $fromToken = $TokenCache[$p.from]
    $toUser = $p.to

    try {
        $conv = Invoke-RestMethod -Uri "$GatewayUrl/api/messages/v1/conversations/start" -Method Post `
            -Headers @{ "Authorization" = "Bearer $fromToken"; "Content-Type" = "application/json" } `
            -Body (@{ participants = @($toUser) } | ConvertTo-Json)
    } catch {
        Log "  [WARN] $($p.from) <-> $($p.to) conversacion fallo: $($_.Exception.Message)"
        continue
    }

    if (-not $conv -or -not $conv.id) { Log "  [WARN] no se obtuvo conversationId"; continue }
    $convId = $conv.id
    Log "  OK conversacion $($p.from) <-> $($p.to) (id $convId)"

    $msgCount = Get-Random -Min 2 -Max 5
    $senders = @($p.from, $p.to)
    for ($m = 0; $m -lt $msgCount; $m++) {
        $sender = $senders[$m % 2]
        $sToken = $TokenCache[$sender]
        $txt = $SampleMessages | Get-Random
        try {
            Invoke-RestMethod -Uri "$GatewayUrl/api/messages/v1/send" -Method Post `
                -Headers @{ "Authorization" = "Bearer $sToken"; "Content-Type" = "application/json" } `
                -Body (@{ conversationId = $convId; message = $txt } | ConvertTo-Json) | Out-Null
            Log "    msg $sender -> $txt"
        } catch {
            Log "    [WARN] mensaje de $sender fallo"
        }
        Start-Sleep -Milliseconds 200
    }
}

Log "`n--- Seed completado! ---"
Log "Usuarios: $($AllUsers -join ', ')"
Log "Gateway: $GatewayUrl"
