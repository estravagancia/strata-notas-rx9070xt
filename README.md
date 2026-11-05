# Strata en una RX 9070 XT (Linux): notas de una caja real

Esto **no es un fork ni un parche oficial**: son las notas de lo que hicimos funcionar (y
lo que no) para montar [Strata](https://github.com/Niko1221/Strata) en un PC de casa con
gráfica AMD **Radeon RX 9070 XT** y Linux. Si tienes una tarjeta RDNA 4 o una RDNA 3.5,
seguramente te sirva tal cual: el caso raro de esta caja (la tarjeta se reporta con el
nombre de arquitectura "hermano") es más común de lo que parece.

Todos los números son **medidos en esta caja**, con la fecha y la versión del motor que
los produjo. Donde no hay medida, lo decimos.

## Qué consiguió esta caja

Con el modelo **Qwen3.8-Flash-Next IQ3_XXS** (75,8 GB en disco, 16 GiB de VRAM y 60 GB de RAM)
y el motor **0.1.57** sobre un runtime **ROCm 10.3 propio** (ver más abajo):

| Métrica | Valor |
|---|---|
| Escritura tipo chat (dominio común) | **~94 tokens/s** de salida |
| Relectura de un texto de 4.000 tokens | **~2.320 tokens/s** (empieza a responder en ~1,75 s) |
| Relectura de 16.000 tokens | **~3.100 tokens/s** (primer token en ~5,2 s) |
| Relectura de 32.000 tokens | ~3.055 tokens/s (primer token en ~10,5 s) |
| Contexto máximo | 131.072 tokens |

Las tres ganancias grandes medidas aquí vienen de upstream y están cada una en su fecha:
la ruta **GDN chunked con tensor cores en gfx12** (motor 0.1.55: +6 % en 4K y +6 % en 16K),
el **drafter DFlash2** en lugar del cabezal predictor (motor 0.1.56: **+12 %/+13 % en chat**,
con el borrador ya en cuartos), y el **anillo de preparación de prompt más profundo**
(motor 0.1.57: **+11 %/+14 % en 4K**). Y una cuarta, menos obvia: el motor oficial corre
**sin recompilar** sobre wheels de ROCm más nuevos que los que empaqueta la release. Todo,
en frío y con su tabla en [RESULTADOS.md](RESULTADOS.md) y [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md).

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
   el endurecimiento de seguridad del servidor y un ajuste de vocabulario en español.
6. [configs/](configs/) y [scripts/](scripts/) — la configuración real y el script de medidas.
7. [benches/muestras/](benches/muestras/) — 5 mediciones completas para que audites las tablas.
8. [CREDITOS.md](CREDITOS.md) — de dónde viene cada pieza.

## Estado actual (31-10-2026)

Motor **0.1.55** oficial (lanzamiento v0.2.9) con `STRATA_GDN_CHUNKED=1`, `STRATA_EXPDEC=0`
y `STRATA_PLE_AUTO_RAM=0`, sobre **ROCm 10.3 propio** (hipBLASLt 1.5.0, tabla de 168 filas
regenerada aquí) y modelo **IQ3_XXS**, contexto 131.072. Servidor Python al día con v0.2.9
(tres correcciones de comportamiento respecto a v0.2.8). La documentación del clon es
espejo de v0.2.9 más dos bloques de endurecimiento propio.

## Aviso

Esto es experiencia de una sola máquina. Nada de aquí debe tomarse como "así funciona
en todas": una ROCm distinta, otros drivers o otra CPU pueden cambiar el resultado. Por
eso cada cifra lleva su fecha y su versión.
