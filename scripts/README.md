# Scripts, separados por era

Copias de los ficheros tal como los ejecutamos en esta caja, con las rutas sustituidas por
`/home/TU-USUARIO`. Ninguno arranca solo: los lanzamos a mano. El contexto del corte entre
eras está en [CAMBIO-DE-ERA.md](../CAMBIO-DE-ERA.md).

| carpeta | contenido |
|---|---|
| [`0.1.57.x/`](0.1.57.x/) | los scripts de medida e instalación de la era anterior (runner del bench en frío, test del KV en disco con reinicio, instalador del motor `0.1.57.90`) |
| [`0.1.62.9x/`](0.1.62.9x/) | los instaladores de los motores nuevos y los arranques de producción del espacio donde viven |

## 0.1.62.9x/ — era actual

| Fichero | Para qué | Dónde se ejecuta |
|---|---|---|
| `install-016290.sh` | Instala el motor propio `0.1.62.90` = base v0.2.16 + CacheKV + IL-mmvq portado a HIP, compilado aquí con el ROCm del sistema (apt 7.2.1). Usa como plantilla de metadata el componente `0.1.61.90`; no toca configs ni hace el cambio de producción | dentro del clon nuevo (`build-rx9070`) |
| `install-016291.sh` | Instala `0.1.62.91`: **el mismo commit** compilado con el SDK ROCm 10.3 del bundle (hipcc 7.18 / clang 24). Lleva en los comentarios las dos desviaciones necesarias para compilar con esos paquetes | sobre un worktree aparte (`/tmp/opencode/p5-src`) |
| `run-strata-iq3_s-up.sh` | Arranca la producción: el servidor de `terminal/serve/server.py` del clon con la config `strata-iq3_s-up.json`, en el puerto 8081. Reintenta el arranque hasta 3 veces y deja en los comentarios la comprobación fija al arrancar (que el motor lleve el drafter declarado y que el log diga cuántos tokens admite) | dentro del clon nuevo |
| `run-strata-iq3_xxs-up.sh` | lo mismo con la config de IQ3_XXS | ídem |
| `run-bench.sh` | Runner del bench en frío de esta era (protocolo heredado del espacio hermano, portado el 19-11): arranca el motor con un brazo de bench, deja log propio y copia de la config exacta usada. Las cinco muestras publicadas salieron de aquí | dentro del clon nuevo (`bench/`) |
| `bench-arms/bench-iq3_s.json` | Brazo de bench para IQ3_S sobre el motor `0.1.62.90`: espejo de la config de producción sin visión, con el chunk de prompt fijo en 16.384 | — |
| `bench-arms/bench-iq3_s-91.json` | El mismo brazo fijando el motor `0.1.62.91` (es lo que cambia entre las series `ctrl90` y `p5-91b`) | — |

Dos cosas a tener en cuenta si quieres repetir esto en tu máquina:

- Los `run-*` siguen usando el entorno Python del checkout anterior (`.../Strata/.venv/...`)
  para lanzar el servidor: en esta caja conviven los dos espacios y comparten ese entorno.
  En la tuya, apunta ese path al tuyo.
- El techo de chunk de prompt lo fija la RAM libre al arrancar; por eso los brazos de bench
  lo fuerzan (16.384) y por eso una serie con chunk distinto no es comparable. Con el motor
  de producción en marcha no cabe un segundo motor (~55/61 GiB): hay que parar la
  producción antes de medir.
