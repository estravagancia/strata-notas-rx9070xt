# Créditos y procedencia de cada pieza

- **Strata** (motor, servidor, utilidades): [github.com/Niko1221/Strata](https://github.com/Niko1221/Strata),
  MIT, © Niko1221 y contribuidores. Todo lo que hay aquí por encima de Strata son notas
  y parches propios; lo que hay dentro de los parches (contexto de código) es de Strata.
- **Versiones usadas**: clon en el lanzamiento v0.1.45; compilaciones propias desde las
  etiquetas v0.2.2 (motor 0.1.46), v0.2.3 (`5c8dd322`, motor 0.1.48), v0.2.4 (`96ca4383`,
  motor 0.1.48.1); motor final **0.1.50 oficial** del lanzamiento v0.2.5 (paquete
  `linux-x86_64-hip-rx9070`, sha256 `0a8f53f1…` verificado contra `SHA256SUMS.txt`).
  La documentación del clon está sincronizada con v0.2.6 (motor 0.1.51).
- **Wheels GPU (ROCm/TheRock)**: `7.10.0a20251120` (`gfx120X-all`), los que instalaría
  el setup de Strata en esa fecha; sin ROCm en el sistema.
- **llama.cpp**: fijado en `3cf03257` (el pin del repositorio Strata de aquella rama).
- **Modelo**: Qwen3.8-Flash-Next en cuantizaciones **IQ3_S** (producción) e IQ3_XXS
  (serie de benches), packs `…-GSQ-RCO-…` descargados por el propio setup de Strata.
  Vector de control de negación: `Huihui-Qwen3.8-Flash-Next-refusal-direction-r.gguf`.
- **Herramienta de bench**: `tools/strata_bench.py` del propio Strata; el protocolo en
  frío y el script son propios (documentados aquí).
- Los docs de Strata [AMD_HIP.md](https://github.com/Niko1221/Strata/blob/main/docs/AMD_HIP.md)
  y [COMMUNITY_BENCHMARKS.md](https://github.com/Niko1221/Strata/blob/main/docs/COMMUNITY_BENCHMARKS.md)
  son la base del estilo "números medidos con lo que fueron medidos" que imita este repo.

Los parches C1/C2 están **preparados pero no enviados** a Strata; si algún día se
publican arriba, aquí se enlazará el hilo correspondiente.
