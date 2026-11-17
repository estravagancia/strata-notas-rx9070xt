# Muestras de bench (para auditar las tablas)

Diecinueve ejecuciones auditadas, en el formato `results.json` "schema 1" de
`tools/strata_bench.py`: cada una contiene 3 pasadas por métrica, la máquina
(GPU/CPU/RAM/OS), la versión del motor y los detalles del arranque (ranuras de
expertos, `pcie_frac`, cachés…). Las diez últimas son sobre **IQ3_S** (contexto
94.000, sin visión); las nueve primeras son IQ3_XXS y todas corrieron con visión
en GPU (`images: true`), un factor más al comparar entre series.

| Carpeta | Etiqueta interna | Motor / qué probaba |
|---|---|---|
| `iqpc0-control-0.1.49/` | `-iqpc0` (24-10) | 0.1.49 sin banderas (control) |
| `iq3-0150-engine-0.1.50/` | `-iq3-0150` (25-10) | 0.1.50 oficial (control; motor adoptado entonces) |
| `iqgather-0.1.50-flag/` | `-iqgather` (25-10) | 0.1.50 + `STRATA_IQ_GATHER=1` (descartado) |
| `off-0.1.55-control/` | `-0155-off-b` (31-10) | 0.1.55 + ROCm 10.3, GDN **apagado** (control del A/B) |
| `gdn-0.1.55-gdn/` | `-0155-gdn-b` (31-10) | 0.1.55 + ROCm 10.3 + **`STRATA_GDN_CHUNKED=1`** (adoptado) |
| `mtp-0.1.56-control/` | `-mtp-0156-control` (03-11) | 0.1.56 con cabezal MTP (control del A/B del drafter) |
| `df2-0.1.56-draft/` | `-df2-0156-draft` (03-11) | 0.1.56 + **`--draft dflash2`** (adoptado) |
| `engine-0.1.57-ring0/` | `-ring0-0157` (05-11) | 0.1.57 con `STRATA_GFX12_RING=0` (control; usa `--long`, añade 32K) |
| `engine-0.1.57-anillo/` | `-anillo-0157` (05-11) | 0.1.57 con el anillo de prompt por defecto, 256/192/96 (adoptado; usa `--long`) |
| `cachekv-0.1.57-ctrl-iq3s/` | `-ctrl-0157-iq3s` (12-11) | 0.1.57 oficial con **IQ3_S** y contexto 94.000 (control; sin visión) |
| `cachekv-0.1.57.90-iq3s/` | `-test-015790-iq3s` (12-11) | 0.1.57.90 = v0.2.11 + **parche CacheKV del fork kinoyu** (adoptado; sin visión) |
| `long-0.1.57.90-iq3s/` | `-test-015790-iq3s` (13-11) | la misma config de producción, ejecución suelta en frío con `--long` (añade el 32K; no es A/B) |
| `cachekv-0.1.57.90-disk-16384-iq3s/` | `-1128` (14-11) | producción 0.1.57.90 con las dos flags de disco (pareja del parche CacheKV) |
| `cachekv-0.1.57.90-nodisk-16384-iq3s/` | `-1138` (14-11) | la misma config sin las flags de disco (control; única diferencia: 3 argumentos) |
| `engine-0.1.60-iq3s/` | `-1936-0160` (15-11) | motor oficial 0.1.60 con config idéntica al control (no supera el gate: no adoptado) |
| `dconf055-0.1.57.90-iq3s/` | `-2328` (15-11) | 0.1.57.90 con `--draft-conf 0.55` (brazo descartado) |
| `dconf085-0.1.57.90-iq3s/` | `-2333` (15-11) | 0.1.57.90 con `--draft-conf 0.85` (brazo descartado) |
| `vocab-es-nuevo-0.1.57.90-iq3s/` | `-1502` (16-11) | CONTROL VIGENTE: 0.1.57.90 sin disco con el vocab `es-modern` (base de la pareja del 16-11) |
| `specadapt-0.1.57.90-iq3s/` | `-1512` (16-11) | como el control + `STRATA_SPEC_ADAPT_EVERY=2` y `_WARM=200` (sin efecto; descartado) |

Hay siete A/B publicados por parejas, cada uno dentro de su era: el del 31-10 (GDN
chunked), el del 03-11 (DFlash2 frente al cabezal MTP), el del 05-11 (anillo de prompt),
el del 12-11 (KV en disco persistente, el primero sobre IQ3_S), el del 14-11 (coste de la
capa de disco, chunk 16.384), el del 15-11 (barrido de `--draft-conf`) y el del 16-11
(knob `STRATA_SPEC_ADAPT`, control `-1502` frente a brazo `-1512`). Comparar solo dentro
de la misma pareja o de la misma era: arrastran cambios de contexto, runtime o protocolo.
Reglas de esta serie IQ3_S: todas las ejecuciones del 14-11 en adelante corrieron con el
chunk de prompt forzado a **16.384** (`STRATA_GFX12_CHUNK=16`, verificado en el log de
cada run) y con la bandera `STRATA_HC_Q8=0` fija en el `env` de la config —así las tablas
son comparables entre sí—; las anteriores no usaron `--long` salvo las dos del 05-11, y la
del 13-11 es una ejecución suelta que arrancó con ~1 GiB menos de RAM libre y el motor le
bajó el chunk de 16.384 a 8.192 (su 32K es cota baja). El bench envía los prompts con
temperature 0; la producción real usa muestreo (temp 0,6): los porcentajes de borradores
aceptados del bench no son comparables con los del uso diario.

Qué mirar si quieres repetir el experimento: `machine.engine_version`, `context`,
`expert_slots` y `machine.engine_info.images` (deben coincidir con la ejecución que
quieras comparar), y el bloque de resultados por métrica. El `README.md` de cada carpeta es el resumen que generamos en
su momento; el detalle del protocolo (run1 descartada, auditoría del log) está en la
raíz del repo.
