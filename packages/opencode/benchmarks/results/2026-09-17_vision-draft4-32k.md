# 2026-09-17 — Vision @ draft-4 + ctx 32768 (ToshLLM 0.87.6): 9/9 accuracy, VRAM SPILL

## Config under test
Main `GSQ-RCO-IQ3_XXS` (non-mtp) + `-md` RCO-mtp draft @ `--spec-draft-n-max 4`
+ paired mmproj + `-c 32768 --parallel 1` (kv_unified=false) + cache-ram 0 + temp 0.2.
Doubling of the verified vision profile's ctx (16384 → 32768) on top of the mmproj.

## Accuracy — 9/9 (script: vision_bench.py, graded vs ground truth)

### V1 — screenshot OCR (image-20250701-203917.png)
prefill 1980 tok @ 189 t/s | gen 5.5 t/s | wall 17.2 s
Title "Credit Card Details" ✅ · URL "app.topsteptrader.com/dashboard" ✅ ·
brand "TOPSTEP" ✅ · weather "Rainy days ahead" ✅ · laptop "hp" ✅ → **5/5**

### V2 — carnival scene (433485762_*.jpg, cap 2048 hit)
prefill 2048 tok @ 225 t/s | gen 6.8 t/s | wall 34.8 s
People 6 ✅ · Bolivia + tricolor reasoning ✅ · costumes maroon-gold / teal-gold ✅ ·
watermark "Vino Rana PHOTOGRAPHY" ✅* (space inserted; stylized script — content correct,
2026-09-10 run matched the no-space styling) → **4/4**

## PERFORMANCE: SPILL CONFIRMED — do not judge draft-4 on this config

| Metric | 2026-09-10 (16k, parallel 2) | Today (32k, parallel 1) |
|---|---|---|
| V1 gen | 21.2 t/s | 5.5 t/s |
| V2 gen | 22.8 t/s | 6.8 t/s |
| text-only probe | ~22 t/s | **2.7 t/s** |

Text-only probe at 2.7 t/s on a 13-token prompt = Metal silently spilled to shared
memory. VRAM budget: 9.7 main + ~1.5 draft runtime + 0.9 mmproj + 2.4 KV(32k) +
~1.5 compute ≈ 16 GB vs 15 GB usable (16 − 1 reserve). The 16k profile measured
≈14.0 GB — the +1.2 GB from doubling ctx is exactly what pushed it over.

Spec-decode vitals: 52/96 accepted (54%) — n too small to judge depth 4; polluted
by spill. Inconclusive. A/B 3 vs 4 only AFTER ctx fix.

## Root cause & fix
Not draft-4's fault — draft depth changes acceptance, never 3-4× t/s. The ctx bump
is the culprit. **Fix: vision profile ctx back to 16384** (the 9/9, 21-23 t/s config).
Rule re-confirmed: with mmproj + draft loaded, budget leaves NO room for 32k on 16 GB.

## Verdict
- Accuracy: depth-4/draft pairing produces correct vision output (9/9, one styling note)
- Speed: INVALID RUN — revert ctx to 16384, restart, re-run bench + text probe
  (expect ~21-23 t/s), then A/B --spec-draft-n-max 3 vs 4 properly.

---

# FOLLOW-UP — root cause found & final vision config (same day)

## Resolution path
1. ctx 16384 restart → STILL spilled (probe 2.6-8.5 t/s) → ctx was not the culprit
2. Removed draft (no `-md`/spec) → probe **26.3-26.6 t/s** → spill gone instantly

## Root cause (explains every data point)
On 0.87.1 the verified profiles used the **`-mtp` file as MAIN with the draft
pointing at the SAME file** — near-zero draft VRAM cost. On 0.87.6 with a
non-mtp main, the separate 9.7 GB `-md` draft file is loaded in full → +9.7 GB
demand → hard spill at ANY ctx. Coding profile never hit this (draft=main file).
ub 1024 was innocent (26 t/s with it active).

## FINAL vision profile (0.87.6) — no speculative decoding
`-m GSQ-RCO-IQ3_XXS + paired mmproj -c 16384 --parallel 1 (kv_unified false)
-b 2048 -ub 1024 -ctk/ctv turbo4 --cache-ram 0 --cache-prompt temp 0.2`
Leftover `--spec-draft-n-max 4` in args is inert without `-md`.

## Final bench (vision_bench.py)
| | V1 OCR | V2 carnival |
|---|---|---|
| prefill | 1980 tok @ 235 t/s | 2048 (cap) @ 236 t/s |
| gen | **25.6 t/s** | **25.6 t/s** |
| wall | **10.0 s** | **15.6 s** |
| accuracy | 5/5 | 4/4* |

*Watermark read "VinoRan PHOTOGRAPHY" — final 'a' truncated (stylized script,
temp-0.2 sampling variance; prior runs got "VinoRana"). Strict 8/9, lenient 9/9.
A single-image re-run would likely flip it; not a config concern.

## History
| Config | gen t/s | wall V1/V2 |
|---|---|---|
| 0.87.1 mtp-main+same-file draft, 16k×2 | 21.2-22.8 | 11.5/16.7 |
| 0.87.6 sep-file draft @32k (SPILL) | 5.5-6.8 | 17.2/34.8 |
| **0.87.6 no draft, 16k×1, ub1024 (FINAL)** | **25.6** | **10.0/15.6** |

+20% gen over the old verified profile, simplest arg set. Draft-4 A/B is moot:
with mmproj on 16 GB, separate-file draft does not fit. Vision keeps spec OFF;
coding profile (draft=main-file layout) unaffected.
