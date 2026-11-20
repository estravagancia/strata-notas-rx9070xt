# Community benchmark on AMD Radeon

Measured on 2026-11-05 with `tools/strata_bench.py` (suite 1, 3 runs per test, medians with ranges). Speeds are the engine's own timings; first-token times are measured by the client over HTTP. Speed only: no correctness check was run.

## Hardware and software

- GPU and VRAM: AMD Radeon, 16 GiB VRAM
- CPU: AMD Ryzen 7 9800X3D 8-Core Processor (8 cores, 16 threads); installed RAM: 61.2 GiB; storage: not measured
- OS: Linux 7.0.0-42-generic; GPU driver: not read; CUDA: not read
- Strata: project 0.1.45, commit 4fa46688; engine 0.1.57
- Background workloads and power limits: not recorded

## Model and configuration

- Model and quantization: qwen3.8-flash-next-iq3_xxs
- Context: 131072 tokens; parallel slots: 1
- Settings: the install's own configuration, unchanged; thinking off for the suite; temperature 0
- A/B variable (the bench tool does not record environment variables in results.json; this
  is recorded in the bench config `cfg-0157-ring0.json` on the test machine): this run
  disabled the engine's gfx12 prompt staging ring with `STRATA_GFX12_RING=0`. The paired
  run (`engine-0.1.57-anillo`) used the 0.1.57 defaults (256 slots below ~6K tokens,
  192 up to 12K, 96 above; upstream documents the change in `DETAILS.md` of v0.2.11).

## Method

Run by `python tools/strata_bench.py --long` against the HTTP API of a Strata server (already running); model loading is not timed. One warm-up chat and a 1K prompt are discarded first. Every prompt starts with a unique tag, so the conversation cache cannot help the fresh-prompt tests.

- short chat: the three questions of `tools/ab_engine.py`, up to 100 new tokens, 3 runs
- 4K / 16K prompts: generated word lists sized by a calibration request, 24 new tokens, 3 fresh prompts each
- agent session: system prompt and four tools, then 5 turns that each add about 1500 words of a project file and continue from the model's own earlier answers (the way agent clients resend a conversation), 64 new tokens per turn, 3 sessions; the cache numbers come from the answer's usage (`cached_tokens`) and timings (`prompt_n`)
- concurrency (when run): N requests sent at the same moment, total tokens over the wall time of the burst, latency over all requests

## Results

| Configuration | Actual prompt tokens | Reused tokens | Generated tokens | Runs | Prompt tok/s median and range | Decode tok/s median and range | TTFT seconds median and range |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| short chat | 46 (43-51) | 0 | 100 (100-100) | 9 | not measured | 79.3 (76.3-126.9) | 0.33 (0.31-0.35) |
| 4K prompt, fresh | 4019 (4019-4019) | 0 (0-0) | 24 cap | 3 | 2098.0 (2089.4-2102.1) | not measured | 1.94 (1.93-1.95) |
| 16K prompt, fresh | 16058 (16058-16058) | 0 (0-0) | 24 cap | 3 | 3099.6 (3099.4-3108.5) | not measured | 5.21 (5.19-5.21) |
| 32K prompt, fresh | 32049 (32049-32049) | 0 (0-0) | 24 cap | 3 | 3067.2 (3058.7-3073.7) | not measured | 10.48 (10.46-10.51) |
| agent session, follow-up turns | 13473 (13443-13500) at the last turn | see below | up to 64 | 3 | see below | 85.4 (75.7-94.3) | 1.66 (1.08-1.76) |

Ranges are the lowest and highest of the runs; `Runs` counts requests that returned a token.

### Agent session (conversation cache)

Cache hit over the follow-up turns: 69.7 % (69.6-69.8); earlier-turn tokens read again per session: 5 (5-5) (earlier turns that the cache did not hold; the 12643 (12643-12644) new tokens of the files are read once); first turn (nothing cached) first token: 1.02 s (0.89-1.02).

| Turn (run 1) | Prompt tokens | Reused | Read | Prompt tok/s | First token (s) | Decode tok/s |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 0 | 609 | 0 | 609 | 702.9 | 0.888 | 68.0 |
| 1 | 3756 | 633 | 3123 | 1849.8 | 1.711 | 75.7 |
| 2 | 5289 | 3819 | 1470 | 1375.4 | 1.09 | 92.2 |
| 3 | 8533 | 5352 | 3181 | 1837.0 | 1.754 | 76.1 |
| 4 | 10761 | 8596 | 2165 | 1442.7 | 1.524 | 85.4 |
| 5 | 13500 | 10790 | 2710 | 1654.9 | 1.661 | 85.1 |

Per-request data: `results.json`.

## Correctness and limitations

Not measured: this is a speed suite. The conversation uses the model's own replies, so token counts differ a little between runs. Machine details come from the server, `nvidia-smi`/`rocm-smi` and the OS; background load and power limits are not recorded. Total time of the suite: 106 s.
