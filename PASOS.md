# Pasos: de cero a producción (octubre–noviembre 2026)

Cronología real de esta caja. Cada paso dice qué se hizo y qué salió. Las versiones
"0.1.4x" son versiones del **motor** de Strata; "v0.2.x" son los lanzamientos de Strata
(de donde salen los códigos que compilamos).

## 18-10 — Primera instalación

Clon del repositorio [Niko1221/Strata](https://github.com/Niko1221/Strata) (rama main,
lanzamiento v0.1.45 de aquel momento) e instalación desde el código fuente con
`setup.sh --backend hip`. Strata no necesita ROCm en el sistema: instala unos *wheels*
TheRock **7.10.0a20251120** en su propio entorno Python y con ellos compila el motor
para la tarjeta (10-20 minutos, una vez). Primer motor: **0.1.45.3** compilado en casa.

## 19-10 — Endurecimiento de seguridad

Revisión del servidor Python (`serve/server.py`) y tres refuerzos, en
`patches/endurecimiento-server-v0.1.45.patch`:

- **tiempo de lectura de cabeceras** (15 s): una conexión que abre y no dice nada ya no
  puede secuestrar un hilo del servidor para siempre. `STRATA_REQUEST_HEADERS_S` lo ajusta.
- **backlog de escucha 5 → 256**: con 5 (el valor de la librería estándar), una ráfaga
  de 30-40 clientes a la vez rechazaba conexiones ("connection reset by peer"). Se midió
  con 4 Radeon R9700. `STRATA_HTTP_BACKLOG` lo ajusta.
- **límites a las imágenes**: cabeceras JPEG que prometen cientos de gigapíxeles,
  ficheros locales enormes, y URLs que apuntaban al propio servidor (un `302` a
  `127.0.0.1:8081` podía hacer que el servidor se llamara a sí mismo). Ahora son un 400
  honesto; las direcciones de tu red local siguen permitidas a propósito.
  (`STRATA_MAX_IMAGE_FILE_MIB`, `STRATA_IMAGE_DIR`, `STRATA_IMAGE_URL_ALLOW_INTERNAL`.)

## 20-21 — Motor 0.1.46 / 0.1.47 y las tablas de ajuste

Compilaciones desde etiquetas v0.2.1.x y v0.2.2. Con 0.1.47 descubrimos el problema de
la tabla (ver [HARDWARE.md](HARDWARE.md)): sin tabla, el prefill pierde su ruta rápida.
Solución en dos partes, que además preparamos como parches para subir arriba:

- **C1**: que la búsqueda de tabla caiga a la de la arquitectura hermana de la misma
  familia (gfx1200 ↔ gfx1201). Nunca enviado; el texto del PR está listo.
- **C2**: tabla recalibrada en esta tarjeta: `tools/hip/gfx1200-hipblaslt-100200.txt`,
  **67 filas**, con el afinador del propio Strata (`tune_hipblaslt`), contra la misma
  versión de hipBLASLt (1.2.0) que el motor va a cargar. Ganancia medida:
  **+1,2 % a 4K y +2,0 % a 16K** de prefill.

Detalle importante: las tablas **dependen de la versión exacta de hipBLASLt**; calibrar
contra la 1.2.2 de `/opt/rocm` mientras el motor carga la 1.2.0 de los wheels hace que
el motor rechace la tabla.

## 23-10 — Protocolo de medida en frío

Con los benches "en caliente" (con otros programas usando el PC) las diferencias de ±3 %
eran puro ruido. A partir de aquí toda decisión usa un protocolo fijo:

- Servidor de producción y todo lo demás **parados**; el script `scripts/run-bench.sh`
  (saneado) arranca el motor con la config de producción y lanza 2 corridas completas:
  la primera es calentamiento, **la segunda es la válida**.
- Cada corrida guarda su propio `server.log`: si se coló algo ajeno, se detecta y se repite.
- Los A/B cambian **una sola variable** (un flag o un valor) y se comparan contra una
  corrida "ancla" del mismo día.

En RESULTADOS.md están las tablas; los resultados de cada experimento, en
LO-QUE-FUNCIONO / LO-QUE-NO.

## 24-10 — Popcount (Zen 5) y motor 0.1.48.1

Port de un atajo de decodificación cuantizada que arriba solo usaba con DeepSeek:
`_mm256_popcnt_epi32` aplicado a los expertos nativos IQ3. En micro-medidas puras era
**15-30 % más rápido**… y en el servidor completo salió **−1,5 %**. Moraleja: un kernel
más rápido no gana cuando el cuello es el PCIe. La bandera (`STRATA_IQ_POPCOUNT`) se
quedó apagada. Motor 0.1.48.1 compilado desde v0.2.4.

## 25-10 — Pasamos al motor **oficial** 0.1.50

Strata ya publicaba paquete HIP para esta tarjeta (lanzamiento v0.2.5, paquete
`linux-x86_64-hip-rx9070`, con los **mismos** wheels 7.10.0 y el mismo pin de llama.cpp
que nuestra compilación). Descarga de 90 MB con sha256 verificado y swap sin compilar
(una decena de segundos, con script de ida y vuelta). Medido: **neutral** (±0,4 %), así
que se quedó. Otro experimento del mismo día (`STRATA_IQ_GATHER`) tampoco pasó.

## 26-10 — Cambio de modelo y ajustes del usuario

Producción pasó de IQ3_XXS a **IQ3_S** (más calidad, 83,6 GB) y se ajustó la config a
mano: contexto 131.072, `--spec-min-p 0.5`, reserva de VRAM 1.536 MiB y
`STRATA_SELECT_WMMA=1`. Se ganó ~17 % a 16K (medido por el usuario el mismo día; el A/B
formal pendiente). Además: **subset de vocabulario en español** para el cabezal
predictor MTP (ver [data/README.md](data/README.md)): +0,8 % en chat y +2,8 puntos
porcentuales de borradores aceptados, con 93 MiB menos de VRAM.

## 27-10 — Estado de entonces

Motor **0.1.50 oficial**, modelo **IQ3_S**, contexto 131.072, subset español activo,
servidor a la escucha en la red local con el servidor endurecido (parche del 19-10
aplicado sobre v0.1.45 del clon). Documentación del clon sincronizada con v0.2.6.

## 27-10 (noche) — Motor 0.1.52: los defaults de gfx12 cuestan un 8,8 %

El paquete oficial de v0.2.7 (motor 0.1.52) traía cuatro interruptores nuevos de
decodificación y un reparto distinto de la ventana PCIe. Tal cual: **chat −8,8 %**
(91,7 → 71,5 tok/s en el primer prompt). La caza de culpables mostró que **ninguno
individual** lo explica — el daño aparece con los cuatro activos — y que apagando
`STRATA_EXPDEC` se recupera **+2,1 %** sobre el control (6 de 6 corridas positivas).
Se adoptó el 0.1.52 con `STRATA_EXPDEC=0` y `STRATA_PLE_AUTO_RAM=0`.

## 29-10 — Un experimento que salió mal y su rollback

El usuario subió a mano el contexto a 262.144, el `--kv-resident` a 32.768 y añadió
`--pcie-frac 0` y `--adapt-every 0`. Medido en frío: **chat −28 %** y agente −21 %, con
prefill plano. La causa: sin la capa adaptativa el acierto de la caché de expertos cae de
~85 % a 60-68 % y sin lecturas PCIe no hay de dónde reponer. Rollback a la config
anterior y lección: `--adapt-every 0` **no** es gratis. (Ver [LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md).)

## 30-10 — Motor 0.1.54 y runtime ROCm propio

El paquete oficial de v0.2.8 (motor 0.1.54) corrige un contador de ranuras de la caché de
expertos y dos fallos de arranque; en frío resultó **neutro o un pelín mejor** que el
0.1.52 y se quedó (con los mismos `STRATA_EXPDEC=0`, `STRATA_PLE_AUTO_RAM=0`,
`STRATA_HIP_WMMA=1`).

El descubrimiento del día fue otro: **el motor oficial corre sin recompilar sobre wheels
de ROCm más nuevos** que los 7.10 que empaqueta la release, con solo cambiar `lib_dirs`.
Probado con 10.1 (estable) y 10.3 (nightly): chat **+3,5 %** y agente **+2,5 %**, con
prefill casi igual. Adoptado 10.3 con su tabla de hipBLASLt 1.5.0 regenerada en casa
(168 filas). La idea que perseguíamos ("ROCm 10.x rotula gfx1201 y por eso va más rápido")
quedó **desmentida**: en Linux sigue diciendo gfx1200; lo que rinde es el stack BLAS.

## 31-10 — Motor 0.1.55 con GDN chunked en gfx12: la ganancia de prefill más grande

El paquete oficial de v0.2.9 (motor 0.1.55) trae `STRATA_GDN_CHUNKED`: la recurrencia GDN
del prefill pasa por un kernel con tensor cores para gfx12. En A/B del mismo día:
**4K +6,1 %/+3,7 %**, **16K +6,7 %/+5,9 %**, primer token −4/−6 %, chat dentro del ruido y
agente sin cambio. Detectado de antemano comparando los binarios: el kernel
(`gdn_w12_scan_kernel`) no existe en 0.1.54. Se adoptó, y antes de tocar producción se
hizo un *soak* de concurrencia (12 requests con 3 clientes a la vez + 10 minutos
continuos, 872 requests, 0 fallos), porque el contrato de la ruta chunked dice que usa un
único buffer de trabajo por dispositivo.

El mismo día, el servidor Python se puso al día con v0.2.9 (tres correcciones de
comportamiento: cierre de bloques de código en el render, herramientas "retiradas" del
turno que siguen contando si la conversación las usó, y el lector de imágenes siguiendo al
motor tras un cambio de versión) y la documentación del clon se resincronizó con v0.2.9.

## 03-11 — Motor 0.1.56: el drafter DFlash2 sustituye al cabezal MTP

El motor oficial 0.1.56 trae **DFlash2**, un modelo borrador con pack propio
(`qwen3.8-flash-next-dflash2.q4_0.pack`: el borrador ya va cuantizado en cuartos) que
sustituye al cabezal predictor MTP. A/B del mismo día contra el control MTP:
chat mediano **81,2 vs 77,0 (+5,5 %)**, 4K y 16K planos. Los rangos son anchos
(69,4-126,2 del drafter frente a 71,2-97,7 del control): la mediana mejora y la
varianza del borrador se nota. Se adoptó: la config de producción usa `--draft dflash2`,
`--draft-fallback none` y `--draft-conf 0.7`. Muestras:
`benches/muestras/mtp-0.1.56-control` y `df2-0.1.56-draft`.

## 05-11 — Motor 0.1.57: anillo de preparación de prompt más profundo (+10,7 % en 4K)

El 0.1.57 profundiza el anillo que prepara la lectura del prompt por adelantado. A/B del
mismo día (control con el anillo en 0): **4K 2.322,6 vs 2.098,0 (+10,7 %)**, 16K y 32K
dentro del ruido (±0,2 %); chat 82,2 vs 79,3. Se adoptó. Desde ese día el script de
medida añade el prompt de 32K (`--long`): **3.055,5 tok/s, 10,5 s hasta el primer
token**. Muestras: `benches/muestras/engine-0.1.57-ring0` y `engine-0.1.57-anillo`.

## Lección de fondo (octubre y principios de noviembre)

**Casi todo lo que prometía era ruido, y lo que funcionó son ocho cosas concretas y
medidas**: la tabla C2, el subset español, la reserva/flags de la config final, el
protocolo de medición en sí, el runtime ROCm propio, GDN gfx12, el drafter DFlash2 y el
anillo de prompt más profundo.
