# Scripts de medida (copias de los que usamos aquí)

Son los ficheros tal como los ejecutamos, con las rutas de esta máquina sustituidas por
`/home/TU-USUARIO` y el host por `127.0.0.1`. Los lanzamos **nosotros** a mano, con el
servidor de producción parado: nunca arrancan solos.

| Fichero | Para qué | Dónde se ejecuta |
|---|---|---|
| `run-bench.sh` | Runner del bench en frío (protocolo del 23-10): arranca el motor con una config, dos ejecuciones de `strata_bench.py` (`run1` = calentamiento, `run2` = la que publicamos), log propio del arranque | dentro del clon de Strata (usa `tools/strata_bench.py`) |
| `kv-persist-test.sh` | Test del **KV en disco persistente**: arranca el motor → conversación larga → apagado normal → segundo arranque → reenvía el mismo prompt. Es el protocolo con el que se midió el **−92,7 %** del prefill tras reinicio, porque el bench continuo no ve ese cambio | dentro del clon (necesita `bench/kv-persist-phase.py`, y este el `tools/` del clon) |
| `kv-persist-phase.py` | Las dos fases del test anterior (antes y después del reinicio): mide `prompt_ms` y `cached_tokens` y compara las respuestas byte a byte con temperature 0 | — |
| `install-01590.sh` | Compila e instala el motor propio `0.1.57.90` = etiqueta v0.2.11 + el parche CacheKV del fork kinoyu (`packaging/build_hip_linux.sh` del tag, ~6 min en esta caja). No toca configs ni hace el swap | sobre el checkout de la rama `local/kinoyu-cachekv` (ruta configurable con `WT=`) |

Los números que produjeron están en [../RESULTADOS.md](../RESULTADOS.md) y su lectura, en
[../LO-QUE-FUNCIONO.md](../LO-QUE-FUNCIONO.md) (§9 anillo, §10 KV en disco).

Aviso: `install-01590.sh` menciona el venv de ROCm de esta caja (`python3.14`,
`_rocm_sdk_*`). Si tu runtime ROCm es suelto en lugar de un venv, apunta `HP`/`CORE`/`LIBW`
a sus directorios; el comentario dentro del script lo indica.
