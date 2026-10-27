# Pasos: de cero a producción (octubre 2026)

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

## 27-10 — Estado actual

Motor **0.1.50 oficial**, modelo **IQ3_S**, contexto 131.072, subset español activo,
servidor a la escucha en la red local con el servidor endurecido (parche del 19-10
aplicado sobre v0.1.45 del clon). Documentación del clon sincronizada con v0.2.6.

Lección de fondo de todo el mes: **casi todo lo que prometía era ruido, y lo que funcionó
son cuatro cosas concretas y medidas** (tabla C2, subset español, reserva/flags de la
config final y el protocolo de medición en sí).
