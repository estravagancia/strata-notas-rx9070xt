# Strata en una RX 9070 XT (Linux): notas de una caja real

Esto **no es un fork ni un parche oficial**: son las notas de lo que hicimos funcionar (y
lo que no) para montar [Strata](https://github.com/Niko1221/Strata) en un PC de casa con
gráfica AMD **Radeon RX 9070 XT** y Linux. Si tienes una tarjeta RDNA 4 o una RDNA 3.5,
seguramente te sirva tal cual: el caso raro de esta caja (la tarjeta se reporta con el
nombre de arquitectura "hermano") es más común de lo que parece.

Todos los números son **medidos en esta caja**, con la fecha y la versión del motor que
los produjo. Donde no hay medida, lo decimos.

La caja cambió de base el 18-11: pasamos de una línea local (motores `0.1.57.x`) a un clon
anclado al tag v0.2.16 (motores `0.1.62.9x`). Este README abre con la **era actual**; debajo
queda como **Histórico** todo lo publicado hasta el 17-11 sobre la era anterior, sin
reescribir. El porqué del corte y qué se llevó al clon nuevo: [CAMBIO-DE-ERA.md](CAMBIO-DE-ERA.md).

## Qué produce hoy esta caja (era actual)

La producción de esta caja es hoy **Qwen3.8-Flash-Next en IQ3_S** (83,6 GB en disco) con el
motor propio **`0.1.62.91`** —base v0.2.16 + CacheKV + IL-mmvq portado a HIP, compilado con
el SDK ROCm 10.3—, contexto 94.000, en la red local (puerto 8081). La config real está en
[configs/0.1.62.91/](configs/0.1.62.91/).

Las únicas cifras auditadas de esta era son las series de validación del 19-11
([benches/0.1.62.9x/muestras/](benches/0.1.62.9x/muestras/)), medidas con el pack de
borrador **antiguo** (`dflash2.q4_0.pack`) y temperature 0 del bench; la producción cambió
después de pack (`strata1.q4_0-selq4`) y de muestreo (temperature 0,7). **No hay todavía una
ejecución auditada con la configuración actual de producción**, así que publicamos estas
cifras etiquetadas como lo que son: cómo se validó la era nueva, no el rendimiento de hoy.
Motor IQ3_S `0.1.62.91`, chunk 16.384 (mediana de la serie `p5-91b`):

| Métrica | Valor (medida 19-11, configuración de validación) |
|---|---|
| Escritura tipo chat | **84,5 tokens/s** de mediana (rango entre requests 72,7–110,4; borradores aceptados 75,7 %) |
| Relectura de un texto de 4.000 tokens | **2.468,5 tokens/s** (primer token en ~1,65 s) |
| Relectura de 16.000 tokens | **3.522,5 tokens/s** (primer token en ~4,59 s) |
| Relectura de 32.000 tokens | sin medir en esta era |
| Contexto máximo | 94.000 tokens en IQ3_S (131.072 con IQ3_XXS, config publicada, sin medir en esta era) |
| Reinicio con la conversación abierta | CacheKV sigue activo (forma parte del commit base del motor); **no re-medido** en esta era — la cifra auditada del −92,7 % es de la era anterior |

Lo que hizo posible esta caja no desapareció con el corte: la ruta GDN chunked, el drafter
DFlash2 y el anillo de prompt vienen ahora **dentro de la base oficial**; CacheKV e IL-mmvq
los portamos nosotros sobre v0.2.16. Las ganancias originales están medidas en su día, en la
era anterior, con sus tablas abajo y en [RESULTADOS.md](RESULTADOS.md).

## Por dónde empezar

1. [CAMBIO-DE-ERA.md](CAMBIO-DE-ERA.md) — el corte entre las dos eras: por qué, qué se llevó,
   qué está medido en cada una. Empieza aquí si llegas ahora.
2. [HARDWARE.md](HARDWARE.md) — qué PC es este y la rareza de la arquitectura gfx1200/gfx1201.
3. [PASOS.md](PASOS.md) — la cronología, con su bloque histórico debajo.
4. [RESULTADOS.md](RESULTADOS.md) — las tablas de rendimiento y cómo medimos (para que
   puedas comparar tus propios números con los nuestros). **No comparar cifras entre eras.**
5. [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) y [LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md) —
   el resultado de cada experimento, positivos y negativos.
6. [patches/](patches/) — separados por era: los propios de la época 0.1.57.x y las 5
   divergencias sobre v0.2.16 con las que se construyen los motores actuales.
7. [configs/](configs/) y [scripts/](scripts/) — la configuración real y los scripts, en
   subcarpetas por era.
8. [benches/](benches/) — 19 ejecuciones de la era anterior y 5 de la actual, para que
   audites las tablas.
9. [CREDITOS.md](CREDITOS.md) — de dónde viene cada pieza.

## Estado actual (20-11-2026)

Motor **propio `0.1.62.91`** = tag oficial v0.2.16 + commit propio `4a7d49cb9` (CacheKV del
fork kinoyu-ai + IL-mmvq portado a HIP + 5 parches propios, ver [patches/era-actual/](patches/era-actual/)),
compilado con el SDK ROCm 10.3 del bundle. Está instalado como vuelta atrás el `0.1.62.90`
(mismo commit, ROCm apt 7.2.1). Flags de siempre: `STRATA_GDN_CHUNKED=1`, `STRATA_EXPDEC=0`,
`STRATA_PLE_AUTO_RAM=0`, `STRATA_PREFILL_CPU_SHARE=0`, `STRATA_HC_Q8=0`, KV en int8 con
16.384 residentes, anillo de prompt, CacheKV en disco, drafter **DFlash2** con el pack nuevo
`strata1.q4_0-selq4`. Modelo **IQ3_S** en producción (contexto 94.000, sin visión, servido
en la red local), **IQ3_XXS** como alternativa. El trabajo vive en un clon nuevo anclado a
v0.2.16 (`~/Strata-upstream`); el checkout anterior sigue en su sitio con su historia, sin
tocar. Comparten datos y carpeta de motores; no comparten benches ni configs.

---

# HISTÓRICO — era 0.1.57.x (publicado hasta el 17-11)

Todo lo que sigue es la portada tal como estaba el 16-11, para la era anterior. Es válido
para aquellos motores; su descripción del proyecto (clon v0.1.45 con serve y documentación
espejo de los tags oficiales) quedó sustituida por la del bloque de arriba.

## Qué consiguió esta caja

La producción de esta caja es hoy **Qwen3.8-Flash-Next en IQ3_S** (83,6 GB en disco), con
**IQ3_XXS** (75,8 GB) como alternativa para contexto más largo; las dos configs están en
[configs/0.1.57.90/](configs/0.1.57.90/). Los números siguientes están medidos en **IQ3_S** con el motor
**0.1.57.90** (la etiqueta v0.2.11 + un parche de un fork ajeno, ver
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §10), 16 GiB de VRAM y ~60 GB de RAM, sobre un
runtime **ROCm 10.3 propio** (ver más abajo). Es la ejecución auditada `run2` del brazo de
producción con disco del 14-11 (`benches/0.1.57.x/muestras/cachekv-0.1.57.90-disk-16384-iq3s/`, con su
control sin disco del mismo día al lado); el control vigente del 16-11 y las series completas
están en [RESULTADOS.md](RESULTADOS.md):

| Métrica | Valor |
|---|---|
| Escritura tipo chat (dominio común) | **~88 tokens/s** de media de la ejecución (mediana 79,5; rango 72,2-112,4; borradores aceptados 78,5 %) |
| Relectura de un texto de 4.000 tokens | **~2.500 tokens/s** (empieza a responder en ~1,63 s) |
| Relectura de 16.000 tokens | **~3.500 tokens/s** (primer token en ~4,61 s) |
| Relectura de 32.000 tokens | **~3.460 tokens/s** (primer token en ~9,3 s; chunk de prompt 16.384 forzado en la misma ejecución) |
| Contexto máximo | 94.000 tokens en IQ3_S (131.072 con IQ3_XXS) |
| Reinicio con la conversación abierta | prefill **−92,7 %** (el KV se restaura del disco) |

Sobre esas cifras: el chat es la media y la mediana de la misma ejecución auditada; en el uso
diario con borradores aceptados se cae en la parte alta del rango (ese ~94 tokens/s que
publicamos antes era una estimación típica del uso, no una medida). Las tres filas de
relectura vienen de esa misma ejecución del 14-11 (suite `--long`, chunk de prompt 16.384
forzado). Como contraste, la muestra del 13-11
([benches/0.1.57.x/muestras/long-0.1.57.90-iq3s/](benches/0.1.57.x/muestras/long-0.1.57.90-iq3s/)) se hizo con ~8,8 GiB
libres de RAM al arrancar: el motor bajó solo el chunk de 16.384 a 8.192 y dio 3.163 en 32K,
cifra que hay que leer como **cota baja** en esas condiciones de memoria.
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

## Estado actual entonces (16-11-2026)

Motor **propio `0.1.57.90`** = etiqueta oficial v0.2.11 (motor 0.1.57) + el parche CacheKV
del fork kinoyu-ai, con las flags `--conversation-cache-dir` y `--conversation-cache-persist`
activas; `STRATA_GDN_CHUNKED=1`, `STRATA_EXPDEC=0`, `STRATA_PLE_AUTO_RAM=0`,
`STRATA_PREFILL_CPU_SHARE=0`, `STRATA_HC_Q8=0` y drafter **DFlash2** (`--draft dflash2`,
pack `q4_0` dedicado, con el vocabulario de borradores en español
`data/draft_vocab_es-modern.bin`, instalado el 15-11 y adoptado el 16-11), sobre **ROCm 10.3 propio** (hipBLASLt 1.5.0, tabla de 168 filas
regenerada aquí). Modelo **IQ3_S** en producción (contexto 94.000, sin visión), **IQ3_XXS**
como alternativa (contexto 131.072). El proyecto Strata sigue sobre el clon v0.1.45 con el
endurecimiento propio; el servidor y la documentación del clon son espejo de **v0.2.15** con
el endurecimiento local reaplicado (ojo: los docs describen v0.2.15 mientras el motor en
marcha es el 0.1.57 parcheado; el 0.1.60 de v0.2.14/0.2.15 está instalado
en esta caja, pero NO se adoptó: gate de no-regresión fallado, ver [RESULTADOS.md](RESULTADOS.md)).
Desde v0.2.15 el servidor retiró la elección automática de DFlash2 en gfx1201: por eso las
dos configs de [configs/0.1.57.90/](configs/0.1.57.90/) declaran `"drafting": "dflash2"` explícitamente.

## Aviso

Esto es experiencia de una sola máquina. Nada de aquí debe tomarse como "así funciona
en todas": una ROCm distinta, otros drivers o otra CPU pueden cambiar el resultado. Por
eso cada cifra lleva su fecha y su versión.
