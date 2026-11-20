#!/bin/sh
# Produccion de este espacio: engine 0.1.62.90 (base v0.2.16 + CacheKV + IL) con el serve
# de este espacio (terminal/serve/server.py) en el puerto 8081, config espejo de la de
# produccion (strata-iq3_s-up.json). Desde el 18-11 este espacio es la produccion viva;
# la linea vieja ~/Strata esta parada. Un segundo engine no cabe con uno en marcha
# (~54/61 GiB): cerrar antes la ventana o strata_stop.
#
# Antes de lanzar: ss -ltn | grep 8081 debe estar vacio y free -g debe dar >45 GiB libres.
# ADR-044 (verificar SIEMPRE al arrancar serve+engine):
#   1) cmdline del engine:  tr '\0' ' ' < /proc/$(pgrep -f 'components/engine/0.1.62.90')/cmdline | grep -- '--draft dflash2'
#   2) linea de log:        strata dflash2: N-token draft head
cd "/home/TU-USUARIO/Strata-upstream" || exit 1

intento=1
while :; do
  "/home/TU-USUARIO/Strata/.venv/bin/python" "terminal/serve/server.py" \
    --engine strata --config "/home/TU-USUARIO/Strata-upstream/strata-iq3_s-up.json" \
    --port 8081
  rc=$?

  [ "$rc" -eq 0 ] && exit 0
  [ "$rc" -eq 130 ] && exit 130
  [ "$rc" -eq 143 ] && exit 143
  [ "$rc" -eq 1 ] || exit "$rc"

  if [ "$intento" -ge 3 ]; then
    echo "arranque fallido 3 veces (ultimo codigo $rc); no se reintenta mas" >&2
    exit "$rc"
  fi
  intento=$((intento + 1))
  echo "arranque fallido (codigo $rc); reintento $intento de 3 en 20 s..." >&2
  sleep 20
done
