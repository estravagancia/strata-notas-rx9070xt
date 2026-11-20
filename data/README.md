# Subset de vocabulario MTP en español

Dos ficheros aquí, ambos arrays `int32` de ids del tokenizador **sin cabecera** (el
motor cuenta las entradas dividiendo el tamaño del fichero entre 4):

- **`draft_vocab_es-modern.bin`** (instalado en producción el 15-11; la decisión de
  mantenerlo se registró el 16-11 tras medirlo): sha256
  `0841873dd9e4fe670ecefe3c94e75edc4e3f9fbcfdb27fce2fda39321a5b1c5e` — 47.047 entradas,
  188.188 bytes.
- `draft_vocab_es.bin` (el original del 26-10, conservado como referencia): sha256
  `f64ecc4c22d201976443f955706f3a3f150fe9ddf827f2fe3d720e38093a9410` — 50.847 entradas,
  203.388 bytes.

**Instalación**: sustituir con ellos el fichero `Strata-data/mtp/rt/draft_vocab.bin`
(primero copia el original, por si quieres volver). El motor solo mira ese fichero: la
clave `"draft_vocab"` del JSON de configuración afecta al *setup* (elige entre
cjk/en/cirílico/francés) pero no al motor. Las variantes del modelo comparten
ese fichero: basta con cambiarlo una vez.

## `draft_vocab_es-modern.bin` (producción desde el 15-11)

**Por qué se cambió**: el subset del 26-10 se había construido con un corpus mezclado que
resultó ser mayoría de **español clásico** —verificado offline el 15-11: el 58 % del
origen del corpus original eran libros de Gutenberg (5,4 MB de `books/` + 2,2 MB de
`dq.txt` sobre 13 MB)—. El nuevo se generó con un corpus moderno de 5,7 MB (conversaciones
reales de agente de las sesiones del proyecto, notas públicas, memoria y planes) sobre la
base del subset oficial `en` (40.525 ids), con el script `draft_vocab.py` del tag v0.2.14 y
cobertura 0,99.

**Medida offline (sin GPU)**:

- El listado oficial `latin` (62.102 ids) cubre **peor** el español propio que nuestro
  subset: deja fuera el 2,45 % de las ocurrencias de nuestro corpus frente al 0,79 % del
  ES del 26-10. La idea de "usar el listado romance de upstream" quedó descartada sin
  necesidad de bench. Detalle: `latin` incluye 14.876 ids que no son español (`de/it/fr/pl`)
  y echa de menos 3.621 tokens españoles.
- `es-modern` (47.047 ids) deja fuera solo el 0,54 % de las ocurrencias del corpus
  moderno, pero el **5,57 % del corpus clásico**: pierde textos antiguos —aceptado
  deliberadamente por el usuario tras ver el balance—. El subset anterior cubría el
  legado; este cubre el español de uso actual. (La alternativa `es-union`, 51.832 ids con
  0,37 % fuera, se descartó por conservar el legado clásico que ya no queríamos.)

**Qué cuesta/gana en la caja:**

- Cabezal: el log de arranque de producción verificó el head nuevo —`strata dflash2:
  47047-token draft head (79,0 MiB)` (15-11 22:55)—. La comparación relativa con el
  subset viejo (~−13 MiB) es **inferencia de proporción, no medida**: no se volvió a medir.
- Bench (ejecución válida del 16-11, IQ3_S, chunk 16.384, suite `--long`): borradores
  aceptados en chat **79,1 %** con este vocab frente al **77,4 %** del control del 14-11
  con el vocab viejo (misma config, **días distintos**: confusor declarado). La pareja
  formal del 16-11 (`-1502` frente a `-1512`) no mide el vocab: mide otro knob.
- Uso real (logs de producción del 16-11, franja de 50.000–70.000 tokens, **con drafter
  en ambas eras**): aceptación mediana **77,2 %** con este vocab (n=78) frente a
  **70,4 %** con el viejo (n=16). Una lectura inicial desfavorable (60,7 %) resultó estar
  contaminada por arranques **sin drafter** —ver el matiz en
  [LO-QUE-FUNCIONO.md](../LO-QUE-FUNCIONO.md) §11— y quedó corregida el mismo día.
- Decisión registrada: mantener `es-modern` (el usuario, 16-11: «no lo restauramos»).

**Reversión**: copiar `draft_vocab_es.bin` (o el backup `draft_vocab.bin.pre-esmodern-20261115.bak`
de la caja) sobre `rt/draft_vocab.bin` y rearrancar.

## `draft_vocab_es.bin` (26-10, histórico)

sha256 arriba. Frecuencia de tokens sobre un corpus real de conversaciones en español
(31 MB) más el vocabulario del modelo; se quedaron los ids que realmente aparecen en
español (el estándar cubre 106.299; el subset, 50.847 → solo el 0,54 % de los tokens de
chats reales quedaron fuera, frente al 11,7 % del listado "en" oficial). Medida de aquella
renovación (1 ejecución limpia): **+0,8 % en chat, +2,8 pp de borradores aceptados,
−93 MiB de VRAM**. Nota honesta: el guion generador del fichero de 26-10 se perdió (no estaba en git). La
receta es la de arriba y el formato es público; si alguien lo rehace en su idioma, estos
ficheros sirven como referencia de tamaño/estructura.
