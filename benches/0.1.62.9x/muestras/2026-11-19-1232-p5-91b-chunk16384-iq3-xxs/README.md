# Community benchmark on AMD Radeon

Measured on 2026-11-19 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.4 GiB; storage: not measured
- OS: Linux 7.0.0-43-generic; GPU driver: not read; CUDA: not read
- Strata: project ?, commit bb0422df; engine 0.1.62
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
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 92.7 (84.8-127.4) | 0.46 (0.41-0.47) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2650.0 (2642.0-2665.6) | not measured | 1.54 (1.53-1.54) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3577.6 (3577.5-3590.7) | not measured | 4.52 (4.50-4.52) |
| agent session, follow-up turns | 13246 (13235-13267) at the last turn | see below | up to 64 | 3 | see below | 96.4 (90.7-107.8) | 1.32 (1.17-1.40) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.3 % (69.2-69.3); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12382 (12382-12383) new tokens of the files are read once); first turn (nothing cached) first token: 1.12 s (1.03-1.14).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 603.7 | 1.03 | 63.1 |
| 1 | 3485 | 636 | 2849 | 2201.7 | 1.316 | 93.6 |
| 2 | 5021 | 3548 | 1473 | 1280.6 | 1.171 | 94.0 |
| 3 | 8258 | 5084 | 3174 | 2312.2 | 1.395 | 93.7 |
| 4 | 10352 | 8319 | 2033 | 1664.2 | 1.245 | 90.7 |
| 5 | 13235 | 10377 | 2858 | 2132.0 | 1.365 | 96.4 |

Per-request data: `results.json`. Engine log lines from the start: `engine-log-excerpt.txt` (when this run started the server).

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 98 s.
