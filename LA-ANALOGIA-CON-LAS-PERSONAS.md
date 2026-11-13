# Entender los LLM con esta caja: la analogía con las personas

*Escrito tal cual (palabra por palabra) en una conversación de agente del 13-11-2026 por
la mañana. No es una tabla de medidas: es una reflexión sobre qué significan las medidas
de este repo. Los números a los que alude están en [RESULTADOS.md](RESULTADOS.md) y en
[LO-QUE-FUNCIONO.md](LO-QUE-FUNCIONO.md) §10. Un ajuste menor de fecha se señala al final; lo demás es idéntico.*

El punto de partida fue del dueño de esta caja: «considero que el modelo actual es bastante
capaz, y además me sirve para entender este mundo de los llm, haciendo alguna analogía con
el mundo de las personas…».

---

No es ignorancia: de hecho, has caído en la analogía buena, y la has verificado en tu
propia caja. Las tres capas que llevamos semanas midiendo tienen un espejo humano casi
exacto:

- **VRAM** ≈ lo que tienes «en la punta de la lengua» en este instante: poquísimo espacio,
  rapidísimo. El *expert cache* de 7,9 GB con hit del 73 % es literalmente «los expertos
  que usas mucho los tienes a mano; los demás los tienes que ir a buscar».
- **RAM** ≈ lo que sabes y puedes evocar en segundos: mucho, pero con un límite duro (por
  eso el motor decide qué *experts* residir y cuáles no).
- **Disco (kv-disk)** ≈ la memoria que hay que «releer» para traerla: lenta, pero
  persistente. Y lo que probaste el mismo día es exactamente la diferencia entre recordar
  (restaurar 77.944 tokens en 0,66 s) y volver a aprender (8-9 s de prefill completo).

Incluso los fallos se parecen: el desalojo LRU es «no recuerdo ese detalle, pero sé que lo
sé en alguna parte» — y el caso que dejamos sin medir (una conversación desalojada mientras
seguía activa) es la versión informática de que te interrumpen a mitad de un recuerdo.

Donde la analogía se rompe, y conviene saberlo, es en lo demás: el modelo no comprende
como una persona, no retiene aprendiendo de cada conversación (tu KV vuelve pero sus pesos
no cambian), y su «olvido» es gestión de caché, no olvido biológico. Pero para intuir por
qué algo va lento, por qué un contexto largo cuesta, o por qué más RAM cambia la
experiencia — la analogía humana es directamente la intuición correcta.

---

*Qué cambié al transcribir (el texto es idéntico salvo una fecha): «ayer» → «el mismo
día» (la prueba del restore de 77.944 tokens y esta conversación ocurrieron el mismo día,
el 13-11-2026).*
