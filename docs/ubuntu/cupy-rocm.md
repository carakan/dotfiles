# CuPy on ROCm 10 — source build for AMD GPUs (FastBlend etc.)

Source of truth for making **CuPy** work on this machine (RX 6800 XT / gfx1030,
ROCm 10.0 nightly torch venv). Done 2026-09-13; every step verified.
Applies to any project whose deps pull in CuPy (ComfyUI-fastblend / PatchMatch
video interpolation is the case that exposed it here).

## Symptom

```
cupy_backends.cuda.api.runtime.CUDARuntimeError:
cudaErrorInsufficientDriver: CUDA driver version is insufficient for
CUDA runtime version
```
from `cp.cuda.Device(...)` inside FastBlend's PatchMatch. CuPy was the
**NVIDIA build** (`cupy-cuda12x`), which speaks the CUDA runtime — there is no
NVIDIA driver on this box, so every call dies.

## Diagnosis

```sh
pip list | grep -i cupy          # cupy-cuda12x  <- the problem
pip index versions cupy-rocm     # No matching distribution (no ROCm wheel for ROCm 10)
grep -l RawKernel <pkg>/         # does the project JIT-compile CUDA C?
```
FastBlend uses `cp.RawKernel` with plain CUDA C (`__global__`, `blockDim`)
— CuPy's HIP mode compiles those via hiprtc, so a source build works.

## The build (all steps, in order — each one was a real blocker)

### 1. Remove the NVIDIA cupy

```sh
pip uninstall -y cupy-cuda12x
```

### 2. Install the devel SDK wheel (system ROCm 10 has NO library headers)

The `amdrocm-*10.0` apt packages ship runtime libs only — no `hipblas.h`,
no `thrust/`, no `hipcub/`. The pip `rocm-sdk-devel` wheel has everything
(2.8 GB unpacked):

```sh
pip install --no-deps \
  "https://stable.repo.amd.com/rocm/core/whl-next/rocm-sdk-devel/rocm_sdk_devel-10.1.0-py3-none-linux_x86_64.whl"
SP="$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")"
tar -xf "$SP/rocm_sdk_devel/_devel.tar" -C "$SP"    # -> $SP/_rocm_sdk_devel/{include,lib,bin,share}
```
(`download.pytorch.org/.../rocm-sdk-devel/` 404s on listing; the direct
stable.repo.amd.com URL works. Include dirs per-lib: `include/hipblas/hipblas.h` etc.)

### 3. ROCM_HOME overlay prefix (no sudo needed)

CuPy hard-requires `$ROCM_HOME/include/hipcub` to *exist as a path* and probes
`$ROCM_HOME/bin/hipcc`. We cannot write under `/opt`, so fake the prefix with
symlinks. Since 2026-09-13 the include dir points at the **global**
`~/rocm-devel/include` (hardlink copy of the devel tree, venv-independent —
see `pytorch-rocm.md`), so a cupy rebuild no longer depends on the ComfyUI venv:

```sh
SP="$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")"
mkdir -p ~/rocm-cupy
ln -sfn "$HOME/rocm-devel/include" ~/rocm-cupy/include
ln -sfn /opt/rocm/bin ~/rocm-cupy/bin
ln -sfn /opt/rocm/lib ~/rocm-cupy/lib
```

### 4. Unversioned `.so` symlinks in the core lib dir

The hipcc driver probe links `libamdhip64.so` (unversioned) and resolves it
into `_rocm_sdk_core/lib`, which only ships `*.so.7` versioned files →

```sh
SP="$(python3 -c "import sysconfig; print(sysconfig.get_paths()['purelib'])")"
cd "$SP/_rocm_sdk_core/lib"
for f in *.so.*; do base="${f%%.*}"; [ -e "$base.so" ] || ln -s "$f" "$base.so"; done
```

### 5. Build

Full script (kept here verbatim — the `/tmp` copy is transient):

```sh
#!/bin/bash
source <venv>/bin/activate
SP=<venv>/lib/python3.13/site-packages
export CUPY_INSTALL_USE_HIP=1
export ROCM_HOME="$HOME/rocm-cupy"
export HIP_PATH="$(hipconfig -p)"
export CPATH="$SP/_rocm_sdk_devel/include:$SP/_rocm_sdk_core/include:$CPATH"
export LIBRARY_PATH="$SP/_rocm_sdk_devel/lib:$SP/_rocm_sdk_libraries/lib:$SP/_rocm_sdk_core/lib:$LIBRARY_PATH"
export CUPY_CACHE_DIR=/tmp/cupy_cache
pip install --no-binary cupy --no-cache-dir cupy -v
```

Build time ~15 min (many Cython modules + a failing hipcc probe mid-log that
is retried/survivable — judge by the final line). Result: `cupy-14.2.0`
built with HIP/hiprtc for gfx1030.

### 6. Runtime JIT fix (thrust headers)

CuPy's JIT compile (first touch of *any* cupy op, and every `RawKernel`)
runs through hiprtc/comgr, whose include paths come from a
`hipcc -x hip -E -v /dev/null` probe. clang honors `CPATH` during that probe,
so the runtime env must export CPATH with the devel include — ComfyUI's
`runme.sh` does this (see the CuPy + CPATH block there). Without it:

```
fatal error: 'thrust/detail/config/namespace.h' file not found
```

Also set `CUPY_CACHE_DIR` to a persistent dir so JIT kernels compile once.

## Verify

```sh
export CPATH="<venv>/lib/python3.13/site-packages/_rocm_sdk_devel/include"
python - <<'EOF'
import cupy as cp
a = cp.arange(10, dtype=cp.float32) * 2
assert a.sum().item() == 90.0
assert (a + 1)[-1].item() == 19.0
assert (cp.random.rand(64, 64) @ cp.random.rand(64, 64)).shape == (64, 64)
print("cupy HIP OK", cp.__version__)
EOF
# FastBlend kernels (RawKernel -> hiprtc):
PYTHONPATH=<comfyui>/custom_nodes/ComfyUI-fastblend python -c \
  "import FastBlend.cupy_kernels as k; print('kernels OK')"
```
Both verified passing on 2026-09-13.

## Dangers / notes

- **`cupy-cuda12x` can come back** if any later `pip install` pulls cupy as a
  dependency and the HIP build isn't installed. Check `pip list | grep cupy`
  after big installs — it must stay `cupy 14.2.0` (no `+cuda` tag).
- `rocm-sdk-devel` also ships its own `hipcub/rocprim/thrust`; the copy step
  in some older notes is unnecessary once devel is installed.
- The devel wheel is ~2.8 GB unpacked inside the venv — don't "clean" it when
  freeing disk space; cupy JIT and rebuilds need it.
- `/tmp/pip-build-env-*` and `/tmp/pip-install-*` dirs from failed builds are
  safe to delete.
- ROCM_HOME is faked per-build/runtime via `~/rocm-cupy`; torch and aiter are
  unaffected (they use their bundled SDK and don't read ROCM_HOME).
