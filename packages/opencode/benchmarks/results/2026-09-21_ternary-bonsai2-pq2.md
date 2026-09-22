# 2026-09-21 — Ternary-Bonsai-2-27B-PQ2_0 vs Qwen scoreboard (ToshLLM 0.87.7)

## Config under test
`-m Ternary-Bonsai-2-27B-PQ2_0.gguf -c 65536 --parallel 2 -ub 1024` + qwen38.jinja,
no mmproj, no draft (inert leftover flags), temp 0.6 server default (bench pins 0.1).
Engine 0.87.7 — first release that loads ternary type-142 quants (0.87.6 could not).

## Headline

| Metric | Bonsai2 PQ2_0 | UD-IQ3_XXS | GSQ-RCO-IQ3_XXS |
|---|---|---|---|
| Reliability (bench.py) | **13/15 (87%)** | 12/15 | 12/15 |
| Tier 2 sweep | **4/4** (first ever) | 3/4 | 3/4 |
| Tools (tools_bench.py) | **6/7** (TT3 = proper defer) | 6/7 | 5/7 (TT2 flaky) |
| Single-stream gen | **41.5 t/s** | ~25 t/s | 25.3 t/s |
| Sustained dual-agent aggregate | **38.5 tok/s (93% scaling)** | ~19-20 | ~19-20 |
| Warm cache hits (A/B) | 133/137 ✓ | 133/137 ✓ | 133/137 ✓ |
| Prefill | ~235-295 t/s | 305 t/s | 305 t/s |

Both fails are the suite's expected fails: T1.6 (raw API can't execute commands —
agent-side tools cover it), T3.1 (overreach probe; burned 2500 tok / 63 s but that
test is informational, Qwen fails it too).

## Stress (dual_agent_bench.py, parallel-2 profile)
Baseline 41.5 → sustained per-stream 28.8/26.8, aggregate **38.5 tok/s**.
Scaling efficiency 93% vs Qwen's ~78% — the 6.7 GB ternary weights leave VRAM
headroom that KV sharing exploits cleanly. No spec decode (draft tokens 0).

## Reliability detail (bench.py auto)
T1.1-T1.5, T1.7, T1.8 PASS (T1.6 expected fail) · T2.1 clarification ✓ ·
T2.2 multi-step 3/3 ✓ (known Qwen flipper) · T2.3 98-line gen 5/5 helpers ✓ ·
T2.4 cross-file plan ✓ · T3.2 asks for file, no hallucination ✓ · T3.3 honest
964-word phased plan, no overreach ✓.

## Honest caveats
1. Suite scope: mechanical JS edits + tool discipline + scope control. Does NOT
   measure long-context recall at 50k+ fill, deep multi-hop reasoning, or
   knowledge breadth — ternary Q2-class models can lag there unmeasured.
2. Single run; borderline tests flip ±1 between runs (suite caveat).
3. Bench avg 47.9 tok/s vs probe 41 t/s — short generations inflate avg; use
   probe/sustained numbers for planning.

## Verdict
Measured axes all favor Bonsai2: more reliable, cleaner tool calls, 65% faster,
far better concurrency scaling on this card. Production verdict needs days of
real opencode work (the suite is a proxy). Keep Qwen RCO profile saved as A/B
fallback; promote Bonsai2 to default and watch for: long-context degradation,
looping at temp 0.6, tool-call JSON fidelity under real agent loads.

---

# FOLLOW-UP — deep tests REVERSE the verdict (same day)

## Long-context recall: BROKEN (not lost-in-the-middle — worse)
Needle-in-haystack, 5 needles at 2/25/50/75/98% depth, exact-value grading:

| Fill (prompt_n) | Needles found |
|---|---|
| 55,134 tok | 1/5 (only the 2%-depth needle) |
| 28,064 tok | 1/5 |
| 14,097 tok | 1/5 |
| 6,097 tok | 1/5 |
| 2,095 tok | **1/5** |

- Prefill stays fast at every depth (233-325 t/s, no spill — the limit is NOT VRAM)
- Single-question probes per needle: same failures; for the passphrase question it
  answers "XQ-4417" (needle-1 bleed-through); for mid-context facts it claims
  "the log contains no information about X"
- Format-matched needle (identical log-line style, mid-context): still denied
- Conclusion: effective attention window ≈ first ~1-2k tokens of ANY prompt.
  Context length, fill format, question format, and temperature are ruled out.

## Multi-hop reasoning: WEAK/FRAGILE
- 2-hop kinship: WRONG ("niece"; correct is cousin)
- Arithmetic word problem: correct method + 76 when allowed to elaborate
  (truncated run), but WRONG ($60/$120) when asked concise — fragile
- 5-box constraint puzzle: no conclusion in 1200 tok, ends confused mid-case-analysis

## Knowledge breadth: EXCELLENT — 10/10
García Márquez, W, Canberra, 1989, 418 teapot, Titan, c, git 2005, Java,
Alonzo Church — including fine-grained recalls.

## Can llama.cpp args fix this? NO.
Recall failure is in the weights (ternary PQ2 attention), not runtime: fa is on,
KV is turbo4, prefill is clean at 233-325 t/s at every depth. No ctx/ub/b/draft
flag changes attention. The only "fix" is capping context at ~2-4k, which makes
a 64k ctx pointless.

# FOLLOW-UP 2 — TEST BUG FOUND, recall verdicts RETRACTED (same day)

The needle test had an insertion bug: needles were keyed by WORD index but the
filler loop counts LINES (~10 words/line). Only the first needle (index 440 <
line count) was ever actually inserted at every fill size. The other four
needles were never in the context — "Not found" was the CORRECT answer.

Consequence: Bonsai2's 1/5 scores and the "~2k effective attention window"
conclusion are INVALID. It correctly found the only needle that existed and
correctly reported the absent ones. Its recall is UNPROVEN, not broken.

## Corrected test (line-index insertion), GSQ-RCO Qwen:
| Fill | prompt_n | prefill | Needles found |
|---|---|---|---|
| 2200 lines | 105,971 tok | 143 t/s (no spill at 106k!) | **5/5** |
| 560 lines | 26,921 tok | 246 t/s | **5/5** |
| 80 lines | 3,828 tok | 292 t/s | **5/5** |

Qwen recall is fully healthy to 106k. Also validates the 131k×2 slot config
(kv-unified lazy allocation; probe 27.5 t/s — no spill).

## What still stands (bug-free short-prompt tests)
- Reasoning: Qwen 2/3 (cousin ✓; apples PERFECT — caught the equal-$76 trap;
  boxes wrong: said Blue, correct is Red) vs Bonsai 0/3 (niece ✗, apples ✗
  concise, boxes no conclusion). Qwen clearly stronger multi-hop.
- Knowledge: both 10/10.
- Speed: Bonsai 41.5 t/s vs Qwen ~27 t/s.
- Mechanical bench: Bonsai 13/15 vs Qwen 12/15.

## Corrected overall
Bonsai2: recall unproven (retest when swapped back), reasoning weak, fast.
Qwen: recall proven 5/5 to 106k, reasoning strong, slower. Daily-driver call
between them is now about reasoning depth vs speed on short-context work —
NOT about a recall defect. Bonsai2 disqualification RETRACTED.

---

# FOLLOW-UP 3 — Bonsai2 retested with the fixed test (same day)

Same corrected battery, Bonsai2 @ 131k×2 kv-unified (same config as Qwen's run):

| Fill | prompt_n | prefill | gen | Recall |
|---|---|---|---|---|
| 2200 lines | 105,971 tok | 162 t/s | 20.3 t/s | **5/5** |
| 560 lines | 26,921 tok | 281 t/s | 32.5 t/s | **5/5** |
| 80 lines | 3,828 tok | 350 t/s | 37.7 t/s | **5/5** |

Bonsai2 recall is FULLY HEALTHY — identical 5/5 at every depth, including 106k.
Probe 41.1 t/s. Knowledge 10/10 again. Reasoning unchanged: Q1 niece ✗,
Q2 wrong again with a DIFFERENT wrong answer ($96/$144/$48 — unstable
arithmetic; Qwen catches the equal-$76 trap), Q3 Blue ✗ (same wrong answer
as Qwen; correct is red).

## FINAL head-to-head (all numbers corrected, same day, same configs)
| Axis | GSQ-RCO Qwen | Bonsai2 PQ2_0 |
|---|---|---|
| Needle recall 106k/27k/3.8k | 5/5 · 5/5 · 5/5 | 5/5 · 5/5 · 5/5 |
| Multi-hop reasoning | **2/3** | 0/3 (unstable on Q2) |
| Knowledge | 10/10 | 10/10 |
| Mechanical bench | 12/15 | **13/15** |
| Tools | 6/7 (TT3 proper defer) | 6/7 (TT3 proper defer) |
| Gen t/s | ~27 | **41** |
| Prefill @106k | 143 t/s | **162 t/s** |

VERDICT: both models healthy; recall is a wash. Qwen = reasoning-critical work;
Bonsai2 = speed-critical + mechanical work. Either is a valid daily driver —
pick per workload, or keep both as profiles.
