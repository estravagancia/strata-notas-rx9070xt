#!/bin/sh
# Test de KV en disco persistente (brazo kinoyu sobre engine local 0.1.57.90) — protocolo con REINICIO.
#
# Lo lanzas TÚ desde tu consola, con OpenCode parado y el servidor de producción parado
# (hace dos arranques completos del motor; no cabe un segundo motor en paralelo):
#   scripts/kv-persist-test.sh LABEL [--config archivo.json] [--tokens N]
#
# Nota de publicación: la copia publicada está en scripts/, pero aquí la ejecutamos dentro
# del clon, en bench/. El helper kv-persist-phase.py está publicado junto a este script y
# necesita el `tools/` de un checkout de Strata (importa strata_bench y ab_engine): ponlo
# en `bench/` de tu clon, o indica su ruta con la variable PHASE (ver abajo).
#
# Secuencia: arranca el motor con esa config -> conversacion larga A (~30k tok) + request
# corto S -> APAGA el motor (TERM, apagado normal) -> vuelve a arrancarlo -> reenvía A y S.
# Sin el nivel disco, el A de después del reinicio es un prefill frío completo (control).
# Con --conversation-cache-dir + --conversation-cache-persist, A debe restaurarse desde
# <dir>/persistent: reused (cached_tokens) ~ el tamaño de A y prompt_ms mucho menor, con la
# respuesta idéntica (temperature 0).
#
# Crea bench/runs/<YYYY-MM-DD-HHMM>-<LABEL>/ con:
#   strata-bench-run1.json / run2.json  configs exactas (solo difiere el campo "log")
#   meta.txt        engine + BUILD.json + sha de configs + args + nota del dir persistente
#   server-run1.log / server-run2.log   logs del motor de cada arranque (buscar "disk cache:")
#   serve-run1.log / serve-run2.log     salida del serve
#   phase1.json / phase2.json           requests medidos (prompt_ms, reused, textos)
# Al terminar revisa el resumen por consola; la auditoría y el traslado a bench/results
# siguen el criterio que fijemos (esto NO es la suite del dashboard ADR-007).
#
# Opciones:
#   --config  config base del motor (por defecto: strata-iq3_s.json, la producción)
#   --exe     sustituye el ejecutable de la config (para el brazo kinoyu:
#             ~/.local/share/strata/components/engine/0.1.57.90-linux-x86_64-hip-rx9070/strata)
#   --extra   args del engine que se AÑADEN a la config (mismo mecanismo que run-bench.sh:
#             si un flag ya estaba, se quita su valor base). Ej para el brazo kinoyu:
#             --extra "--conversation-cache-dir /home/TU-USUARIO/Strata-data/kv-disk --conversation-cache-persist"
#   --tokens  tamaño objetivo de A en tokens (por defecto 30000; con ctx 94000 no pasar de ~60000)
#   (env) PORT  puerto del test, por defecto 8094; NUNCA el 8081 de producción

ROOT=/home/TU-USUARIO/Strata
PY=$ROOT/.venv/bin/python
# helper de fases (necesita el tools/ de un checkout de Strata). Aquí: bench/ del clon.
PHASE=${PHASE:-$ROOT/bench/kv-persist-phase.py}
PORT=${PORT:-8094}
HEALTH=http://127.0.0.1:$PORT/health
URL=http://127.0.0.1:$PORT

LABEL=$1; [ -n "$LABEL" ] || { echo "uso: $0 LABEL [--config JSON] [--exe RUTA] [--extra ARGS] [--tokens N]" >&2; exit 64; }
shift
CFG=$ROOT/strata-iq3_s.json; TOKENS=30000; EXTRA=""; NEWEXE=""
while [ $# -gt 0 ]; do
  case $1 in
    --config) CFG=$2; shift ;;
    --exe) NEWEXE=$2; shift ;;
    --extra) EXTRA=$2; shift ;;
    --tokens) TOKENS=$2; shift ;;
    *) echo "opción desconocida: $1" >&2; exit 64 ;;
  esac
  shift
done
[ -z "$NEWEXE" ] || [ -x "$NEWEXE" ] || { echo "--exe no existe o no es ejecutable: $NEWEXE" >&2; exit 64; }

if $PY - "$HEALTH" <<'PYEOF'
import sys, urllib.request
try:
    sys.exit(0 if urllib.request.urlopen(sys.argv[1], timeout=2).status == 200 else 1)
except Exception:
    sys.exit(1)
PYEOF
then
  echo "responde algo en $PORT: el puerto del test debe estar libre (PORT=$PORT)" >&2
  exit 1
fi

RUNDIR=$ROOT/bench/runs/$(date +%Y-%m-%d-%H%M)-$LABEL
mkdir -p "$RUNDIR" || exit 1

# dos configs iguales salvo el log de cada arranque; meta.txt con la procedencia
CFG="$CFG" EXTRA="$EXTRA" NEWEXE="$NEWEXE" EXTRA_TARGET="$TOKENS" RUNDIR="$RUNDIR" ROOT="$ROOT" $PY <<'PYEOF' || exit 2
import hashlib, json, os, shlex, subprocess, time
cfg_path, rundir = os.environ["CFG"], os.environ["RUNDIR"]
cfg = json.load(open(cfg_path))
if os.environ.get("NEWEXE"):
    cfg["exe"] = os.environ["NEWEXE"]
extra = shlex.split(os.environ.get("EXTRA", ""))
if extra:
    flags = [t for t in extra if t.startswith("--")]
    args, i, out = list(cfg.get("args", [])), 0, []
    while i < len(args):
        if args[i] in flags and i + 1 < len(args) and not args[i + 1].startswith("--"):
            i += 2  # el valor base se quita; el de --extra manda
            continue
        out.append(args[i]); i += 1
    cfg["args"] = out + extra
for n in (1, 2):
    c = dict(cfg)
    c["log"] = os.path.join(rundir, f"server-run{n}.log")
    json.dump(c, open(os.path.join(rundir, f"strata-bench-run{n}.json"), "w"), indent=2)

sha = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]
head = subprocess.run(["git", "-C", os.environ["ROOT"], "rev-parse", "--short", "HEAD"],
                      capture_output=True, text=True).stdout.strip()
exe = cfg["exe"]
try:
    build = open(os.path.join(os.path.dirname(exe), "BUILD.json")).read().strip()
except Exception:
    build = "(sin BUILD.json)"
args = cfg.get("args", [])
kv = [args[i] + " " + (args[i + 1] if i + 1 < len(args) else "") for i, a in enumerate(args)
      if a.startswith("--conversation-cache")]
m = ["kv-persist test %s  %s" % (os.path.basename(rundir), time.strftime("%F %T")),
     "clone HEAD: " + head, "engine: " + exe, "BUILD.json: " + build,
     "puerto test: " + os.environ.get("PORT", "8094") + " (produccion 8081 intacto)",
     "config base: %s  sha256:%s" % (cfg_path, sha(cfg_path)),
     "args conversation-cache en el test:", *["  " + k for k in kv],
     "tokens objetivo A: " + os.environ["EXTRA_TARGET"],
     "env: " + json.dumps(cfg.get("env", {}))]
open(os.path.join(rundir, "meta.txt"), "w").write("\n".join(m) + "\n")
PYEOF

start_serve() { # $1 = numero de arranque; deja SRV y espera health; sale con error si muere
  N=$1
  cd "$ROOT" || exit 1
  $PY serve/server.py --engine strata --config "$RUNDIR/strata-bench-run$N.json" --port "$PORT" \
    > "$RUNDIR/serve-run$N.log" 2>&1 &
  SRV=$!
  echo "arranque $N: servidor pid $SRV en $PORT; esperando health..."
  i=0
  while [ $i -lt 60 ]; do
    sleep 10
    if ! kill -0 $SRV 2>/dev/null; then
      echo "el servidor murio durante la carga; ultimas lineas:" >&2
      tail -n 20 "$RUNDIR/serve-run$N.log" >&2
      exit 2
    fi
    if $PY - "$HEALTH" <<'PYEOF'
import sys, urllib.request
try:
    sys.exit(0 if urllib.request.urlopen(sys.argv[1], timeout=3).status == 200 else 1)
except Exception:
    sys.exit(1)
PYEOF
    then echo "listo en $(( (i + 1) * 10 )) s"; sleep 20; return 0; fi
    i=$((i + 1))
  done
  echo "salud: $PORT no responde tras 10 min" >&2
  kill -TERM $SRV 2>/dev/null
  exit 3
}

stop_serve() {
  [ -n "$SRV" ] || return 0
  echo "apagando el motor (INT/TERM a $SRV; apagado normal = persistent/ sobrevive)..."
  kill -INT $SRV 2>/dev/null; sleep 6
  kill -TERM $SRV 2>/dev/null
  i=0
  while kill -0 $SRV 2>/dev/null && [ $i -lt 60 ]; do sleep 2; i=$((i + 1)); done
  if kill -0 $SRV 2>/dev/null; then
    echo "no cierro en 2 min; KILL -9 (pierde el ultimo mirror en curso, persistent/ sigue)" >&2
    kill -9 $SRV 2>/dev/null
  fi
  wait $SRV 2>/dev/null
  SRV=""
}

trap 'stop_serve' INT TERM

start_serve 1
$PY "$PHASE" --url "$URL" --phase 1 --tokens "$TOKENS" --out "$RUNDIR/phase1.json" || { stop_serve; exit 4; }
stop_serve
sleep 5   # soltar puerto y RAM

start_serve 2
$PY "$PHASE" --url "$URL" --phase 2 --tokens "$TOKENS" --out "$RUNDIR/phase2.json" || { stop_serve; exit 4; }
stop_serve

echo
echo "=== resumen ==="
$PY - "$RUNDIR" <<'PYEOF'
import json, sys, os
rd = sys.argv[1]
p1 = json.load(open(os.path.join(rd, "phase1.json")))
p2 = json.load(open(os.path.join(rd, "phase2.json")))
a1, a2 = p1["A"], p2["A"]
print(f"A frio (arranque 1):        prompt_ms={a1.get('prompt_ms')}  reused={a1.get('reused_tokens')}")
print(f"A tras REINICIO (arranque 2): prompt_ms={a2.get('prompt_ms')}  reused={a2.get('reused_tokens')}")
print(f"A identico: {p2.get('match_A')}   S identico: {p2.get('match_S')}")
ms1, ms2 = a1.get("prompt_ms"), a2.get("prompt_ms")
if ms1 and ms2:
    print(f"delta prompt_ms: {100.0 * (ms2 - ms1) / ms1:+.1f} %   (en el control debe ser ~0)")
PYEOF
echo
echo "busca en los logs las lineas 'disk cache:' (parked / read / restored):"
echo "  grep -n 'disk cache' $RUNDIR/server-run2.log"
echo "run-dir: $RUNDIR"
