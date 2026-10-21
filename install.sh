#!/usr/bin/env bash
# Instalador para Linux (x86_64)
# Descarga Python 3.13 (via uv), clona FaceFusion 3.9.1 e instala las dependencias
# con el motor que corresponda: CUDA (NVIDIA) o CPU.
#
#   ./install.sh
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

paso() { printf '\n== %s ==\n' "$1"; }
fallo() { printf 'ERROR: %s\n' "$1" >&2; exit 1; }

paso 'Comprobando requisitos'
command -v git >/dev/null || fallo 'Falta git (sudo apt install git).'
command -v uv  >/dev/null || {
  printf 'Falta uv (gestor de Python). Instalalo con:\n  curl -LsSf https://astral.sh/uv/install.sh | sh\n' >&2
  printf 'Revisa el script antes de ejecutarlo y vuelve a correr ./install.sh\n' >&2
  exit 1
}
command -v ffmpeg >/dev/null || printf 'AVISO: no hay ffmpeg en el PATH (sudo apt install ffmpeg). Suele no ser necesario.\n'
echo 'git y uv: OK'

paso 'Instalando Python 3.13 (sin tocar el Python del sistema)'
uv python install 3.13

paso 'Descargando FaceFusion 3.9.1'
if [ -d facefusion ]; then
  echo 'Ya existe la carpeta facefusion/, se reutiliza.'
else
  git clone --depth 1 --branch 3.9.1 https://github.com/facefusion/facefusion.git facefusion \
    || git clone --depth 1 https://github.com/facefusion/facefusion.git facefusion \
    || fallo 'No se pudo clonar FaceFusion.'
fi

paso 'Creando el entorno de Python'
export UV_LINK_MODE=copy
uv venv -p 3.13 facefusion/.venv
PY="$ROOT/facefusion/.venv/bin/python"

paso 'Instalando dependencias (tarda unos minutos)'
uv pip install --python "$PY" -r facefusion/requirements.txt

paso 'Eligiendo motor de IA'
# Quitar cualquier motor anterior antes de instalar el nuevo: comparten el modulo
# `onnxruntime` y mezclarlos deja la importacion rota.
uv pip uninstall --python "$PY" onnxruntime onnxruntime-directml onnxruntime-gpu >/dev/null 2>&1 || true
if command -v nvidia-smi >/dev/null; then
  echo 'GPU NVIDIA detectada -> CUDA'
  uv pip install --python "$PY" onnxruntime-gpu
  echo cuda > .provider
  echo 'Para que CUDA funcione de verdad necesitas driver NVIDIA + CUDA 12 + cuDNN 9.'
else
  echo 'Sin NVIDIA -> CPU (lento: 1-2 fps). Con GPU Intel/AMD en Linux no hay DirectML.'
  uv pip install --python "$PY" onnxruntime
  echo cpu > .provider
fi

paso 'Verificando'
"$PY" -c "import onnxruntime as o; print('onnxruntime', o.__version__); print('motores:', o.get_available_providers())"

printf '\nTodo listo.\nEjecuta ./run.sh para arrancar. La primera vez descargara ~1,8 GB de modelos.\nGuia completa: GUIA.md\n'
