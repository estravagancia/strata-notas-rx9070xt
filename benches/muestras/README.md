# Muestras de bench (para auditar las tablas)

Cinco corridas auditadas, en el formato `results.json` "schema 1" de
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

Las dos últimas son el A/B del 31-10 con el contexto en 131.072 y el runtime ROCm propio:
mismo día, misma config, una sola variable (`STRATA_GDN_CHUNKED`). Comparar esas dos sí;
compararlas con las tres primeras arrastra el cambio de contexto y de runtime.

Qué mirar si quieres repetir el experimento: `machine.engine_version`, `context` y
`expert_slots` (deben coincidir con la corrida que quieras comparar), y el bloque de
resultados por métrica. El `README.md` de cada carpeta es el resumen que generamos en
su momento; el detalle del protocolo (run1 descartada, auditoría del log) está en la
raíz del repo.
