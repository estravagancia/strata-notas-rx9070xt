# Community benchmark on AMD Radeon

Measured on 2026-11-16 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-43-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 3f3495f0; engine 0.1.57
- Engine label note: the folder name says `0.1.57.90` — official engine 0.1.57 **with the CacheKV fork patch applied** (diff in `../../patches/CacheKV-fork-kinoyu-sobre-v0.2.11.patch`); that binary reports `0.1.57` in `--version`, as the line above shows.
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 79.7 (74.9-109.5) | 0.49 (0.47-0.50) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2513.4 (2510.8-2514.1) | not measured | 1.62 (1.62-1.62) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3497.0 (3496.4-3504.4) | not measured | 4.62 (4.61-4.62) |
| 32K prompt, fresh | 32049 (32049-32049) | 0 (0-0) | 24 cap | 3 | 3467.9 (3462.6-3480.7) | not measured | 9.28 (9.24-9.29) |
| agent session, follow-up turns | 13508 (13450-13524) at the last turn | see below | up to 64 | 3 | see below | 80.9 (69.2-112.5) | 1.51 (1.37-1.58) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.6 % (69.5-69.6); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12643 (12642-12644) new tokens of the files are read once); first turn (nothing cached) first token: 1.32 s (1.22-1.33).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 509.1 | 1.218 | 53.4 |
| 1 | 3746 | 623 | 3123 | 2102.7 | 1.508 | 74.6 |
| 2 | 5279 | 3809 | 1470 | 1088.8 | 1.372 | 69.2 |
| 3 | 8507 | 5342 | 3165 | 2084.2 | 1.542 | 77.7 |
| 4 | 10602 | 8570 | 2032 | 1438.5 | 1.437 | 85.1 |
| 5 | 13524 | 10665 | 2859 | 1912.1 | 1.52 | 90.3 |

Per-request data: `results.json`. Engine log lines from the start were captured locally; they are not published in this folder.

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 105 s.
