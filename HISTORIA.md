# Historia de una caja

*Tres semanas (del 20 de octubre al 13 de noviembre de 2026) convirtiendo un PC de casa
en un servidor de inteligencia artificial. Lo que se hizo, qué se logró y qué se aprendió.
Sin tecnicismos: los números concretos están en [RESULTADOS.md](RESULTADOS.md).*

## El punto de partida

La idea era sencilla de decir y nada trivial de conseguir: que un modelo de lenguaje grande
—de los que normalmente viven en servidores de una empresa— funcionase **en casa**,
en un PC con una tarjeta gráfica de 16 gigabytes y 64 gigabytes de memoria, sin conexión a la nube,
sin suscripciones y sin que nadie lea tus conversaciones por ti. El modelo elegido pesa
entre 76 y 84 gigabytes en disco según la versión: mucho más de lo que cabe en la tarjeta gráfica. Que funcione igual
ya es, de por sí, una pequeña hazaña de ingeniería —**pero esa hazaña no es nuestra**.
El mérito es de [Strata](https://github.com/Niko1221/Strata), un proyecto libre (licencia MIT)
de Niko1221 y sus colaboradores, cuyo motor consigue que un modelo más grande que la memoria de la
tarjeta funcione apoyándose en la memoria del sistema. Lo que añade este cuaderno es lo que hubo
detrás: dos semanas de elegir, configurar y medir con rigor en un PC concreto.

Pero "que funcione" no era el listón. El listón era que fuese **rápido, fiable y mejorable**.
Y eso es lo que ocupa estas dos semanas.

## El método: nunca actualizar a ciegas

Casi todo lo que sigue obedece a una sola regla que nos impusimos desde el primer día:

> **Ninguna mejora se adopta porque "suena bien" o porque el fabricante la anuncia.**
> Primero se mide contra lo que ya teníamos funcionando, con la misma prueba, en las mismas condiciones,
> con el equipo recién encendido y frío. Si el número mejora y no rompe nada más, se adopta.
> Si no, se descarta y queda escrito el porqué. Y cada adopción lleva siempre preparada la marcha atrás:
> la copia de la configuración anterior y un guion que la restaura en un minuto.

Gracias a esa disciplina, estas tres semanas incluyen varias actualizaciones que resultaron ser
**negativas** y que se detectaron y se deshicieron el mismo día. Sin medirlas,
algunas habrían pasado desapercibidas durante semanas, en forma de un equipo "un poco más lento"
cuya causa nadie sabría señalar.

## La cronología

### 20–21 de octubre · Los cimientos
*engine 0.1.46*

Primeras versiones del motor probadas y medidas. Nace el "banco de pruebas": un protocolo para
repetir siempre la misma tanda de pruebas (una conversación normal, un texto de 4.000 tokens,
otro de 16.000, una tarea de agente) y un panel local donde queda guardada la historia de todas
las mediciones, versión a versión. Ese panel es hoy la memoria del proyecto.

### 23–25 de octubre · El banco de pruebas se pone serio
*engine 0.1.48, compilado en casa → 0.1.49 → 0.1.50 oficial*

Se compila una versión del motor a medida de esta tarjeta y se adopta tras medirla.
Días después llegan las primeras versiones oficiales preparadas para esta tarjeta: se miden,
resultan neutras (ni mejor ni peor), y se adoptan igualmente por mantenerse al día sin pagar peaje.
Ese mismo día se detecta que el protocolo de medida tenía un agujero (equipos "calientes" frente
a "fríos" dan resultados distintos) y se corrige: a partir de ahí, todas las comparaciones se hacen
en frío, con el equipo recién arrancado. También se prueba a ampliar la memoria de conversación
y se mide que no compensa: se queda la que había. **Cada descarte queda documentado.**

### 26–27 de octubre · Proteger lo conseguido

Antes de seguir avanzando, se aseguraron las espaldas: un archivo de respaldo de recuperación
tras desastre (configuraciones, parches propios, la serie completa de mediciones) en un disco
externo; un repositorio de copia de seguridad del trabajo propio; y un repositorio público
de notas en español, donde está lo que funcionó y lo que no, para quien tenga una tarjeta parecida.
También se construyó un ajuste del motor en español: como el modelo predice palabra a palabra,
acotar su vocabulario a nuestro idioma lo afina.

### 27 de octubre (tarde-noche) · Detectives de una caída invisible
*engine 0.1.52: descartado por medidas → adoptado horas después con un interruptor apagado*

Una actualización nueva llegaba con cambios de fábrica en cuatro ajustes de la tarjeta gráfica.
Al medir, la conversación normal caía un 9 %: los cuatro juntos. Se desmontó el misterio con
cuatro pruebas de aislamiento: ninguno era el culpable por sí solo, pero al apagar
**uno solo de los cuatro interruptores** la máquina no solo recuperaba lo perdido:
quedaba un **2 % más rápida que antes**. Se adopta el motor nuevo con ese
interruptor apagado. La lección vale oro: una mejora entera escondida dentro de una actualización
que, tal cual, iba a peor.

### 29 de octubre · El experimento que salió mal (y se deshizo en horas)
*sobre engine 0.1.52*

Se probó a forzar la máquina: más memoria de conversación, más reserves, más todo.
Resultado medido ese mismo día: **un 28 % más lento** en la conversación
diaria. En lugar de discutir por qué, se revirtió a la configuración de la mañana y se escribió
la causa probable para el futuro. Del error salió, además, una nueva referencia oficial de comparación.
*(Curiosidad: la misma prueba detectó que apagar el sistema que se adapta solo
a la carga es lo que hundía el rendimiento. Más vale lo conocido...)*

### 30 de octubre · Dos mejoras seguidas, ambas medidas
*engine 0.1.54 oficial + runtime ROCm 10.3 propio*

Primera: la versión 0.1.54 del motor se adopta por cumplir el criterio estricto de "no empeora nada".
Segunda, más surprising: se sustituye la librería de drivers de la tarjeta gráfica por una versión
más moderna, **sin recompilar nada**. Medida: **+3,5 % en conversación**.
La forma en que se actualiza un componente sin tocar el resto merece un artículo aparte.

### 31 de octubre · Textos largos: +6 % de golpe
*engine 0.1.55 oficial, ruta GDN chunked*

Una ruta nueva del motor para procesar documentos largos aprovecha mejor la tarjeta.
Cuatro pruebas independientes, las cuatro por encima del umbral que nos fijamos:
**+6 % releer textos de 4.000 y 16.000 tokens**, y la máquina tarda
un poco menos en empezar a responder. Antes de adoptarlo, una prueba de resistencia: una hora
de carga continua con varios usuarios a la vez, cientos de peticiones, cero fallos.

### 3 de noviembre · La ganancia del caso más usado: +5,5 % escribiendo
*engine 0.1.56 oficial + drafter DFlash2*

El truco del oficio: para escribir más rápido, el modelo *predice las siguientes palabras y las
verifica en bloque* en vez de escribirla una a una. Se sustituye el sistema de predicción
antiguo por uno nuevo, más listo y comprimido (viene cuantizado en cuartos), afinado para español.
Medido contra el sistema antiguo el mismo día: **+5,5 % en la velocidad típica
de conversación**, y en los tramos favorables el techo sube de ~98 a ~125 tokens/s; la
contrapartida es más variación entre respuestas. Los textos largos no se mueven. No es la mejora
porcentual más grande del proyecto (las de relectura lo fueron más), pero es la que se nota en el
uso de cada día.

### 5 de noviembre · El anillo de preparación: +10,7 % preparando textos
*engine 0.1.57 oficial, anillo de preparación más profundo*

Última versión del motor (0.1.57), medida contra la anterior el mismo día:
**+10,7 % en la relectura de textos de 4.000 tokens** (y se pasa de tardar
1,9 s a 1,75 s en empezar a responder) gracias a un anillo más profundo que prepara los documentos
por adelantado. En textos de 16.000 y 32.000 tokens no aporta nada: ahí el cuello de botella es otro.
La marcha atrás preparada, por si acaso, sigue siendo una sola variable.

### 12 de noviembre · Un arreglo de fuera: la conversación sobrevive a apagar el PC
*parche CacheKV del fork de kinoyu-ai, sobre la versión oficial v0.2.11*

Alguien más se había encontrado con el mismo problema: al apagar el equipo se pierde la memoria de
lo que ya se había leído, y a la mañana siguiente la primera respuesta vuelve a tardar lo que costó
leer todo. Un fork público ([kinoyu-ai](https://github.com/kinoyu-ai/Strata-CacheKV-kinoyu))
guarda esa memoria en el disco. Nos lo aplicamos nosotros sobre la versión oficial y lo compilamos
(seis minutos). Medido con un reinicio de verdad:
**la relectura de una conversación de 29.000 tokens pasa de 8,7 segundos a 0,6
(−92,7 %)**; en la sesión real más larga que teníamos abierta, restaurar 41.600 tokens
fueron 192 milisegundos. Y aquí llegó la lección incómoda: **el banco de pruebas de siempre no
veía nada**, las dos mediciones salían idénticas, porque ese arreglo no cambia nada en el uso
continuo —solo cobra por adelantado lo que se paga al encender. Hubo que inventar una prueba
distinta (encender, apagar, volver a encender) para verlo. Escrito queda, con su protocolo en
[scripts/](scripts/).

### 13 de noviembre · Y al día siguiente, funcionando solo
*uso real, no una prueba de banco*

Comprobamos el arreglo usándolo de verdad, y salió una frontera útil. **Sin apagar el
equipo**, una conversación muy larga a la que la memoria rápida ya no llegaba volvió a
tardar lo de siempre: quince segundos de lectura completa. (Era una expectativa nuestra
equivocada: lo que guarda el disco entra en juego al encender, no a mitad de una charla.)
**Apagando y volviendo a encender**, en cambio, funcionó tal cual: una conversación
de 64.000 tokens se recuperó del disco en tres décimas de segundo, y la
primera pregunta tardó **un segundo en vez de unos dieciocho**. Y se vio
el límite honesto del sistema: el espacio que el programa se asigna a sí mismo para esto
(12 gigabytes, por defecto) se llena con ocho o diez conversaciones así de grandes, y entonces
empieza a desalojar las más antiguas —sin romperse nada, y con una opción para ampliarlo si
algún día hiciera falta.

## Qué se logró, en números comprensibles

Estos son los números publicados por esta misma caja al cerrar el proyecto (5 de noviembre de 2026).
Para quien no conozca la unidad: un token es aproximadamente media palabra en español;
82–94 tokens por segundo vienen a ser 40–45 palabras por segundo, más rápido que la mayoría de nosotros tecleamos.

| Qué hace | Antes (23 de octubre) | Ahora (5 de noviembre) |
|---|---|---|
| Escribir una conversación normal | ~71 tokens/s | **82 tokens/s** *(mediana medida en frío; el uso diario típico ronda ~94 y los mejores tramos llegan a ~125\*)* |
| Releer y entender un texto de 4.000 tokens | ~1.980 tokens/s | **~2.320 tokens/s** (responde en menos de 2 s) |
| Releer un texto de 16.000 tokens | ~2.430 tokens/s | **~3.100 tokens/s** |
| Releer un texto de 32.000 tokens | — (no se medía) | **~3.055 tokens/s** (responde en ~10 s) |
| Memoria de conversación | 98.000 tokens | **131.000 tokens** (un libro entero) |

\* La comparación directa de los dos extremos tiene trampa: en medio cambió la configuración
y el protocolo de medida. Cada escalón intermedio sí está medido contra su inmediato anterior;
el total es una orientación, no una medida. Lo medido en frío y con control: +2 % (27 oct, engine 0.1.52
con un interruptor apagado), +3,5 % (30 oct, runtime ROCm 10.3), +6 % releyendo (31 oct, engine 0.1.55),
+5,5 % escribiendo (3 nov, engine 0.1.56 con DFlash2), +10,7 % releyendo 4.000 tokens (5 nov, engine 0.1.57).

*12 de noviembre: la producción cambió de modelo (IQ3_S, con contexto de
94.000 en lugar de 131.000). Ese cambio **bajó la velocidad** —un 5,5 % escribiendo y
un 5,3 % en tareas de agente— a cambio de conocer 3,2 puntos porcentuales más de palabras: se
publicó con su medición y su criterio de aceptación fijados de antemano (techo de pérdida: 20 %).
Sus dos corridas completas y las del arreglo del párrafo anterior están en
[RESULTADOS.md](RESULTADOS.md) y en [benches/muestras/](benches/muestras/).*

Además de la velocidad, hay dos logros silenciosos que valen tanto como los números:

- **Cero sorpresas en producción.** En dos semanas hubo varios intentos que salieron mal.
  Todos se detectaron con las mediciones del mismo día y se revirtieron en minutos, no en días.
  Nunca se estuvo "un poco raro" sin saber por qué.
- **Un método que se puede repetir.** Cada decisión tiene su fecha, su prueba y su marcha atrás
  escrita en un cuaderno. Cualquiera con un PC parecido puede copiar el camino o discutir cada paso
  con datos delante.

## Lo aprendido (que sirve para más que para esto)

- **Medir antes de creer.** La actualización que parecía mejor no lo era; la que parecía
  neutra escondía un +2 %. Sin banco de pruebas, ambas habrían pasado por "cosas del equipo".
- **Tener siempre marcha atrás preparada** convierte cualquier actualización en una apuesta
  barata: si va mal, se deshace y no pasa nada.
- **Aislar las variables.** Cuando algo va mal y han cambiado cinco cosas a la vez,
  la respuesta casi nunca es "culpa de X"; hay que apagar X una a una.
- **Escribir los descartes** es igual de valioso que escribir los éxitos: evita repetir
  el mismo error dos semanas después. Aquí los descartes están escritos:
  [LO-QUE-NO-FUNCIONO.md](LO-QUE-NO-FUNCIONO.md) recoge trece resultados negativos
  (y alguna rectificación), y [PASOS.md](PASOS.md) documenta cada adopción con su
  marcha atrás.
- **El banco de pruebas no lo ve todo.** La mejora más grande de noviembre en cifras
  (−92,7 %) no aparece en ninguna de las tablas de velocidad: solo se manifiesta al encender el
  equipo. Si la prueba que tienes no puede ver el cambio, el problema puede ser la prueba.
- **Ajuses de fuera.** La solución a un problema propio ya la tenía otra persona en otro
  sitio: estaba en el fork público de un desconocido, y aquí solo ha hecho falta aplicarlo, medirlo y
  darle la autoría. También hay que decir lo que eso significa: no es código del proyecto original y no
  está enviado arriba.

Tampoco fue perfecto: al cerrar estas notas estaba abierto un caso raro —una respuesta sin sentido
en una conversación muy larga, justo al comprimir su memoria—, sin causar daños y con la solución de
momento conocida (comprimir antes). Queda abierto y documentado, como todo lo demás: aquí no se
esconde nada.

---

*Crónica escrita el 5 de noviembre de 2026 y ampliada el 12 y 13 de noviembre con la última entrada,
a partir del cuaderno de sesiones del proyecto (append-only,
desde el 20 de octubre). Todas las cifras son mediciones de esta caja con RX 9070 XT y el motor que
se indica en cada fecha; donde algo no está medido, se dice. Todo esto se sostiene sobre hombros
ajenos: el motor y el servidor son de [Strata](https://github.com/Niko1221/Strata) (MIT,
Niko1221 y contribuidores), y el modelo y el borrador los instala su propio setup —su procedencia
pieza por pieza, en [CREDITOS.md](CREDITOS.md). Si quieres repetir el camino:
[PASOS.md](PASOS.md) y [RESULTADOS.md](RESULTADOS.md).*
