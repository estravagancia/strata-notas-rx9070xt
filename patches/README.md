# Parches propios, separados por era

| carpeta | contenido |
|---|---|
| [`era-anterior/`](era-anterior/) | los 6 ficheros de la época 0.1.49–0.1.57.x (incluido el parche CacheKV del fork ajeno kinoyu-ai, que sigue vivo en los motores nuevos) con su tabla de estado |
| [`era-actual/`](era-actual/) | las 5 divergencias sobre la base v0.2.16 con las que se construyen los motores `0.1.62.9x` |

Contexto del corte: [CAMBIO-DE-ERA.md](../CAMBIO-DE-ERA.md).

## era-actual/ — divergencias sobre v0.2.16

Ninguna está enviada a Strata (el clon donde se desarrollan tiene el upstream de solo
lectura). CacheKV e IL-mmvq no están aquí como parche: forman parte del commit base del
motor (`4a7d49cb9`); lo que sí va como parche suelto es lo que hubo que tocar para poder
portarlos y compilarlos.

| Fichero | Qué hace | Estado |
|---|---|---|
| `p1-hip-gate-y-shim-l2.patch` | extiende a HIP el control de paridad IL (upstream solo lo ejecuta en CUDA) y quita un guard de AMD al shim de nivel 2 | aplicado; es lo que permite verificar la paridad bit a bit del porteo IL en esta tarjeta |
| `p1-sink-try-catch.patch` | protege con try/catch el punto de salida del servidor, para que un fallo no tumbe el proceso | aplicado |
| `p1-dedupe-snapshot-sources.patch` | quita una lectura duplicada en las pruebas de instantánea de conversación (ese test no compilaba en ningún build) | aplicado |
| `serve-local-hardening-v0.2.16.patch` | endurecimiento del servidor con imágenes: respuesta neutra y razón legible ante peticiones inválidas, y control de la arquitectura gfx1201 | aplicado y verificado en vivo el 19-11 (puerto de visión) |
| `p5-rocm-sdk-103-build.patch` | hace posible compilar con el SDK ROCm 10.3: los paquetes nuevos no propagan el flag de compilación HIP y sin él los `.cu` se compilaban como CUDA | aplicado; es la base del motor en producción (`0.1.62.91`) |

Los tres primeros son fixes de compilación del porte (P1); el cuarto es el endurecimiento
que ya existía en la era anterior, re-portado al servidor nuevo; el quinto pertenece al
cambio de compilador (P5).
