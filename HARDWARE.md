# El equipo

| Pieza | Detalle |
|---|---|
| Gráfica | AMD Radeon **RX 9070 XT**, 16 GiB de VRAM (RDNA 4) |
| CPU | AMD Ryzen 7 **9800X3D** (8 núcleos / 16 hilos, Zen 5, con AVX-512) |
| Placa base | ASUS **PRIME X870-P WIFI** (BIOS 1644, 03/2026) |
| RAM | **64 GB** DDR5 — Corsair Vengeance RGB, 6400 MHz, 2×32 GB (dual channel) |
| Almacenamiento | NVMe **Crucial T700 1 TB** (PCIe Gen5, `CT1000T700SSD5`): ahí viven los modelos, sus packs y la caché KV de disco (`/`, 184 GB libres a 13-11). La caja tiene además un WD_BLACK SN850X 2 TB que no usamos para los modelos. |
| Sistema | Ubuntu Linux, kernel 7.0.0-38 (x86_64) |
| Driver | amdgpu (sin ROCm del sistema; ver más abajo) |

Nota: donde otras notas hablan de "60 GB de RAM" se refieren a lo que el modelo llega a
ocupar en esta caja, no a la capacidad instalada (64 GB nominales; `MemTotal` reporta
61,2-61,4 GiB utilizables).

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

Etiqueta de modelos: la producción actual es **IQ3_S**; **IQ3_XXS** fue la producción del
20-10 al 12-11. Ninguna de estas cifras es intercambiable entre los dos.

- Tamaños del modelo en disco (medidos el 13-11 sobre los shards GGUF de
  `~/Strata-data/models/`): **IQ3_S, 83,6 GB** (2 shards de 52+27 GiB); **IQ3_XXS, 75,8 GB**
  (44+27 GiB). Ninguno cabe en los 16 GiB de VRAM: Strata mantiene en la tarjeta lo que se
  usa a menudo (cache de expertos y KV residentes, que el motor autogestiona) y el resto
  queda en RAM, trayendo expertos por el PCIe.
- La sonda PCIe del propio motor mide en esta caja **entre 47,4 y 55,3 GB/s según el
  arranque** (rango observado en los logs de octubre y noviembre de los dos modelos). El
  motor no se queda en un número fijo: autoajusta `pcie_frac` con el ritmo real de traslado
  de bytes de expertos (en producción con IQ3_S se observó 0,40 → 0,45). El cuello de
  botella del chat son esos traslados expertos/PCIe, no la GPU: la palanca es la tasa de
  acierto de la cache de expertos (observada del 60-84 % en los logs).
- Las ranuras de la cache de expertos **no son un número fijo ni generalizable**: dependen
  del modelo y de la reserva de VRAM (`--vram-reserve-mib`, 1536 por defecto). Ejemplos
  medidos en los logs: con **IQ3_S** en producción **4.105-4.121 ranuras (7,83-7,86 GiB)**
  (en un arranque con menos VRAM libre, 9,88 GiB en vez de ~10,2, bajó a 3.170); con
  **IQ3_XXS** y visión activada **5.025 (8,15 GiB)** y 3.710 (6,05 GiB) en el laboratorio
  con 3.072 MiB reservados.
