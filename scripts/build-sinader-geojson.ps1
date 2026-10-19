# ============================================================
# build-sinader-geojson.ps1
# Convierte el dataset SINADER 2024 (xlsx) en un GeoJSON de
# puntos (EPSG:4326), agregado a nivel de establecimiento.
#
# Uso:  powershell -ExecutionPolicy Bypass -File scripts/build-sinader-geojson.ps1
# ============================================================

param(
  [string]$XlsxPath = (Join-Path $PSScriptRoot '..\gi-sinader-2024-ckan (3).xlsx'),
  [string]$OutPath  = (Join-Path $PSScriptRoot '..\data\sinader_2024.geojson')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem

Write-Host "Leyendo: $XlsxPath"
$tmp = Join-Path $env:TEMP ('sinader_xlsx_' + [guid]::NewGuid().ToString('N'))
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
[System.IO.Compression.ZipFile]::ExtractToDirectory($XlsxPath, $tmp)

# --- 1. Cadena de strings compartidos (sharedStrings.xml) ---
Write-Host "Cargando tabla de strings..."
$sstRaw = [System.IO.File]::ReadAllText((Join-Path $tmp 'xl\sharedStrings.xml'), [System.Text.Encoding]::UTF8)
$sharedStrings = New-Object 'System.Collections.Generic.List[string]'
foreach ($si in [regex]::Matches($sstRaw, '<si>(.*?)</si>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
  $text = ''
  foreach ($t in [regex]::Matches($si.Groups[1].Value, '<t[^>]*>(.*?)</t>', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
    $text += $t.Groups[1].Value
  }
  $sharedStrings.Add($text)
}
Write-Host "  strings únicos: $($sharedStrings.Count)"

# --- 2. Hoja "Datos" (sheet1.xml) ---
$sheet = [System.IO.File]::ReadAllText((Join-Path $tmp 'xl\worksheets\sheet1.xml'), [System.Text.Encoding]::UTF8)
$rowMatches = [regex]::Matches($sheet, '<row[^>]*r="(\d+)"[^>]*>(.*?)</row>', [System.Text.RegularExpressions.RegexOptions]::Singleline)
Write-Host "  filas totales (incl. encabezado): $($rowMatches.Count)"

function Get-Cells {
  param([string]$Body)
  $cells = @{}
  foreach ($c in [regex]::Matches($Body, '<c r="([A-Z]+)\d+"(?:\s[^>]*?t="([^"]*)")?[^>]*>(?:<v>(.*?)</v>)?', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
    $col = $c.Groups[1].Value
    $type = $c.Groups[2].Value
    $val = $c.Groups[3].Value
    if ($type -eq 's' -and $val -ne '') {
      $val = $sharedStrings[[int]$val]
    }
    $cells[$col] = $val
  }
  return $cells
}

# Encabezados desde la primera fila
$headerCells = Get-Cells $rowMatches[0].Groups[2].Value
$colByHeader = @{}
foreach ($col in $headerCells.Keys) { $colByHeader[$headerCells[$col]] = $col }
Write-Host "  columnas: $(($colByHeader.Keys | Sort-Object) -join ', ')"

# Índices de las columnas requeridas
$idx = @{
  id_vu     = $colByHeader['id_vu']
  razon     = $colByHeader['razon_social']
  nombre    = $colByHeader['nombre_establecimiento']
  rubro     = $colByHeader['rubro']
  region    = $colByHeader['region']
  comuna    = $colByHeader['comuna']
  cut       = $colByHeader['codigo_unico_territorial']
  tipo      = $colByHeader['tipo_recepcion']
  lat       = $colByHeader['latitud']
  lon       = $colByHeader['longitud']
  ton       = $colByHeader['cantidad_toneladas']
}

# --- 3. Agregación por establecimiento ---
$establishments = @{}
$total = 0; $invalidas = 0; $validas = 0

foreach ($rm in $rowMatches) {
  if ($rm.Groups[1].Value -eq '1') { continue }  # encabezado
  $total++
  $cells = Get-Cells $rm.Groups[2].Value
  $latRaw = $cells[$idx.lat]
  $lonRaw = $cells[$idx.lon]
  $lat = 0.0; $lon = 0.0
  $ok = $false
  if ($latRaw -ne '' -and $lonRaw -ne '' -and
      [double]::TryParse($latRaw, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$lat) -and
      [double]::TryParse($lonRaw, [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$lon)) {
    if ([math]::Abs($lat) -le 90 -and [math]::Abs($lon) -le 180) { $ok = $true }
  }
  if (-not $ok) { $invalidas++; continue }
  $validas++

  $key = [string]$cells[$idx.id_vu]
  $ton = 0.0
  [void][double]::TryParse([string]$cells[$idx.ton], [System.Globalization.NumberStyles]::Any, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$ton)

  if ($establishments.ContainsKey($key)) {
    $e = $establishments[$key]
    $e.n_declaraciones++
    $e.toneladas_totales += $ton
  } else {
    $establishments[$key] = [pscustomobject]@{
      id_vu                      = $key
      razon_social               = [string]$cells[$idx.razon]
      nombre_establecimiento     = [string]$cells[$idx.nombre]
      rubro                      = [string]$cells[$idx.rubro]
      region                     = [string]$cells[$idx.region]
      comuna                     = [string]$cells[$idx.comuna]
      codigo_unico_territorial   = [string]$cells[$idx.cut]
      tipo_recepcion             = [string]$cells[$idx.tipo]
      lat                        = $lat
      lon                        = $lon
      n_declaraciones            = 1
      toneladas_totales          = $ton
    }
  }
}

Write-Host "Filas totales: $total"
Write-Host "Filas descartadas (coordenadas inválidas/nulas): $invalidas"
Write-Host "Filas válidas: $validas"
Write-Host "Establecimientos agregados: $($establishments.Count)"

# --- 4. Serializar GeoJSON ---
function Json-Escape([string]$s) {
  if ($null -eq $s) { $s = '' }
  $sb = New-Object System.Text.StringBuilder
  [void]$sb.Append('"')
  foreach ($ch in $s.ToCharArray()) {
    switch ($ch) {
      '"'  { [void]$sb.Append('\"') }
      '\'  { [void]$sb.Append('\\') }
      "`b" { [void]$sb.Append('\b') }
      "`f" { [void]$sb.Append('\f') }
      "`n" { [void]$sb.Append('\n') }
      "`r" { [void]$sb.Append('\r') }
      "`t" { [void]$sb.Append('\t') }
      default {
        if ([int]$ch -lt 32) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) }
        else { [void]$sb.Append($ch) }
      }
    }
  }
  [void]$sb.Append('"')
  return $sb.ToString()
}

$inv = [System.Globalization.CultureInfo]::InvariantCulture
$features = New-Object 'System.Collections.Generic.List[string]'
foreach ($e in $establishments.Values) {
  $latStr = $e.lat.ToString('R', $inv)
  $lonStr = $e.lon.ToString('R', $inv)
  $tonStr = $e.toneladas_totales.ToString('R', $inv)
  $props = '{"id_vu":' + (Json-Escape $e.id_vu) +
           ',"razon_social":' + (Json-Escape $e.razon_social) +
           ',"nombre_establecimiento":' + (Json-Escape $e.nombre_establecimiento) +
           ',"rubro":' + (Json-Escape $e.rubro) +
           ',"region":' + (Json-Escape $e.region) +
           ',"comuna":' + (Json-Escape $e.comuna) +
           ',"codigo_unico_territorial":' + (Json-Escape $e.codigo_unico_territorial) +
           ',"tipo_recepcion":' + (Json-Escape $e.tipo_recepcion) +
           ',"n_declaraciones":' + $e.n_declaraciones +
           ',"toneladas_totales":' + $tonStr + '}'
  $features.Add('{"type":"Feature","properties":' + $props + ',"geometry":{"type":"Point","coordinates":[' + $lonStr + ',' + $latStr + ']}}')
}

$json = '{"type":"FeatureCollection","name":"sinader_2024","crs":{"type":"name","properties":{"name":"urn:ogc:def:crs:OGC:1.3:CRS84"}},"features":[' +
        ($features -join ',') + ']}'

$outFull = [System.IO.Path]::GetFullPath($OutPath)
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($outFull, $json, $utf8NoBom)
Write-Host "GeoJSON escrito en: $outFull"

Remove-Item -Recurse -Force $tmp
Write-Host "Listo."
