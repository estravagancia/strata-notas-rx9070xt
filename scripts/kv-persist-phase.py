#!/usr/bin/env python3
"""Una fase del test de KV en disco persistente (brazo kinoyu) contra un serve ya arrancado.

Fase 1: conversacion larga A (fria, sin prompt-cache tras arranque) + request corto S.
Fase 2: tras REINICIO del motor, reenviar A y S: mide cuanto prefill se reutiliza desde
el nivel disco (`timings.prompt_ms`, `usage.prompt_tokens_details.cached_tokens`) y compara
las respuestas byte a byte (temperature 0 en chat(), mismo long_prompt con seed fija).

Lo lanza scripts/kv-persist-test.sh; no lo uses a mano con el motor de produccion en marcha.
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tools"))
from strata_bench import chat, digest  # noqa: E402
from ab_engine import long_prompt, PROMPTS  # noqa: E402

A_MAX_TOKENS = 24   # respuesta corta y determinista: basta para comparar el texto


def calibrate(base: str):
    """tokens por palabra como pendiente de dos requests (igual que strata_bench.calibrate)."""
    pts = []
    for words in (200, 800):
        r = digest(chat(base, "", [{"role": "user", "content": f"[kvp cal {words}]\n" + long_prompt(words)}], 1))
        pts.append(r.get("prompt_tokens"))
    slope = (pts[1] - pts[0]) / 600 if all(pts) and pts[1] and pts[0] and pts[1] > pts[0] else None
    tpw = slope or 1.1
    overhead = max(0, (pts[0] or 0) - 200 * tpw) if slope else 40
    return tpw, overhead


def ask(base: str, messages, max_tokens: int) -> dict:
    r = chat(base, "", messages, max_tokens)
    d = digest(r)
    d["text"] = r["text"]
    if r.get("err"):
        d["err"] = r["err"]
    return d


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True)
    ap.add_argument("--phase", type=int, required=True, choices=(1, 2))
    ap.add_argument("--tokens", type=int, default=30000, help="tamano objetivo de A en tokens")
    ap.add_argument("--out", required=True, help="ruta del json de esta fase")
    a = ap.parse_args()
    base = a.url.rstrip("/")

    tpw, over = calibrate(base)
    words = max(50, int((a.tokens - over) / tpw))
    msgs_a = [{"role": "user", "content": f"[kvp A {a.tokens}]\n" + long_prompt(words)}]
    msgs_s = [{"role": "user", "content": PROMPTS[0]}]

    out = {"phase": a.phase, "target_tokens": a.tokens, "words": words, "tokens_per_word": round(tpw, 3)}
    print(f"fase {a.phase}: A ~{a.tokens} tokens ({words} palabras, ~{tpw:.2f} tok/palabra)")

    ra = ask(base, msgs_a, A_MAX_TOKENS)
    out["A"] = ra
    print(f"  A: {ra.get('prompt_tokens')} tok, prompt_ms={ra.get('prompt_ms')}, "
          f"reused={ra.get('reused_tokens')}, reutilizados de prompt: {(ra.get('reused_tokens') or 0)}")

    if a.phase == 1:
        # cambio de conversacion: aparca/mirrea A (con --conversation-cache-persist, el mirado
        # a disco tambien ocurre al final de la propia respuesta de A)
        rs = ask(base, msgs_s, 16)
        out["S"] = rs
        print(f"  S corto: prompt_ms={rs.get('prompt_ms')}")
    else:
        rs = ask(base, msgs_s, 16)
        out["S"] = rs
        prev = os.path.join(os.path.dirname(a.out), "phase1.json")
        if os.path.exists(prev):
            p = json.load(open(prev))
            out["match_A"] = p["A"].get("text") == ra.get("text")
            out["match_S"] = p["S"].get("text") == rs.get("text")
            p1 = (p["A"].get("prompt_ms"), p["A"].get("prompt_tokens"))
            print(f"  comparacion con fase 1: A identico={out['match_A']} (fase1 prompt_ms={p1[0]} "
                  f"sobre {p1[1]} tok), S identico={out['match_S']}")
            if not out["match_A"]:
                # OJO: el control sin nivel disco tambien da A no identico (adapt-async: el motor
                # no es bit-exact entre arranques). No es criterio de exito; solo ayuda visual.
                t1, t2 = p["A"].get("text") or "", ra.get("text") or ""
                k = next((i for i, (x, y) in enumerate(zip(t1, t2)) if x != y), min(len(t1), len(t2)))
                out["first_diff_at"] = k
                print(f"  primera diferencia en char {k} de {len(t1)}/{len(t2)}:")
                print(f"    fase1: {t1[max(0, k - 40):k + 40]!r}")
                print(f"    fase2: {t2[max(0, k - 40):k + 40]!r}")

    json.dump(out, open(a.out, "w"), indent=2, ensure_ascii=False)
    print(f"  escrito: {a.out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
