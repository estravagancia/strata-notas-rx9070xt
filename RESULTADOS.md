# Resultados y cómo medimos

## El método (para que nuestros números se puedan comparar y repetir)

- Herramienta: `tools/strata_bench.py` del propio Strata (3 pasadas por cada prueba;
  el informe guarda `results.json` con el esquema "schema 1").
- **Consola fría**: producción parada, OpenCode/agentes parados, servidor exclusivo de
  la corrida con su propio log. Script: `scripts/run-bench.sh`.
- 2 corridas por sesión: **run1 = calentamiento (se descarta), run2 = la válida**, tras
  auditar el `server.log` (cero prompts ajenos ≥20k tokens) y el `meta.txt` (engine,
  config con sha256, flags reales).
- El "chat" de las tablas es la **media de los 9 requests de conversación** del bench;
  la línea resumen del script muestra la **mediana**. No mezclar las dos.
- Nada de comparar con la serie anterior al 23-10 (aquella se midió "en caliente" y no
  es comparable en absoluto).
- **Cada bloque de la tabla lleva su configuración**: el 26-10 el contexto pasó de
  98.304 a 131.072 y el 27-10 cambió la reserva de VRAM; el 30-10 pasamos a un runtime
  ROCm propio. Comparar entre bloques arrastra esos cambios; dentro de un bloque los
  A/B cambian una sola variable.

## Serie 23-10 → 25-10 (IQ3_XXS, contexto 98.304, wheels 7.10)

| Corrida (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-anclaje98` (23-10) | 0.1.48 | 74,6 | 1.957,7 | 2.409,4 | referencia del protocolo |
| `-iqpc0` (24-10) | 0.1.48.1 | **78,1** | 1.924,1 | 2.375,1 | control A/A del día del popcount |
| `-iqpc1` (24-10) | 0.1.48.1 | 76,9 | 1.926,2 | 2.384,3 | + `STRATA_IQ_POPCOUNT=1` → descartado |
| `-iq3-0150` (25-10) | **0.1.50** | 77,8 | **1.949,3** | **2.385,5** | motor oficial → **neutral, adoptado** |
| `-iqgather` (25-10) | 0.1.50 | 76,7 | 1.949,9 | 2.385,5 | + `STRATA_IQ_GATHER=1` → descartado |

Lecturas honestas:

- **No mezcles la columna "chat" entre días**: `-anclaje98` publica la mediana del
  script y `-iqpc0`/`-iq3-0150` publican la media de los 9 requests; restarlas tal cual
  da falsos +4 %. La comparación cuidada de ese cruce de días dio chat **+0,3 %**
  (y −1,7 % / −1,4 % en prefill), arrastrando además un cambio de flags de caché
  posterior al `-anclaje98`. Ese ancla solo sirve dentro de su propio día.
- Los dos A/B limpios (mismo día, misma config, una sola variable) son
  `-iqpc0` vs `-iqpc1` (24-10) y `-iq3-0150` vs `-iqgather` (25-10).
- 0.1.48.1 → 0.1.50 (comparando los controles de cada día, con la reserva de "días
  distintos"): chat −0,3 %, 4K +1,3 %, 16K +0,4 % → **neutral**, y por eso el motor
  oficial se quedó.
- Las muestras completas de `-iqpc0`, `-iq3-0150` e `-iqgather` están en
  [benches/muestras/](benches/muestras/) (cada una con su `results.json`).

## La ganancia de las tablas de ajuste (el 21-10, motor 0.1.47)

Comparativa publicada en el parche C2 (medida antes del protocolo en frío; los dos runs
usaron contexto distinto, 100.000 vs 105.000, por eso el "chat" sale mezclado y solo los
números de prefill son limpios):

| Métrica | sin tabla | con tabla (67 filas) |
|---|---|---|
| prefill 4K tok/s | 1.965,9 | **1.989,5 (+1,2 %)** |
| prefill 16K tok/s | 2.398,4 | **2.445,9 (+2,0 %)** |
| primer token (4K) | 2,065 s | 2,042 s |
| chat tok/s | 71,4 | 70,6 (mezclado con el contexto, achacar con cuidado) |

## Serie 27-10 → 29-10 (IQ3_XXS, contexto 131.072, wheels 7.10, config "ADR-017")

La config pasa a: contexto 131.072, `--spec-min-p 0.50`, reserva 1.536 MiB, `--kv int8`,
`--kv-resident 16384`, `STRATA_EXPDEC=0`, `STRATA_PLE_AUTO_RAM=0`, `STRATA_HIP_WMMA=1`.

| Corrida (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-0150-control` (27-10) | 0.1.50 | 79,1 | 2.002,4 | 2.789,8 | control de la config nueva |
| `-0152-new` (27-10) | 0.1.52 | 72,1 | — | — | defaults nuevos de gfx12 → **−8,8 % chat**, no adoptado |
| `-0152-026` (27-10) | 0.1.52 | 79,3 | — | — | `STRATA_DEFAULTS=026` → neutro |
| `-0152-kernelsoff` (27-10) | 0.1.52 | 77,7 | — | — | sin kernels nuevos |
| `0152-off-expdec` (27-10) | 0.1.52 | 79,4-82,1 | — | — | `STRATA_EXPDEC=0` → **+2,1 % chat, adoptado** |
| `-ctrl0152c` (29-10) | 0.1.52 | 78,1 / 78,1 | 1.988,4 | 2.778,1 | control del día |
| `-262k-a` / `-262k-b` (29-10) | 0.1.52 | 56,0 / 56,6 | 1.988 | 2.778 | contexto 262k + `--pcie-frac 0` + `--adapt-every 0` → **−28 % chat**, rollback |

## Serie 30-10 → 31-10 (runtime ROCm propio, tabla 100500)

El 30-10 el motor oficial corre sobre un runtime ROCm propio (10.1 y luego 10.3 nightly,
hipBLASLt 1.5.0) sin recompilar; el 31-10 llega el motor 0.1.55 con la ruta GDN chunked
en gfx12.

| Corrida (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-0154-plain` / `-b` (30-10) | 0.1.54 | 80,4 / 79,2 | 2.009,3 / 1.974,0 | 2.793,5 / 2.783,9 | wheels 7.10, control |
| `-0154-specp70-a/-b` (30-10) | 0.1.54 | −0,1 % / +2,4 % | plano | plano | `--spec-min-p 0.70` → neutro, se queda 0,50 |
| `-rocm10-100401` (30-10) | 0.1.54 | 83,3 | 1.919,0 | 2.763,1 | ROCm 10.1 + tabla 100401 |
| `-rocm103-100500` (30-10) | 0.1.54 | 83,2 | 1.961,6 | 2.805,1 | ROCm 10.3 + tabla 100500 → **adoptado** |
| `-0155-off-a/-b` (31-10) | 0.1.55 | 81,8 / 82,3 | 1.932,6 / 1.953,0 | 2.791,1 / 2.801,6 | GDN apagado (control del día) |
| `-0155-gdn-a/-b` (31-10) | 0.1.55 | 80,5 / 81,7 | **2.050,8 / 2.025,1** | **2.977,0 / 2.966,1** | `STRATA_GDN_CHUNKED=1` → **+6,1 %/+3,7 % 4K, +6,7 %/+5,9 % 16K, adoptado** |

Lecturas:

- **GDN chunked gfx12** (motor 0.1.55) es la ganancia de prefill más grande de todas las
  medidas aquí, y viene de serie en A/B del mismo día: 4K **+6,1 %/+3,7 %**, 16K
  **+6,7 %/+5,9 %**, primer token −4 %/−6 %, chat −1,6 %/−0,7 % (dentro del ruido de
  ±1,5 % del motor) y agente sin cambio.
- El runtime ROCm propio (30-10) dio chat **+3,5 %** y agente **+2,5 %** con prefill casi
  igual; el 10.1 pagaba −4,4 % en 4K y el 10.3 lo recuperó (+2,2 % de 4K sobre el 10.1).
  Ver [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) y la premisa gfx1201 desmentida en
  [HARDWARE.md](HARDWARE.md).
- `0155-off` cae dentro de la banda del control `-rocm103-100500` (−1,7 % de chat como
  peor caso): el motor nuevo no aporta ni cuesta por sí solo; lo que aporta es GDN.

## Serie 03-11 → 05-11 (0.1.56: drafter DFlash2; 0.1.57: anillo de prompt)

El 03-11, A/B en el mismo día del drafter **DFlash2** (pack `q4_0` dedicado,
`--draft-fallback none`, `--draft-conf 0.7`) contra el cabezal MTP de siempre. El 05-11,
con el motor **0.1.57** instalado, A/B del **anillo de preparación de prompt más
profundo** (control: anillo en 0). Las corridas del 05-11 usan `strata_bench.py --long`,
que añade el prompt de 32K; las anteriores no son comparables en esa métrica. Muestras
completas en [benches/muestras/](benches/muestras/).

| Corrida (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-mtp-0156-control` (03-11) | 0.1.56 | 77,0 | 2.046,1 | 3.041,5 | cabezal MTP (control del A/B) |
| `-df2-0156-draft` (03-11) | 0.1.56 | **81,2** | 2.040,8 | 3.071,4 | `--draft dflash2` → **+5,5 % chat (mediana)**, 4K/16K planos, **adoptado** |
| `-ring0-0157` (05-11) | 0.1.57 | 79,3 | 2.098,0 | 3.099,6 | anillo en 0 (control); 32K: 3.067,2 |
| `-anillo-0157` (05-11) | 0.1.57 | 82,2 | **2.322,6** | 3.098,8 | anillo más profundo → **4K +10,7 %**, **adoptado**; 32K: 3.055,5 |

Lecturas:

- **DFlash2** sube la mediana de chat un +5,5 % pero con rangos anchos (69,4-126,2
  frente a 71,2-97,7 del control): la ganancia existe, y la varianza del
  borrador también. 4K y 16K quedan planos.
- El **anillo profundo** solo se nota en 4K (+10,7 %); en 16K y 32K queda dentro del
  ruido (±0,2 %). El primer token de 4K baja de 1,94 a 1,75 s; el de 32K se queda en
  ~10,5 s.

## Medida de producción actual (05-11, con IQ3_XXS, contexto 131.072)

Motor **0.1.57** + `STRATA_GDN_CHUNKED=1` + `STRATA_EXPDEC=0` + drafter **DFlash2** sobre
ROCm 10.3 propio (medias de `-anillo-0157`, con `--long`): chat **82,2** tok/s (rango
74,7-125,3), prefill **2.322,6** (4K), **3.098,8** (16K) y **3.055,5** (32K), primer
token **1,75 s / 5,21 s / 10,52 s**.

Nota: la producción alterna **IQ3_XXS** e **IQ3_S**. Todas las medidas de este archivo
corresponden a IQ3_XXS; no hay bench auditado de IQ3_S (solo la medida informal del 26-10,
ver [PASOS.md](PASOS.md)).

El estado anterior (31-10, motor 0.1.55): chat 80,5-81,7, prefill 2.025-2.051 (4K) y
2.966-2.977 (16K), primer token 1,98-2,01 s / 5,42-5,46 s; medida puntual del servidor
real (no del bench) aquel día: respuesta completa en ~1,2 s para un prompt corto.
