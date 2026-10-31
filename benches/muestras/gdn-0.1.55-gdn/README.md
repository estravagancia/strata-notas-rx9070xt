# Community benchmark on AMD Radeon

Measured on 2026-10-31 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-42-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 477ac13c; engine 0.1.55
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 76.7 (69.7-97.8) | 0.38 (0.32-0.43) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2023.3 (2023.0-2029.1) | not measured | 2.01 (2.00-2.01) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 2957.9 (2954.7-2985.8) | not measured | 5.46 (5.41-5.46) |
| agent session, follow-up turns | 13300 (13281-13319) at the last turn | see below | up to 64 | 3 | see below | 81.6 (72.9-107.5) | 1.58 (1.26-1.71) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 70.0 % (69.9-70.0); earlier-turn tokens read again per session: 3 (2-4) (earlier turns that the cache did not hold; the 12456 (12455-12456) new tokens of the files are read once); first turn (nothing cached) first token: 1.10 s (1.02-1.10).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 609.7 | 1.019 | 54.9 |
| 1 | 3748 | 628 | 3120 | 1888.6 | 1.674 | 82.6 |
| 2 | 5281 | 3812 | 1469 | 1176.7 | 1.27 | 81.6 |
| 3 | 8525 | 5345 | 3180 | 1883.9 | 1.71 | 79.7 |
| 4 | 10584 | 8579 | 2005 | 1440.1 | 1.414 | 80.1 |
| 5 | 13300 | 10617 | 2683 | 1724.2 | 1.579 | 72.9 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 77 s.
