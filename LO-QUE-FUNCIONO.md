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

**Cuánto (1 corrida limpia, 26-10):** chat **+0,8 %**, borradores aceptados **+2,8
puntos porcentuales**, y **−93 MiB** de VRAM del cabezal. Una segunda corrida se
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
entre corridas "en caliente"). Sin él, habríamos adoptado cuatro cosas que no mejoraban
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

**Cuánto (A/B en frío, 31-10, dos corridas por brazo, IQ3_XXS, contexto 131.072):**

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
