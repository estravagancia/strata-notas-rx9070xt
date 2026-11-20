# Configs reales, separadas por era

| carpeta | contenido |
|---|---|
| [`0.1.57.90/`](0.1.57.90/) | las dos configs de la era anterior (motor propio `0.1.57.90` = etiqueta v0.2.11 + parche CacheKV): IQ3_S en producción e IQ3_XXS como alternativa |
| [`0.1.62.91/`](0.1.62.91/) | las dos configs de la era actual (motor propio `0.1.62.91` = base v0.2.16 + CacheKV + IL-mmvq, compilado con el SDK ROCm 10.3), tal como están montadas en la caja desde el 19-11 |

Las dos carpetas están saneadas igual: las rutas aparecen como `/home/TU-USUARIO/` y no
llevan datos personales. Comparar una config con la otra tiene sentido solo en parte: los
motores son distintos, así que las diferencias de rendimiento no son atribuibles a la config.

Qué cambió entre la config vieja y la nueva (detalle en [CAMBIO-DE-ERA.md](../CAMBIO-DE-ERA.md)):

- **Igual**: pack del modelo, contexto (94.000 en IQ3_S), KV en int8 con 16.384 residentes,
  anillo de preparación de prompt, drafter DFlash2, CacheKV en disco y las banderas de
  entorno de siempre.
- **Cambiado por decisión de uso** (no es cosa del motor): el servidor escucha en la
  dirección de la red local en lugar de solo `127.0.0.1`, y el muestreo declara más
  parámetros (temperatura 0,7 frente a 0,6).
- **Cambiado por el corte**: las rutas del motor, del registro de sesiones y del log apuntan
  al espacio nuevo, y el pack del borrador pasó de `dflash2.q4_0.pack` a
  `dflash2.strata1.q4_0-selq4.pack`. Ten en cuenta que **las medidas publicadas de la era
  actual se hicieron con el pack antiguo**.
