# Muestras de bench, separadas por era

Cada subcarpeta contiene ejecuciones completas del mismo formato (`results.json` "schema 1"
de `tools/strata_bench.py`, con su `README.md` resumen) y su propia tabla de qué es cada
ejecución:

| carpeta | contenido |
|---|---|
| [`0.1.57.x/muestras/`](0.1.57.x/muestras/) | 19 ejecuciones de la era anterior (motores 0.1.49 → 0.1.57.90), del 24-10 al 16-11 |
| [`0.1.62.9x/muestras/`](0.1.62.9x/muestras/) | 5 ejecuciones de la era actual (motores 0.1.62.90 y 0.1.62.91), del 19-11 |

**No comparar entre eras.** Son motores construidos sobre bases distintas, con otro servidor
y controles propios. Dentro de cada carpeta vale la regla de siempre: solo son comparables
las ejecuciones de la misma suite y el mismo chunk de prompt. El porqué del corte está en
[CAMBIO-DE-ERA.md](../CAMBIO-DE-ERA.md).
