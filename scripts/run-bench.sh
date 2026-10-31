#!/bin/sh
# Runner de bench en frío — protocolo ADR-007 (2026-10-23).
#
# Lo lanzas TÚ desde tu consola, con OpenCode parado y el servidor de producción parado:
#   bench/run-bench.sh LABEL [--det] [--extra "args engine..."] [--config archivo.json]
#
# Crea bench/runs/<YYYY-MM-DD-HHMM>-<LABEL>/ con SOLO los datos de esta corrida:
#   server.log         log del motor de esta corrida (el log de producción no se toca)
#   serve-stdout.log   salida del serve
#   strata-bench.json  config exacta usada (copia con "log" y args ajustados)
#   meta.txt           procedencia: engine + BUILD.json, sha256 de configs, args reales, tabla tuning
#   run1/ run2/        salidas de strata_bench.py (run1 = warm-up, descartable; run2 = válida)
# Al terminar: reabres OpenCode y el asistente audita run2 (server.log + meta.txt: si hubo
# requests ajenos, se marca y repite) y solo entonces la copia a bench/results (serie del dashboard).
#
# Opciones:
#   --det    modo determinista de docs/DETAILS.md (0.2.3): añade --prompt-cache 0 --adapt-swaps 0
#   --extra  args del engine que se AÑADEN a los del config; si un flag ya estaba, su valor
#            base se elimina primero (solo flags de un valor: --pcie-frac, --spec, --spec-min-p…)
#   --config bench desde otro config (por defecto: strata-iq3_xxs.json)
#
# Ejemplos (protocolo del 2026-10-23):
#   bench/run-bench.sh anclaje
#   bench/run-bench.sh det035 --det
#   bench/run-bench.sh det060 --det --extra "--pcie-frac 0.6"

ROOT=/home/estravagancia/Strata
PY=$ROOT/.venv/bin/python
HEALTH=http://192.168.0.35:8081/health
URL=http://192.168.0.35:8081

LABEL=$1; [ -n "$LABEL" ] || { echo "uso: $0 LABEL [--det] [--extra ARGS] [--config JSON]" >&2; exit 64; }
shift
CFG=$ROOT/strata-iq3_xxs.json; DET=0; EXTRA=""
while [ $# -gt 0 ]; do
  case $1 in
    --det) DET=1 ;;
    --extra) EXTRA=$2; shift ;;
    --config) CFG=$2; shift ;;
    *) echo "opción desconocida: $1" >&2; exit 64 ;;
  esac
  shift
done

# ¿sigue vivo el servidor de producción? (fallar rápido: debe pararse antes)
if $PY - "$HEALTH" <<'PYEOF'
import sys, urllib.request
try:
    sys.exit(0 if urllib.request.urlopen(sys.argv[1], timeout=2).status == 200 else 1)
except Exception:
    sys.exit(1)
PYEOF
then
  echo "responde algo en 8081: para el servidor de producción antes del bench" >&2
  exit 1
fi

RUNDIR=$ROOT/bench/runs/$(date +%Y-%m-%d-%H%M)-$LABEL
mkdir -p "$RUNDIR/run1" "$RUNDIR/run2" || exit 1

# config de bench + meta.txt en un solo paso python
CFG="$CFG" EXTRA="$EXTRA" DET="$DET" RUNDIR="$RUNDIR" ROOT="$ROOT" $PY <<'PYEOF' || exit 2
import hashlib, json, os, shlex, subprocess, time
cfg_path, rundir = os.environ["CFG"], os.environ["RUNDIR"]
cfg = json.load(open(cfg_path))
extra = shlex.split(os.environ.get("EXTRA", ""))
if os.environ.get("DET") == "1":
    extra += ["--prompt-cache", "0", "--adapt-swaps", "0"]
flags = [t for t in extra if t.startswith("--")]
out, i, args = [], 0, list(cfg.get("args", []))
while i < len(args):
    if args[i] in flags and i + 1 < len(args) and not args[i + 1].startswith("--"):
        i += 2  # el valor base se quita; el de --extra manda
        continue
    out.append(args[i]); i += 1
cfg["args"] = out + extra
cfg["log"] = os.path.join(rundir, "server.log")
bench_cfg = os.path.join(rundir, "strata-bench.json")
json.dump(cfg, open(bench_cfg, "w"), indent=2)

sha = lambda p: hashlib.sha256(open(p, "rb").read()).hexdigest()[:16]
head = subprocess.run(["git", "-C", os.environ["ROOT"], "rev-parse", "--short", "HEAD"],
                      capture_output=True, text=True).stdout.strip()
exe = cfg["exe"]
try:
    build = open(os.path.join(os.path.dirname(exe), "BUILD.json")).read().strip()
except Exception:
    build = "(sin BUILD.json)"
m = ["cold bench %s  %s" % (os.path.basename(rundir), time.strftime("%F %T")),
     "clone HEAD: " + head, "engine: " + exe, "BUILD.json: " + build,
     "config base: %s  sha256:%s" % (cfg_path, sha(cfg_path)),
     "config bench: sha256:%s" % sha(bench_cfg),
     "args en el bench:", *["  " + a for a in cfg["args"]],
     "env: " + json.dumps(cfg.get("env", {}))]
table = cfg.get("env", {}).get("STRATA_HIPBLASLT_TUNING", "")
if table and os.path.exists(table):
    m.append("tabla tuning: %s lineas  %s" % (sum(1 for _ in open(table)), table))
open(os.path.join(rundir, "meta.txt"), "w").write("\n".join(m) + "\n")
PYEOF

cd "$ROOT" || exit 1
$PY serve/server.py --engine strata --config "$RUNDIR/strata-bench.json" --port 8081 \
  > "$RUNDIR/serve-stdout.log" 2>&1 &
SRV=$!
echo "servidor arrancando (pid $SRV); esperando a que 8081 responda..."
READY=0; i=0
while [ $i -lt 60 ]; do
  sleep 10
  if ! kill -0 $SRV 2>/dev/null; then
    echo "el servidor murio durante la carga; ultimas lineas:" >&2
    tail -n 20 "$RUNDIR/serve-stdout.log" >&2
    exit 2
  fi
  if $PY - "$HEALTH" <<'PYEOF'
import sys, urllib.request
try:
    sys.exit(0 if urllib.request.urlopen(sys.argv[1], timeout=3).status == 200 else 1)
except Exception:
    sys.exit(1)
PYEOF
  then READY=1; break; fi
  i=$((i + 1))
done
if [ "$READY" != 1 ]; then
  echo "el servidor no arranco en 10 min; datos en $RUNDIR" >&2
  kill -TERM $SRV 2>/dev/null; exit 2
fi
sleep 20   # margen para el primer warm-up del engine

RC=0
for n in 1 2; do
  echo "== bench corrida $n / 2 =="
  $PY tools/strata_bench.py --url "$URL" --out "$RUNDIR/run$n" > "$RUNDIR/bench-run$n.log" 2>&1
  RC=$?
  tail -n 15 "$RUNDIR/bench-run$n.log"
  [ $RC = 0 ] || break
done

kill -INT $SRV 2>/dev/null; sleep 6
kill -0 $SRV 2>/dev/null && kill -TERM $SRV 2>/dev/null
wait $SRV 2>/dev/null

echo "==========================================="
if [ $RC = 0 ]; then
  echo "bench terminada: $RUNDIR"
  grep -m1 "tuning enabled\|plain hipBLAS" "$RUNDIR/server.log" || true
  grep -m1 "expert cache auto:" "$RUNDIR/server.log" || true
  echo "run1 = warm-up descartable; run2 se copia a bench/results tras la auditoria"
else
  echo "bench FALLIDA (codigo $RC); datos en $RUNDIR"
fi
exit $RC
