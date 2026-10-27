# Parches

Ninguno está enviado a Strata (a fecha 27-10-2026). Los C1/C2 tienen el texto del PR
en inglés ya redactado; la decisión de enviarlos es pendiente.

| Fichero | Qué hace | ¿Aplicado aquí? |
|---|---|---|
| `C1-hipblaslt-lookup-familia-hermana.patch` | Que la búsqueda de tabla de ajuste caiga a la de la arquitectura hermana (gfx1200↔gfx1201, gfx1100/1101/1102). Base: tag v0.2.3 | No (va en el outbox; el motor oficial 0.1.50 no lo trae) |
| `C2-tabla-gfx1200-hipblaslt-100200-67filas.patch` | Tabla de 67 filas recalibrada en RX 9070 XT + doc. Base: v0.2.3 | La tabla sí se usa (en `tools/hip/` del clon); el commit no está subido |
| `C6-borrador-popcount-iq_avx512.patch` | Popcount en los expertos IQ3 (Zen 5). Base: v0.2.4 | Compilado y medido: **−1,5 % chat → no adoptado** (bandera apagada) |
| `C5-borrador-vram-elastic-hip.md` | apuntes del port HIP de `--vram-elastic` (ceder VRAM a otro programa entre requests) | No portado: sin uso local para eso |
| `endurecimiento-server-v0.1.45.patch` | Endurecimiento del servidor Python (cabeceras/backlog/imágenes). Diff sobre el clon v0.1.45 | **Sí, en producción desde 19-10** |

Evidencia medida de C1/C2 (motor 0.1.47, 21-10): prefill 4K +1,2 %, 16K +2,0 % — con la
advertencia de que los dos runs usaron contexto distinto (100.000 vs 105.000); el
detalle, en `RESULTADOS.md`.
