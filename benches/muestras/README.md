# Muestras de bench (para auditar las tablas)

Nueve corridas auditadas, en el formato `results.json` "schema 1" de
`tools/strata_bench.py`: cada una contiene 3 pasadas por métrica, la máquina
(GPU/CPU/RAM/OS), la versión del motor y los detalles del arranque (ranuras de
expertos, `pcie_frac`, cachés…).

| Carpeta | Etiqueta interna | Motor / qué probaba |
|---|---|---|
| `iqpc0-control-0.1.48.1/` | `-iqpc0` (24-10) | 0.1.48.1 sin banderas (control) |
| `iq3-0150-engine-0.1.50/` | `-iq3-0150` (25-10) | 0.1.50 oficial (control; motor adoptado entonces) |
| `iqgather-0.1.50-flag/` | `-iqgather` (25-10) | 0.1.50 + `STRATA_IQ_GATHER=1` (descartado) |
| `off-0.1.55-control/` | `-0155-off-b` (31-10) | 0.1.55 + ROCm 10.3, GDN **apagado** (control del A/B) |
| `gdn-0.1.55-gdn/` | `-0155-gdn-b` (31-10) | 0.1.55 + ROCm 10.3 + **`STRATA_GDN_CHUNKED=1`** (adoptado) |
| `mtp-0.1.56-control/` | `-mtp-0156-control` (03-11) | 0.1.56 con cabezal MTP (control del A/B del drafter) |
| `df2-0.1.56-draft/` | `-df2-0156-draft` (03-11) | 0.1.56 + **`--draft dflash2`** (adoptado) |
| `engine-0.1.57-ring0/` | `-ring0-0157` (05-11) | 0.1.57 con `STRATA_GFX12_RING=0` (control; usa `--long`, añade 32K) |
| `engine-0.1.57-anillo/` | `-anillo-0157` (05-11) | 0.1.57 con el anillo de prompt por defecto, 256/192/96 (adoptado; usa `--long`) |

Hay tres A/B publicados por parejas: el del 31-10 (GDN chunked), el del 03-11 (DFlash2
frente al cabezal MTP) y el del 05-11 (anillo de prompt). Comparar solo dentro de la
misma pareja: arrastran cambios de contexto, runtime o protocolo (las dos del 05-11
usan `strata_bench.py --long` e incluyen el prompt de 32K; las anteriores no).

Qué mirar si quieres repetir el experimento: `machine.engine_version`, `context` y
`expert_slots` (deben coincidir con la corrida que quieras comparar), y el bloque de
resultados por métrica. El `README.md` de cada carpeta es el resumen que generamos en
su momento; el detalle del protocolo (run1 descartada, auditoría del log) está en la
raíz del repo.
