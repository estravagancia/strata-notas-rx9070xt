#!/bin/bash
# Instala el componente 0.1.62.91-linux-x86_64-hip-rx9070 = MISMO commit 4a7d49cb9 de
# local/up-il-cachekv compilado con el toolchain ROCm 10.3 del bundle (rocm-sdk devel:
# hipcc 7.18.26433 / clang 24), worktree detached en /tmp/opencode/p5-src, build en
# build-rocm103d. P5: experimentar si el toolchain 10.3 iguala/supera al .90 (apt 7.2.1).
# Dos desviaciones locales sobre 4a7d49cb9 (parches en outbox/):
#   1) hip_backend.cmake: add_compile_options($<$<COMPILE_LANGUAGE:HIP>:-x hip>) — con los
#      paquetes rocm-sdk, hip::device ya no propaga -x hip y los .cu se compilaban como CUDA.
#   2) conversation_snapshot_test.cpp: duplicado de 'SessionReadLimits limits' (defecto del
#      port P1; el test nunca compiló en ningún build). Renombrado a rlimits.
# Flags efectivos alineados con los del .90: -O3 -DNDEBUG -std=c++20 -fPIC + isystem SDK
# (evitar headers apt de /usr/include) + rocm-path/device-lib al SDK.
set -u
WT=/home/TU-USUARIO/Strata-upstream
CE=$HOME/.local/share/strata/components/engine
DST=$CE/0.1.62.91-linux-x86_64-hip-rx9070
TEMPLATE=$CE/0.1.61.90-linux-x86_64-hip-rx9070
SRC=/tmp/opencode/p5-src/build-rocm103d/strata

[ -x "$SRC" ] || { echo "no hay binario en $SRC (primero cmake --build)"; exit 1; }
[ -d "$TEMPLATE" ] || { echo "falta la plantilla $TEMPLATE"; exit 1; }
if [ -e "$DST" ]; then echo "ya existe $DST (re-instalando sobre ella)"; fi

# plantillas de metadata: copiar y sustituir al final
rm -rf "$WT/.install-tmp-91" && mkdir -p "$WT/.install-tmp-91"
cp -a "$TEMPLATE" "$WT/.install-tmp-91/C" || exit 1
rm -f "$WT/.install-tmp-91/C/strata" "$WT/.install-tmp-91/C/strata-vision" "$WT/.install-tmp-91/C/strata-vision-hip" \
      "$WT/.install-tmp-91/C/engine-component.json" "$WT/.install-tmp-91/C/BUILD.json"
cp -a "$SRC" "$WT/.install-tmp-91/C/strata" || exit 1

COMMIT=$(git -C /tmp/opencode/p5-src rev-parse HEAD)
python3 - "$WT/.install-tmp-91/C" "$COMMIT" <<'PY'
import hashlib, json, os, sys
d, commit = sys.argv[1], sys.argv[2]
meta = {
 "schema_version": 2, "id": "strata-engine", "name": "strata-engine",
 "version": "0.1.62.91", "platform": "linux-x86_64", "backend": "hip",
 "archs": ["gfx1200", "gfx1201"], "min_driver": {},
 "build_id": commit + "+rocm-sdk-10.3", "entrypoint": "strata", "files": [],
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
 "version": "0.1.62.91",
 "source": "local/up-il-cachekv " + commit + " +p5-local-patches",
 "variant": "rx9070", "archs": ["gfx1200", "gfx1201"], "portable": True,
 "vision": "off", "dsv41": False, "hipblaslt_version": 100200,
}
json.dump(build, open(os.path.join(d, "BUILD.json"), "w"), indent=1)
PY

rm -rf "$DST" && mv "$WT/.install-tmp-91/C" "$DST" || exit 1
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
