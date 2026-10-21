# Instalador para Windows (PowerShell 5.1 o superior)
# Descarga Python 3.13 (via uv), clona FaceFusion 3.9.1 e instala las dependencias
# con el motor que corresponda a tu GPU: CUDA (NVIDIA) o DirectML (Intel/AMD).
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#
param(
    [switch]$Quality   # no hace nada aqui; se usa en run.ps1
)
$ErrorActionPreference = 'Stop'
$root = $PSScriptRoot
Set-Location $root

function Paso($t) { Write-Host "`n== $t ==" -ForegroundColor Cyan }
function Fallo($t) { Write-Host "ERROR: $t" -ForegroundColor Red; exit 1 }

Paso 'Comprobando requisitos'
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Fallo 'Falta git. Instala Git para Windows: https://git-scm.com/download/win'
}
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
    Write-Host 'Falta uv (gestor de Python). Instalalo con:' -ForegroundColor Yellow
    Write-Host '  winget install --id=astral-sh.uv -e' -ForegroundColor Yellow
    Write-Host 'y vuelve a ejecutar este script.' -ForegroundColor Yellow
    exit 1
}
'git y uv: OK'

Paso 'Instalando Python 3.13 (sin tocar el Python del sistema)'
& uv python install 3.13
if ($LASTEXITCODE -ne 0) { Fallo 'No se pudo instalar Python 3.13 con uv.' }

Paso 'Descargando FaceFusion 3.9.1'
$ff = Join-Path $root 'facefusion'
if (Test-Path $ff) {
    Write-Host 'Ya existe la carpeta facefusion\, se reutiliza.'
} else {
    & git clone --depth 1 --branch 3.9.1 https://github.com/facefusion/facefusion.git $ff
    if ($LASTEXITCODE -ne 0) {
        Write-Host 'La etiqueta 3.9.1 no existe; se usa la ultima version.' -ForegroundColor Yellow
        & git clone --depth 1 https://github.com/facefusion/facefusion.git $ff
        if ($LASTEXITCODE -ne 0) { Fallo 'No se pudo clonar FaceFusion.' }
    }
}

Paso 'Creando el entorno de Python'
$env:UV_LINK_MODE = 'copy'
& uv venv -p 3.13 (Join-Path $ff '.venv')
$py = Join-Path $ff '.venv\Scripts\python.exe'

Paso 'Instalando dependencias (tarda unos minutos)'
& uv pip install --python $py -r (Join-Path $ff 'requirements.txt')
if ($LASTEXITCODE -ne 0) { Fallo 'Fallo la instalacion de dependencias.' }

Paso 'Eligiendo motor de IA'
# Quitar cualquier motor anterior ANTES de instalar el nuevo: onnxruntime,
# onnxruntime-directml y onnxruntime-gpu comparten el modulo `onnxruntime`, y si
# se mezclan (o se re-ejecuta el instalador) queda roto:
#   ImportError: cannot import name 'InferenceSession' from 'onnxruntime'
& uv pip uninstall --python $py onnxruntime onnxruntime-directml onnxruntime-gpu 2>&1 | Out-Null
if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) {
    Write-Host 'GPU NVIDIA detectada -> CUDA'
    & uv pip install --python $py onnxruntime-gpu
    if ($LASTEXITCODE -ne 0) { Fallo 'No se pudo instalar onnxruntime-gpu.' }
    Set-Content -Path (Join-Path $root '.provider') -Value 'cuda' -Encoding ascii
} else {
    Write-Host 'Sin NVIDIA -> DirectML (Intel/AMD, DirectX 12)'
    & uv pip install --python $py 'onnxruntime-directml==1.24.4'
    if ($LASTEXITCODE -ne 0) { Fallo 'No se pudo instalar onnxruntime-directml.' }
    Set-Content -Path (Join-Path $root '.provider') -Value 'directml' -Encoding ascii
}

Paso 'Verificando'
& $py -c "import onnxruntime as o; print('onnxruntime', o.__version__); print('motores:', o.get_available_providers())"
if ($LASTEXITCODE -ne 0) { Fallo 'onnxruntime no importa correctamente.' }

Write-Host "`nTodo listo." -ForegroundColor Green
Write-Host 'Ejecuta run.ps1 para arrancar. La primera vez descargara ~1,8 GB de modelos.' -ForegroundColor Green
Write-Host 'Guia completa: GUIA.md' -ForegroundColor Green
exit 0
