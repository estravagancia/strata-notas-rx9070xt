#!/bin/bash
# Instala el componente 0.1.62.90-linux-x86_64-hip-rx9070 = base v0.2.16 + CacheKV
# (local/t33-rebase-0215) + IL-mmvq portado a HIP, compilado aqui en build-rx9070 con
# ROCm apt 7.2.1 (symlink libxml2.so.2 en /tmp/opencode/xmllib; decision 18-11: entorno
# de los .9x). Receta: .opencode/memory/CONTEXT.md §P1.
#
# Las bibliotecas ROCm y las tablas Tensile del componente se toman del 0.1.61.90 (mismo
# GPU, validado en el espacio hermano); la produccion sigue imponiendo el runtime
# rocm-10.3/lib por lib_dirs (hipBLASLt 100500), igual que hace hoy con los .9x.
# Vision: NO se incluye (la produccion no usa mmproj; este build no compila strata-vision*).
set -u
WT=/home/TU-USUARIO/Strata-upstream
CE=$HOME/.local/share/strata/components/engine
DST=$CE/0.1.62.90-linux-x86_64-hip-rx9070
TEMPLATE=$CE/0.1.61.90-linux-x86_64-hip-rx9070
SRC=$WT/build-rx9070/strata

[ -x "$SRC" ] || { echo "no hay binario en $SRC (primero cmake --build)"; exit 1; }
[ -d "$TEMPLATE" ] || { echo "falta la plantilla $TEMPLATE"; exit 1; }
if [ -e "$DST" ]; then echo "ya existe $DST (re-instalando sobre ella)"; fi

# plantillas de metadata: copiar y sustituir al final
rm -rf "$WT/.install-tmp" && mkdir -p "$WT/.install-tmp"
cp -a "$TEMPLATE" "$WT/.install-tmp/C" || exit 1
rm -f "$WT/.install-tmp/C/strata" "$WT/.install-tmp/C/strata-vision" "$WT/.install-tmp/C/strata-vision-hip" \
      "$WT/.install-tmp/C/engine-component.json" "$WT/.install-tmp/C/BUILD.json"
cp -a "$SRC" "$WT/.install-tmp/C/strata" || exit 1

COMMIT=$(git -C "$WT" rev-parse HEAD)
python3 - "$WT/.install-tmp/C" "$COMMIT" <<'PY'
import hashlib, json, os, sys
d, commit = sys.argv[1], sys.argv[2]
meta = {
 "schema_version": 2, "id": "strata-engine", "name": "strata-engine",
 "version": "0.1.62.90", "platform": "linux-x86_64", "backend": "hip",
 "archs": ["gfx1200", "gfx1201"], "min_driver": {},
 "build_id": commit + "+rocm", "entrypoint": "strata", "files": [],
}
for root, _, files in os.walk(d):
    for f in sorted(files):
        p = os.path.join(root, f)
        rel = os.path.relpath(p, d)
        if rel in ("engine-component.json", "BUILD.json"): continue
        h = hashlib.sha256()
        with open(p, "rb") as fh:
            for chunk in iter(lambda: fh.read(1 << 20), b""): h.update(chunk)
        meta["files"].append({"path": rel, "sha256": h.hexdigest(), "bytes": os.path.getsize(p)})
meta["files"].sort(key=lambda e: e["path"])
json.dump(meta, open(os.path.join(d, "engine-component.json"), "w"), indent=1)
build = {
 "version": "0.1.62.90",
 "source": "local/up-il-cachekv " + commit,
 "variant": "rx9070", "archs": ["gfx1200", "gfx1201"], "portable": True,
 "vision": "off", "dsv41": False, "hipblaslt_version": 100200,
}
json.dump(build, open(os.path.join(d, "BUILD.json"), "w"), indent=1)
PY

rm -rf "$DST" && mv "$WT/.install-tmp/C" "$DST" || exit 1
echo "instalado: $DST"
LD_LIBRARY_PATH=/home/TU-USUARIO/Strata-data/rocm-10.3/lib "$DST/strata" --version

echo "== comprobaciones de contenido =="
echo -n "flags CacheKV (--conversation-cache, deben aparecer): "
"$DST/strata" --help 2>&1 | grep -c -- "--conversation-cache" || true
echo -n "knobs IL (STRATA_MMVQ_IL*, deben aparecer >0): "
strings "$DST/strata" | grep -c "STRATA_MMVQ_IL" || true
echo -n "kernel fusionado de la base v0.2.16 (PF_FUSED_Q50): "
strings "$DST/strata" | grep -c "PF_FUSED_Q50" || true
echo -n "try/catch del sink (RAM cache spill failed): "
strings "$DST/strata" | grep -c "RAM cache spill failed" || true
