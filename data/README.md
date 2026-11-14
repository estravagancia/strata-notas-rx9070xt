# Subset de vocabulario MTP en español

`draft_vocab_es.bin`: el vocabulario recortado del cabezal predictor de borradores
(MTP). sha256 `f64ecc4c22d201976443f955706f3a3f150fe9ddf827f2fe3d720e38093a9410`
(50.847 entradas; 203.388 bytes).

**Instalación**: sustituir con él el fichero `Strata-data/mtp/rt/draft_vocab.bin`
(primero copia el original, por si quieres volver). El motor solo mira ese fichero: la
clave `"draft_vocab"` del JSON de configuración afecta al *setup* (elige entre
cjk/en/cirílico/francés) pero no al motor.

**Formato**: array `int32` de ids del tokenizador, **sin cabecera**. El motor cuenta
las entradas dividiendo el tamaño del fichero entre 4.

**Cómo se generó**: frecuencia de tokens sobre un corpus real de conversaciones en
español (31 MB) más el vocabulario del modelo; se quedaron los ids que realmente
aparecen en español (el estándar cubre 106.299; el subset, 50.847 → solo el 0,54 % de
los tokens de chats reales quedaron fuera, frente al 11,7 % del listado "en" oficial).
El resultado: +0,8 % en chat, +2,8 pp de borradores aceptados, −93 MiB de VRAM
(una ejecución limpia; pendiente de confirmar con más muestras).

Nota honesta: el guion generador se perdió (no estaba en git). La receta es la de
arriba y el formato es público; si alguien lo rehace en su idioma, este fichero sirve
como referencia de tamaño/estructura.
