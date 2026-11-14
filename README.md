# Strata en una RX 9070 XT (Linux): notas de una caja real

Esto **no es un fork ni un parche oficial**: son las notas de lo que hicimos funcionar (y
lo que no) para montar [Strata](https://github.com/Niko1221/Strata) en un PC de casa con
gráfica AMD **Radeon RX 9070 XT** y Linux. Si tienes una tarjeta RDNA 4 o una RDNA 3.5,
seguramente te sirva tal cual: el caso raro de esta caja (la tarjeta se reporta con el
nombre de arquitectura "hermano") es más común de lo que parece.

Todos los números son **medidos en esta caja**, con la fecha y la versión del motor que
los produjo. Donde no hay medida, lo decimos.

## Qué consiguió esta caja

La producción de esta caja es hoy **Qwen3.8-Flash-Next en IQ3_S** (83,6 GB en disco), con
**IQ3_XXS** (75,8 GB) como alternativa para contexto más largo; las dos configs están en
[configs/](configs/). Los números siguientes están medidos en **IQ3_S** con el motor
**0.1.57.90** (la etiqueta v0.2.11 + un parche de un fork ajeno, ver
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §10), 16 GiB de VRAM y ~60 GB de RAM, sobre un
runtime **ROCm 10.3 propio** (ver más abajo). Es la corrida auditada `run2` del brazo de
producción del 12-11 (`benches/muestras/cachekv-0.1.57.90-iq3s/`, con su control
0.1.57 oficial al lado); las de **IQ3_XXS** (contexto 131.072, del 05-11) siguen en
[RESULTADOS.md](RESULTADOS.md):

| Métrica | Valor |
|---|---|
| Escritura tipo chat (dominio común) | **~88 tokens/s** de media de la corrida (mediana 79,0; rango 74,6-110,1) |
| Relectura de un texto de 4.000 tokens | **~2.440 tokens/s** (empieza a responder en ~1,67 s) |
| Relectura de 16.000 tokens | **~3.460 tokens/s** (primer token en ~4,67 s) |
| Relectura de 32.000 tokens | **~3.160 tokens/s** (primer token en ~10,2 s; medido el 13-11, cota baja, ver [RESULTADOS.md](RESULTADOS.md)) |
| Contexto máximo | 94.000 tokens en IQ3_S (131.072 con IQ3_XXS) |
| Reinicio con la conversación abierta | prefill **−92,7 %** (el KV se restaura del disco) |

Sobre esas cifras: el chat es la media y la mediana de la misma corrida auditada; en el uso
diario con borradores aceptados se cae en la parte alta del rango (ese ~94 tokens/s que
pubblicamos antes era una estimación típica del uso, no una medida). La fila de 32K no
viene de la pareja del 12-11 (esa no usó `--long`): la midió el 13-11 una corrida de
banco de pruebas en frío con `--long`, con la misma config de producción y la producción
intacta (puerto aparte). En esa corrida quedaban ~8,8 GiB libres de RAM al arrancar, y el
motor bajó solo el tamaño de chunk de prompt de 16.384 a 8.192; por eso su 16K salió ~7 %
por debajo del de la tabla y el 32K hay que leerlo como **cota baja**. La muestra auditada
está en [benches/muestras/long-0.1.57.90-iq3s/](benches/muestras/long-0.1.57.90-iq3s/).
Como referencia histórica: la config anterior con IQ3_XXS y anillo profundo (05-11) daba
~3.055 tokens/s en 32K. Los porcentajes de DFlash2 (+12 %/+13 %) y del anillo (+11 %/+14 %) son
estimaciones previas al A/B; las ganancias auditadas de esos A/B son **+5,5 % de chat
(mediana)** y **+10,7 % en 4K**, con sus tablas en [RESULTADOS.md](RESULTADOS.md).

Las cuatro ganancias grandes medidas aquí vienen de upstream o de un fork ajeno, y están
cada una en su fecha: la ruta **GDN chunked con tensor cores en gfx12** (motor 0.1.55:
+6 % en 4K y +6 % en 16K), el **drafter DFlash2** en lugar del cabezal predictor (motor
0.1.56: **+12 %/+13 % en chat**, con el borrador ya en cuartos), el **anillo de
preparación de prompt más profundo** (motor 0.1.57: **+11 %/+14 % en 4K**) y el **KV en
disco que sobrevive a los reinicios** (parche CacheKV del fork kinoyu-ai, 12-11:
**−92,7 % del prefill tras arrancar**, que en el bench continuo no se ve). Y una quinta,
menos obvia: el motor oficial corre **sin recompilar** sobre wheels de ROCm más nuevos que
los que empaqueta la release. Todo, en frío y con su tabla en [RESULTADOS.md](RESULTADOS.md)
y [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md).

Lo interesante no es la cifra, sino **por qué** se llegó a ella y qué experimentos
quedaron por el camino: hay una lista de cosas que mejoraron de verdad y una lista, más
larga y más útil, de cosas que se midieron y **no** mejoraron nada.

## Por dónde empezar

1. [HARDWARE.md](HARDWARE.md) — qué PC es este y la rareza de la arquitectura gfx1200/gfx1201.
2. [PASOS.md](PASOS.md) — la cronología completa, de cero a producción, con enlaces.
3. [RESULTADOS.md](RESULTADOS.md) — las tablas de rendimiento y cómo medimos (para que
   puedas comparar tus propios números con los nuestros).
4. [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) y [LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md) —
   el resultado de cada experimento, positivos y negativos.
5. [patches/](patches/) — los 2 parches que preparamos para Strata (aún no enviados),
   el endurecimiento de seguridad del servidor, un ajuste de vocabulario en español y el
   parche CacheKV de un fork ajeno tal como lo aplicamos (sí en producción).
6. [configs/](configs/) y [scripts/](scripts/) — la configuración real y los scripts de
   medidas (bench en frío, y el test con reinicio que necesita el KV en disco).
7. [benches/muestras/](benches/muestras/) — 11 mediciones completas para que audites las tablas.
8. [CREDITOS.md](CREDITOS.md) — de dónde viene cada pieza.

## Estado actual (12-11-2026)

Motor **propio `0.1.57.90`** = etiqueta oficial v0.2.11 (motor 0.1.57) + el parche CacheKV
del fork kinoyu-ai, con las flags `--conversation-cache-dir` y `--conversation-cache-persist`
activas; `STRATA_GDN_CHUNKED=1`, `STRATA_EXPDEC=0`, `STRATA_PLE_AUTO_RAM=0`,
`STRATA_PREFILL_CPU_SHARE=0` y drafter **DFlash2** (`--draft dflash2`, pack `q4_0`
dedicado), sobre **ROCm 10.3 propio** (hipBLASLt 1.5.0, tabla de 168 filas regenerada
aquí). Modelo **IQ3_S** en producción (contexto 94.000, sin visión), **IQ3_XXS** como
alternativa (contexto 131.072). El proyecto Strata sigue sobre el clon v0.1.45 con el
endurecimiento propio; la documentación del clon es espejo de v0.2.13 con el
endurecimiento local reaplicado (ojo: los docs describen v0.2.13 mientras el motor en
marcha es el 0.1.57 parcheado).

## Aviso

Esto es experiencia de una sola máquina. Nada de aquí debe tomarse como "así funciona
en todas": una ROCm distinta, otros drivers o otra CPU pueden cambiar el resultado. Por
eso cada cifra lleva su fecha y su versión.
