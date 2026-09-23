# AI Toolkit (ostris) on ROCm 10 — venv at ~/Desktop/ai-toolkit

Working setup of https://github.com/ostris/ai-toolkit on the RX 6800 XT.
Executed and verified 2026-09-20. Base recipe + footguns: `pytorch-rocm.md`
(read it first). Flash-attn build details incl. the flydsl footgun are in that
doc's flash-attention section.

## Stack installed (exact pins that day)

- venv from **python3.13.14** (linuxbrew). The repo's default venv came up on
  3.14 — recreated: `rm -rf venv && python3.13 -m venv venv`.
- torch **2.15.0.dev20260919+rocm10.0** `--no-deps`. Version chosen by
  torchvision: the newest torchvision METADATA (0.30.0.dev20260920) pins an
  exact torch dev build (dev20260919) — install THAT torch, same dev series.
- torchvision **0.30.0.dev20260920+rocm10.0** `--no-deps`
- torchaudio **2.11.0.dev20260902+cpu** `--no-deps` (no rocm10.0 build exists)
- triton-rocm pin of that torch: **3.8.0+gitc01b6774** (from torch wheel
  METADATA; changes per dev build — always re-check) + rocm-sdk-core /
  rocm-sdk-device-gfx1030 / rocm-sdk-libraries
- torchcodec **0.17.0.dev20260920+cpu** `--no-deps`. Repo pins 0.9.1, which
  requires `torch==2.9.*`. The nightly dev builds carry **no torch pin** —
  the clean video-dep route on a nightly torch.
- rocm shim wheel (see pytorch-rocm.md) — REQUIRED, requirements pull
  torchao/diffusers/accelerate/bitsandbytes which all depend on torch.
- flash_attn 2.8.4 + amd-aiter 0.1.14rc1.dev177 + flydsl 0.1.9.dev599 (source
  build from ~/Desktop/extras/flash-attention, gfx1030 aiter patches applied;
  see pytorch-rocm.md flydsl footgun — upstream broke this build after
  2026-09-12)

**Manual deps for `--no-deps` torch:** typing-extensions sympy networkx
jinja2 fsspec filelock; torchvision adds numpy pillow.

## requirements edits (repo pins conflict with py3.13 / nightly torch)

- `requirements.txt`: `scipy==1.12.0` → `scipy>=1.14.1` (1.12.0 max cp312;
  resolves 1.18.1, fine)
- `requirements_base.txt`: `torchcodec==0.9.1` commented out (torch 2.9 pin;
  nightly installed instead — command kept in the comment)
- setuptools **80.9.0** — latest (84) removed `pkg_resources`, which
  `pytorch_wavelets` imports. Repo pin `setuptools>=77.0.3` still satisfied.
- `torchao==0.10.0` fine as-is: ships a `py3-none-any` wheel, JIT-compiles
  its kernels at runtime (verified: torchao 0.10.0 has no cp313 wheels but
  doesn't need them)

## Launcher

`runme.sh` in the repo root (CLI training: `./runme.sh <config.yaml>`).
Exports the mandatory env: `HIP_VISIBLE_DEVICES=0`, `GPU_ARCHS=gfx1030`,
`FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE`, `AITER_TRITON_ONLY=1`,
`TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1`, `HSA_ENABLE_SDMA=0`,
malloc-trim hygiene. Any manual venv activation needs at least `GPU_ARCHS`
and `FLASH_ATTENTION_TRITON_AMD_ENABLE` or aiter/flash-attn imports break.

UI: node v26.9.0 already on the box; `cd ui && npm run build_and_start` →
http://localhost:8675. UI-spawned jobs run WITHOUT the flash-attn env —
toolkit uses SDPA by default, which on gfx1030 is the slow-but-correct path
(see pytorch-rocm.md). CLI via runme.sh is the fast path.

## Triton state (don't "fix" blindly)

aiter's install swapped dist `triton-rocm` → multi-backend `triton 3.8.0`
(amd+nvidia backends; the build everything was verified on). torch's
`triton-rocm==3.8.0+gitc01b6774` pin is satisfied by a shim dist-info wheel
(same pattern as the rocm shim). Force-reinstalling triton-rocm would
degrade it — only do that with a full flash-attn re-verification.

## ROCm fork merge (ChuloAI/ai-toolkit) — 2026-09-20

Upstream UI was NVIDIA-blind: `GPUMonitor` → "No NVIDIA GPUs detected"
(nvidia-smi-only). Fixed by merging the ROCm fork:

- remote: `git remote add rocm https://github.com/ChuloAI/ai-toolkit.git`
- `git fetch rocm rocm && git merge rocm/rocm` (fork = upstream 9d6a9a0 + 4
  ROCm commits: UI gpu monitoring via amd-smi/rocm-smi, HIP/ROCR_VISIBLE_DEVICES
  in job spawner, run.py ROCm env defaults + gfx auto-detect, Wan ROCm attn)
- scipy conflict resolved as `scipy>=1.14.1,<2` (fork widened to >=1.12,<2;
  the 1.14.1 floor is the py3.13 requirement)
- local patch commit on top: startJob.ts must NEVER emit an empty
  HIP/ROCR_VISIBLE_DEVICES (empty hides all GPUs — pytorch-rocm.md footgun #1);
  parent-env passthrough removed (it stomped the job's GPU selection)

UI runs via `npm run start` in ui/ (supervisor: `hub start ai-toolkit-ui`),
serves http://localhost:8675; `/api/gpu` now returns the 6800 XT with live
amd-smi metrics (name shows "EXT48025" — amd-smi's VBIOS product string, not
a bug; rocm-smi reports "AMD Radeon RX 6800 XT").

Gotchas learned restarting the UI:
- `concurrently --restart-tries -1` RESURRECTS killed children — kill the
  concurrently pid (SIGKILL) first, then its children, or the old stack
  re-grabs port 8675 mid-rebuild.
- Never rebuild `.next` while a next-server is running on it: a next-server
  booted mid-build serves the PREVIOUS build from memory (this produced the
  stale NVIDIA-only response once). Stop → build → start.
- run.py (merged) sets ROCm env defaults pre-torch only when unset; our
  zshrc's `HSA_OVERRIDE_GFX_VERSION=10.3.0` wins, `PYTORCH_ROCM_ARCH=gfx1030`
  gets auto-detected. `ROCBLAS_USE_HIPBLASLT=0` is GOOD here (gfx1030 has no
  hipBLASLt Tensile libs anyway). `PYTORCH_ROCM_ALLOC_CONF=max_split_size_mb:768,
  garbage_collect=1` is the fork's APU default — unrelated to the poisoned
  `expandable_segments:True`, keep unless render corruption reappears.
- `python3 -m manager doctor`: gpu/venv/torch all OK. Two expected FAILs:
  (1) "torch stack pins" — manager expects its own rocm7.1 stable stack;
  NEVER run `manager install/sync` on this venv, it would replace the
  rocm10 nightly stack. (2) "ffmpeg (local)" — manager wants its own bundled
  copy; system ffmpeg 6.1.1 is installed and fine.

## Manual: start the UI + enqueue a job JSON (verified 2026-09-20)

Automated wrapper (verified 2026-09-22): `~/Desktop/ai-toolkit/aitk.sh` —
`start | stop | status | enqueue <config.json>`. Encodes the whole procedure
below: readiness wait, the concurrently-first kill order, graceful job stop
(SIGINT via API, 90 s wait) before the stack kill, orphaned-trainer cleanup,
and duplicate-name 409 → re-queue existing job (trainer auto-resumes from its
latest checkpoint). Server log when started by it: `ui/ui-server.log`.

### gfx1030 stack research (2026-09-23, benchmarked)

- **Attention is MATH-only on gfx1030 in every stack here.** torch SDPA flash +
  memory-efficient backends are UNAVAILABLE (kohya `2.9.1+rocm7.1.1`: "not
  compiled for gfx1030"; `2.15.0.dev+rocm10.0`: unavailable incl. head_dim 40).
  SD1.5 UNet (all heads head_dim 40, seq 4096) materializes S×S → measured
  ~54 ms/iter fwd+bwd @ b2. The built flash-attn Triton package (23 ms for the
  same shape) is NOT engaged by the UNet path.
- **ROCm userspace swap gains nothing.** SD1.5-shaped conv+attn fwd+bwd bench:
  torch 2.9.1+rocm7.1.1 = 58.2 ms vs 2.15.0.dev+rocm10.0 = 58.1 ms. A tie.
  No measured 2× "legacy regression" exists between ROCm 7/10 kernels.
- **Legacy ~1 s/it was 512² work** (v1/v2 configs: 512, batch 2 → 1.9 s/it
  today). v4 at 704² = 1.89× the pixels → ~2.4 s/it is the same per-pixel
  speed, not a regression. Biggest safe lever: resolution.
- **expandable_segments**: upstream pytorch/pytorch#187343 (closed can't-
  reproduce 2026-07-16) — AMD clean on kernel 6.17, crash only on the
  reporter's Ubuntu kernel 7.0 box; heisenbug (vanishes with AMD_LOG_LEVEL=4)
  ⇒ race in kernel-7.0 amdgpu VMM path, not a torch version issue. This box
  (kernel 7.0.0-31) matches. **Real-training A/B probe (150 steps, v4 config,
  2026-09-23): expandable_segments corrupts training on BOTH stacks tested —
  torch 2.15.0.dev+rocm10.0 (70 nan-skip events) and torch 2.14.0+rocm7.2
  stable (71) — while the default allocator ran clean (0).** No pip-level fix
  exists; fix axis = OS kernel. Keep defaults; retest after any kernel change.
- **Nightly upgrade check (2026-09-23)**: rocm10.0 nightlies exist up to
  `dev20260923` (installed: `dev20260919`). The only perf-relevant delta,
  aotriton 0.14b (PR #197747), was merged Sep 21 and **reverted 14 h later**
  (still unmerged) — and its new `flyc` SDPA backend targets gfx950/gfx1201
  only, never gfx1030. Remaining window = test unskips, MI355X metadata,
  nccl/kineto/fp8/inductor items — none affect gfx1030 training. Upgrade = no
  benefit, real churn (flash-attn rebuild + torchvision repin). Stay put until
  aotriton 0.14b actually lands AND ships gfx1030 kernels.
- **Stack shootout (same 150-step probe, defaults)**: torch 2.14.0+rocm7.2
  stable = 4.09 s/it vs current 2.15.0.dev+rocm10.0 nightly = 2.68 s/it.
  The current nightly is the fastest stack measured here — do not downgrade.
  (torch 2.14+rocm7.2 wheel: 5.9 GB download / 13.7 GB unpacked.)
- **LEGACY STACK REVIVED (2026-09-23): torch 2.3.1+rocm5.7 on latest kohya
  (v26, vendored sd-scripts) + python 3.10 = REAL 1.9x training win.**
  Same v4-fidelity config (704 bucketed, LoCon 256/128+conv 128/64, ckpt on,
  bs1): 1.42 s/it vs 2.68 s/it. Kernel bench: 25.4 ms vs 58.2 (2.3x) —
  MIOpen 2.x CK conv kernels, lost in MIOpen 3.x. Wheels bundle their own HIP
  userspace; coexists with ROCm 10 (kernel 7.0 KFD back-compat verified).
  Setup: uv venv (py3.10) + torch==2.3.1+rocm5.7 + torchvision==0.18.1+rocm5.7
  + sd-scripts/requirements.txt pins minus torch/bitsandbytes. Gotchas:
  bitsandbytes = CUDA-only → use AdamW not 8bit; LoCon conv args go in
  `--network_args "algo=locon" "conv_dim=.." "conv_alpha=.."`; venv built in
  /tmp (tmpfiles-cleaned on reboot — rebuild per runme-legacy.sh header or
  relocate to a real home when disk allows). Launcher:
  `~/Desktop/kohya_ss/runme-legacy.sh`.


### gfx1030 env footguns (2026-09-23, DO NOT re-try blindly)

runme.sh env parity in UI-spawned jobs was tested and FAILED on gfx1030:
- `TORCH_ROCM_AOTRITON_ENABLE_EXPERIMENTAL=1` → training crashes mid-run with
  `hipErrorLaunchFailure` (async, surfaces at next sync — SalaySD1.5_v4). The
  line is now commented out in runme.sh too. Absence = stable.
- `PYTORCH_ALLOC_CONF=expandable_segments:True` + `HSA_ENABLE_SDMA=0` →
  `loss is nan` events ~60 steps after resume (same job). Baseline env
  (login defaults: `gc_threshold:0.9,max_split_size_mb:512`, SDMA on) ran
  1200+ steps and a full 2000-step job clean at ~2.4 s/it. expandable_segments
  on ROCm 10 nightly is a known corruptor: nondeterministic black/garbage
  renders in ComfyUI, same seed (see ~/Desktop/ComfyUI/runme.sh, 2026-09-13).
  Defaults are correct everywhere.
- SD1.5 LoRA speed levers that remain: resolution 704→640 (−17%), the
  kohya_ss venv (`torch 2.9.1+rocm7.1.1`, unbenchmarked), torch.compile
  (not exposed by the trainer). ~2.4 s/it appears to be the ROCm-10/gfx1030
  baseline; ROCm-5-era 1 s/it came from full CK/MIOpen gfx1030 kernel coverage
  (`libMIOpenCKGroupedConv_gfx1030.so` missing in MIOpen 3.6).

### 1. Start the UI

```sh
cd ~/Desktop/ai-toolkit/ui
npm run start          # build already present; serves http://localhost:8675
# npm run build_and_start   # only after code changes (runs prisma + tsc + next build)
```

First start of the day just needs `npm run start`. If the port is busy with a
stale stack: kill the `concurrently` pid FIRST (SIGKILL — it respawns killed
children), then `pkill -9 -f 'dist/cron|next-server'`, confirm port 8675 free.

### 2. Enqueue a training JSON through the API

The UI is a thin DB queue: `POST /api/jobs` stores the config, the queue row
per gpu_ids must be `is_running` for the cron worker to launch
`python run.py output/<job-name>/.job_config.json`. `job_config` must be the
FULL config object (`{"job": ..., "config": ...}`), exactly the file run.py eats.

```sh
CFG=$HOME/Desktop/training/StableDifussion/salay/salay_sd15_lora.json

ID=$(python3 - "$CFG" <<'EOF'
import json, sys, urllib.request
cfg = json.load(open(sys.argv[1]))
payload = json.dumps({"name": cfg["config"]["name"], "gpu_ids": "0",
                      "job_config": cfg}).encode()
req = urllib.request.Request("http://localhost:8675/api/jobs", data=payload,
                             headers={"Content-Type": "application/json"})
print(json.load(urllib.request.urlopen(req))["id"])
EOF
)

curl -s "http://localhost:8675/api/jobs/$ID/start"        > /dev/null   # status -> queued
curl -s "http://localhost:8675/api/queue/0/start"         > /dev/null   # queue is_running=true
echo "enqueued job $ID"
```

Notes:
- Step 3 (`/api/queue/0/start`) is only needed the first time or after the
  queue was stopped — `is_running` persists in the DB. Job start alone is NOT
  enough: the start route creates the queue row with `is_running: false`, and
  `processQueue` only launches jobs from a RUNNING queue.
- Job names are unique (409 on duplicate) — bump the name in the json (v2, ...)
  to re-enqueue.
- gpu_ids "0" reaches the training process as HIP/ROCR/CUDA_VISIBLE_DEVICES=0
  (our patched spawner never emits an empty value).
- No auth by default. If AI_TOOLKIT_AUTH is set when starting the UI, every
  request needs it as a Bearer token.

### 3. Monitor

- UI: http://localhost:8675 (GPU widget reads amd-smi now; jobs page shows step)
- API: `curl "http://localhost:8675/api/jobs?id=<ID>"` → status/step/speed
- Raw log: `~/Desktop/ai-toolkit/output/<job-name>/log.txt`
- Weights: the config's `training_folder` (e.g.
  `~/Desktop/training/StableDifussion/salay/output/`), samples + checkpoints
  every `save_every` steps.

## Known bug fixed: sample crash on transformers 5.5 (2026-09-20)

First job died at the pre-training sample: `ValueError: text input must be of
type str` from the tokenizer. Root cause: `SampleConfig.neg` defaulted to
**False** (bool) and `TrainConfig.negative_prompt` to **None**; with a config
that doesn't set them, the bool/None flowed into `GenerateImageConfig` →
`encode_prompts` → transformers 5.5's strict tokenizer. Fixed locally in
`toolkit/config_modules.py` (both defaults → `''`, matching the subclasses'
own `str` type hints). Any config that sets an explicit string
`negative_prompt` was never affected. Training (salay job) verified running
after the fix: 1.55 s/it at batch 2 / 512 on the 6800 XT.

## Verified 2026-09-20

- `pip check` clean (with both shims in place)
- `torch.cuda` on RX 6800 XT; matmul / SDPA / conv on device (bf16)
- `flash_attn_func` fwd causal bf16: rel-diff 0.0028 vs SDPA;
  aiter JIT `module_aiter_core` built in 24 s, cached
- end-to-end: tiny SD pipeline (diffusers git c943837) 2 denoise steps on GPU
  → real image; `run.py` argparse boots (full trainer import chain)
- benign noise: MIOpen `CK grouped conv library not found for gfx1030`
  (falls back, output verified); aiter opus a16w16 gfx950-only RuntimeWarning
  (AITER_TRITON_ONLY=1 silences); inductor "origami GEMM … ROCm 10.0+"

## LoRA v2: legacy kohya sweet-spot config (2026-09-20)

User's 10 legacy kohya LoRAs (`~/Desktop/ComfyUI/models/loras/carakan/`) all
carry `__metadata__.ss_*`: SD1.5 **LoCon** (lycoris.kohya, algo=locon,
conv_dim=128/conv_alpha=64), dim 256/alpha 128, unet 1e-4 + TE 4e-5,
AdamW8bit, cosine + ~10% warmup, batch 1 @ 768², fp16, grad ckpt, 4-12.5k
images-seen. v1 was linear 32/16 @ 512 batch 2, 1500 steps.

`salay_sd15_lora_v2.json` = midpoint: **linear 64/α32 + conv 32/α16**
(ai-toolkit supports `network.conv`/`conv_alpha` for SD1.5), 768² batch 1,
unet 1e-4 + TE 4e-5 (`train_text_encoder: true`), cosine, warmup 200,
2000 steps, save/sample every 400, EMA 0.99, AdamW8bit, fp16. Runs ~1.9 s/it
on the 6800 XT (MIOpen compiles new 768 shapes on first run; TE-training +
conv + EMA fit in VRAM, no OOM).

Attention note (measured, closes the "is SDPA slow in training?" question):
patching the UNet to flash-attn triton kernels is **0.92x** (563 vs 517 ms
fwd+bwd, batch 2 512²) — the doc's 3.8-5.7x flash wins are inference-only
shapes. Training SDPA stands; no attention patch needed.

### Enqueue API facts (learned the hard way)
- Create/update job: `POST /api/jobs` `{name?, gpu_ids, job_config}`.
  With `id` = update, without = create (status defaults **stopped**).
- `POST /api/jobs/<id>/start` only re-queues; ALSO need
  `GET /api/queue/<gpu_ids>/start` to flip `queue.is_running` (the 1 s cron
  worker then spawns the job).
- `job_config` MUST be the full file incl. `{"config": {...}}` wrapper —
  `startJob.ts` does `jobConfig.config.process[0].sqlite_db_path = ...` and
  crashes the worker on a bare config.
- After a UI-server restart, a dead job stays "running" forever
  (`watchDetachedJob` died with the old server; no reconciliation). Unblock
  the queue with `GET /api/jobs/<id>/mark_stopped`.
- Trainer `log.txt` lands in `ai-toolkit/output/<name>/log.txt`; samples +
  checkpoints go to the config's `training_folder/<name>/`.

## v2 vs v1 + v3 recipe (2026-09-20)

v2 (2000 steps) finished 1:20:26 @ ~1.9 s/it. Learned 3.81x v1's total |W|;
share in conv modules (clothes textures) 14% -> 32%, TE 19% (v1 TE frozen).
Sample review: clothes fidelity strong from step 400, best ~1200; 1600-2000
overfits 22 images (mode collapse: dominant dataset colors, dataset-crop
framing, headless crops). Conclusion: sweet spot = conv capacity up, steps
down. v3 = linear 64/32, conv 48/24, 1200 steps, warmup 120, caption
dropout 0.10, save/sample every 300. v2's keepable checkpoints: 1200 (best
clothes), 1600 (fallback).

## v3 result (2026-09-20) — final recommendation

v3 (linear 64/32 + conv 48/24, 1200 steps, dropout 0.10) finished 54:35.
Learned 4.03x v1's |W| in 60% of v2's steps; conv share 37.8% (v2 31.8%).
Final-step samples show denser costume vocabulary (vest+tassels+aguayo
pouch+headband+pompoms+striped skirt bands simultaneously), no collapse.
**Best LoRA: `salay_sd15_lora_v3.safetensors`.** Fallback: v2_000001200.
UI server stopped on user request; restart: `cd ~/Desktop/ai-toolkit/ui
&& npm run start` (or hub-managed `ai-toolkit-ui`).

## kullawada LoCon mimic run (2026-09-20)

`kullawada_sd15_locon_v1` mimics `kullawadav1.1.safetensors` metadata:
linear 256/a128 + conv 128/a64 (lycoris locon), unet 1e-4 / TE 4e-5,
AdamW8bit, cosine + 10% warmup, batch 1, 768-area aspect buckets, fp16,
grad ckpt, shuffle tokens, seed 123454321, no EMA (kohya had none).
Diffs vs legacy: base model Realistic_Vision_V6.0 (epicrealism not on
disk), dataset 30 imgs x 10 epochs = 300 steps (kohya: 400 imgs), ai-toolkit
aspect buckets (kohya center-cropped squares), max_token_length 150 not
exposed (77 padding). Config: kullawada/kullawada_sd15_locon.json. ~4.5
s/it, 94% VRAM, no OOM. Checkpoints 100/200/300; samples at 624x944.

## Rank-256 LoCon OOM lesson (2026-09-20)
kullawada mimic (linear 256/a128 + conv 128/a64, ~2 GB optimizer+grad state)
crashed with CUDA OOM + SIGSEGV in the in-job step-100 sampling block: trainer
keeps all state resident while the sampling pipeline needs ~1.3 GB more.
Rule: for LoCon rank >= 128 on 16 GB, strip the job's `sample` block entirely
and evaluate checkpoints offline with compare_loras.py (full GPU free).
Training-only peak was 94% VRAM and stable.
Workflow improvements: runme.sh now sets
PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True; reusable eval tool at
~/Desktop/training/StableDifussion/compare_loras.py.

## kullawada results (2026-09-20)
v2 (300 steps/10 epochs) and v3 (600/20) both completed clean with in-job
sampling stripped; evaluation offline via compare_loras.py at 624x944,
seed 42+i, 2 prompts (base RV6 for all rows).
Verdict: style consolidates monotonically 150->600, NO overfit at 600
(loss plateaus ~1.5e-01, faces clean, prompt-obedient). v3_600final is
the best all-around (densest beadwork, dataset-faithful); v2@300 already
matches legacy quality on-style. Legacy kullawadav1.1 keeps the
fabric-fringe spinning-skull drama, but that partly comes from its
epicrealism base; diffusers also drops its conv.in/out+time_emb LoCon
keys (approximate comparison). Grids: kullawada/compare_mimic/ and
.../v3_grid/.
UI quirks learned: job row can stay "running" after process exit and
blocks the next queue start - clear with GET /api/jobs/<id>/mark_stopped
(it's a GET, POST 405s) then POST /api/queue/0/start. diffusers cannot
load_lora_weights(file) with HF_HUB_OFFLINE=1 - drop the flag for eval.
Final save has NO step suffix (name.safetensors), step saves get
_0000NNN.safetensors.

## SalaySD1.5 (epicrealism) resume state (2026-09-20 night)
Stopped cleanly at step ~1203/2000 (user request). Resume: press start on
job SalaySD1.5_16b (id 0c1a08b3) - auto-resumes from ckpt 1200 + optimizer.pt
(scheduler state included; verified earlier tonight resuming at 404).
Checkpoints 400/800/1200 all scanned CLEAN (0 non-finite tensors).
Config: fp16/fp16, lr 5e-5 (halved after lr 1e-4 NaN'd 3x), 704-area buckets,
rank 256 LoCon, epicrealism_naturalSinRC1VAE (songkey HF mirror).
NaN skips: 279 total, all before step ~380 (lr warmup/peak phase), none after.
On finish: scan final safetensors + compare_16bit samples script at
/tmp/salay16_verify.sh (render 592x896 x2 vs RV6 base).

## 16-bit saga: NaN poisoning, dtype matrix, the working recipe (2026-09-20/21)

The epicrealism base NaN'd fp16 training at ~step 200 three times (RV6-based
kullawada never showed this — base-dependent). Mechanism, verified in code and
logs: fp16 grads hit inf → `clip_grad_norm_` multiplies inf by clip-coef →
`0×inf = NaN` → permanent. ai-toolkit zero-skips NaN-loss steps
(SDTrainer.py:2305-2311), so a skipped step never touches weights — weights
only die when the fp16 LoRA weights themselves grow into overflow range
(≥65504), after which every forward is inf. Dtype matrix, all measured:

| dtype | outcome |
|---|---|
| fp16/fp16 @ lr 1e-4, 768² | permanent NaN ~step 200 (3 attempts) |
| bf16 train+base | real loss 2.5e-01 ✓, then `HSA_STATUS_ERROR_EXCEPTION` at ~step 202 — gfx1030 bf16 GEMM hardware fault |
| fp32 mix | `HSA_STATUS_ERROR_EXCEPTION` at step 10 (Chrome already closed — not VRAM) |
| **fp16/fp16 @ unet 5e-5 / TE 2e-5, 704 buckets** | **stable; 279 NaN-skips, all before ~step 380 (warmup/peak-lr phase), zero after; every checkpoint scans clean** |

Rules: pure fp16 end-to-end is the ONLY dtype on this stack that doesn't
fault the GPU runtime; halve lr (legacy kohya used 1e-4 with fp32 LoRA
weights — autocast hid the overflow) to keep fp16 weight growth under the
exponent ceiling through warmup; a warmup-phase NaN-skip storm is expected
and self-limiting; verify with a non-finite tensor scan (clean scans: 1050
tensors, 0 NaN/inf, max|w| = 128). If a base+rank still NaN-storms past
warmup at 5e-5, drop rank (fewer params → fewer overflow steps), not steps.

## Aspect-bucket investigation: nothing is cropped (2026-09-21)

"Training drops/resizes images to a hardcoded size" — investigated with hard
evidence after headless samples appeared. Pipeline innocent, evaluation was
the flaw:

- ai-toolkit bucketing (`toolkit/buckets.py`) is aspect-preserving,
  area-capped: `scale = √(min(area, res²)/area)`, then 16-px rounding.
  Measured across salay/ (109 imgs): worst trim 1.56%, average 0.31% —
  rounding dust, zero dropped content.
- Cached latents are ground truth: all full-frame portrait buckets
  (624×944, 656×896, 688×848) × flip-augment. Portraits trained as portraits.
- This is BETTER than legacy kohya: `ss_resolution (768,768)` without
  bucketing meant kohya center-cropped 2:3 photos to squares. ai-toolkit
  never crops.
- The actual flaw: in-training samples were generated 768×768 SQUARE while
  the LoRA trained on portrait buckets — every judgment went through that
  distortion (the "headless crops" were the square sampler, not the
  trainer). Re-eval at native 624×944 + fixed seed reversed two verdicts.
- **Always sample/eval at the trained bucket aspect** (portrait datasets →
  624×944 or per-image bucket), with a no-LoRA baseline row.
- `resolution: [896]` = 0.00% trim and genuinely up-scales the ~6 smallest
  images ×1.07 — optional texture lever; SD1.5 loses coherence above ~768
  area, so it's a gamble.
- Image-dims cache from this investigation: `<dataset>/.aitk_size.json`
  (regenerable, safe to delete). Grids: `salay/compare_portrait/`.

## SalaySD1.5_16b final (2026-09-22)

Resumed from ckpt 1200 (+ `optimizer.pt`; log confirmed RESUMING + optimizer
state load) → finished all 2000 steps in 42:42 (~2.4 s/it), LR annealed to 0,
final loss 9.4e-03, zero NaN after the warmup phase, final safetensors
scanned clean (1050 tensors, 0 non-finite, max|w| = 128). Artifacts in
`salay/output/SalaySD1.5_16b/`: `SalaySD1.5_16b.safetensors` (final =
step 2000; step saves keep `_0000NNN` suffix) + checkpoints 400/800/1200/1600
+ optimizer.pt. Open item: 1200 vs 1600 vs 2000 comparison — the last 800
steps ran at near-zero LR (detail tightening vs overfit risk). Lifecycle
wrapper `~/Desktop/ai-toolkit/aitk.sh` verified end-to-end this day (start /
stop / status / enqueue; see "Manual" section above).
