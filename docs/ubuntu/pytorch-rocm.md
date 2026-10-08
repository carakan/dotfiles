# PyTorch on ROCm 10 — reusable setup (Ubuntu 24.04, RX 6800 XT / gfx1030)

Source of truth for setting up any PyTorch project on this machine's AMD GPU.
Written after the full working setup of ComfyUI (2026-09-12); every command below
was executed and verified on the real hardware.

**Machine:** i9-10900, AMD Radeon RX 6800 XT (gfx1030, RDNA2, 16 GB), 64 GB RAM
**Stack:** Ubuntu 24.04, kernel 7.0.0-38-generic, ROCm 10.1.0-3 (amdrocm-*
packages), Python 3.13

---

## The four footguns (read first)

1. **Never set `HIP_VISIBLE_DEVICES` from `$(hipconfig -R)`.** That command
   prints the ROCm *install path* (or empty on failure). An empty or invalid
   value means "hide every GPU from HIP" — `rocminfo` still works, PyTorch sees
   0 GPUs. Correct value for this machine: `HIP_VISIBLE_DEVICES=0`.
2. **`pip install torch` from PyPI = the CUDA build.** On Linux it drags in the
   full `nvidia-*` wheel set (~3 GB) and silently replaces a working ROCm
   install. ROCm wheels only exist on AMD/PyTorch indexes.
3. **pip backtracks ROCm torch → CUDA torch** when anything in the resolution
   graph depends on `torch` and torch's own `rocm[device-all,libraries]==10.0.*`
   dependency cannot be satisfied. Fix: the `rocm` shim wheel (below). This
   happens even when the installed torch version satisfies the requirement.
4. **ROCm 10.0 torch existed only as a nightly; ROCm 10.1 has STABLE wheels.**
   Since 2026-10-04 the ComfyUI venv runs the stable pairing from AMD's index
   `https://stable.repo.amd.com/rocm/whl-next/` (see the 2026-10-04 note in the
   venv section below): `torch==2.14.0+rocm10.1.0`,
   `torchvision==0.29.0a0+rocm10.1.0` (the `a0` is AMD's official pairing for
   stable 2.14.0, not a dev build), `torchaudio==2.11.0.3+rocm10.1.0` (a real
   ROCm torchaudio exists at last — no CPU stand-in needed). The rocm10.0
   nightly recipe below is kept for history/fallback.

---

## Installing PyTorch ROCm 10 into a venv (reusable)

**2026-10-04 — stable ROCm 10.1 upgrade (ComfyUI venv, verified):** the whole
nightly dance below is obsolete for 10.1. AMD's stable index hosts everything,
including the real `rocm` metapackage (no handmade shim needed) and
per-arch SDK wheels. Proven sequence, gfx1030-only:

```sh
pip install --no-deps --index-url https://stable.repo.amd.com/rocm/whl-next/ \
  "rocm==10.1.0" "rocm-sdk-core==10.1.0" "rocm-sdk-device-gfx1030==10.1.0" \
  "rocm-sdk-libraries==10.1.0" "triton==3.8.0+git669b31ac.rocm10.1.0" \
  "amd-torch-device-gfx1030==2.14.0+rocm10.1.0" \
  "amd-torchvision-device-gfx1030==0.29.0a0+rocm10.1.0"
pip install --no-deps --index-url https://stable.repo.amd.com/rocm/whl-next/ \
  "torch==2.14.0+rocm10.1.0" "torchvision==0.29.0a0+rocm10.1.0" \
  "torchaudio==2.11.0.3+rocm10.1.0"
rm -rf venv/lib/python3.13/site-packages/rocm-10.0.0.dist-info   # old handmade shim
```

Notes from the migration:
- torch 2.14 pins plain `triton` (no `triton-rocm` pin anymore) — the
  triton_rocm shim dist-info becomes stale; `pip check` decides if it can go.
- flash-attn 2.8.4 (Triton backend) and aiter (with the local gfx1030 patches)
  kept working **without rebuild**; aiter JIT cache survived. cupy 14.2.0
  still works against the 10.1 system libs.
- MIOpen rebuilds its kernel cache on first renders after the ROCm bump —
  first render is ~2x slower once, then normal.
- The bare `torch`/`torchvision` lines in requirements.txt are now SAFE:
  with the real `rocm==10.1.0` installed, pip's resolver satisfies torch's
  deps locally and `pip install -r requirements.txt` changes nothing
  (verified by `--dry-run --report`).

```sh
python3.13 -m venv venv && source venv/bin/activate
pip install -U pip

# 1. SDK pieces for THIS gpu only (rocm-sdk-device-gfx1030, not device-all!)
pip install rocm-sdk-core rocm-sdk-device-gfx1030 rocm-sdk-libraries \
            triton-rocm==<hash-required-by-torch> \
    --index-url https://download.pytorch.org/whl/nightly/rocm10.0

# 2. torch itself, --no-deps so it cannot pull rocm[device-all] (~10 GB of
#    other people's GPU SDKs) — find the exact triton-rocm pin first:
curl -s "https://download.pytorch.org/whl/nightly/rocm10.0/torch-<VER>+rocm10.0-cp313-cp313-manylinux_2_28_x86_64.whl.metadata" \
  | grep "Requires-Dist: triton"
pip install --no-deps torch==<VER>+rocm10.0 \
    --index-url https://download.pytorch.org/whl/nightly/rocm10.0

# 3. torchvision same index (date lags torch by ~2 days; its METADATA pins an
#    exact torch dev version — install THAT torch version, no downgrade drama,
#    they are the same dev series)
# 4. torchaudio: NO rocm10.0 build exists. CPU nightly works fine next to a
#    HIP torch (ComfyUI imports it unconditionally):
pip install --no-deps torchaudio==<latest-cpu-dev>+cpu \
    --index-url https://download.pytorch.org/whl/nightly/cpu
```

**Browse available builds:**
`https://download.pytorch.org/whl/nightly/rocm10.0/<pkg>/` (plain HTML index).
The older `https://rocm.nightlies.amd.com/v2/gfx103X-*` and `whl-multi-arch`
indexes are stale for gfx1030 — ignore them.

**Verify:**

```sh
python -c "import torch; print(torch.__version__, torch.cuda.is_available(), \
torch.cuda.get_device_name(0))"
# expect: 2.15.0.dev...+rocm10.0 True AMD Radeon RX 6800 XT
```

If `False` while `rocminfo` shows the GPU: check `env | grep HIP` — footgun #1.

---

## The `rocm` shim wheel (protects every future pip run)

**Problem:** pip resolves the full dep graph of anything that touches `torch`.
Installed torch requires `rocm[device-all,libraries]==10.0.*`; PyPI has no such
package, so pip discards the installed torch and installs CUDA torch instead —
even for a plain `pip install -r requirements.txt` with bare `torch` lines.

**Fix (once per venv):** a 2 KB metapackage that declares the extras satisfied.

```sh
mkdir -p /tmp/rocm-shim/rocm-10.1.0.dist-info && cd /tmp/rocm-shim
cat > rocm-10.1.0.dist-info/METADATA <<'EOF'
Metadata-Version: 2.1
Name: rocm
Version: 10.1.0
Summary: Local shim; real SDK installed as rocm-sdk-* packages
Provides-Extra: device-all
Provides-Extra: libraries
EOF
cat > rocm-10.1.0.dist-info/WHEEL <<'EOF'
Wheel-Version: 1.0
Generator: handmade
Root-Is-Purelib: true
Tag: py3-none-any
EOF
printf 'rocm-10.1.0.dist-info/METADATA,,\nrocm-10.1.0.dist-info/WHEEL,,\nrocm-10.1.0.dist-info/RECORD,,\n' \
  > rocm-10.1.0.dist-info/RECORD
zip -q rocm-10.1.0-py3-none-any.whl rocm-10.1.0.dist-info/*
pip install --no-deps rocm-10.1.0-py3-none-any.whl
pip check   # must report: No broken requirements found
```

**requirements.txt hygiene for ROCm projects:** delete the bare
`torch` / `torchvision` / `torchaudio` lines (keep `torchsde` — pure Python,
range deps only). pip then never manages the torch stack. See ComfyUI
`requirements.txt` for the reference edit.

---

## flash-attention from source (Triton backend — CK is impossible on gfx1030)

Repo: `~/Desktop/extras/flash-attention` (tracks upstream main).
Upstream README claims "RDNA GPUs" for the Triton backend, but gfx1030 is
blocked by aiter's arch allowlists. The CK C++ backend has no RDNA2 codegen
at all (MI200/MI300/MI355 + RDNA3/4 only) — do not try it.

```sh
cd ~/Desktop/extras/flash-attention
pip uninstall -y amd-aiter flash-attn          # clean slate
FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE \
  pip install --no-build-isolation .
```

**2026-09-23 (upstream #2900): `FLASH_ATTENTION_USE_SYSTEM_AITER=TRUE`** skips
the vendored `third_party/aiter` install entirely — it uses the already-installed
patched aiter and validates it provides the required symbols. This bypasses the
flydsl pin footgun below. Preferred recipe now:
`FLASH_ATTENTION_USE_SYSTEM_AITER=TRUE FLASH_ATTENTION_TRITON_AMD_ENABLE=TRUE pip install --no-build-isolation .`

**2026-09-20 (ai-toolkit venv) — NEW footgun: `flydsl==0.1.9.dev599`.**
Upstream flash-attn's setup.py now pip-installs vendored
`third_party/aiter`, whose pyproject pins `flydsl==0.1.9.dev599`. That exact
version is gone from PyPI AND from the AMD mirrors
(`rocm.frameworks-devreleases.amd.com/whl{,-staging}/gfx942-gfx950/` renamed the
same-era build to `0.1.9.dev20260529+d7ae22d`) → build dies at
metadata-generation-failed. Fix that worked: copy the installed tree from the
ComfyUI venv into the new venv before building —
`flydsl/`, `flydsl.libs/`, `flydsl-0.1.9.dev599.dist-info/`
(alt: patch the pin + the equality check in `third_party/aiter/setup.py:16`
and `pyproject.toml` to the d7ae22d version). Note aiter's CI installs flydsl
from `https://rocm.frameworks-devreleases.amd.com/whl-staging/gfx942-gfx950/`.

**Side effect of that aiter install:** it swaps dist `triton-rocm` for a
multi-backend `triton 3.8.0` (has BOTH `amd` and `nvidia` backends — verified
working end-to-end). torch's `triton-rocm==…` pin then trips `pip check`;
satisfy it with a shim dist-info wheel (same pattern as the rocm shim, version
must match torch's pin exactly). Don't force-reinstall triton-rocm over it —
that degrades the aiter-chosen build; re-verify flash-attn if you ever do.

**Local patches to the INSTALLED aiter** (site-packages; lost on reinstall —
re-apply after any flash-attn/aiter upgrade, the ComfyUI venv will hard-crash
with `KeyError: Unknown GPU architecture: gfx1030` without them):

1. `aiter/jit/utils/build_targets.py` — add to `GFX_MAP`:
   `19: "gfx1030",` and to `GFX_CU_NUM_MAP`: `"gfx1030": 64,`
2. `aiter/jit/core.py` — add `"gfx1030",` to the `allowed_archs` list in
   `validate_and_update_archs()`.

**First-run JIT build** needs HIP headers that the system ROCm 10 runtime
package does not ship (`/opt/rocm/core-10.0/include` has no `hip/`). They live
in the venv SDK:

```sh
export CPATH="$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")/_rocm_sdk_core/include"
```

`module_aiter_core` builds in ~17 s on first `import aiter` and is cached.

**Runtime env (mandatory, or import crashes):**

```sh
export GPU_ARCHS="gfx1030"                  # steers config lookup AND codegen target
export FLASH_ATTENTION_TRITON_AMD_ENABLE="TRUE"
```

All of this is baked into ComfyUI's `runme.sh`; copy from there.

---

## What you gain (RX 6800 XT, measured 2026-09-12)

| attention kernel (fwd, causal, fp16) | time | vs SDPA |
|---|---|---|
| SD1.5-ish b8 s4096 h8 d40  | flash-attn **23.0 ms** | 5.7x faster |
| SDXL-ish  b4 s4096 h20 d64 | flash-attn **30.2 ms** | 5.5x faster |
| Flux-ish  b1 s4096 h24 d128| flash-attn **22.0 ms** | 3.8x faster |

PyTorch's SDPA (AOTriton/CK path) is slow on RDNA2 — always route attention
through flash-attn here (ComfyUI: `--use-flash-attention`). Numerics verified
against SDPA: rel. diff 0.03%.

## Dangers / limits of this card (gfx1030, RDNA2)

- **RDNA2 is in nobody's support matrix.** flash-attn CK: no. aiter CK ops:
  no. MFMA matrix instructions: gfx950-only. WMMA: RDNA3+. Anything tuned for
  MI300 will refuse to run or silently need fallbacks. Expect per-project
  patching exactly like the aiter one above.
- **Torch = nightly only.** No stable `+rocm10.0` wheels; torchvision lags
  torch by ~2 days and hard-pins one exact dev build; torchaudio has no ROCm
  build at all (use CPU). Dates must line up across the stack.
- **The pip CUDA-backtrack** (footgun #3) can happen through any transitive
  dependency of any package you install later. The shim wheel + torch-less
  requirements.txt are the standing defenses; re-check with
  `pip install --dry-run` before big installs.
- **CuPy needs the HIP source build** — see `cupy-rocm.md`. A stray
  `cupy-cuda12x` dependency reintroduces `cudaErrorInsufficientDriver`
  crashes in anything using GPU arrays (ComfyUI-fastblend hit this).
- **aiter patches don't survive reinstalls**, and without `GPU_ARCHS=gfx1030`
  exported, `import aiter` crashes with KeyError — which takes down anything
  importing flash_attn (ComfyUI included). Keep both in the launcher script.
- **Sliding-window attention** is WIP in the Triton backend; models needing it
  must fall back to SDPA (drop `--use-flash-attention`).
- **System vs venv SDK split:** system ROCm 10 (`/opt/rocm` → alternatives →
  `core-10.0`) is runtime-only (no `hip/` headers); the venv's bundled
  `_rocm_sdk_core` is the complete one. Compile-time things need `CPATH` set
  to the venv include dir.
- **SDPA on this card is the slow path** (see table). Anything that silently
  "falls back to PyTorch attention" is a 4–6x regression, not a safety net.
- **Benign MIOpen warning** on first conv: `CK grouped conv library not found
  for device gfx1030: libMIOpenCKGroupedConv_gfx1030.so` — MIOpen falls back
  to its normal kernels; conv output verified correct. Ignore it.

## Global ROCm devel (any project)

2026-09-13: the devel headers/libs no longer live only inside the ComfyUI venv.

- `~/rocm-devel` — hardlink copy of the venv's `_rocm_sdk_devel` tree (2.8 GB
  logical, ~0 extra disk; survives venv deletion). All internal relative
  symlinks into `_rocm_sdk_core` were replaced with hardlinks (0 dangling).
  Repointed to 10.1.0 on 2026-10-04 (internal relative links break at $HOME —
  resolve each link against the venv source tree, then hardlink the resolved
  core/libraries target; llvm/amd-smi internal links left relative).
- `~/.zshrc` sources `~/rocm-devel/env.sh` → global `CPATH`/`LIBRARY_PATH`.
  `hipcc` comes from `/opt/rocm/bin` (already on PATH).
- Repoint after a future SDK update: extract the new `rocm_sdk_devel` wheel's
  `_devel.tar` into a temp dir, then re-do the hardlink copy + symlink fix.
- Build HIP packages with `hipcc`, never raw `g++` (rocPRIM/thrust headers use
  AMD device builtins that host g++ rejects — normal).
- Optional: `echo "$HOME/rocm-devel/lib" | sudo tee /etc/ld.so.conf.d/rocm-devel.conf`
  + `sudo ldconfig` for linker resolution without LIBRARY_PATH.

Everything needed to source-build cupy / flash-attn / aiter in any project:
hip, hipblas, hipcub, rocprim, thrust, miopen, rocblas, rccl headers + 48
unversioned `.so` links in `lib/`.

## Quick health check

```sh
python -c "import torch; print(torch.__version__, torch.version.hip, torch.cuda.is_available())"
python -c "import aiter; print('aiter ok')"          # needs GPU_ARCHS set
python -c "from flash_attn import flash_attn_func; print('fa ok')"
pip check                                            # must be clean
```
