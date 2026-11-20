# Muestras de bench (era actual: motores 0.1.62.9x)

Cinco ejecuciones del 19-11-2026, en el mismo formato `results.json` "schema 1" de
`tools/strata_bench.py` (3 pasadas por métrica, máquina, versión del motor y detalles del
arranque). Pertenecen a la era documentada en [CAMBIO-DE-ERA.md](../../../CAMBIO-DE-ERA.md):
el código es el commit propio `4a7d49cb9` (base v0.2.16 + CacheKV + IL-mmvq) y lo único que
cambia entre series es el compilador del motor y el chunk de prompt.

| Carpeta | Motor | Chunk de prompt | Modelo | Para qué era |
|---|---|---|---|---|
| `2026-11-19-1012-ctrl90-chunk16384-iq3-s/` | 0.1.62.90 (ROCm apt 7.2.1) | 16.384 | IQ3_S | control de la era |
| `2026-11-19-1040-ctrl90-chunk16384-iq3-xxs/` | 0.1.62.90 | 16.384 | IQ3_XXS | control de la era |
| `2026-11-19-1152-p5-91-chunk8192-iq3-s/` | 0.1.62.91 (SDK ROCm 10.3) | 8.192 | IQ3_S | brazo del cambio de compilador, primera pasada |
| `2026-11-19-1215-p5-91b-chunk16384-iq3-s/` | 0.1.62.91 | 16.384 | IQ3_S | pareja del control con el motor nuevo |
| `2026-11-19-1232-p5-91b-chunk16384-iq3-xxs/` | 0.1.62.91 | 16.384 | IQ3_XXS | ídem en el modelo pequeño |

Cómo se distinguen los dos motores, si el `results.json` no lo dice: el campo
`machine.engine_version` reporta `0.1.62` en las cinco (el nombre del componente no viaja en
ese campo). La distinción está en el brazo de bench que generó cada serie —
`bench/bench-iq3_s.json` fija el componente `0.1.62.90` y `bench/bench-iq3_s-91.json` fija
el `0.1.62.91`— y en el nombre de la carpeta.

## Reglas de comparabilidad de esta serie

- Comparables entre sí: `ctrl90-chunk16384-*` contra `p5-91b-chunk16384-*` (misma suite,
  mismo chunk, mismo modelo en cada pareja). La serie con chunk 8.192 queda aparte: el techo
  de chunk lo fija la RAM libre al arrancar y cambia el resultado del prefill.
- Ninguna de estas ejecuciones es comparable con las de
  [`../../0.1.57.x/muestras/`](../../0.1.57.x/muestras/): otros motores, otro servidor,
  otros controles.
- **Configuración del borrador:** todas corrieron con el pack `dflash2.q4_0.pack`. La
  producción cambió después a `dflash2.strata1.q4_0-selq4.pack`; mientras no haya una serie
  con esa configuración, estas cifras describen cómo se construyó y validó la era actual, no
  lo que rinde hoy la producción.
- El bench envía los prompts con temperature 0; la producción usa muestreo (temperatura 0,7
  desde el 18-11). Los porcentajes de borradores aceptados del bench no son comparables con
  los del uso diario.

Qué mirar para repetir el experimento: `machine.engine_version`, `params` (chunk), el modelo
y el bloque de resultados por métrica. El protocolo completo (pasada de calentamiento
descartada, prompts con etiqueta única para que la caché de conversación no ayude) está en
el `README.md` de cada carpeta.
