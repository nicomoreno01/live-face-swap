# Guía completa

Todo lo que hace falta para poner una cara ajena en tu webcam y llevarla a Discord, Zoom, Meet o Teams. Windows y Linux.

- [1. Instalación](#1-instalación)
- [2. Primer arranque](#2-primer-arranque)
- [3. Llevarlo a la llamada](#3-llevarlo-a-la-llamada)
- [4. Calidad y velocidad](#4-calidad-y-velocidad)
- [5. Linux en detalle](#5-linux-en-detalle)
- [6. Problemas típicos](#6-problemas-típicos)
- [7. Qué se descarga y dónde](#7-qué-se-descarga-y-dónde)

---

## 1. Instalación

### Windows 10/11

Requisitos previos: **git** (https://git-scm.com/download/win) y **uv** (`winget install --id=astral-sh.uv -e`).

```powershell
git clone https://github.com/nicomoreno01/live-face-swap.git
cd live-face-swap
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Con `-ExecutionPolicy Bypass` te evitas el bloqueo típico de PowerShell («la ejecución de scripts está deshabilitada»). No cambia nada del sistema: solo afecta a esa ejecución.

Qué hace el instalador:

1. Comprueba `git` y `uv`.
2. Baja un Python 3.13 **aislado** (via uv), sin tocar el Python del sistema.
3. Clona FaceFusion en la etiqueta `3.9.1` dentro de `facefusion/`.
4. Crea `facefusion/.venv` e instala `requirements.txt`.
5. Elige motor: si existe `nvidia-smi` → `onnxruntime-gpu` (CUDA); si no → `onnxruntime-directml` (Intel/AMD con DirectX 12).
6. Guarda el motor elegido en `.provider` y verifica que `onnxruntime` importa.

### Linux

Requisitos: `git`, `uv` y, si no lo tienes, `ffmpeg`.

```bash
sudo apt install -y git ffmpeg
curl -LsSf https://astral.sh/uv/install.sh | sh    # revisa el script antes de ejecutarlo
git clone https://github.com/nicomoreno01/live-face-swap.git
cd live-face-swap
./install.sh
```

El instalador de Linux elige **CUDA** si hay `nvidia-smi`; si no, **CPU** (no existe DirectML para Linux).

---

## 2. Primer arranque

```powershell
.\run.ps1            # Windows
```
```bash
./run.sh             # Linux
```

La primera vez tarda varios minutos porque descarga ~1,8 GB de modelos (`inswapper_128`, detector `yoloface`, marcador de puntos faciales). Las siguientes veces arranca en segundos.

Se abre el navegador en `http://127.0.0.1:7860`. En el panel:

| Campo | Qué poner |
|---|---|
| **SOURCE** | la foto de la cara (botón de subir). Ejemplos en `faces/` |
| **TARGET** | tu webcam (ya viene seleccionada) |
| **WEBCAM DEVICE ID** | `0` (si tienes varias cámaras, prueba `1`, `2`…) |
| **WEBCAM RESOLUTION** | `320x240` si va lento · `640x480` equilibrado · `1280x720` con GPU buena |
| **WEBCAM FPS** | `15` |
| **WEBCAM MODE** | `inline` en Windows · `v4l2` en Linux si montaste cámara virtual |

Pulsa **START**. A los 10-20 s aparece el vídeo procesado.

Cambiar de cara en mitad de la llamada: sube otra foto en **SOURCE**, sin reiniciar.

---

## 3. Llevarlo a la llamada

### Con OBS (Windows y Linux)

1. OBS → *Fuentes* → **+** → **Captura de ventana** → elige el navegador con el panel.
2. Recorta para que solo se vea el vídeo: click derecho en la fuente → *Filtros* → *Recorte* (o *Transformar* → ajustar con Alt).
3. Botón **Iniciar cámara virtual** (abajo a la derecha).
4. En Discord: *Ajustes de usuario → Voz y vídeo → Cámara* → **OBS Virtual Camera**.
   Zoom / Meet / Teams: la misma cámara.

### Solo con Linux (sin OBS)

Ver [sección 5](#5-linux-en-detal).

---

## 4. Calidad y velocidad

El coste está casi todo en el modelo de swap, no en la detección:

| Modelo | Resolución de trabajo | Coste |
|---|---|---|
| `inswapper_128_fp16` | 128x128 | el más rápido, algo menos nítido |
| `inswapper_128` | 128x128 | ~30 % más lento, algo mejor |
| boost `256x256` / `512x512` | más resolución de salida | más lento, más detalle |

`run.ps1` / `run.sh` eligen solos: **CUDA → `inswapper_128` + `512x512`**; DirectML/CPU → **`inswapper_128_fp16` + `128x128`**.

Para forzar máxima calidad (solo tiene sentido con NVIDIA):

```powershell
.\run.ps1 -Quality
```

**Lo que NO hay que activar si va lento:** `face_enhancer`, `face_editor`, `face_masker`, `frame_colorizer`. Cada uno suma cientos de ms por fotograma.

**Medido en un i7-1195G7 + Intel Iris Xe (sin NVIDIA): 2-3 fps.** Con RTX 3060/4060 se estiman 25-40 fps.

---

## 5. Linux en detalle

### Cámara virtual con v4l2loopback

```bash
sudo apt install v4l2loopback-dkms v4l2loopback-utils
sudo modprobe v4l2loopback exclusive_caps=1 card_label="FaceFusion" video_nr=10
```

Comprueba el dispositivo:

```bash
v4l2-ctl --list-devices
```

En la UI: **WEBCAM MODE** → `v4l2` (y como salida, el `/dev/video10`). En Discord ya aparece una cámara llamada **FaceFusion**.

Para que el módulo se cargue en cada arranque:

```bash
echo 'v4l2loopback' | sudo tee /etc/modules-load.d/v4l2loopback.conf
echo 'options v4l2loopback exclusive_caps=1 card_label="FaceFusion" video_nr=10' | sudo tee /etc/modprobe.d/v4l2loopback.conf
```

### CUDA que de verdad funciona

`onnxruntime-gpu` necesita **driver NVIDIA reciente + CUDA 12 + cuDNN 9**. Si falta cuDNN, onnxruntime arranca en CPU sin avisar y todo va lentísimo. Verifica:

```bash
python -c "import onnxruntime as o; print(o.get_available_providers())"
```

Debe aparecer `CUDAExecutionProvider`. Si solo sale `CPUExecutionProvider`, falta la librería (en Ubuntu, `sudo apt install libcudnn9-cuda-12` o el paquete equivalente de tu distro).

### GPU Intel/AMD en Linux

No hay `onnxruntime-directml` para Linux. Opciones: CPU (lento), o usar el build ROCm/OpenVINO por tu cuenta (no incluido aquí).

---

## 6. Problemas típicos

| Síntoma | Causa / solución |
|---|---|
| «la ejecución de scripts está deshabilitada» | Usa `powershell -ExecutionPolicy Bypass -File .\install.ps1` |
| «Falta uv» | `winget install --id=astral-sh.uv -e` (Windows) o el script de astral.sh (Linux) |
| La imagen sale congelada o en negro | Pulsa STOP y START. La webcam solo la usa un programa a la vez: cierra Discord/Zoom/OBS mientras pruebas |
| No detecta la cara | Hace falta luz frontal, cara centrada y sin gafas oscuras ni gorra |
| Va a 1-2 fps | `320x240`, FPS 15, sin face_enhancer. Sin NVIDIA es lo esperable |
| `onnxruntime` no importa (`DLL load failed`) | Reinstala dependencias: `uv pip install --python facefusion/.venv/Scripts/python.exe -r facefusion/requirements.txt` y repite el paso del motor |
| Puerto 7860 ocupado | Cierra la otra instancia de FaceFusion |
| OBS no encuentra la ventana | Usa *Captura de pantalla* en vez de *Captura de ventana* |
| En Linux no aparece `/dev/video10` | El módulo `v4l2loopback` no está cargado: `sudo modprobe v4l2loopback` |

---

## 7. Qué se descarga y dónde

- `facefusion/` — código de FaceFusion 3.9.1 (~50 MB). Está en `.gitignore`: no se sube al repo.
- `facefusion/.venv/` — Python 3.13 + dependencias (~700 MB).
- `facefusion/.assets/models/` — modelos de IA (~1,8 GB), con verificación de hash desde el CDN de FaceFusion.
- `.provider` — una línea de texto con `cuda`, `directml` o `cpu`.

Para borrarlo todo: elimina la carpeta `facefusion/` (y `.provider`).

### Mover la instalación a otro equipo

Se puede copiar `facefusion/.assets/models/` para no volver a descargar 1,8 GB, pero **el `.venv` no es portable** (Windows ↔ Linux): en el equipo nuevo corre `install.ps1` / `install.sh` y listo; reutilizará la carpeta `facefusion/` y los modelos ya copiados.
