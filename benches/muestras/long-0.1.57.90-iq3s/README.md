# Community benchmark on AMD Radeon

Measured on 2026-11-13 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-43-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 563d0958; engine 0.1.57
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_s
- Context: 94000 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged; thinking off for the suite; temperature 0

## Method

Run by `python tools/strata_bench.py --long` against the HTTP API of a Strata server (already running); model loading is not timed. One warm-up chat and a 1K prompt are discarded first. Every prompt starts with a unique tag, so the conversation cache cannot help the fresh-prompt tests.

- short chat: the three questions of `tools/ab_engine.py`, up to 100 new tokens, 3 runs
- 4K / 16K prompts: generated word lists sized by a calibration request, 24 new tokens, 3 fresh prompts each
- agent session: system prompt and four tools, then 5 turns that each add about 1500 words of a project file and continue from the model's own earlier answers (the way agent clients resend a conversation), 64 new tokens per turn, 3 sessions; the cache numbers come from the answer's usage (`cached_tokens`) and timings (`prompt_n`)
- concurrency (when run): N requests sent at the same moment, total tokens over the wall time of the burst, latency over all requests

## Results

| Configuration | Actual prompt tokens | Reused tokens | Generated tokens | Runs | Prompt tok/s median and range | Decode tok/s median and range | TTFT seconds median and range |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 80.3 (72.5-113.3) | 0.49 (0.46-0.50) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2507.8 (2500.2-2512.8) | not measured | 1.63 (1.62-1.63) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3220.4 (3218.3-3230.7) | not measured | 5.01 (5.00-5.02) |
| 32K prompt, fresh | 32049 (32049-32049) | 0 (0-0) | 24 cap | 3 | 3161.1 (3156.7-3172.5) | not measured | 10.17 (10.14-10.19) |
| agent session, follow-up turns | 13520 (13497-13524) at the last turn | see below | up to 64 | 3 | see below | 79.6 (72.3-101.3) | 1.50 (1.37-1.57) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.7 % (69.7-69.8); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12648 (12648-12648) new tokens of the files are read once); first turn (nothing cached) first token: 1.32 s (1.21-1.34).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 511.1 | 1.214 | 59.5 |
| 1 | 3745 | 622 | 3123 | 2103.6 | 1.507 | 78.1 |
| 2 | 5278 | 3808 | 1470 | 1086.3 | 1.374 | 75.9 |
| 3 | 8524 | 5341 | 3183 | 2059.8 | 1.569 | 75.7 |
| 4 | 10739 | 8571 | 2168 | 1531.1 | 1.439 | 99.2 |
| 5 | 13497 | 10788 | 2709 | 1834.1 | 1.501 | 99.8 |

Per-request data: `results.json`.

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 109 s.

## Nota de esta muestra (añadida al auditarla)

Corrida suelta en frío del 13-11 con `--long`, con la config de producción del 12-11 y la
producción intacta en otro puerto. No es un A/B: sirve solo para cerrar el 32K que la
pareja del 12-11 no midió.

Condición que hay que tener en cuenta al comparar: quedaban ~8.804 MiB libres de RAM al
arrancar (en la corrida del 12-11, ~9.815), y el motor adaptó solo el tamaño de chunk de
prompt de 16.384 a 8.192 (línea del `server.log`, política `gfx12`, ajustable con
`STRATA_GFX12_CHUNK`). En este mismo run el 16K dio 3.220 tok/s frente a los 3.461 de la
muestra `cachekv-0.1.57.90-iq3s/`, un 6,7 % menos. El 32K de esta muestra (3.161,1 en la
mediana) es por tanto una **cota baja** en esas condiciones de memoria; no es comparable
con el 16K de la otra muestra. El resto de métricas (chat, agente) sí cuadran con la
pareja del 12-11 dentro del ruido.
