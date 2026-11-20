#!/bin/sh
# Brazo IQ3_XXS con vision de este espacio (19-11): espejo del antiguo ~/Strata/run-iq3_xxs.sh adaptado aqui.
# Vision habilitada el 19-11: lector CPU strata-vision construido de terminal/tools/vision e instalado en el
# componente .90 (regla upstream: CPU por debajo de 23,5 GiB de VRAM; esta caja tiene 16). El mmproj ~1.1 GB va
# a RAM: con la produccion en marcha no cabe nada mas. Mismo puerto 8081: un brazo a la vez.
#
# Antes de lanzar: ss -ltn | grep 8081 debe estar vacio y free -g debe dar >45 GiB libres.
# ADR-044 (verificar SIEMPRE al arrancar serve+engine):
#   1) cmdline del engine:  tr '\0' ' ' < /proc/$(pgrep -f 'components/engine/0.1.62.90')/cmdline | grep -- '--draft dflash2'
#   2) linea de log:        strata dflash2: N-token draft head
cd "/home/TU-USUARIO/Strata-upstream" || exit 1

intento=1
while :; do
  "/home/TU-USUARIO/Strata/.venv/bin/python" "terminal/serve/server.py" \
    --engine strata --config "/home/TU-USUARIO/Strata-upstream/strata-iq3_xxs-up.json" \
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
