# Candidate C5 (draft — nothing sent, no patch): `--vram-elastic` on HIP, plus a HIP data point on `--kv k8v4`

> Draft status (2026-10-23): idea + local measurements only; no code was written for this candidate. **Local status: not ported on this box** — `--vram-elastic` is a VRAM-coexistence feature (`POST /v1/vram` hands cache segments of 512 MiB to another program between requests, ~0.1 s to take them back; docs/DETAILS.md #533 section), not a throughput one: it does not move this box's measured bottleneck (PCIe/expert-swap, chat ~72–74 tok/s), and the user has no shared-GPU use case with the server running. Kept as an upstream draft (ADR-011). Source line references are against v0.2.3 (`5c8dd322`). Machine: RX 9070 XT (16 GiB, reported as **gfx1200** on the TheRock 7.10.0a20251120 wheels), Ryzen 7 9800X3D, 60 GiB RAM, Linux; engine 0.1.48 built from v0.2.3.

## 1. Feature request: extend the segmented expert cache (`--vram-elastic`, #533) to HIP

`--vram-elastic` currently errors out on the HIP build: `src/core/expert_cache.cpp` takes the `STRATA_EC_NO_VMM` branch and reports "--vram-elastic (a segmented expert cache) is CUDA-only for now" (line 300); docs/DETAILS.md lists the feature under one NVIDIA GPU.

The HIP building block already exists elsewhere in the same engine: `src/core/vmm.cpp` implements the elastic range with `hipMemAddressReserve / hipMemCreate / hipMemMap / hipMemSetAccess` for ROCm ≥ 6 (gfx906 and devices without the VMM device attribute keep `--kv-grow` off; `STRATA_HIP_VMM=0` turns it off). Whether that path actually serves this card is **not** confirmed: the args pass `--kv-grow`, yet every cold-bench run on this box (engine 0.1.48 from v0.2.3, serve mode, single GPU, 2026-10-23) logs `strata generate: --kv-grow is off (one GPU, a profile, the whole K/V in VRAM, every expert in RAM, no --batch, --vram-elastic or --peer-device)` — the engine ships the HIP VMM path for this platform but disables its K/V use in this configuration. Which is itself part of the point: the expert cache refuses HIP outright where `vmm.cpp` at least probes it.

So the expert cache sits one file away (`vmm.cpp`) from a HIP virtual-memory path that the engine already ships and uses for the K/V. What was **not** checked here, and what a real patch would have to answer:

- whether ExpertCache's segmented arena needs cuMem* features beyond reserve/create/map/setAccess (handle import, eviction-order semantics when segments are handed back mid-request);
- ROCm's allocation granularity vs the cache's 512 MiB segments;
- behavior under multi-GPU HIP configs and on gfx906/older ROCm (expected: stays off, same gate as `--kv-grow`).

A first step would mirror what `vmm.cpp` already does for the K/V: drop the CUDA-only refusal behind a probe of the device's virtual-memory-management support, opt-in, default path unchanged.

Why it matters on this box: the bottleneck is PCIe/expert-swap (16 GiB VRAM, ~49 of 60 GiB RAM used) and no configuration knob moves it — local cold-bench measurements: `pcie-frac` 0.6 vs 0.35 no gain; `--expert-cache-per-layer` noise; `--kv k8v4` and `--spec-min-p 0.75` neutral or worse. An expert cache that can hand VRAM back in segments while still serving is the engine-side lever that today is CUDA-only.

## 2. Report data point: `--kv k8v4` is far slower on HIP than the CUDA numbers suggest

Upstream's published measurement for the K8/V4 hybrid K/V mode (RTX 3090, CUDA): prompt −2..5 %. This box (engine 0.1.48, cold bench protocol, run2 medians, same-day anchor at the same context):

| metric | int8 K/V (`-anclaje`) | `--kv k8v4` | Δ |
|---|---|---|---|
| prompt 4K tok/s | 1,971.8 | 1,503.7 | **−23.7 %** |
| prompt 16K tok/s | 2,422.0 | 1,654.4 | **−31.7 %** |
| chat decode tok/s | 72.5 | 72.8 | +0.4 % |

The mode itself works on this card: the conversation-cache snapshot slope shows the marginal K/V cost dropping ≈20 % (predicted ≈23 %), so the hybrid cells are real. What collapses is prefill compute — the Q4_0 V Hadamard-rotation path looks far slower on RDNA4/HIP than on the CUDA card measured upstream. Not checked here: whether a gfx12 rotation kernel exists at all, or whether the path falls back to a generic one; only the end-to-end prompt cost is measured.

Run evidence on this box: `bench/runs/2026-10-23-1408-k8v4/` (audited: engine 0.1.48, `--kv k8v4` in the engine start line, reused_tokens=0, 74 requests, run1/run2 coherent); audited copy in `bench/results/…-iq3-xxs-k8v4`.
