# Community benchmark on AMD Radeon

Measured on 2026-11-19 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-43-generic; GPU driver: not read; CUDA: not read
- Strata: project ?, commit 015e6c58; engine 0.1.62
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 89.2 (80.8-131.7) | 0.43 (0.42-0.46) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2605.7 (2597.6-2620.8) | not measured | 1.56 (1.56-1.57) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3531.2 (3530.1-3532.3) | not measured | 4.57 (4.57-4.58) |
| agent session, follow-up turns | 13270 (13258-13277) at the last turn | see below | up to 64 | 3 | see below | 91.4 (74.3-112.0) | 1.32 (1.17-1.41) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.3 % (69.3-69.3); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12382 (12382-12383) new tokens of the files are read once); first turn (nothing cached) first token: 1.09 s (1.02-1.10).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 610.0 | 1.02 | 77.3 |
| 1 | 3492 | 643 | 2849 | 2191.5 | 1.322 | 94.6 |
| 2 | 5028 | 3555 | 1473 | 1282.8 | 1.169 | 83.9 |
| 3 | 8265 | 5091 | 3174 | 2289.2 | 1.409 | 74.3 |
| 4 | 10360 | 8327 | 2033 | 1661.9 | 1.246 | 96.8 |
| 5 | 13270 | 10412 | 2858 | 2115.2 | 1.374 | 101.7 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 82 s.
