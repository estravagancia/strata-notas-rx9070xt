# Community benchmark on AMD Radeon

Measured on 2026-10-25 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-38-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 477ac13c; engine 0.1.50
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_xxs
- Context: 98304 tokens; parallel slots: 1
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 72.7 (67.9-91.6) | 0.43 (0.37-0.49) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 1956.4 (1927.6-1965.0) | not measured | 2.08 (2.07-2.11) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 2384.3 (2372.8-2391.9) | not measured | 6.76 (6.74-6.79) |
| agent session, follow-up turns | 14590 (14590-14608) at the last turn | see below | up to 64 | 3 | see below | 78.4 (65.3-92.5) | 1.73 (1.28-1.92) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 68.8 % (68.7-68.9); earlier-turn tokens read again per session: 3 (3-74) (earlier turns that the cache did not hold; the 13718 (13717-13718) new tokens of the files are read once); first turn (nothing cached) first token: 1.10 s (1.05-1.15).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 592.8 | 1.048 | 69.2 |
| 1 | 3768 | 647 | 3121 | 1813.8 | 1.742 | 81.1 |
| 2 | 5301 | 3831 | 1470 | 1166.8 | 1.281 | 78.0 |
| 3 | 8734 | 5365 | 3369 | 1840.1 | 1.853 | 78.1 |
| 4 | 11657 | 8795 | 2862 | 1684.3 | 1.722 | 86.8 |
| 5 | 14608 | 11709 | 2899 | 1694.9 | 1.733 | 65.3 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 87 s.
