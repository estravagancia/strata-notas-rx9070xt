# Créditos y procedencia de cada pieza

- **Strata** (motor, servidor, utilidades): [github.com/Niko1221/Strata](https://github.com/Niko1221/Strata),
  MIT, © Niko1221 y contribuidores. Todo lo que hay aquí por encima de Strata son notas
  y parches propios; lo que hay dentro de los parches (contexto de código) es de Strata.
- **Versiones usadas**: clon en el lanzamiento v0.1.45; compilaciones propias desde las
  etiquetas v0.2.2 (motor 0.1.46), v0.2.3 (`5c8dd322`, motor 0.1.48), v0.2.4 (`96ca4383`,
  motor 0.1.49); después, **paquetes oficiales** sin compilar: 0.1.50 (v0.2.5),
  0.1.52 (v0.2.7), 0.1.54 (v0.2.8), 0.1.55 (v0.2.9) y, desde el 03-11/05-11, **0.1.56 y
  0.1.57**, todos
  `linux-x86_64-hip-rx9070` con sha256 verificado contra el `SHA256SUMS.txt` de su release
  (0.1.55: `88a19b89…4a77`). Desde el 12-11, en producción un motor **propio: `0.1.57.90`**
  = la etiqueta v0.2.11 más el parche CacheKV de un fork ajeno (ver la siguiente viñeta),
  compilado por nosotros con el `packaging/build_hip_linux.sh` del tag
  (`scripts/install-01590.sh`). La documentación del clon está sincronizada con **v0.2.13**
  (sincronizada el 09-11; los motores en marcha siguen siendo los de la familia 0.1.57),
  con el endurecimiento local reaplicado.
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
  producción de forma indistinta; packs `…-GSQ-RCO-…` descargados por el propio setup de Strata.
  Vector de control de negación: `Huihui-Qwen3.8-Flash-Next-refusal-direction-r.gguf`.
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
