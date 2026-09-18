# 2026-09-10 — Vision profile smoke bench (GSQ-RCO-IQ3_XXS-mtp + mmproj)

## Config under test
Coding profile adapted: `-c 16384 --parallel 2 --kv-unified` + `--mmproj` (paired 885 MB)
+ `--image-min-tokens 1024` + `--temp 0.2`. Inert leftovers still in args: `--cache-ram`,
`--slot-save-path` (engine disables both under mmproj).

## Ground-truth graded results (script: vision_bench.py)

### Test V1 — photo of laptop screen (OCR: image-20250701-203917.png)
prefill 1980 tok @ 205 t/s | gen 21.2 t/s | wall 11.5 s
| Question | Expected | Got | Verdict |
|---|---|---|---|
| Popup dialog title | Credit Card Details | Credit Card Details | ✅ verbatim |
| Address bar URL | app.topsteptrader.com/dashboard | app.topsteptrader.com/dashboard | ✅ verbatim |
| Brand top-left | TOPSTEP | TOPSTEP | ✅ |
| Taskbar weather text | Rainy days ahead | Rainy days ahead | ✅ verbatim |
| Laptop brand | hp | hp | ✅ |
**5/5**

### Test V2 — carnival scene (recognition + grounding: 433485762_*.jpg)
prefill 2820 tok @ 211 t/s | gen 22.8 t/s | wall 21.5 s
| Question | Expected | Got | Verdict |
|---|---|---|---|
| People count | 6 | 6 | ✅ |
| Flag country | Bolivia | Bolivia (+ correct tricolor reasoning) | ✅ |
| Costume colors L vs R | maroon-gold / teal-gold | red-maroon/gold left, teal/blue-green/gold right | ✅ |
| Watermark verbatim | stylized script "VinoRana PHOTOGRAPHY" | VinoRana PHOTOGRAPHY | ✅ |
**4/4**

## Findings
1. **--image-min-tokens honored**: image contributed ~1800–2650 tokens (prefill_n minus
   question length) — well above the 1024 floor; native dynamic resolution active.
2. **No VRAM spill with vision loaded**: gen 21.2–22.8 t/s ≈ text-only 32k baseline (22.2).
   The 16k-context budget math (≈14.0 GB) is confirmed by measurement.
3. **Vision encode cheap**: 205–211 t/s prefill including encoder — 2.8 MB JPEG fully
   encoded in seconds (AMD kernel path, ~0.3–0.4 GB runtime, as documented).
4. OCR through screen-photo artifacts (moiré/glare/angle) was flawless at temp 0.2.

## Verdict
Vision profile is production-ready. Keep pair: coding (32k, no mmproj, full cache stack)
/ vision (16k, mmproj, temp 0.2). 9/9 graded accuracy on first run.

## Re-run with --image-max-tokens 2048 (same day)
| Image | Prefill before | Prefill capped | Wall | Accuracy |
|---|---|---|---|---|
| screenshot photo | 1980 tok @ 205 t/s | 1980 @ 227 t/s (already under cap) | 10.6 s | 5/5 unchanged |
| carnival 2.8 MB | 2820 tok @ 211 t/s | **2048 @ 224 t/s (cap hit)** | 21.5 → 16.7 s | 4/4 unchanged |

Cap costs nothing on small/medium images, saves ~5 s on large ones, and bounds worst-case
KV (each image ≤2048 tok — multi-image chats stay inside the 16k slot). **Keep it.**
Side note: `--cache-ram 0` also force-disables `--cache-idle-slots` (log warning) — fine
for vision, never copy `--cache-ram 0` to the coding profile.
