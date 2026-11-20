# Créditos y procedencia de cada pieza

- **Strata** (motor, servidor, utilidades): [github.com/Niko1221/Strata](https://github.com/Niko1221/Strata),
  MIT, © Niko1221 y contribuidores. Todo lo que hay aquí por encima de Strata son notas
  y parches propios; lo que hay dentro de los parches (contexto de código) es de Strata.
- **Versiones usadas**: clon en el lanzamiento v0.1.45; compilaciones propias desde las
  etiquetas v0.2.2 (motor 0.1.47, verificado el 17-11 en su `CMakeLists.txt`), v0.2.3
  (`5c8dd322`, motor 0.1.48), v0.2.4 (`96ca4383`,
  motor 0.1.49); después, **paquetes oficiales** sin compilar: 0.1.50 (v0.2.5),
  0.1.52 (v0.2.7), 0.1.54 (v0.2.8), 0.1.55 (v0.2.9) y, desde el 03-11/05-11, **0.1.56 y
  0.1.57**, todos
  `linux-x86_64-hip-rx9070` con sha256 verificado contra el `SHA256SUMS.txt` de su release
  (0.1.55: `88a19b89…4a77`). Desde el 12-11, en producción un motor **propio: `0.1.57.90`**
  = la etiqueta v0.2.11 más el parche CacheKV de un fork ajeno (ver la siguiente viñeta),
  compilado por nosotros con el `packaging/build_hip_linux.sh` del tag
  (`scripts/0.1.57.x/install-01590.sh`). El 15-11 se instaló además el motor oficial **0.1.60**
  (v0.2.14) para su gate: NO adoptado (falló la no-regresión; ver
  [RESULTADOS.md](RESULTADOS.md)). La documentación y el servidor del clon están sincronizados
  con **v0.2.15** (con el endurecimiento local reaplicado; los motores en marcha siguen
  siendo los de la familia 0.1.57).
- **Versiones usadas (era actual, desde el 18-11)**: clon nuevo anclado a la etiqueta
  **v0.2.16** con un commit propio `4a7d49cb9` = v0.2.16 + CacheKV (kinoyu-ai) + IL-mmvq
  portado a HIP + las 5 divergencias de [patches/era-actual/](patches/era-actual/). Motores
  **`0.1.62.90`** (compilado con el ROCm del sistema, apt 7.2.1; queda como vuelta atrás) y
  **`0.1.62.91`** (el mismo commit con el SDK ROCm 10.3 del bundle; en producción desde el
  19-11). Recetas: `scripts/0.1.62.9x/install-016290.sh` e `install-016291.sh`. El checkout
  anterior sigue existiendo con su historia; conviven (ver [CAMBIO-DE-ERA.md](CAMBIO-DE-ERA.md)).
- **IL-mmvq en la ruta HIP** (los motores `0.1.57.91`, `0.1.62.90` y `0.1.62.91`): el trabajo
  material es de **bsorensen110**, fork público [github.com/bsorensen110/Strata](https://github.com/bsorensen110/Strata)
  (otro usuario de AMD RDNA 4). Nosotros portamos esas mejoras a nuestra base, abrimos las
  familias de kernels a HIP y añadimos el control de paridad; el porteo lo verificamos aquí
  bit a bit. No está enviado a Strata.
- **Parche CacheKV** (el motor `0.1.57.90`): es trabajo de **kinoyu-ai**, fork público
  [github.com/kinoyu-ai/Strata-CacheKV-kinoyu](https://github.com/kinoyu-ai/Strata-CacheKV-kinoyu).
  Nosotros solo lo aplicamos sobre una etiqueta concreta y lo medimos; el diff que publicamos
  en `patches/` lleva el autor original (kinoyu-ai) en el commit. No está enviado a Strata:
  quien puede enviarlo arriba es su autor, no nosotros.
- **Wheels GPU (ROCm/TheRock)**: la release empaqueta `7.10.0a20251120` (`gfx120X-all`);
  producción corre sobre un **runtime ROCm propio 10.3.0a20261030 con hipBLASLt 1.5.0**
  (wheels `nightly.repo.amd.com`, instalados aparte y apuntados con `lib_dirs`, sin
  recompilar el motor) y la tabla `gfx1200-hipblaslt-100500.txt` regenerada en esta caja
  con el afinador de Strata (168 filas). Ver [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md).
  Sin ROCm en el sistema.
- **llama.cpp**: fijado en `3cf03257` (el pin del repositorio Strata de aquella rama).
- **Modelo**: Qwen3.8-Flash-Next en cuantizaciones **IQ3_XXS** e **IQ3_S**, ambas en
  producción **IQ3_S** desde el 12-11 (IQ3_XXS fue el modelo de producción hasta esa
  fecha y queda como alternativa para contexto largo); packs `…-GSQ-RCO-…` descargados por el propio setup de Strata.
  Vector de control de negación: `Huihui-Qwen3.8-Flash-Next-refusal-direction-r.gguf`, publicado en
  [alesha-pro/Qwen3.8-Flash-Next-abliterated-GSQ-RCO-Strata-GGUF](https://huggingface.co/alesha-pro/Qwen3.8-Flash-Next-abliterated-GSQ-RCO-Strata-GGUF)
  (la dirección de negativa procede de los pesos de huihui-ai; verificado el 17-11).
- **Vocabularios de borradores** (`data/draft_vocab_es.bin` y
  `data/draft_vocab_es-modern.bin`): propios, generados en esta caja a partir de corpus de
  chats reales en español; cómo se generan, en [data/README.md](data/README.md).
- **Herramienta de bench**: `tools/strata_bench.py` del propio Strata; el protocolo en
  frío y el script son propios (documentados aquí).
- Los docs de Strata [AMD_HIP.md](https://github.com/Niko1221/Strata/blob/main/docs/AMD_HIP.md)
  y [COMMUNITY_BENCHMARKS.md](https://github.com/Niko1221/Strata/blob/main/docs/COMMUNITY_BENCHMARKS.md)
  son la base del estilo "números medidos con lo que fueron medidos" que imita este repo.

Los parches C1/C2 están **preparados pero no enviados** a Strata; si algún día se
publican arriba, aquí se enlazará el hilo correspondiente. Las notas de los motores
0.1.52/0.1.54/0.1.55 y del runtime ROCm propio (incluidos los negativos: defaults de
gfx12, contexto 262k con la capa adaptativa apagada) están en
[LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md) — son justo las que nos habría gustado
encontrar a nosotros.
