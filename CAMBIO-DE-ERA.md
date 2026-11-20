# Cambio de era: del motor 0.1.57.x al 0.1.62.9x (base v0.2.16)

Este fichero explica el corte que dimos entre el 17 y el 19 de noviembre de 2026: la caja
dejó de ejecutarse sobre los motores `0.1.57.x` y pasó a unos nuevos (`0.1.62.9x`)
construidos sobre una base de Strata distinta. No es una actualización de versión: cambió
la forma de construir y de servir el modelo.

Todo lo publicado en este repositorio hasta el 17-11 pertenece a la **era anterior** y
sigue siendo válido para ella. Lo de la **era actual** va separado, con sus fechas y sus
versiones. Este documento es el índice de las dos.

## Las dos eras de un vistazo

| | era anterior (documentada hasta el 17-11) | era actual (desde el 18-11) |
|---|---|---|
| checkout de trabajo | `~/Strata`: línea local anclada en v0.1.45, con serve y documentación espejo de tags oficiales hasta v0.2.15 | `~/Strata-upstream`: clon de Strata anclado al tag **v0.2.16**, sin tocar `~/Strata` |
| motores construidos | 0.1.49 → **0.1.57.91** (el último, sobre la etiqueta v0.2.11 + CacheKV + IL-mmvq) | **0.1.62.90** y **0.1.62.91** (sobre v0.2.16 + CacheKV + IL-mmvq) |
| de dónde sale el servidor | del checkout viejo (`serve/`) | del propio clon nuevo (`terminal/serve/`), que es como upstream organiza el proyecto desde su reestructuración |
| herramienta de medida | `~/Strata/bench/` | `~/Strata-upstream/bench/` (portada el 19-11) |
| en marcha hoy (verificado 20-11) | parado | motor **0.1.62.91** con IQ3_S, contexto 94.000, puerto 8081 |

## Por qué se cortó, si la era anterior funcionaba

Tres cosas se juntaron el 17 y el 18 de noviembre:

1. **El método de trabajo se rompió con v0.2.16.** Hasta entonces manteníamos el serve y la
   documentación como espejo del tag oficial y re-aplicábamos encima nuestros parches
   locales. En v0.2.16 upstream reestructuró todo el repositorio (separó el proyecto en
   `app/`, `engine/` y `terminal/`, con llama.cpp incluido dentro): las rutas del espejo
   ya no existían. El ciclo se cerró sin hacer el porte (allí, ADR-048).
2. **Las bases nuevas, probadas sin todo, iban más lentas.** En la era anterior medimos un
   motor sobre base v0.2.15 con CacheKV pero **sin** IL-mmvq (`0.1.61.90`): perdió contra
   nuestro `0.1.57.91` un 1,35 %/3,85 % en chat y un 3,08 %/1,99 % en agente, teniendo
   además mejores borradores (allí, T33/ADR-047). De ahí la regla fija de la era actual:
   **ninguna versión intermedia sin IL-mmvq**.
3. **Los cambios locales seguían haciendo falta.** CacheKV (el KV en disco que sobrevive a
   los reinicios) y el porteo de IL-mmvq a la ruta HIP no están aguas arriba. Hacerlos
   valer sobre la base nueva exigía un sitio propio, y el usuario decidió crearlo: el clon
   `~/Strata-upstream` (allí, ADR-U01, 18-11).

La alternativa descartada fue seguir re-portando a mano en `~/Strata`: mezclaba historias y
series de medidas de dos bases distintas. Por eso hoy hay dos repositorios conviviendo;
comparten los datos (`~/Strata-data`) y la carpeta de motores instalados, pero no sus
historias ni sus benches. Los motores del clon nuevo se numeran `0.1.62.x` para no chocar
con los `.90`/`.91` de la línea vieja.

## Cómo son los motores nuevos

Los dos comparten el mismo código: el commit propio `4a7d49cb9`, que es v0.2.16 más los
portes locales. Lo único que cambia entre ellos es el compilador:

| componente | base | compilado con | estado |
|---|---|---|---|
| `0.1.62.90` | v0.2.16 + CacheKV (`local/t33-rebase-0215`) + IL-mmvq portado a HIP | ROCm del sistema (apt 7.2.1) | en producción el 18-11; queda instalado como vuelta atrás |
| `0.1.62.91` | **el mismo commit** | SDK ROCm 10.3 del bundle (hipcc 7.18 / clang 24) | en producción desde el 19-11 |

La comparación entre los dos se hizo para decidir con qué toolchain quedarse. Con la misma
suite y el mismo chunk de prompt (16.384): paridad bit a bit en la prueba de paridad IL,
sin regresión demostrable en la suite de CacheKV, y una ejecución de control contra otra
con chat un 3,9 % mejor en los dos modelos (con aceptación de borradores idéntica) y agente
desigual (−5,2 % con IQ3_S, +10,5 % con IQ3_XXS). Con una sola pareja de ejecuciones **no
podemos atribuir ni ganancias ni pérdidas**; lo que sí está medido es que no hay una caída
sistemática en todas las métricas. La decisión (allí,
ADR-U02) fue quedarse con el SDK 10.3 —el entorno de ejecución real de la caja ya era
10.3— y conservar el `.90` como vuelta atrás cambiando una línea de la config. Las tablas
completas están en [RESULTADOS.md](RESULTADOS.md), sección de la era actual.

Detalle importante heredado de la lección anterior: en v0.2.16 la prueba de paridad IL está
colgada del camino CUDA y el preset HIP la apaga, así que hubo que extender ese control a
HIP para poder verificar el porteo. Es una de las divergencias locales registradas.

## Qué se llevó al clon nuevo (inventario de parches propios)

Cinco divergencias sobre v0.2.16, cada una con su parche en `patches/` de este repo:

| parche | qué hace |
|---|---|
| `p1-hip-gate-y-shim-l2` | extiende a HIP el control de paridad IL (que upstream solo ejecuta en CUDA) y quita un guard de AMD a un shim de nivel 2 |
| `p1-sink-try-catch` | protege con try/catch el punto de salida del servidor para que un fallo no tumbe el proceso |
| `p1-dedupe-snapshot-sources` | elimina una lectura duplicada en las pruebas de instantánea de conversación (el test no compilaba en ningún build) |
| `serve-local-hardening-v0.2.16` | endurecimiento del servidor con imágenes: respuesta neutra y razón legible ante peticiones inválidas, y control de la arquitectura gfx1201 |
| `p5-rocm-sdk-103-build` | hace posible compilar con el SDK 10.3 (los paquetes nuevos ya no propagan el flag de compilación HIP: sin él, los `.cu` se compilaban como CUDA) |

CacheKV e IL-mmvq no van como parche suelto: forman parte del commit base del motor. El
porteo de IL no fue copiar y pegar tres commits: upstream ya había absorbido nuestro fix de
cabeceras, pero las familias de kernels seguían cerradas para HIP, así que hubo que
abrirlas y traer las celdas de las tablas gfx12 del fork ajeno (bsorensen110, ver
[CREDITOS.md](CREDITOS.md)).

## Qué cambió en la forma de servir (y qué es herencia)

Las flags del motor son **las mismas** de la era anterior: mismo pack, mismos modelos,
mismo contexto de 94.000, KV en int8 con 16.384 residentes, anillo de prompt, DFlash2,
CacheKV en disco. Lo que cambia es de dónde se arranca y dos decisiones de uso ajenas al
motor:

- El servidor y las configs viven ahora en el clon nuevo (`terminal/`), con sus propios
  `run-*.sh`. Al arrancar se sigue aplicando la comprobación fija de siempre: que la línea
  de arranque del motor lleve `--draft dflash2` y que el log diga cuántos tokens admite el
  cabezal borrador.
- La config pasa de escuchar solo en `127.0.0.1` a hacerlo en la dirección de la red local
  (para servir a otros equipos). Esto es una decisión de uso, no una novedad del motor.
- El muestreo cambió (temperatura 0,6 → 0,7 y tres parámetros más explícitos). También es
  una decisión de uso.
- El pack del borrador pasó de `dflash2.q4_0.pack` a `dflash2.strata1.q4_0-selq4.pack`.
  **Importante para las cifras:** todas las medidas de la era actual se hicieron con el pack
  antiguo; la producción cambió después. Ver más abajo.

## Qué está medido en la era actual y con qué configuración

Cinco ejecuciones publicadas, todas del 19-11, con su `results.json` y su lectura en
[RESULTADOS.md](RESULTADOS.md) (sección de la era actual). Suite y chunk están en el nombre:

| serie | motor | chunk de prompt | modelo | pack del borrador |
|---|---|---|---|---|
| `ctrl90-chunk16384-iq3-s` | 0.1.62.90 | 16.384 | IQ3_S | `dflash2.q4_0.pack` |
| `ctrl90-chunk16384-iq3-xxs` | 0.1.62.90 | 16.384 | IQ3_XXS | idem |
| `p5-91-chunk8192-iq3-s` | 0.1.62.91 | 8.192 | IQ3_S | idem |
| `p5-91b-chunk16384-iq3-s` | 0.1.62.91 | 16.384 | IQ3_S | idem |
| `p5-91b-chunk16384-iq3-xxs` | 0.1.62.91 | 16.384 | IQ3_XXS | idem |

Dos avisos de comparabilidad, que son la regla de siempre:

- Solo son comparables entre sí las ejecuciones de la **misma suite y el mismo chunk**. Aquí
  eso significa: `ctrl90` contra `p5-91b` (ambas con chunk 16.384). La serie con 8.192 queda
  aparte, y ninguna de estas es comparable con las tablas de la era anterior: son otros
  motores, otro servidor y otros controles.
- Estas cifras pertenecen a la configuración con el pack de borrador antiguo. La producción
  actual usa otro pack; hasta que no haya una serie con esa configuración, lo publicado
  describe **cómo se construyó y validó la era nueva**, no lo que rinde hoy la producción.

## Lo que no sabemos / límites de esta nota

- Upstream publica notas de versión hasta v0.2.7 en su repositorio; para el tramo
  v0.2.8 → v0.2.16 no hay resumen público, así que aquí solo describimos lo que verificamos
  en el checkout y lo que nos afectó a nosotros. No afirmamos qué más cambió entre versiones.
- La comparación de toolchains (`.90` vs `.91`) es una sola pareja de ejecuciones: vale para
  descartar regresiones, no para atribuir ganancias.
- El clon nuevo tiene configs y scripts para un brazo con visión; en la caja **no** se usó en
  producción y no hay medidas publicadas de ese brazo.

## Dónde vive cada cosa a partir de ahora

Los artefactos de este repositorio se separaron por era:

| | era anterior (0.1.49 – 0.1.57.x) | era actual (0.1.62.9x) |
|---|---|---|
| configs | `configs/0.1.57.90/` | `configs/0.1.62.91/` |
| scripts de medida e instalación | `scripts/0.1.57.x/` | `scripts/0.1.62.9x/` |
| parches propios | `patches/era-anterior/` | `patches/era-actual/` |
| ejecuciones publicadas | `benches/0.1.57.x/muestras/` | `benches/0.1.62.9x/muestras/` |

Y en los textos: cada fichero (`README.md`, `PASOS.md`, `RESULTADOS.md`,
`LO-QUE-FUNCIONO.md`, `LO-QUE-NO-FUNCIONO.md`) abre con la era actual y debajo conserva,
sin reescribir, un bloque **Histórico — era 0.1.57.x**, que es lo publicado hasta el 17-11.
