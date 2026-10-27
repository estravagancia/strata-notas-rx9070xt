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
