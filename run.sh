#!/usr/bin/env bash
# Arranca FaceFusion en modo webcam (cara en vivo).
#
#   ./run.sh              # equilibrado
#   ./run.sh --quality    # mas calidad (mas lento)
#   ./run.sh --v4l2       # salida a camara virtual v4l2 (requiere v4l2loopback)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

PY="$ROOT/facefusion/.venv/bin/python"
if [ ! -x "$PY" ]; then
  echo 'No esta instalado. Ejecuta primero: ./install.sh' >&2
  exit 1
fi

PROVIDER="$(cat .provider 2>/dev/null || echo cpu)"
QUALITY=0
LAYOUT="webcam"
for a in "$@"; do
  case "$a" in
    --quality) QUALITY=1 ;;
    --v4l2) LAYOUT="webcam" ;;   # la salida se elige en la UI (Webcam mode: v4l2)
    *) echo "Opcion desconocida: $a" >&2; exit 1 ;;
  esac
done

if [ "$PROVIDER" = "cuda" ] || [ "$QUALITY" = "1" ]; then
  MODEL="inswapper_128"; BOOST="512x512"
else
  MODEL="inswapper_128_fp16"; BOOST="128x128"
fi

echo "Motor: $PROVIDER | modelo: $MODEL | pixel boost: $BOOST"
echo "Abriendo http://127.0.0.1:7860 ... (Ctrl+C para cerrar)"

exec "$PY" "$ROOT/facefusion/facefusion.py" run \
  --ui-layouts "$LAYOUT" \
  --execution-providers "$PROVIDER" \
  --processors face_swapper \
  --face-swapper-model "$MODEL" \
  --face-swapper-pixel-boost "$BOOST" \
  --execution-thread-count 2 \
  --open-browser
