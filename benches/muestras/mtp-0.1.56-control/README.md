# Community benchmark on AMD Radeon

Measured on 2026-11-03 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-42-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 0d9f5891; engine 0.1.56
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_xxs
- Context: 131072 tokens; parallel slots: 1
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 77.0 (71.2-97.7) | 0.39 (0.34-0.40) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2046.1 (2034.9-2058.7) | not measured | 1.99 (1.97-2.00) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3041.5 (3032.9-3059.0) | not measured | 5.31 (5.28-5.32) |
| agent session, follow-up turns | 13290 (13289-13309) at the last turn | see below | up to 64 | 3 | see below | 86.3 (73.3-102.5) | 1.62 (1.05-1.72) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.9 % (69.9-70.0); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12458 (12457-12458) new tokens of the files are read once); first turn (nothing cached) first token: 1.00 s (0.92-1.03).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 680.5 | 0.917 | 58.5 |
| 1 | 3740 | 617 | 3123 | 1882.0 | 1.682 | 93.7 |
| 2 | 5273 | 3803 | 1470 | 1413.2 | 1.062 | 84.2 |
| 3 | 8517 | 5336 | 3181 | 1874.9 | 1.72 | 73.3 |
| 4 | 10581 | 8576 | 2005 | 1414.7 | 1.44 | 84.1 |
| 5 | 13290 | 10607 | 2683 | 1682.0 | 1.619 | 81.1 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 75 s.
