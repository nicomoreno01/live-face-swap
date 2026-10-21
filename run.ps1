# Arranca FaceFusion en modo webcam (cara en vivo).
#
#   powershell -ExecutionPolicy Bypass -File .\run.ps1
#   powershell -ExecutionPolicy Bypass -File .\run.ps1 -Quality     (mas calidad, mas lento)
#
# La primera vez descarga los modelos (~1,8 GB) y tarda; despues arranca en segundos.
#
param(
    [switch]$Quality,
    [string]$Provider = ''
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot

$ff = Join-Path $root 'facefusion'
$py = Join-Path $ff '.venv\Scripts\python.exe'
if (-not (Test-Path $py)) {
    Write-Host 'No esta instalado. Ejecuta primero:  powershell -ExecutionPolicy Bypass -File .\install.ps1' -ForegroundColor Red
    exit 1
}

if (-not $Provider) {
    $file = Join-Path $root '.provider'
    if (Test-Path $file) { $Provider = (Get-Content $file -Raw).Trim() } else { $Provider = 'directml' }
}

# Motor -> modelo y resolucion del swap
if ($Provider -eq 'cuda' -or $Quality) {
    $model = 'inswapper_128'
    $boost = '512x512'
} else {
    $model = 'inswapper_128_fp16'
    $boost = '128x128'
}

# IMPORTANTE: hay que ejecutar desde dentro de facefusion\
# (el programa resuelve sus layouts como rutas relativas al directorio actual).
Set-Location $ff

Write-Host "Motor: $Provider | modelo: $model | pixel boost: $boost" -ForegroundColor Cyan
Write-Host 'Abriendo http://127.0.0.1:7860 ... (Ctrl+C para cerrar)' -ForegroundColor Cyan

& $py 'facefusion.py' run `
    --ui-layouts webcam `
    --execution-providers $Provider `
    --processors face_swapper `
    --face-swapper-model $model `
    --face-swapper-pixel-boost $boost `
    --execution-thread-count 2 `
    --open-browser
