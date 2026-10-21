# Cara en vivo para videollamadas (face swap con una foto)

Ponerse la cara de otra persona (Elon Musk, El Alfa, quien sea) **en tiempo real** en Discord, Zoom, Meet o Teams, usando **una sola foto** y sin pagar nada. Todo corre en tu equipo: ninguna imagen sale a internet.

Basado en [FaceFusion](https://github.com/facefusion/facefusion) 3.9.1 (open source, AGPL-3.0). Este repo solo trae el instalador, el lanzador, las guías y dos fotos de ejemplo.

```
foto de la cara  +  tu webcam  ->  cara cambiada  ->  OBS / cámara virtual  ->  Discord
```

## Requisitos

- Windows 10/11 (64 bits) o Linux (x86_64)
- 4 GB libres en disco (los modelos ocupan ~1,8 GB y se bajan solos la primera vez)
- Webcam
- GPU **NVIDIA** recomendada. Sin NVIDIA funciona, pero a 2-3 fps (ver [rendimiento](#rendimiento))
- No hace falta instalar Python: el instalador usa [uv](https://docs.astral.sh/uv/) y baja su propio Python 3.13

## Instalación (2 comandos)

**Windows (PowerShell):**
```powershell
git clone https://github.com/nicomoreno01/live-face-swap.git
cd live-face-swap
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**Linux:**
```bash
git clone https://github.com/nicomoreno01/live-face-swap.git
cd live-face-swap
./install.sh
```

El instalador detecta la GPU y elige el motor: **CUDA** si hay NVIDIA, **DirectML** si es Intel/AMD en Windows, **CPU** en Linux sin NVIDIA. Tarda 3-10 minutos.

Si no tienes `uv`, instálalo antes (Windows: `winget install --id=astral-sh.uv -e` · Linux: `curl -LsSf https://astral.sh/uv/install.sh | sh`) y revisa el script antes de ejecutarlo.

## Uso

**Windows:** doble clic en `run.ps1` (o `powershell -ExecutionPolicy Bypass -File .\run.ps1`)
**Linux:** `./run.sh`

Se abre el navegador en `http://127.0.0.1:7860`:

1. **SOURCE** → sube la foto de la cara (están en `faces/`: `elon_musk.jpg`, `el_alfa.jpg`).
2. **WEBCAM DEVICE ID** → `0` (tu cámara).
3. **WEBCAM RESOLUTION** → `320x240` si va lento, `640x480` o `1280x720` si tienes GPU.
4. **START**. A los ~15 s aparece el vídeo ya transformado.

Puedes cambiar de cara **en mitad de la llamada** volviendo a subir otra foto en SOURCE.

### Llevarlo a Discord / Zoom / Meet

Con **OBS** (Windows y Linux):

1. Fuente → **Captura de ventana** (o *Captura de pantalla*) → el navegador con el panel de FaceFusion.
2. Recorta a solo el vídeo: click derecho en la fuente → *Filtros* → *Recorte*.
3. **Iniciar cámara virtual**.
4. En Discord: *Ajustes → Voz y vídeo → Cámara* → **OBS Virtual Camera** (en Zoom/Meet, la misma).

En Linux también puedes usar `v4l2loopback` y el modo `v4l2` de la UI (ver [GUIA.md](GUIA.md)).

## Rendimiento

Medido en un portátil i7-1195G7 + **Intel Iris Xe** (sin NVIDIA): **2-3 fps**. El resto son estimaciones por rango de GPU, no medidas:

| Equipo | fps en vivo |
|---|---|
| Intel Iris Xe / iGPU | 2-3 fps |
| GTX 1650 / RTX 3050 4 GB | ~10-15 fps |
| RTX 3060 / 4060 8 GB | ~25-40 fps |
| RTX 4070 o superior | 40-60 fps |

El cuello de botella es el modelo de swap (`inswapper_128`), no la detección de cara. En Windows con Intel/AMD se usa DirectML; en Linux sin NVIDIA solo queda CPU, que es mucho más lento.

Si va lento: baja la resolución a `320x240`, deja `WEBCAM FPS` en 15, no actives *face_enhancer* ni *face_masker*.

## Qué hay dentro

```
install.ps1 / install.sh   instala Python 3.13 (uv), clona FaceFusion 3.9.1 y las dependencias
run.ps1 / run.sh           lanza la UI en modo webcam
faces/                     dos fotos de ejemplo (con créditos y licencia)
GUIA.md                    guía detallada + problemas típicos
```

No se incluyen los modelos de IA (los descarga FaceFusion desde su propio CDN, con verificación de hash) ni binarios de terceros.

## Licencias y créditos

- Scripts y documentación de este repo: **MIT** (ver `LICENSE`).
- FaceFusion: **AGPL-3.0**, se clona desde su repositorio oficial, no se redistribuye aquí.
- Fotos de `faces/`: ver [faces/CREDITS.md](faces/CREDITS.md) (CC BY-SA 4.0 y CC BY 3.0).
- Los modelos de IA tienen sus propias licencias; se descargan en tu equipo, no se redistribuyen.

## Aviso

Esto es para bromear con tu grupo. Cambiar la cara de alguien para suplantarlo en algo serio (fraude, acoso, difamación, contenido íntimo sin consentimiento) es delito en muchos países y va contra las normas de las plataformas. Úsalo con gente que sepa que es un juego.
