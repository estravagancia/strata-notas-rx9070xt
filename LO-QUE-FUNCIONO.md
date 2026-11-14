# Lo que funcionó (medido en esta caja)

## 1. Tabla de ajuste hipBLASLt recalibrada (C2) — la mayor ganancia limpia

**Qué:** una tabla de 67 filas de algoritmos matriciales elegidos para esta tarjeta,
generada con el afinador del propio Strata (`tune_hipblaslt --workspace-mib 32`) y
colocada en `tools/hip/gfx1200-hipblaslt-100200.txt`.

**Cuánto:** prefill 4K **+1,2 %**, 16K **+2,0 %** (motor 0.1.47, 21-10; tabla arriba en
[RESULTADOS.md](RESULTADOS.md)).

**Trucos que importan:**
- Calibrar contra la hipBLASLt que el motor **realmente carga** (la de los wheels,
  1.2.0), no contra la del sistema: si no, el motor rechaza la tabla.
- El parche C1 (buscar la tabla de la arquitectura hermana) es lo que hace que una
  tarjeta que se reporta gfx1200 *encuentre* su tabla gfx1201 y viceversa.

## 2. Subset de vocabulario en español para el cabezal MTP

**Qué:** el cabezal predictor de borradores (MTP) lleva su propio vocabulario. El
estándar cubre 106.299 entradas; recortamos a **50.847 ids** frecuentes en español
(medio corpus real de chats, ver [data/README.md](data/README.md)) y el motor lo acepta
sustituyendo `Strata-data/mtp/rt/draft_vocab.bin`.

**Cuánto (1 ejecución limpia, 26-10):** chat **+0,8 %**, borradores aceptados **+2,8
puntos porcentuales**, y **−93 MiB** de VRAM del cabezal. Una segunda ejecución se
contaminó y no cuenta: señal positiva pero de una sola muestra.

**Formato** (por si quieres generar el tuyo en tu idioma): el fichero es un array
`int32` **sin cabecera**; el motor calcula cuántas entradas hay dividiendo el tamaño
entre 4. Nuestro `draft_vocab_es.bin` mide 203.388 bytes = 4 × 50.847.

## 3. Ajustes de la config final (26-10)

Cambiados a mano y en conjunto (no es un A/B de uno a uno):

| Flag | Efecto observado |
|---|---|
| `--spec-min-p 0.5` (antes 0.70) | más borradores aceptados en chat; con MTP español no salió el problema de aceptaciones del experimento `--spec-min-p 0.75` |
| `--vram-reserve-mib 1536` (antes 2940 libres) | liberó VRAM para la cache de expertos: de 3.777 a **4.471 ranuras** |
| `STRATA_SELECT_WMMA=1` (warp-level matrix multiply en HIP) | el usuario midió **+17 % a 16K** el mismo día (medida rápida, A/B formal pendiente) |
| `--conversation-cache-mib 5376` + `--prompt-cache-tail` | chats largos que siguen donde estaban; parte del salto 74→78 de chat entre series |

## 4. El protocolo de medida en frío

No es un flag, pero fue lo que desmontó la mayoría de las falsas mejoras (±3 % de ruido
entre ejecuciones "en caliente"). Sin él, habríamos adoptado cuatro cosas que no mejoraban
nada. Ver [scripts/run-bench.sh](scripts/run-bench.sh).

## 5. Endurecimiento del servidor (19-10)

Sin coste de rendimiento medido; tres refuerzos de robustez (cabeceras con tiempo
límite, backlog 256, límites de imágenes/SSRF) que van en
[patches/endurecimiento-server-v0.1.45.patch](patches/). Nunca hemos tenido un
incidente desde entonces (lo cual no prueba nada, pero 12 conexiones colgadas y ráfagas
de 40 clientes sí ocurrieron antes).

## 6. El motor oficial sobre wheels de ROCm más nuevos (sin recompilar)

**Qué:** los paquetes oficiales de Strata traen sus propios wheels (7.10 en las releases
de octubre). El motor **no está atado a ellos**: se puede apuntar `lib_dirs` a otro
runtime ROCm instalado aparte y el binario oficial carga ese en su lugar. Sin recompilar.

**Cuánto (A/B en frío, 30-10, mismo motor 0.1.54, misma config):**

| Runtime | chat tok/s | 4K tok/s | 16K tok/s | agente |
|---|---|---|---|---|
| wheels 7.10 de la release | 80,4 | 2.009,3 | 2.793,5 | 80,6 |
| ROCm 10.1 (estable) + tabla 100401 | **83,3** | 1.919,0 | 2.763,1 | 87,2 |
| ROCm 10.3 (nightly) + tabla 100500 | **83,2** | 1.961,6 | 2.805,1 | 81,1 |

**Cómo:** runtime autocontenido ("pip install" de los wheels en un venv aparte y copia de
las librerías), `lib_dirs` en la config del motor y **tabla de hipBLASLt regenerada**
contra la versión nueva (las tablas son por versión de hipBLASLt). El procedimiento
exacto está en el script `bench/rocm-runtime-rebuild.sh` del clon local.

**Aviso:** esto no es una configuración soportada por la release. Funciona porque el
binario resuelve todas las dependencias por `lib_dirs`; si algún día no carga, el
rollback es volver a los wheels de la release (un cambio de dos líneas en la config).

## 7. GDN chunked con tensor cores en gfx12 (motor 0.1.55, `STRATA_GDN_CHUNKED=1`)

**Qué:** la recurrencia GDN del prefill (la que da memoria "de estado" a las capas
lineales) tiene desde el 0.1.55 un kernel nuevo para gfx12 que usa los tensor cores
(WMMA). Se activa por variable de entorno; el umbral bajó a 64 tokens, así que también
mejoran prompts medianos.

**Cuánto (A/B en frío, 31-10, dos ejecuciones por brazo, IQ3_XXS, contexto 131.072):**

| Métrica | GDN off | GDN on | Diferencia |
|---|---|---|---|
| 4K tok/s | 1.932,6 / 1.953,0 | **2.050,8 / 2.025,1** | **+6,1 % / +3,7 %** |
| 16K tok/s | 2.791,1 / 2.801,6 | **2.977,0 / 2.966,1** | **+6,7 % / +5,9 %** |
| primer token 4K / 16K | 2,10 / 5,78 s | 1,98 / 5,42 s | −4 % / −6 % |
| chat | 81,8 / 82,3 | 80,5 / 81,7 | dentro del ruido (±1,5 %) |
| agente | 80,4 / 81,8 | 79,6 / 82,3 | sin cambio |

**Lo que hay que saber:** en esta caja el motor reporta **gfx1200** y la ganancia es la
misma que upstream midió en gfx1201 (R9700), así que el kernel cubre las dos variantes.
El contrato de la ruta (`docs/GDN_CONTRACT.md` de v0.2.9) dice que usa **un único buffer
de trabajo por dispositivo**: no está pensada para dos prefills simultáneos en la misma
tarjeta. En nuestro servidor los requests se encolan, así que antes de adoptarla hicimos
un *soak* de 3 clientes concurrentes (12 requests) y 10 minutos de carga continua
(872 requests, 0 fallos, primer token mediano 2,0 s). Si algún día se usa `parallel` > 1
a nivel de motor, revisar esto primero.

## 8. Drafter DFlash2 en lugar del cabezal MTP (motor 0.1.56, `--draft dflash2`)

**Qué:** desde el 0.1.56 el borrador para la decodificación especulativa puede ser un
modelo DFlash2 con pack propio (`qwen3.8-flash-next-dflash2.q4_0.pack`, ya cuantizado en
cuartos) en lugar del cabezal MTP entrenado junto al modelo. Config: `--draft dflash2`,
`--draft-model <pack>`, `--draft-fallback none`, `--draft-conf 0.7`.

**Cuánto (A/B en frío, 03-11, IQ3_XXS, contexto 131.072, medias de 9 requests en chat y
3 en prefill):**

| Métrica | Control MTP | DFlash2 | Diferencia |
|---|---|---|---|
| chat tok/s | 77,0 (71,2-97,7) | **81,2** (69,4-126,2) | **+5,5 %** en la mediana |
| 4K tok/s | 2.046,1 | 2.040,8 | plano |
| 16K tok/s | 3.041,5 | 3.071,4 | plano |

**Lo que hay que saber:** la ganancia es de mediana, no de peor caso: el rango del
drafter es mucho más ancho (69,4-126,2). En el dominio favorable el techo sube de ~98 a
~126 tok/s; en el desfavorable puede bajar del control. Aun así se adoptó por el
balance. Con `--draft-fallback none` no hay vuelta al MTP en caliente: el rollback es
quitar el `--draft` de la config.

## 9. Anillo de preparación de prompt más profundo (motor 0.1.57, `STRATA_GFX12_RING`)

**Qué:** el 0.1.57 profundiza el anillo de preparación (*staging ring*) por el que pasan
los trozos del prompt antes de leerlos en la GPU: 256 ranuras por debajo de ~6K tokens,
192 hasta 12K y 96 por encima (antes: 96 en todos los tamaños). La ganancia es
bit-exacta (upstream la documenta en `DETAILS.md` de v0.2.11 con +16 % en 4K en un R9700).
No hace falta activar nada: viene de serie. El control del A/B se hizo desactivándolo con
`STRATA_GFX12_RING=0` (la otra vuelta atrás documentada es `STRATA_PREFILL_RING=96`).
En los binarios se comprueba el cambio de familia: la variable no existe en 0.1.55/0.1.56
y sí en 0.1.57.

**Cuánto (A/B en frío, 05-11, IQ3_XXS, contexto 131.072, `--long`):**

| Métrica | Anillo 0 (control) | Anillo profundo | Diferencia |
|---|---|---|---|
| 4K tok/s | 2.098,0 | **2.322,6** | **+10,7 %** |
| 16K tok/s | 3.099,6 | 3.098,8 | dentro del ruido |
| 32K tok/s | 3.067,2 | 3.055,5 | dentro del ruido |
| primer token 4K | 1,94 s | **1,75 s** | −10 % |
| chat tok/s | 79,3 (76,3-126,9) | 82,2 (74,7-125,3) | dentro del rango |

**Lo que hay que saber:** la ganancia se concentra en los 4K; a 16K y 32K el cuello ya
es otro (PCIe/swap de expertos) y el anillo no lo mueve. Es la mayor ganancia de prefill
desde GDN; nuestro +10,7 % en 4K queda por debajo del +16 % que mide upstream en R9700,
pero en la misma dirección. Si algún día da problemas, el rollback es una variable:
`STRATA_GFX12_RING=0`.

## 10. El KV de la conversación sobrevive a un reinicio (motor 0.1.57.90, parche CacheKV de un fork)

**Qué:** Strata aparca el KV de las conversaciones inactivas en un anillo de RAM
(`--conversation-cache-mib`), que se pierde al apagar el motor. Un parche de un fork
ajeno — [kinoyu-ai/Strata-CacheKV-kinoyu](https://github.com/kinoyu-ai/Strata-CacheKV-kinoyu) —
añade un nivel de disco que **sobrevive al reinicio**: dos flags nuevas,
`--conversation-cache-dir <dir>` y `--conversation-cache-persist`, que espejan al final de
cada respuesta las conversaciones aparcadas y las restauran al volver a arrancar.
**No es un parche de Strata y no está enviado arriba**: lo aplicamos nosotros sobre la
etiqueta v0.2.11 (el diff está en [patches/](patches/CacheKV-fork-kinoyu-sobre-v0.2.11.patch)).

**Cómo se monta sin recompilar a mano:** `scripts/install-01590.sh` aplica el diff sobre el
checkout de la etiqueta y compila con el `packaging/build_hip_linux.sh` del propio tag →
componente `0.1.57.90-linux-x86_64-hip-rx9070` (~6 min en esta caja). Un detalle que
descoloca: el binario se declara **`0.1.57`** en `--version` y en los logs (el `.90` solo
consta en su `BUILD.json`), así que `engine_version: 0.1.57` en el health del servidor es
lo esperado, no un fallo. La config con las flags activas es la de
[configs/strata-iq3_s.json](configs/strata-iq3_s.json).

**Cuánto — el test es con reinicio, así que no lo hace `strata_bench.py`:** hay un script
aparte, `scripts/kv-persist-test.sh` (arranca el motor → conversación larga → apagado
normal → segundo arranque → reenvío del mismo prompt). Con el mismo prompt de 29.347
tokens tras el reinicio (12-11, IQ3_S, contexto 94.000):

| | 0.1.57 oficial (control) | 0.1.57.90 con CacheKV |
|---|---|---|
| restaurar desde disco | no existe | **29.340 tokens en 245,5 ms** |
| leer el prompt | 0 reused + 29.347 read en **8.662 ms** | **29.340 reused + 7 read en 634 ms** |
| prefill | — | **−92,7 %** |

En el uso de verdad (no un bench), en la sesión real más larga que teníamos abierta:

```
disk cache: restored 41612 tokens in 191.6 ms
prompt 41648 tokens = 41612 reused + 36 read in 894 ms
```

O sea: el primer request después de encender el PC vuelve a coste de un request normal.
En frío ese prompt costaría ~9 s de prefill (es lo que mide el control del test anterior);
aquí son 894 ms, de los cuales 191,6 ms son restaurar del disco. El ahorro **no está en el
tok/s**, está en el primer token tras cada arranque — por eso la métrica útil es esta y no
la tabla del A/B.

**Los dos niveles en la práctica (13-11, logs de producción en vivo — no protocolo de
bench frío; fuente: `strata-iq3_s.log`):** al día siguiente de publicarlo lo probamos en
vivo y quedó clara la frontera entre el nivel de RAM y el de disco:

| Situación real (13-11 00:14–00:16, IQ3_S) | Lo que mostró el log |
|---|---|
| Sin reiniciar, sesión de 55.208 tokens con la capa de RAM desalojando (`evictions=12` en esa sesión) | `0 reused + 55208 read en 15800 ms` — prefill frío completo (~3.494 tok/s) |
| Reinicio 00:14, sesión de ~60k | `restored 59944 tokens in 279.8 ms` → primer request `61708 = 59944 reused + 1764 read en 2297 ms` (~2,3 s frente a ~17-18 s esperados en frío a ese tamaño, estimado sobre los 3.494 tok/s medidos arriba) |
| Reinicio 00:16, la misma sesión ya en 64k y el disco lleno | `indexed 12 entries, 10.85 GB`; dos expulsiones `LRU capacity` (entradas de 63.851 y 85.148 tok); `restored 64212 tokens in 353.7 ms` → primer request `64244 = 64212 reused + 32 read en 1122 ms` (~1,1 s frente a ~18 s estimado en frío) |

Qué se sigue de esto, y qué no:

- **Durante una sesión viva manda la capa de RAM** (`--conversation-cache-mib`): si se
  agota, el request va completamente frío y el nivel de disco no la sustituye a mitad de
  sesión — su papel documentado es espejar al final de cada respuesta y restaurar al
  arrancar. (El caso de 55k fue un error de prueba: se esperaba reutilización sin
  reiniciar.) Que el disco no atienda mid-sesión es lo observado, no un mecanismo afirmado.
- **Al reiniciar, el disco persiste y devuelve la conversación en cientos de ms**, con el
  primer request a coste casi normal incluso con el disco por encima del techo y expulsión
  LRU en curso.
- **Techo medido, no solo declarado**: con el default de 12.288 MiB y sesiones de 60k–85k
  (1,1-1,5 GB por entrada) caben ~8-10 entradas y **las expulsiones LRU ya empezaban en
  ese arranque**. Si trabajas con varias sesiones grandes a la vez y no quieres que se
  desalojen entre ellas, sube el techo: `--conversation-cache-disk-mib 30720`
  (`df /`: 200 G libres, no urge).
- **Matiz del umbral, sin afirmar mecanismo**: el motor declara el nivel de disco en el
  arranque como `minimum 60001 tokens; mirrors RAM-eligible conversations at reply
  boundaries`, pero en el mismo log se aparca una entrada de 55.656 tokens y se restaura
  una de 59.944 (etiquetada `(checkpoint)`, por debajo del mínimo declarado). El
  comportamiento exacto de ese umbral no lo aclara el log: no afirmamos por qué una
  sesión de ~55-60k se espeja o no.

**Cuánto cuesta en lo demás (A/B en frío, 12-11, IQ3_S, contexto 94.000, run2 auditada en
ambos brazos, en `benches/muestras/cachekv-0.1.57-ctrl-iq3s/` y
`cachekv-0.1.57.90-iq3s/`):**

| Métrica | Control 0.1.57 | 0.1.57.90 | Diferencia |
|---|---|---|---|
| 4K tok/s | 2.441,8 | 2.437,8 | −0,2 % (plano) |
| 16K tok/s | 3.457,1 | 3.461,1 | +0,1 % (plano) |
| primer token 4K / 16K | 1,67 s / 4,67 s | 1,67 s / 4,67 s | sin cambio |
| chat tok/s | 78,0 (70,1-109,3) | 79,0 (74,6-110,1) | dentro del rango |
| agente tok/s | 86,8 (71,5-112,4) | 88,0 (70,1-114,6) | dentro del rango |
| agente acierto de caché % | 69,78 | 69,74 | sin cambio |

Sin las flags el código nuevo no toca nada y con ellas el camino caliente es el mismo: los
números dicen que el coste es cero y el beneficio solo aparece al reiniciar. Es la primera
vez en esta caja que una mejora no se ve en el bench estándar y hay que medirla con un
protocolo propio.

**Lo que hay que saber:**
- El disco **se autolimita**: `--conversation-cache-disk-mib` (default 12.288 MiB) es un
  techo duro con autoexpulsión, y `--conversation-cache-disk-min-free-mib` deja siempre
  512 MiB libres. No hace falta ninguna política de limpieza nuestra: tras un día de uso
  real con varias sesiones abiertas ocupaba **10,8 GiB con 10 entradas**, por debajo del
  techo y sin que tengamos que hacer nada. Si alguna vez trabajas con varias sesiones de
  ~1,5 GB a la vez y quieres que no se desalojen entre ellas, sube el techo (p. ej.
  `--conversation-cache-disk-mib 30720`).
- La restauración es de la **conversación aparcada**, no de un prompt cualquiera: si el
  prompt no coincide con lo espejado, no hay nada que reutilizar.
- No probado sobre motores 0.1.58/0.1.59 (que aquí se rechazaron por otro motivo). En 32K
  la pareja del A/B no usó `--long`; la única ejecución posterior con `--long` sobre esta
  config (13-11, en frío) dio 3.161 tok/s — cota baja, porque el motor le bajó el chunk de
  prompt por falta de RAM libre — y el CacheKV no mostró regresión a esa longitud (ver
  [RESULTADOS.md](RESULTADOS.md)).
- El rollback: quitar las dos flags y volver al componente `0.1.57` (nuestro backup de la
  config es `strata-iq3_s.json.pre-cachekv-20261112.bak`).
