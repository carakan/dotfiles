# comfyui-rocm (patientx-cfz) — env/flag keys inventory, annotated for gfx1030

Audit of https://github.com/patientx-cfz/comfyui-rocm (Windows-only ComfyUI+ROCm
installer; author ships an RX 6800 himself, so RDNA2 is a first-class target).
Checked 2026-09-12 against our Linux setup: ROCm 10.0 nightly torch
2.15.0.dev20260907, ComfyUI 0.35, ComfyUI venv at `~/Desktop/ComfyUI/venv`.

Status legend:
- [SET] already in our `runme.sh`
- [TESTED] verified working/ineffective on this machine
- [N/A] Windows-only or not applicable to gfx1030
- [CANDIDATE] present on our stack, untested here — worth trying

Every ComfyUI flag below was confirmed present in our 0.35 (`main.py --help`).

---

## SDP backend overrides (RDNA1/2 branch of comfyui-rocm.bat)

| key | value | purpose | status here |
|---|---|---|---|
| `TORCH_BACKENDS_CUDA_FLASH_SDP_ENABLED` | `0` | disable torch SDP flash backend on RDNA1/2 | **[TESTED: NOT effective]** — torch 2.15.0.dev+rocm10.0 has no reference to `TORCH_BACKENDS_CUDA_*` and setting it does not flip `torch.backends.cuda.flash_sdp_enabled()`. Code-side alternative: `torch.backends.cuda.enable_flash_sdp(False)` |
| `TORCH_BACKENDS_CUDA_MEM_EFF_SDP_ENABLED` | `0` | disable mem-efficient SDP backend | **[TESTED: NOT effective]** (same reason) |
| `TORCH_BACKENDS_CUDA_MATH_SDP_ENABLED` | `1` | keep math SDP as the fallback | moot — same mechanism missing |

Why they bother: on RDNA2 the AOTriton SDP kernels are the *slow* path.
Confirmed in ComfyUI 0.35 source: `comfy/model_management.py` gates
aotriton efficient attention to `gfx90a/gfx942/gfx950/gfx1100/gfx115x…` and
lists gfx1030 in `AMD_RDNA2_AND_OLDER_ARCH` — so SDPA here falls back to a
4–6x slower path (matches our benchmark: SDXL shape 167 ms vs 30 ms
flash-attn-triton). Our defense is `--use-flash-attention` with the locally
built Triton backend, which bypasses SDPA entirely — see
`pytorch-rocm.md` flash-attention section.

| key | value | purpose | status here |
|---|---|---|---|
| `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL` | `1` | experimental AOTriton ops (their RDNA3+ branch) | [SET] — harmless on gfx1030 (SDPA gate excludes us anyway); keep for non-attention AOTriton ops |

## Caches & library DBs (comfyui-rocm.bat)

| key | value | purpose | status here |
|---|---|---|---|
| `PYTORCH_TUNABLEOP_CACHE_DIR` | dir | persistent TunableOp GEMM-tuning cache | **[TESTED: BLOCKED on gfx1030]** — hipBLASLt in the rocm-sdk-gfx1030 build ships NO RDNA2 Tensile libraries; TunableOp's sweep calls hipblaslt `getAllAlgos` → `HIPBLAS_STATUS_INVALID_VALUE` → *every* matmul raises (plain fp16 `a@b` crashes with `PYTORCH_TUNABLEOP_ENABLED=1`). No env selects a rocBLAS-only tuning backend, and `HIPBLASLT_TENSILE_LIBPATH` pointed at the rocBLAS dir does not help. Left commented-out in runme.sh; re-try if a future SDK ships hipblaslt Tensile libs for gfx1030 |
| `TRITON_CACHE_DIR` | dir | persistent Triton JIT cache across runs | [CANDIDATE] — default `~/.triton` works; explicit dir keeps it out of dotfile backups |
| `TRITON_PRINT_AUTOTUNING` | `0` | quiet autotune logs | cosmetic |
| `TRITON_CACHE_AUTOTUNING` | `0` | don't persist autotune results | their choice; we may want the opposite |
| `MIOPEN_SYSTEM_DB_PATH` | venv `_rocm_sdk_devel/bin` | prebuilt MIOpen kernel DB | **[SET+TESTED]** — Linux venv equivalent: `venv/…/site-packages/_rocm_sdk_libraries/share/miopen/db` (ships `gfx1030_36.db.txt`, fdb files); no errors, matmuls clean |
| `ROCBLAS_TENSILE_DB_PATH` / `ROCBLAS_TENSILE_LIBPATH` | venv `_rocm_sdk_devel/bin/rocblas…` | prebuilt rocBLAS Tensile libs | **[SET+TESTED]** — Linux equivalent: `_rocm_sdk_libraries/lib/rocblas` (+ `/library`, has `TensileLibrary_lazy_gfx1030.dat` — note: that dat belongs to rocBLAS; hipBLASLt has none for gfx1030, see TunableOp row) |
| `COMFYUI_ENABLE_MIOPEN` | `0` | author defaults MIOpen OFF | [SET=1 here] — their default contradicts our runme.sh; MIOpen mainly helps conv/VAE. If VAE decode misbehaves, try `0` |
| `MIOPEN_FIND_ENFORCE` | `1` | re-run find every run (no db trust) | [CANDIDATE] — pairs with a writable user db; costs first-run time |
| `MIOPEN_FIND_MODE` | `2` | normal find mode | [SET] already |
| `MIOPEN_DEBUG_DISABLE_FIND_DB` | `0` | allow find-db use | [CANDIDATE] |
| `MIOPEN_SEARCH_CUTOFF` | `1` | cut off slow search results | [CANDIDATE] |
| `MIOPEN_ENABLE_LOGGING` / `MIOPEN_LOG_LEVEL` / `MIOPEN_ENABLE_LOGGING_CMD` | `0` | quiet MIOpen | cosmetic |

## Launcher workarounds (comfyui-rocm.bat)

| key | purpose | status here |
|---|---|---|
| `HIP_VISIBLE_DEVICES=1` | their fix for `AcceleratorError: CUDA error: invalid kernel file` (iGPU+dGPU index mixup on Windows) | [N/A but related] — on this box the values that matter are `0` (select the 6800 XT) and *never empty* (empty hides all GPUs, see `pytorch-rocm.md` footgun #1) |
| `rocm-sdk init` at every launch + `HIP_PATH=$(rocm-sdk path --root)` | bootstrap bundled SDK | [N/A] — our venv SDK loads via normal import; nothing to init on Linux |

## ComfyUI startup flags (their `PARAMS`, all exist in 0.35)

| flag | purpose | status here |
|---|---|---|
| `--use-quad-cross-attention` | math-based cross attention; author recommends for RDNA1/2 | [CANDIDATE] — relevant only if we drop `--use-flash-attention`; quad-cross may beat the SDPA fallback for cross-attn shapes |
| `--enable-dynamic-vram` | dynamic VRAM management; "much better than it was" | **[SET+TESTED]** — in runme.sh; ComfyUI logs `DynamicVRAM support detected and enabled` |
| `--disable-triton-backend` | ComfyUI's built-in triton attention targets RDNA3+ ("won't activate for older gens") | [N/A for gfx1030] — never activates here; keep or drop, no effect |
| `--use-ck-attention` | comfy-kitchen attention; best on RDNA4 | [N/A for gfx1030] |
| `--use-sage-attention` | optional for legacy GPUs | [CANDIDATE] — sage itself not installed on Linux here |
| `--cache-lru 20` | LRU node-output cache limit | [CANDIDATE] — upstream 0.35 flag; pairs with `--cache-none` we currently use (theirs is friendlier for workflows that re-run nodes) |
| `--disable-smart-memory` / `--disable-pinned-memory` / `--disable-api-nodes` | already mirrored in runme.sh | [SET] |

## Install-time choices (install.bat) — portable to Linux

| item | notes | status here |
|---|---|---|
| `torch[device-<arch>]` extras from `https://nightly.repo.amd.com/rocm/whl-next/` | pip auto-selects the correct per-GPU SDK — cleaner than our manual `--no-deps` + `rocm-sdk-device-gfx1030` dance; same origin as the device wheels we already use (stable.repo.amd.com whl-next) | [CANDIDATE] for the next fresh venv — try `pip install "torch[device-gfx1030]" --pre --index-url https://nightly.repo.amd.com/rocm/whl-next/` before falling back to the manual recipe in `pytorch-rocm.md` |
| flash-attention prebuilt wheel (`0xDELUXA` v2.8.4 win) + matching `amd_aiter` wheel | same aiter-Triton backend we compiled from `~/Desktop/extras/flash-attention` | [TESTED] our source build works; Linux prebuilt equivalent not found — keep the source recipe |
| sageattention-autotune 2.2 (patientx fork) | int8-per-block sage with autotuning; claims RDNA2 support | [CANDIDATE] — pure-Triton path may JIT under our `triton-rocm`; untested |
| bitsandbytes ROCm fork (`0xDELUXA` cp312 rocm7.16 win wheel) | NF4/int8 quant loaders | [CANDIDATE] — upstream bitsandbytes has multi-backend ROCm builds; check Linux wheel before hunting forks |
| ComfyUI-INT8-Fast-ROCM custom node | int8 models via Triton; auto-activates below RDNA3; author: 25–40% faster than fp8, "global hijacker" reroutes native-loader int8 ops | **[LOADED+TESTED-BOOT]** — cloned into `custom_nodes`; on boot it detects gfx1030 and patches `int8_linear` → its own Triton GEMM (`rocm_int8_linear`), exactly as advertised. Perf claim still needs a real generation A/B |
| H3 SLA attention custom node (patientx fork of PlagueKind sparse attn) | author: much faster than sage-attention on RDNA2 | **[LOADED]** — cloned into `custom_nodes`, imports clean alongside our Triton 3.8.0 (rocm). Perf claim untested |
| ComfyUI-HFRemoteVae (kijai) | OOM-free VAE decode for SD1.5/SDXL/Flux | [CANDIDATE] — 16 GB card benefits on big models |
| CFZ-SwitchMenu / CFZ-Caching | QoL custom nodes | optional |
| `rocm_kpack.dll` copy fix (`_rocm_sdk_devel` → `_rocm_sdk_core`) | Windows packaging quirk | [N/A] |
| comfy-aimdo "NVIDIA-only" warning disabled in fork | our Linux `comfy-aimdo` 0.5.3 imports and runs fine | [N/A] — no action |

---

## TL;DR for this machine

Already paying off here: flash-attn-Triton attention (3.8–5.7x vs SDPA),
`TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL`, `MIOPEN_FIND_MODE=2`, allocator
tuning, the four footgun defenses in `pytorch-rocm.md`.

Loaded 2026-09-12: `ComfyUI-INT8-Fast-ROCM` + `comfyui-h3-sla-attention-rocm`
cloned into `custom_nodes` (INT8 auto-patches int8_linear → Triton GEMM on
gfx1030); `--enable-dynamic-vram` and the MIOpen/rocBLAS DB paths are in
`runme.sh`. TunableOp is **blocked** (hipBLASLt has no RDNA2 Tensile libs in
the rocm-sdk — getAllAlgos raises on every matmul).

**Local patch — WanVideoWrapper `wanvideo/modules/attention_flash.py`**
(2026-09-13): renamed shadowed comprehension vars in the `k_lens` path
(`[u[:v] for u, v in zip(v, ...)]` → `[u[:n] for u, n in zip(v, ...)]`, 3
lines). Under torch.compile dynamo resolves the shadowed `v` to the
function-local being assigned → UnboundLocalError on every compiled Wan run
with k_lens (cross-attention). Reverts on node update — re-apply if needed.
WanVideoWrapper attention_mode: use **`flash_attn_2`** (verified: our
flash_attn 2.8.4 Triton-AMD implements `flash_attn_varlen_func` incl. the
bf16/cu_seqlens pattern the wrapper calls). `sageattention==1.0.6` installed
for the sage modes but is slower than flash on gfx1030.

Next experiments, in expected-value order:
1. INT8-Fast-ROCM: quantize a real model (needs bf16 checkpoint) and A/B the
   25–40% claim
2. H3 SLA attention in a workflow (node exists after loading the custom node)
3. MIOpen user-DB warm-up: run a generation twice, confirm the second is faster

---

## Changelog — ComfyUI launch args (runme.sh)

Current line:

```sh
python3 main.py --listen 0.0.0.0 --disable-api-nodes --cache-none \
  --disable-smart-memory --disable-pinned-memory \
  --use-flash-attention --enable-dynamic-vram --enable-manager
```

Standing args (unchanged from the original script, kept with reasons):

| arg | why |
|---|---|
| `--listen 0.0.0.0` | LAN access from other devices |
| `--disable-api-nodes` | no paid/cloud API nodes wanted locally |
| `--cache-none` | predictable memory behavior; revisit `--cache-lru 20` if workflow re-runs matter more than RAM headroom |
| `--disable-smart-memory` / `--disable-pinned-memory` | aggressive unload between nodes — needed on 16 GB with big video models; pinned memory has no benefit and wastes locked RAM on this setup |

Changes, newest first:

- **2026-09-13 — GPU thermal shutdown (SW CTF) + gist env vars.**
  The "unexpected shutdown while rendering" was **GPU overheat**: amdgpu
  logged `GPU over temperature range(SW CTF)` and initiated a protective
  system poweroff (preceded by a gfx ring timeout + reset two minutes
  earlier). Idle temps are fine (45-48C) but fan speed is not detectable via
  rocm-smi — check fan/dust/zero-RPM mode; mitigation options: lower power
  limit (`rocm-smi --setpoweroverdrive`), CoreCtrl fan curve, or just watch
  `rocm-smi --showtemp` during long renders. From alexheretic's gfx1100
  ComfyUI gist, adopted: `AITER_TRITON_ONLY=1` (silences gfx950 opus import,
  skips dead CK paths), `MALLOC_MMAP_THRESHOLD_=65536` +
  `MALLOC_TRIM_THRESHOLD_=65536` (RAM fragmentation hygiene for long
  sessions). Already had: `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL`,
  `FLASH_ATTENTION_TRITON_AMD_ENABLE`, `COMFYUI_ENABLE_MIOPEN`,
  `--disable-pinned-memory`. Rejected/skip: `MIOPEN_FIND_MODE=FAST`
  (equivalent via our warm FIND cache), `PYTORCH_NO_HIP_MEMORY_CACHING`
  (OOM-only), TunableOp (blocked on gfx1030), optional perf experiments left
  for later: `FLASH_ATTENTION_TRITON_AMD_AUTOTUNE`,
  `PYTORCH_MIOPEN_SUGGEST_NHWC`.

- **2026-09-13 — ROOT CAUSE FOUND: `expandable_segments:True` (allocator env).**
  Final diagnosis of the garbage/black-image saga: the `PYTORCH_*_ALLOC_CONF`
  vars — specifically `expandable_segments:True` — cause **nondeterministic**
  weight/latent corruption on ROCm 10 nightly torch. Proof: identical
  workflow+seed renders clean, then black, then clean again within one server
  session; with the vars removed entirely, 6/6 renders are bit-identical to
  the known-good baseline. Earlier theories (wedged GPU state, cold-boot
  first-render, MIOpen cache, model switching, dynamic-vram) were all wrong —
  each was consistent with some incidents but failed controlled reproduction.
  `runme.sh` now has **no custom allocator vars at all**. Kept from later
  experiments (harmless): `HSA_ENABLE_SDMA=0`, `--reserve-vram 2`. Per-gen
  timing is now captured: runme.sh tees the session to
  `logs/comfy_<timestamp>.log`; every generation logs
  "Prompt executed in X.XXs" (≈23s for SD1.5+LoRA 20-30 steps incl. model
  reload, ≈0.80 s/step all-in on the minimal bench).

- **2026-09-13 — automatic post-boot warm-up render (runme.sh) — now a CANARY.**
  Originally added for a "cold-boot first-render corrupts" theory that turned
  out to be wrong (real cause: `expandable_segments`, see root-cause entry).
  Kept anyway: (1) absorbs MIOpen's first-run kernel benchmarking so the first
  real render is faster; (2) acts as an early-warning canary — the 4-step
  render lands in `output/warmup/`; if it is ever flat/black again, something
  regressed before any real generation is wasted. Cost: ~3.5s per server start.

- **2026-09-13 — incident: black/garbage images; NO arg was changed.**
  Symptoms: SD1.5 txt2img produced solid-black or flat-color images, FastBlend
  frames came out black/pure-noise, on the server session started 01:18 (right
  after a window with crashed processes: cupy-cuda12x-era crashes, an OOM'd
  bench process, a server dying mid-prompt). Bisected with a clean harness:
  identical env + args in a fresh process reproduce a bit-perfect correct image
  every time (deterministic seed 42 fox). Every env group was exonerated
  individually: allocator conf (incl. `expandable_segments:True`), MIOpen
  FIND_MODE=2 + SDK DB paths, HSA flags, inductor/BLAS vars, flash-attn
  numerics (re-verified vs SDPA under the devel CPATH). Diagnosis: **wedged
  GPU/driver process state inherited by the 01:18 and 01:45 sessions** — the
  user's "broken memory" hunch, but process-level, not hardware and not a
  launch arg. Resolution: full restart via `runme.sh` from a clean process
  table. If garbage images ever come back: restart ComfyUI first; only if it
  survives restarts across reboots suspect driver/hardware.

- **2026-09-13 — added `--enable-manager`.**
  ComfyUI 0.35 moved the Manager into the pip package (`comfyui_manager==4.2.2`,
  pinned in the repo's `manager_requirements.txt`). Without this flag the
  Manager feature is off and the UI shows the "run pip install -U --pre
  comfyui-manager" message; installing nodes from the frontend does nothing.
  The old `custom_nodes/comfyui-manager` clone (Manager UI v1) was deleted —
  the pip package replaces it; its API now lives under `/v2/manager/*`.

- **2026-09-13 — added `--enable-dynamic-vram`.**
  Taken from the comfyui-rocm (patientx) audit — "much better than what it
  was" regarding AMD compatibility. Boot log confirms
  `DynamicVRAM support detected and enabled`. Better VRAM reuse than the
  estimate-based loader on a 16 GB card.

- **2026-09-12 — re-added `--use-flash-attention`.**
  After building flash-attention from `~/Desktop/extras/flash-attention`
  (Triton backend via vendored aiter, gfx1030 patches). It is 3.8–5.7× faster
  than SDPA on this card, and this flag makes ComfyUI route attention through
  it. Requires `GPU_ARCHS=gfx1030` + `FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE`
  in the env (also in runme.sh) or imports crash.

- **2026-09-12 — removed `--use-flash-attention` (temporary).**
  The prebuilt flash_attn stub was uninstalled: its only code path on AMD went
  through `aiter`, which has no gfx1030 support and raised KeyError at import.
  With the flag set but the package missing, ComfyUI calls `exit(-1)` at
  startup (`comfy/ldm/modules/attention.py`), so the flag had to go while the
  package was gone.

Considered and rejected (do not add without reason):

- `--use-quad-cross-attention` — only relevant if flash-attn is dropped;
  math-based cross attention is slower than the Triton kernels here.
- `--use-ck-attention` — comfy-kitchen attention targets RDNA4; gfx1030
  gains nothing.
- `--disable-triton-backend` — ComfyUI's built-in Triton attention never
  activates on RDNA2 anyway; flag is a no-op here.
- `--use-sage-attention` — `sageattention==1.0.6` (pure-Triton) IS installed and
  works on gfx1030, but benchmarked SLOWER than the flash-attn Triton backend
  everywhere (e.g. SDXL-shape: 93ms vs 53ms vs SDPA 385ms). flash-attn wins;
  sage only exists for node compatibility (WanVideoWrapper imports it).
- `--enable-manager-legacy-ui` — implies `--enable-manager` and restores the
  old Manager window UI; use only if the integrated 0.35 Manager UI is
  disliked.
