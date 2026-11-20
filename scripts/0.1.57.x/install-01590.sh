#!/bin/bash
# Compila e instala el componente 0.1.57.90 = engine del tag v0.2.11 (c3b3f503)
# + el parche CacheKV del fork kinoyu-ai/Strata-CacheKV-kinoyu (commiteado en la
# rama local/kinoyu-cachekv; ver git log de la rama para el origen del parche).
#
# NO repunta ni toca configs: el swap a produccion se hace solo con el A/B aprobado
# (registro: ADR-036 en la memoria del clon; datos 2026-11-12: prefill post-reinicio
# -92,7 % con --conversation-cache-persist, A/B de no-regresion con la reserva de la
# media del agente documentada alli).
#
# Que hace 0.1.57.90 sobre 0.1.57: solo el parche CacheKV (23 ficheros, +1731/-56;
# conversaciones a disco persistentes a reinicios + espejos RAM + PLE disk cache por
# franjas). Flags nuevas todas opt-in: --conversation-cache-dir, --conversation-cache-persist,
# --conversation-cache-disk-mib (12288, solo con dir), --conversation-cache-disk-min-tokens
# (60001), --conversation-cache-tier-order, --conversation-cache-disk-min-free-mib,
# --ple-disk-cache. Sin esas flags el binario equivale a 0.1.57 (arranques identicos
# verificados 2026-11-12 en server.log: gfx1200, tabla 100500 via lib_dirs, chunk
# 16 384/ring 96, 4 121 slots, 0 FATAL).
#
# Base: rama local/kinoyu-cachekv. El parche aplica CLEAN con git apply --3way
# tambien sobre v0.2.13 (comprobado 2026-11-12) -> al adoptar un engine nuevo,
# re-aplicar aqui encima y reconstruir con el PKGVER equivalente.
#
# Build: packaging/build_hip_linux.sh del tag (igual que las eras 0.1.46-0.1.48.1;
# pasos completos en .opencode/memory/notas-tecnicas.md). Primer build 2026-11-12
# 22:34-22:40 (~6 min, BUILD-DONE, work-rx9070/build.status).
#
# El binario instalado no se verifica por sha (un rebuild no es byte-identico); se
# imprime el sha del primero conocido como referencia:
#   strata  c1712649d4d892ada55dd6793e0741307ddf72852c74fc030a1a7a7f8de89e1d  (101 118 168 B, 2026-11-12)
set -u
BRANCH=local/kinoyu-cachekv
PKGVER=0.1.57.90
WT=${WT:-$HOME/Strata/wt-v0211}   # checkout de la rama; ponlo tú donde lo hayas puesto
CE=$HOME/.local/share/strata/components/engine
DST=$CE/$PKGVER-linux-x86_64-hip-rx9070

git -C "$WT" rev-parse --abbrev-ref HEAD | grep -qx "$BRANCH" \
  || { echo "este checkout NO esta en $BRANCH: $(git -C "$WT" rev-parse --abbrev-ref HEAD)"; exit 1; }
COMMIT=$(git -C "$WT" rev-parse HEAD)
[ -e "$DST" ] && { echo "ya instalado: $DST"; exit 1; }

# Pin de llama.cpp del tag v0.2.11 = 3cf03257 (reutilizamos el checkout fijado)
LLAMA=${LLAMA:-$HOME/Strata/third_party/llama.cpp}
# Los wheels de ROCm del venv de esta caja (TheRock 7.10: _rocm_sdk_devel/_core/
# _libraries_gfx120X_all). Si usas el runtime ROCm suelto (nosotros hoy lib_dirs ->
# rocm-10.3), apunta HP/CORE/LIBW a sus directorios en lugar de al venv; la versión
# de Python del venv también es local (aquí 3.14).
SP=$HOME/Strata/.venv/lib/python3.14/site-packages
cd "$WT" || exit 1
PATH="$HOME/Strata/.venv/bin:$PATH" \
  VARIANT=rx9070 \
  LLAMA="$LLAMA" \
  HP="$SP/_rocm_sdk_devel" CORE="$SP/_rocm_sdk_core" LIBW="$SP/_rocm_sdk_libraries_gfx120X_all" \
  OUT="$WT/work-rx9070" \
  PKGVER="$PKGVER" COMMIT="$COMMIT" DSV41=0 JOBS=16 \
  bash packaging/build_hip_linux.sh || { echo "falla el build (ver work-rx9070/build.status)"; exit 1; }

SRC=$WT/work-rx9070/components/engine/$PKGVER-linux-x86_64-hip-rx9070
[ -x "$SRC/strata" ] || { echo "no hay componente en $SRC"; exit 1; }
cp -a "$SRC" "$CE/" || exit 1
echo "instalado: $DST"
"$DST/strata" --version
echo "flags del parche (deben aparecer 6 lineas):"
"$DST/strata" --help 2>&1 | grep -c -- "--conversation-cache"
