# Resultados y cómo medimos

Este fichero tiene dos bloques separados, porque la caja cambió de base el 18-11:

- **Era actual** (motores propios `0.1.62.9x`, base v0.2.16): lo publicado desde el 19-11.
- **Histórico — era 0.1.57.x** (base v0.2.11 para el motor, del 21-10 al 16-11): todo lo
  publicado hasta el 17-11, tal cual se publicó. Sigue siendo válido para aquella base.

Por qué hay dos bloques y qué cambió entre uno y otro:
[CAMBIO-DE-ERA.md](CAMBIO-DE-ERA.md). **No comparar cifras entre bloques**: son motores
distintos, otro servidor y controles propios. Dentro de cada bloque vale la regla de siempre:
solo comparables las ejecuciones de la misma suite y el mismo chunk de prompt.

## El método (para que nuestros números se puedan comparar y repetir)

- Herramienta: `tools/strata_bench.py` del propio Strata (3 pasadas por cada prueba;
  el informe guarda `results.json` con el esquema "schema 1"). Vocabulario de estos
  textos: un **brazo** es una ejecución de un lado de un A/B; una **era** es cada bloque
  de la serie con su config; una **ancla** es la ejecución de referencia del protocolo.
- **Consola fría**: producción parada, OpenCode/agentes parados, servidor exclusivo de
  la ejecución con su propio log. Scripts: `scripts/0.1.57.x/run-bench.sh` (era anterior)
  y `scripts/0.1.62.9x/run-bench.sh` con sus brazos de bench (era actual).
- 2 ejecuciones por sesión: **run1 = calentamiento (se descarta), run2 = la válida**, tras
  auditar el `server.log` (cero prompts ajenos ≥20k tokens) y el `meta.txt` (engine,
  config con sha256, flags reales).
- Cada celda lleva el estadístico con el que se computó. Donde la tabla no lo dice,
  "chat" es la **media de los 9 requests de conversación** y prefill es la media de sus
  3 pasadas. Las filas del 03-11 y del 05-11 publican **medianas** (de los 9 requests y
  de las 3 pasadas). La línea resumen del script muestra la mediana. No mezclar las dos.
- Del agente se usan dos ventanas distintas según la tabla y cada una lo declara: los
  **18 turnos** completos (3 sesiones de 6) —filas del 14-11— y el agregado del
  `results.json` (`turn_decode_tps`), que **excluye el turno 0 de cada sesión (n=15)**
  —filas del 12-11—. Las dos dan números distintos (p. ej. en el brazo con disco del
  14-11: mediana 79,6 sobre 18 turnos frente a 82,0 sobre n=15).
- No todas las filas tienen muestra publicada en `benches/0.1.57.x/muestras/`: `-anclaje98`,
  `-iqpc1`, toda la serie 27-10→29-10 y las filas del 30-10 no la tienen; esos datos
  viven en el banco privado de la caja.
- Nada de comparar con la serie anterior al 23-10 (aquella se midió "en caliente" y no
  es comparable en absoluto).
- **Cada bloque de la tabla lleva su configuración**: el 26-10 el contexto pasó de
  98.304 a 131.072 y el 27-10 cambió la reserva de VRAM; el 30-10 pasamos a un runtime
  ROCm propio. Comparar entre bloques arrastra esos cambios; dentro de un bloque los
  A/B cambian una sola variable.
- **Visión**: todas las muestras de la serie IQ3_XXS corrieron con visión en GPU
  (`images: true` en su `results.json`) y las de IQ3_S, sin visión (`images: false`).
  La visión en GPU ocupa ~1 GiB de VRAM estable que se resta de la cache de expertos
  (ver [LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md) §"Visión (imágenes) en la GPU").
  Dentro de una misma serie el flag es idéntico en todos los brazos y los A/B valen;
  entre series es un factor más de diferencia junto a la cuantización.

# ERA ACTUAL — motores 0.1.62.9x (base v0.2.16)

## Serie 19-11 (IQ3_S e IQ3_XXS, contexto 94.000, sin visión): control de la era y comparación de compiladores

Cinco ejecuciones con su muestra completa en
[`benches/0.1.62.9x/muestras/`](benches/0.1.62.9x/muestras/) (motivo del corte:
[CAMBIO-DE-ERA.md](CAMBIO-DE-ERA.md)). Los dos motores son **el mismo commit** (`4a7d49cb9`:
v0.2.16 + CacheKV + IL-mmvq); lo único que cambia es el compilador — `0.1.62.90` con el
ROCm del sistema (apt 7.2.1), `0.1.62.91` con el SDK ROCm 10.3 del bundle. Chat = mediana de
los 9 requests; prefill y agente = medianas de sus pasadas.

| Ejecución | Motor | chunk prompt | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|---|
| `ctrl90-…-iq3-s` (19-11) | 0.1.62.90 | 16.384 | 81,3 | 2.469,9 | 3.476,4 | control de la era con IQ3_S |
| `p5-91b-…-iq3-s` (19-11) | **0.1.62.91** | 16.384 | **84,5** | 2.468,5 | **3.522,5** | pareja del control con el motor nuevo |
| `ctrl90-…-iq3-xxs` (19-11) | 0.1.62.90 | 16.384 | 89,2 | 2.605,7 | 3.531,2 | control con IQ3_XXS |
| `p5-91b-…-iq3-xxs` (19-11) | **0.1.62.91** | 16.384 | **92,7** | **2.650,0** | **3.577,6** | pareja del control con el motor nuevo |
| `p5-91-…-iq3-s` (19-11) | 0.1.62.91 | 8.192 | 82,6 | 2.469,9 | 3.245,8 | primera pasada del brazo nuevo; **no comparable** con las de arriba (chunk distinto) |

Lecturas honestas:

- **.91 contra .90 (misma suite y chunk)**: en chat el `.91` gana en los dos modelos
  (+3,9 % IQ3_S, +3,9 % IQ3_XXS) con aceptación de borradores idéntica (75,9 % vs 75,7 % y
  85,7 % vs 85,5 %), así que la diferencia viene del token por sí mismo, no de los borradores.
  En prefill: +1,3 % en 16K en ambos, −0,1 %/+1,7 % en 4K (ruido). En agente el resultado es
  **desigual**: mediana agrupada de decode −5,2 % con IQ3_S (84,1 → 79,7) y +10,5 % con
  IQ3_XXS (86,7 → 95,8), movida por la aceptación de borradores del agente (61,7→56,9 y
  67,7→71,4 %). Con una sola pareja de ejecuciones **no podemos atribuir ni ganancias ni
  pérdidas**: lo que queda medido es que no hay una caída sistemática en todas las métricas.
- Decisión derivada (allí, ADR-U02): quedarse con el `.91` (SDK 10.3, el entorno real de la
  caja) y conservar el `.90` instalado como vuelta atrás. La verificación que sí fue dura es
  la de paridad: mismo commit compilado de dos formas pasa el control de paridad bit a bit IL.
- **Configuración de estas medidas**: pack del borrador antiguo (`dflash2.q4_0.pack`) y
  temperature 0 del bench. La producción cambió después de pack y muestreo; hasta que no haya
  una serie con esa configuración, estas cifras describen cómo se construyó y validó la era,
  no lo que rinde hoy la producción.

# HISTÓRICO — era 0.1.57.x (publicado hasta el 17-11)

Todo lo que sigue es la documentación de la era anterior, tal como se publicó. Es válido para
aquellos motores (línea local con base v0.1.45; los últimos sobre etiquetas oficiales hasta
v0.2.11 + CacheKV + IL-mmvq). **No comparar estas tablas con las de arriba.**

## Serie 23-10 → 25-10 (IQ3_XXS, contexto 98.304, wheels 7.10)

| Ejecución (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-anclaje98` (23-10) | 0.1.48 | 74,6 | 1.957,7 | 2.409,4 | referencia del protocolo |
| `-iqpc0` (24-10) | 0.1.49 | **78,1** | 1.924,1 | 2.375,1 | control A/A del día del popcount |
| `-iqpc1` (24-10) | 0.1.49 | 76,9 | 1.926,2 | 2.384,3 | + `STRATA_IQ_POPCOUNT=1` → descartado |
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
- 0.1.49 → 0.1.50 (comparando los controles de cada día, con la reserva de "días
  distintos"): chat −0,3 %, 4K +1,3 %, 16K +0,4 % → **neutral**, y por eso el motor
  oficial se quedó.
- Las muestras completas de `-iqpc0`, `-iq3-0150` e `-iqgather` están en
  [benches/0.1.57.x/muestras/](benches/0.1.57.x/muestras/) (cada una con su `results.json`).

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

| Ejecución (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
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

| Ejecución (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-0154-plain` / `-b` (30-10) | 0.1.54 | 80,4 / 79,2 | 2.009,3 / 1.974,0 | 2.793,5 / 2.783,9 | wheels 7.10, control |
| `-0154-specp70-a/-b` (30-10) | 0.1.54 | −0,1 % / +2,4 % | plano | plano | `--spec-min-p 0.70` → neutro, se queda 0,50 |
| `-rocm10-100401` (30-10) | 0.1.54 | 83,3 | 1.919,0 | 2.763,1 | ROCm 10.1 + tabla 100401 |
| `-rocm103-100500` (30-10) | 0.1.54 | 83,2 | 1.961,6 | 2.805,1 | ROCm 10.3 + tabla 100500 → **adoptado** |
| `-0155-off-a/-b` (31-10) | 0.1.55 | 81,8 / 82,3 | 1.932,6 / 1.953,0 | 2.791,1 / 2.801,6 | GDN apagado (control del día) |
| `-0155-gdn-a/-b` (31-10) | 0.1.55 | 80,5 / 81,7 | **2.050,8 / 2.025,1** | **2.977,0 / 2.966,1** | `STRATA_GDN_CHUNKED=1` → **+6,1 %/+3,7 % 4K, +6,7 %/+5,9 % 16K, adoptado** |

De las filas del 31-10 hay muestra publicada (`off-0.1.55-control/`, `gdn-0.1.55-gdn/`,
corresponden a las ejecuciones `-b`); sus celdas de chat y prefill son **medias** (de los
9 requests y de las 3 pasadas). Las cuatro filas del 30-10 no tienen muestra publicada.

Lecturas:

- **GDN chunked gfx12** (motor 0.1.55) es la ganancia de prefill más grande de todas las
  medidas aquí, y viene de serie en A/B del mismo día: 4K **+6,1 %/+3,7 %**, 16K
  **+6,7 %/+5,9 %**, primer token −4 %/−6 %, chat −1,6 %/−0,7 % (dentro del ruido de
  ±1,5 % del motor) y agente sin cambio.
- El runtime ROCm propio (30-10) dio chat **+3,5 %** y agente **+2,5 %** con prefill casi
  igual (el +2,5 % no se deriva de la tabla de [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §6,
  donde el agente va de 80,6 a 81,1: +0,6 %; queda como cifra adicional sin desglose
  publicado, porque estas ejecuciones no tienen muestra en `benches/0.1.57.x/muestras/`);
  el 10.1 pagaba −4,4 % en 4K y el 10.3 lo recuperó (+2,2 % de 4K sobre el 10.1).
  Ver [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) y la premisa gfx1201 desmentida en
  [HARDWARE.md](HARDWARE.md).
- `0155-off` cae dentro de la banda del control `-rocm103-100500` (−1,7 % de chat como
  peor caso): el motor nuevo no aporta ni cuesta por sí solo; lo que aporta es GDN.

## Serie 03-11 → 05-11 (0.1.56: drafter DFlash2; 0.1.57: anillo de prompt)

El 03-11, A/B en el mismo día del drafter **DFlash2** (pack `q4_0` dedicado,
`--draft-fallback none`, `--draft-conf 0.7`) contra el cabezal MTP de siempre. El 05-11,
con el motor **0.1.57** instalado, A/B del **anillo de preparación de prompt de gfx12**
(256/192/96 ranuras por defecto; control: `STRATA_GFX12_RING=0`). Las ejecuciones del 05-11 usan `strata_bench.py --long`,
que añade el prompt de 32K; las anteriores no son comparables en esa métrica. Muestras
completas en [benches/0.1.57.x/muestras/](benches/0.1.57.x/muestras/).

| Ejecución (etiqueta) | Motor | chat tok/s | 4K tok/s | 16K tok/s | Qué era |
|---|---|---|---|---|---|
| `-mtp-0156-control` (03-11) | 0.1.56 | 77,0 | 2.046,1 | 3.041,5 | cabezal MTP (control del A/B) |
| `-df2-0156-draft` (03-11) | 0.1.56 | **81,2** | 2.040,8 | 3.071,4 | `--draft dflash2` → **+5,5 % chat (mediana)**, 4K/16K planos, **adoptado** |
| `-ring0-0157` (05-11) | 0.1.57 | 79,3 | 2.098,0 | 3.099,6 | `STRATA_GFX12_RING=0` (control); 32K: 3.067,2 |
| `-anillo-0157` (05-11) | 0.1.57 | 82,2 | **2.322,6** | 3.098,8 | anillo por defecto de 0.1.57 (256/192/96) → **4K +10,7 %**, **adoptado**; 32K: 3.055,5 |

Lecturas:

- **DFlash2** sube la mediana de chat un +5,5 % pero con rangos anchos (69,4-126,2
  frente a 71,2-97,7 del control): la ganancia existe, y la varianza del
  borrador también. 4K y 16K quedan planos.
- El **anillo profundo** solo se nota en 4K (+10,7 %); en 16K y 32K queda dentro del
  ruido (±0,2 %). El primer token de 4K baja de 1,94 a 1,75 s; el de 32K se queda en
  ~10,5 s.

## Medida de producción y coste del KV en disco (14-11, con **IQ3_S**, contexto 94.000, chunk 16.384)

Producción: motor **0.1.57.90** con el parche CacheKV y sus dos flags de disco activas
(`--conversation-cache-dir`, `--conversation-cache-persist`), drafter **DFlash2**, sin visión,
ROCm 10.3 propio. El 14-11 se corrió la pareja que mide lo que cuesta llevar el KV en disco:
brazo con disco (idéntico a la producción) contra brazo sin disco, misma config salvo los
3 argumentos de disco, suite `--long` y `STRATA_GFX12_CHUNK=16` forzado. Los dos brazos
quedaron auditados: chunk 16.384, ring 96, cero fallos de carga. Números del run2 (el válido):

| Métrica | con disco (producción) | sin disco |
|---|---|---|
| chat tok/s (media de los 9) | 88,1 | **89,1** |
| chat tok/s (mediana) | 79,5 (72,2-112,4) | 79,8 (71,9-115,0) |
| borradores aceptados | 78,5 % | 77,4 % |
| prefill 4K tok/s · primer token | 2.499,5 · 1,63 s | 2.507,9 · 1,63 s |
| prefill 16K tok/s · primer token | 3.502,0 · 4,61 s | 3.499,7 · 4,62 s |
| prefill 32K tok/s · primer token | 3.463,3 · 9,29 s | 3.461,0 · 9,28 s |
| agente tok/s (media, 18 turnos) | 82,5 | **83,7** |
| agente tok/s (mediana, 18 turnos) | 79,6 | 82,0 |

Lectura: el disco cuesta alrededor de **un 1 % de chat en la media** (las medianas quedan
dentro del ruido) y en el agente entre un 1,4 % (media) y un 2,9 % (mediana), ambas sobre
los 18 turnos. El mecanismo se
ve en el log del brazo con disco: **79 escrituras de espejo de 120-140 ms** al cerrar cada
respuesta. El coste está en escribir el espejo, no en leer: el prefill y el acierto de expertos
quedan planos entre brazos (acierto de expertos 69,7 % en los dos). Y es una prima de seguro:
lo que cubre no aparece en un bench en frío, porque el bench no reinicia a mitad. Con las
flags activas, tras un arranque en frío el primer request deja de pagar el prefill de la
conversación: 894 ms de relectura desde disco frente a ~9 s de prefill en frío de un prompt
equivalente (medido con reinicio, no con `strata_bench.py`). Decisión del 14-11: **se mantiene
el disco**, con el coste medido y conocido. Muestras:
[benches/0.1.57.x/muestras/cachekv-0.1.57.90-disk-16384-iq3s/](benches/0.1.57.x/muestras/cachekv-0.1.57.90-disk-16384-iq3s/)
y [benches/0.1.57.x/muestras/cachekv-0.1.57.90-nodisk-16384-iq3s/](benches/0.1.57.x/muestras/cachekv-0.1.57.90-nodisk-16384-iq3s/).
Controles de la serie: `2026-11-14-1128-kvdisk-chunk16384-iq3-s` y
`2026-11-14-1138-nodisk-chunk16384-iq3-s`.

## Gate del motor 0.1.60 y barrido de `--draft-conf` (15-11)

**Motor 0.1.60 (el de v0.2.14/0.2.15): instalado y NO adoptado.** El brazo corrió con la copia
exacta del control sin disco del 14-11 (misma config, solo motor y librerías nuevos; chunk
16.384 auditado; suite `--long`). Frente a ese control, en el run2 válido (positivo = brazo
más lento): chat **+0,78 %**, 16K +1,37 %, 32K **+9,36 %**, agente **+5,28 %**. Estos
cuatro números son **medias** (chat: media de los 9 requests; 16K/32K: media de la
**decodificación** de esos requests en sus 3 pasadas; agente: media de los 18 turnos).
Por medianas la señal de 32K se invierte: la decodificación mediana del brazo es 63,9
frente a 63,4 del control —un 0,8 % **más rápido**—, y el +9,36 % lo fabrica la pasada 1
(51,1, con solo 5/11 borradores aceptados, frente a 62,5 del control). La «segunda
ejecución» donde se repetiría la señal no está entre las muestras publicadas.
El gate
pre-registrado de no-regresión falló por el agente y el 16K, y la señal más fuerte se repite
en las dos ejecuciones realizadas: decodificación a 32K entre −6,7 % y −9,4 %. A cambio, los
borradores aceptados subieron +1,0/+1,4 puntos y el resto quedó dentro del ruido. Vista la
dependencia del estadístico, la decisión de no adoptar se sostiene sobre el agente y el
16K; la señal de 32K requiere re-ejecutar 0.1.60 con dos brazos válidos antes de citarse.
La producción sigue en 0.1.57.90. Muestra: [benches/0.1.57.x/muestras/engine-0.1.60-iq3s/](benches/0.1.57.x/muestras/engine-0.1.60-iq3s/).

**`--draft-conf` 0,55 y 0,85: rechazados, se mantiene 0,7.** Pareja del 15-11 (23:28 y 23:33)
contra el mismo control sin disco (chunk 16.384 auditado; cada brazo difiere en una sola
variable). Run2 frente al control (positivo = más lento): 0,55 → chat **+1,85 %**, agente
+2,74 %, borradores 68,3 %; 0,85 → chat **+3,01 %**, agente +6,58 %, borradores 87,8 % (control
77,4 %). Los dos brazos fallan el gate; ambos prefills quedan neutros. Inferencia (etiquetada,
no medida): 0,7 está cerca del óptimo local. Muestras:
[benches/0.1.57.x/muestras/dconf055-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/dconf055-0.1.57.90-iq3s/) y
[benches/0.1.57.x/muestras/dconf085-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/dconf085-0.1.57.90-iq3s/). Una pareja previa de 23:13/23:20
quedó inválida: el motor del bench bajó el chunk a 8.192 porque la ventana de producción
ocupaba RAM. Regla que quedó de ahí: cerrar la ventana de producción antes de cada bench.

## Vocabulario de borradores nuevo y el lever `SPEC_ADAPT` (16-11)

**Vocab nuevo del drafter (español moderno), adoptado con atribución incompleta.** El
archivo `data/draft_vocab_es-modern.bin` (47.047 ids) sustituyó en la producción al vocabulario
en inglés del drafter. El control vigente de la serie es desde el 16-11 la ejecución
`2026-11-16-1502-ctrl-nuevo-vocab-chunk16384-iq3-s` (chunk 16.384 auditado, sin disco): chat media 87,6,
mediana 80,0, borradores aceptados 79,1 %. Frente al control anterior sin disco (14-11):
borradores **+1,7 puntos** (79,1 vs 77,4), pero chat −1,7 % y agente entre **−5,9 % y
−7,2 % según la ventana de turnos** (18 turnos: 78,5 frente a 83,7 = −6,2 %; agregado
n=15 del JSON: −7,2 %). Son días
distintos y todos los brazos del 16-11 comparten el vocab nuevo: **la atribución no es
separable** y la duda queda declarada. Muestra: [benches/0.1.57.x/muestras/vocab-es-nuevo-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/vocab-es-nuevo-0.1.57.90-iq3s/).

**`STRATA_SPEC_ADAPT_EVERY`/`_WARM`: sin efecto, lever cerrado.** Dos parejas independientes
del mismo día (14:37/14:48 y 15:02/15:12) dieron signos invertidos entre pasadas del propio
bench (la pasada 1 marcaba el brazo más lento y la 2 más rápido, con magnitudes de 1-9 %):
firma de ruido, comparable al spread interno del control. Nada que llevar a la producción.
Muestra: [benches/0.1.57.x/muestras/specadapt-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/specadapt-0.1.57.90-iq3s/).

**Regla de eras que quedó de este día:** la pareja de las 14:37/14:48 no alcanzó chunk 16.384
(el guard de RAM del motor lo bajó a 8.192 pese a la ventana cerrada: faltaban ~2,7 GiB
libres) y no es comparable con las ejecuciones de 16.384. Las muestras publicadas de
16-11 son las de la pareja re-lanzada a 16.384.

## Medida de producción anterior (12-11, con **IQ3_S**, contexto 94.000)

Motor **0.1.57.90** (v0.2.11 + el parche CacheKV del fork kinoyu, ver
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §10) + `STRATA_GDN_CHUNKED=1` + `STRATA_EXPDEC=0` +
`STRATA_PREFILL_CPU_SHARE=0` + drafter **DFlash2**, **sin visión**, sobre ROCm 10.3 propio.
Números de la ejecución auditada `run2` de la pareja del 12-11 (muestra
`benches/0.1.57.x/muestras/cachekv-0.1.57-ctrl-iq3s/`; la otra columna es el brazo `.90`, y entre
ellas todas las diferencias están dentro del ruido — lo que aporta el parche es el
prefill tras reinicio, no el tok/s):

| Métrica | 0.1.57 oficial | 0.1.57.90 (producción) |
|---|---|---|
| chat tok/s (mediana de 9) | 78,0 (70,1-109,3) | 79,0 (74,6-110,1) |
| chat tok/s (media de los 9) | 86,6 | 88,2 |
| prefill 4K tok/s · primer token | 2.441,8 · 1,67 s | 2.437,8 · 1,67 s |
| prefill 16K tok/s · primer token | 3.457,1 · 4,67 s | 3.461,1 · 4,67 s |
| prefill 32K tok/s · primer token † | — | 3.161,1 · 10,17 s |
| agente tok/s (mediana, 15 turnos) | 86,8 | 88,0 |
| agente acierto de caché | 69,78 % | 69,74 % |

† El 32K no lo midió la pareja del 12-11 (no usó `--long`). Lo midió el 13-11 una ejecución
de banco en frío con `--long`, con la misma config de producción y la producción intacta
en otro puerto
([benches/0.1.57.x/muestras/long-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/long-0.1.57.90-iq3s/): media
3.163,4, rango 3.156,7-3.172,5). Ojo con la comparación: en esa ejecución quedaban ~8,8 GiB
libres de RAM al arrancar (en la del 12-11, ~9,8) y el motor bajó solo el tamaño de chunk
de prompt de 16.384 a 8.192; en ese mismo run el 16K dio 3.220 tok/s, un 6,7 % por debajo
del valor de la tabla. El 32K hay que leerlo como **cota baja** en esas condiciones de
memoria. Aun así supera en ~3,4 % al 3.055,5 de la config anterior con IQ3_XXS y anillo
profundo (05-11). El resto de métricas de esa ejecución cuadra con la tabla: chat 88,4 de
media y 80,3 en la mediana, acierto del agente 69,74 %; la decodificación por turno del
agente salió más baja (79,6 de mediana frente a 88,0), pero es la métrica más ruidosa de
todas (depende de cuántos borradores acepta el drafter en cada turno) y no la usamos para
nada.

Y la consecuencia práctica, comprobada el 14-11 a las 09:35: la producción se había
relanzado a las 09:22 y llevaba ~13 min con **3,3 GiB disponibles** y 53 GB de RSS. Con tan poca RAM libre al arrancar,
lo esperable es que el motor también le haya bajado el chunk de prompt. El endpoint no
expone ese estado (solo `/health` y `/v1/models`), así que lo dejamos como sospecha sin
afirmar: para confirmarlo habría que relanzar la producción con más RAM libre o mirar el
log de esa sesión.

Con las dos flags del CacheKV
activas, el primer request tras un arranque en frío deja de pagar el prefill de la
conversación: `41612 reused + 36 read en 894 ms` frente a los ~9 s de prefill frío de un
prompt equivalente (medido con reinicio, no con `strata_bench.py`).

## Medida de producción anterior (05-11, con IQ3_XXS, contexto 131.072)

Motor **0.1.57** + `STRATA_GDN_CHUNKED=1` + `STRATA_EXPDEC=0` + drafter **DFlash2** sobre
ROCm 10.3 propio (medias de `-anillo-0157`, con `--long`): chat **82,2** tok/s (rango
74,7-125,3), prefill **2.322,6** (4K), **3.098,8** (16K) y **3.055,5** (32K), primer
token **1,75 s / 5,21 s / 10,52 s**.

Nota: desde el 12-11 la producción es **IQ3_S** (ver la sección anterior). Las medidas de
las secciones de series corresponden a **IQ3_XXS**; la única excepción son las dos ejecuciones
del 12-11, sobre IQ3_S con contexto 94.000. La medida informal del 26-10 (sobre
**IQ3_XXS**, con la config de entonces; unos días antes de que IQ3_S entrara en
producción; ~+17 % en 16K) quedó desfasada: ver [PASOS.md](PASOS.md).
La flag `STRATA_SELECT_WMMA=1` que la acompañaba sigue activa en las dos configs de
producción como decisión anterior a esa evidencia: el A/B formal nunca se hizo.

El estado anterior (31-10, motor 0.1.55): chat 80,5-81,7, prefill 2.025-2.051 (4K) y
2.966-2.977 (16K), primer token 1,98-2,01 s / 5,42-5,46 s; medida puntual del servidor
real (no del bench) aquel día: respuesta completa en ~1,2 s para un prompt corto.
