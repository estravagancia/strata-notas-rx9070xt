# Community benchmark on AMD Radeon

Measured on 2026-11-12 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-43-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 8bdcde46; engine 0.1.57
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_s
- Context: 94000 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged; thinking off for the suite; temperature 0

## Method

Run by `python tools/strata_bench.py` against the HTTP API of a Strata server (already running); model loading is not timed. One warm-up chat and a 1K prompt are discarded first. Every prompt starts with a unique tag, so the conversation cache cannot help the fresh-prompt tests.

- short chat: the three questions of `tools/ab_engine.py`, up to 100 new tokens, 3 runs
- 4K / 16K prompts: generated word lists sized by a calibration request, 24 new tokens, 3 fresh prompts each
- agent session: system prompt and four tools, then 5 turns that each add about 1500 words of a project file and continue from the model's own earlier answers (the way agent clients resend a conversation), 64 new tokens per turn, 3 sessions; the cache numbers come from the answer's usage (`cached_tokens`) and timings (`prompt_n`)
- concurrency (when run): N requests sent at the same moment, total tokens over the wall time of the burst, latency over all requests

## Results

| Configuration | Actual prompt tokens | Reused tokens | Generated tokens | Runs | Prompt tok/s median and range | Decode tok/s median and range | TTFT seconds median and range |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 78.0 (70.1-109.3) | 0.54 (0.51-0.55) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2441.8 (2441.4-2444.2) | not measured | 1.67 (1.67-1.67) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3457.1 (3445.9-3465.6) | not measured | 4.67 (4.66-4.69) |
| agent session, follow-up turns | 13518 (13508-13538) at the last turn | see below | up to 64 | 3 | see below | 86.8 (71.5-112.4) | 1.50 (1.38-1.56) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.8 % (69.8-69.8); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12648 (12648-12650) new tokens of the files are read once); first turn (nothing cached) first token: 1.34 s (1.25-1.36).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 495.2 | 1.252 | 58.6 |
| 1 | 3754 | 631 | 3123 | 2050.2 | 1.547 | 77.8 |
| 2 | 5287 | 3817 | 1470 | 1084.6 | 1.377 | 72.2 |
| 3 | 8533 | 5350 | 3183 | 2075.8 | 1.556 | 75.0 |
| 4 | 10765 | 8596 | 2169 | 1534.6 | 1.437 | 100.2 |
| 5 | 13538 | 10828 | 2710 | 1839.0 | 1.498 | 103.9 |

Per-request data: `results.json`.

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 78 s.

## Nota nuestra (añadida al generar esta muestra)

Control de la pareja del 12-11 sobre **IQ3_S, contexto 94.000, sin visión**: motor
**0.1.57 oficial**. Su gemelo con el parche CacheKV (motor propio **0.1.57.90**) está en
`../cachekv-0.1.57.90-iq3s/`. La ganancia real de ese experimento no está en estas
tablas (son planas): se mide con reinicio, en `../../scripts/kv-persist-test.sh`.
Corrida `run2` auditada; `run1` fue el calentamiento y se descartó.
