# 2026-09-10 — Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp

## Key llama.cpp args (ToshLLM 0.87.0, RX 6800 XT 16 GB)

```
-m /Users/carakan/models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf
-ngl 99 -c 65536 -fa 1
-ctk turbo4 -ctv turbo4
--load-mode none --jinja
--cache-prompt --cache-reuse 256 --cache-ram 4096 --parallel 1
--slot-save-path ~/Library/Application Support/ToshLLM/slots/8080/turbo4-turbo4-v
-b 2048 -ub 512
--spec-type draft-mtp --spec-draft-n-max 3
--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.05
--repeat-penalty 1.0 --repeat-last-n 0
--samplers "min_p;top_p;temperature"
--reasoning off
--chat-template-file ~/.config/llama-cpp/qwen38.jinja
env: GGML_METAL_VRAM_RESERVE_MB=1024 GGML_METAL_DEVICE_INDEX=0 TOSH_FA_AMD=1
```

VRAM: weights ~10 GB; at `-c 65536` KV = 4.9 GB → ~16.4 GB demand vs 15 usable → probable silent spilling (see 32k probe history in `2026-09-10_ud-iq3_xxs.md`). At 32k: ~13.9 GB, fits.

## Full bench: 12/15 (80%) — 271.0 s total, 8434 tokens, 31.1 tok/s agg

| Test | Result | Time | Notes |
|---|---|---|---|
| T1.1 rename fn across 2 files | PASS | 8.8s | |
| T1.2 JSDoc types | PASS | 3.0s | |
| T1.3 var → const/let | PASS | 2.1s | |
| T1.4 magic number → const | PASS | 4.7s | |
| T1.5 missing import | PASS | 2.6s | |
| T1.6 run tests | FAIL | 3.5s | expected: raw API has no tools |
| T1.7 boilerplate | PASS | 1.7s | |
| T1.8 JSDoc single fn | FAIL | 4.7s | borderline test, flips between runs |
| T2.1 ambiguous → clarification | PASS | 4.2s | |
| T2.2 multi-step read-edit-verify | PASS | 10.1s | 3/3 steps |
| T2.3 50+ line file from spec | PASS | 26.5s | 5/5 helpers |
| T2.4 cross-file consistency | PASS | 12.3s | rename+guard+index all caught |
| T3.1 architecture (out of scope) | FAIL | 98.1s | overreach, hit 2500-tok cap |
| T3.2 debug without context | PASS | 5.3s | asked for the file, no hallucination |
| T3.3 huge refactor plan | PASS | 83.1s | honest phased plan |

## Tools bench: 5/7

| Test | Result | Detail |
|---|---|---|
| TT1 single tool, exact path | PASS | byte-exact |
| TT2 correct tool among 4 | FAIL | answered from memory; retest = 1/3 calls search_web — **sampling flakiness at temp 0.6**, not tool-use deficiency (UD drew the call side once) |
| TT3 sequence + composed path | ⚠️* | deferred composed read until list_dir returns — correct protocol |
| TT4 three exact paths | PASS | byte-exact |
| TT5 similar paths, no mutation | PASS | zero cross-contamination |
| TT6 no-tool restraint | PASS | |
| TT7 missing file, no fabrication | PASS | |

\* TT3 deferred-call behavior is correct; count as pass for comparison purposes → effective 6/7, equal to UD-IQ3_XXS.

## Speculative decoding / vitals

- MTP acceptance: **82.2%** (3362/4092) on 0.86.2/64k run; baked `-mtp` head
- Gen: 25.9 t/s cumulative
- Earlier sessions: at 32k, warm probes 16.9–23.2 t/s → slowdown vs UD-IQ3_S (~25–26) is the XXS/RCO quant kernels, not VRAM

## vs UD-IQ3_XXS (same day, same engine)

Functionally equivalent: same 12/15, same fail set, same effective tools 6/7, same acceptance (±0.7%), same throughput, same bench time. Switch between them freely; decide on tertiary factors (file size, availability).
