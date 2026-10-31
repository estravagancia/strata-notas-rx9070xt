# El equipo

| Pieza | Detalle |
|---|---|
| Gráfica | AMD Radeon **RX 9070 XT**, 16 GiB de VRAM (RDNA 4) |
| CPU | AMD Ryzen 7 **9800X3D** (8 núcleos / 16 hilos, Zen 5, con AVX-512) |
| RAM | **60 GB** DDR5 |
| Sistema | Ubuntu Linux, kernel 7.0.0-38 (x86_64) |
| Driver | amdgpu (sin ROCm del sistema; ver más abajo) |

## La rareza: la tarjeta se reporta como "gfx1200", no "gfx1201"

Las tarjetas RDNA 4 tienen dos nombres de arquitectura: **gfx1201** (Navi 48, la RX 9070)
y **gfx1200** (Navi 44). La distinción oficial llegó con ROCm; las librerías GPU (wheels
TheRock **7.10.0a20251120**) que Strata instala en su propio entorno Python (`venv`, sin
instalar ROCm en el sistema) **son anteriores a esa distinción** y en esta caja la
tarjeta aparece como **gfx1200**. El log del motor lo dice textualmente.

Consecuencia práctica: Strata empaqueta sus tablas de ajuste de rendimiento
(hipBLASLt) por nombre de arquitectura. Una tarjeta que se reporta con el nombre
hermano **no encuentra la tabla de su familia** y pierde la ruta rápida de prefill.
Ese es exactamente el caso de esta caja, y es el motivo del parche C1
([patches/](patches/)) y de la tabla recalibrada C2.

Nota (2026-10-27): el comprobador de hardware de Strata ya reporta la tarjeta como
gfx1201, pero el motor con esos wheels sigue arrancando como gfx1200. El motor lleva
compiladas **ambas** arquitecturas (`gfx1200;gfx1201`), así que el motor funciona igual;
lo que cambia es **qué tabla de ajuste encuentra**.

**Actualización (2026-10-30, con ROCm 10.3 propio): la sospecha "ROCm 10.x rotula gfx1201
en Linux" es falsa.** El runtime 10.3, su `rocminfo` y su propio afinador de hipBLASLt
siguen diciendo **gfx1200** en esta tarjeta; el rótulo gfx1201 que aparece en Windows es
del driver de Windows. Lo que da velocidad no es el nombre de la arquitectura: es el stack
BLAS más nuevo (chat +3,5 % al pasar de los wheels 7.10 a ROCm 10.3, ver
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md)). Los kernels nuevos de v0.2.9 para gfx12 (GDN
chunked) sí rinden igual aquí con el nombre "hermano".

## Cómo encaja el hardware en el rendimiento

- Los 83 GB del modelo no caben en VRAM: Strata mantiene en la tarjeta lo caliente
  (~14,4 GiB) y el resto en RAM, y va trayendo trozos (expertos) por el PCIe.
- Medimos el PCIe real de esta caja con la sonda del propio motor: **55,5 GB/s** → el
  motor se autoajusta con `pcie_frac 0.55`. El cuello de botella del chat son esos
  traslados expertos/PCIe, no la GPU.
- RAM de sistema: ~49-55 GB consumidos con el servidor encima. **No cabe un segundo
  modelo en paralelo.**
- La cache de expertos quedó en ~3.800-4.500 ranuras (6,2 GiB) según reserva de VRAM.
