# Lo que NO funcionó (y no lo repitas)

Todo esto se midió en esta caja con el protocolo en frío. Un negativo documentado vale
tanto como un positivo: son ideas que cualquiera (incluido yo mismo dentro de seis
meses) podría volver a intentar.

## `STRATA_IQ_POPCOUNT=1` — popcount Zen 5 en los expertos IQ3 → **−1,5 % chat**

El atajo: sustituir una tabla de signos por `_mm256_popcnt_epi32` (instrucción que la
CPU tiene). Micro-medida pura del kernel: **15-30 % más rápido**. Servidor completo
(A/B mismo día, `-iqpc0` vs `-iqpc1`): chat **−1,5 %**, prefill plano.
Moraleja: con el cuello en el PCIe (55 GB/s reales), acelerar el decode CPU de los
cuantizados no mueve el total — y el overhead de la bandera sí.

## `STRATA_IQ_GATHER=1` — gathers AVX-512 → **−1,4 % chat**

Arriba (upstream) lo midieron en Zen 4: 3-5 % más LENTO. Hipótesis local: Zen 5 (9800X3D)
tiene gather por hardware y se invertirá. Medido (A/B mismo día `-iq3-0150` vs
`-iqgather`): **−1,5 % / −1,4 %** en dos ejecuciones. No se invierte. Segundo flag de CPU
que se estrella contra el mismo muro.

## Subir el contexto (131k o 163k) → chat −4 % para +1 % de prefill

Ejecuciones del 23-10 contra la ancla del día (98.304):

| Contexto | 4K | 16K | chat |
|---|---|---|---|
| 131.072 | +1,0 % | +0,8 % | **−4,2 %** |
| 163.840 | −1,5 % | +0,3 % | **−3,9 %** |

Ninguno superó nuestro umbral de adopción (subida de prefill >1,5 % sin perder >2 % de
chat). Se mantenía 98.304… hasta que el 26-10 el usuario subió a 131.072 por necesidad
de contexto real aceptando el coste. Si solo necesitas contexto largo, 131.072 es el
paso menos caro.

## `--kv k8v4` (cuantización de la memoria KV) → desastre en AMD

4K **−23,7 %**, 16K **−31,7 %**. Upstream lo reporta casi neutro en CUDA (RTX 3090:
prompt −2..5 %); la rotación Hadamard de la clave V es mucho más lenta en HIP. Dato a
tener en cuenta en cualquier RDNA 3/4: lo que está medido en NVIDIA no vale aquí.

## Wheels ROCm nuevos (7.14) + motor experimental → −22 % a 4K

El experimento "Plan B": motor de laboratorio 0.1.47.14 con wheels **7.14.0a20260612**
y su tabla 100400, corriendo en paralelo (puerto 8082) contra la baseline del momento.
Prefill 4K **−22 %** (1.547 vs 1.990), 16K −1,3 %. Se quedó la combinación vieja:
wheels 7.10.0a20251120 + su tabla 100200. Buscar lo nuevo no pagó aquí.

## Caché de expertos "por capa" (`--expert-cache-per-layer`) → ruido

+0,8/+0,1/+1,2 % (4K/16K/chat), dentro de la varianza entre ejecuciones. No adoptado.

## `--spec-min-p 0.75` → neutro

Chat +4,7 % pero 4K −2,2 % y 16K −1,0 %. (Ojo: ese +4,7 % es del día sin el subset
español; la historia cambió cuando el subset entró — ver [LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md).)

## `--pcie-frac 0.6` (ajuste de la ventana de carga por PCIe) → nada

Modo determinista, mismo día, única variable: −0,2/−0,1/−0,3 %. El auto-valor de la
sonda (0.55) ya era correcto; tocarlo no sirve.

## Visión (imágenes) en la GPU → 1 GiB de VRAM que se paga en chat

El lector de imágenes en GPU (`strata-vision-hip`) es rápido (1,06 s por imagen
768×768) pero ocupa ~1 GiB de VRAM estable que se resta de la cache de expertos. Con
16 GiB justos, mejor lector en CPU (el valor por defecto de Strata para tarjetas de
menos de ~23 GB). Coincide con lo que recomienda upstream.

## Borradores "dflash2" → descartado de oídas, adoptado al medirlo

Esta es la historia de un negativo que resultó falso, y por eso va aquí y no en
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §8.

- **Antes del 03-11** no lo intentamos: upstream lo había medido en familias RDNA 4 y
  lo reportaba *"gfx1201 (R9700): slower on every prompt"*. Confiamos en esa medida y la
  apuntamos como descartada, sin replicarla.
- **El 03-11 sí lo medimos**, con el motor 0.1.56 y A/B en frío del mismo día contra el
  cabezal MTP (IQ3_XXS, contexto 131.072): chat **+5,5 % en la mediana** (81,2 vs 77,0),
  4K y 16K planos. **Se adoptó** y es hoy la config de producción (`--draft dflash2`,
  `--draft-fallback none`, `--draft-conf 0.7`).

Moraleja, la misma del aviso del final de este fichero: la cifra ajena que nos hizo
descartarlo no era de esta caja. Aquí sigue habiendo un coste real —el rango del borrador
es mucho más ancho (69,4-126,2 frente a 71,2-97,7 del control)—, pero el balance salió a
favor. Si algún día quieres volver atrás, el rollback es quitar el `--draft` de la config.


## Los defaults nuevos de gfx12 del motor 0.1.52 → **chat −8,8 %**

El lanzamiento v0.2.7 (motor 0.1.52) traía cuatro interruptores de decodificación nuevos
para gfx12 y un reparto distinto de la ventana PCIe. Con los defaults tal cual: chat
**91,7 → 71,5 tok/s (−8,8 %)** y borradores aceptados 81,9 % → 56,9 %. Probamos apagar los
cuatro de uno en uno: **cada uno recupera el prompt 0** (ningún culpable único; el daño
necesita los cuatro activos). Con `STRATA_DEFAULTS=026` (los defaults viejos) queda
neutro (+0,2 %). La solución que se adoptó fue más fina: **solo `STRATA_EXPDEC=0`** da
+2,1 % sobre el control (6 de 6 ejecuciones), y los otros tres se quedaron como vinieron.
Lección: un default de upstream no está medido en tu tarjeta; apágalo si tu A/B lo pide.

## Contexto 262.144 + `--pcie-frac 0` + `--adapt-every 0` → **chat −28 %**

El 29-10 se subieron a mano tres knobs a la vez (contexto 262k, `--kv-resident 32768`,
reserva 1.024 MiB) y se apagaron dos mecanismos (`--pcie-frac 0`, `--adapt-every 0`). En
frío: chat **56,0-56,6 vs 78,1** del control (−28 %) y agente −21 %, con prefill plano. El
trio contexto/reserva no era el culpable (los contadores de KV salen idénticos); lo que
mata es la **capa adaptativa apagada** (acierto de la caché de expertos 85 % → 60-68 %)
sumada a **cero lecturas PCIe** (sin ellas no se repone la caché). Rollback hecho el mismo
día. Si alguien quiere contexto 262k, que suba primero el contexto solo y mida; no toque
`--adapt-every` sin A/B.

## `--spec-min-p 0.70` sobre el motor 0.1.54 → neutro (y por qué se queda 0,50)

A/B del 30-10 con dos ejecuciones por brazo: chat **−0,1 % / +2,4 %** (gate ≥ +1,5 % en las
dos, no cumplido). Un detalle bonito: los borradores aceptados suben **+11 puntos**
(61-63 % → 72,6-74,3 %) pero el rendimiento no, porque aceptar más tarde no compra
tokens extra. El primer token mejora un pelo en 4K/16K (≈50-70 ms). Se queda 0,50.

## Y un aviso sobre el propio proceso

Dos notas de rendimiento que dábamos por ciertas resultaron ser falsas en su día (una
porque citaba documentación de una versión vieja que la documentación nueva contradice,
otra porque usaba cifras ajenas que no aplicaban a esta ruta). Regla que aprendimos:
**nada de decisiones con cifras que no hayas medido tú en tu caja**, y medir siempre en frío.
