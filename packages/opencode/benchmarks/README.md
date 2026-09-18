# Local LLM Benchmarks — opencode daily-drive models

Reproducible benchmarks for models served by ToshLLM (llama.cpp) at `127.0.0.1:8080`.
Store every future run as `results/YYYY-MM-DD_<model-shortname>.md` so runs stay comparable.

## Scripts

| Script | What it measures | Usage |
|---|---|---|
| `bench.py` | 15-task reliability battery: Tier 1 mechanical edits (8), Tier 2 edge cases (4), Tier 3 out-of-scope behavior (3) | `python3 bench.py <key>` — keys: `qwen`, `ds`, `rco`, `ud3x`, or `auto` (uses whatever model is loaded) |
| `tools_bench.py` | 7 tool-calling tests: exact paths, tool selection among distractors, path composition, similar-path mutation, no-tool restraint, no fabrication on missing files | edit `MODEL` var or use the loaded-model pattern; tests whatever you point it at |

Both read the API key from `LLAMACPP_API_KEY` env var, falling back to the key in `opencode.json`.

## Before running `bench.py` — reset fixtures

`T1.1` writes renamed files back into the sandbox. Reset first or T1.1/T1.4/T1.8 run against mutated fixtures:

```bash
B=/var/folders/4k/p68p4w1n6sbbx0xglr90jdq00000gn/T/opencode/qwen-bench
mkdir -p $B/src $B/test
cat > $B/src/pricing.js <<'JS'
export function calculateTotal(items) {
  var total = 0;
  for (var i = 0; i < items.length; i++) {
    total = total + items[i].price * items[i].qty;
  }
  return total;
}

export function applyDiscount(total, discount) {
  return total - total * discount;
}

export function foo(amount) {
  return amount * 1.15;
}
JS
cat > $B/src/index.js <<'JS'
import { calculateTotal, applyDiscount, foo } from './pricing.js';

const cart = [
  { price: 10, qty: 2 },
  { price: 5, qty: 4 },
];

console.log('subtotal:', calculateTotal(cart));
console.log('discounted:', applyDiscount(calculateTotal(cart), 0.1));
console.log('foo(100):', foo(100));
JS
cat > $B/src/messy.js <<'JS'
const items = [1, 2, 3];
for (let i = 0; i < items.length; i++) {
  console.log(items[i]);
}
JS
cat > $B/src/api.js <<'JS'
const DELAY_MS = 100;

async function wait(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function fetchUser(id) {
  const response = await fetch(`/api/users/${id}`);
  return response.json();
}
JS
cat > $B/test/pricing.test.js <<'JS'
import { test } from 'node:test';
import assert from 'node:assert';
import { calculateTotal, applyDiscount, foo } from '../src/pricing.js';

test('calculateTotal sums price*qty', () => {
  const items = [{ price: 10, qty: 2 }, { price: 5, qty: 4 }];
  assert.strictEqual(calculateTotal(items), 40);
});

test('applyDiscount subtracts percentage', () => {
  assert.strictEqual(applyDiscount(100, 0.1), 90);
});

test('foo multiplies by 1.15', () => {
  assert.strictEqual(foo(100), 115);
});
JS
```

Note: `/var/folders/.../T/opencode/` is macOS temp — it **gets purged**; recreate fixtures as above when missing. The 30s VRAM probe and known caveats are at the bottom.

## Known caveats (bake into every comparison)

- **T1.6 always fails via raw API** (model can't execute commands without the agent's tools) — real qwen-local/coder-local agents have bash and do better. Expected fail.
- **T3.1 always fails** (models overreach on architecture asks) — informational, measures overreach magnitude.
- **T1.4/T2.2 checkers were improved** mid-history: pre-2026-09-10 runs (Qwen3.6-14B, first DeepSeek run) used the strict old T1.4 check and the disk-path T2.2 prompt — not perfectly comparable on those two tests.
- **TT2 (tools) is flaky at temp 0.6** — models that know the answer sometimes skip the search tool. 1/3 calls ≠ tool-use deficiency. Judge tool use on TT1/TT4/TT5/TT7 (deterministic).
- **TT3 "fail" is usually correct behavior** — deferring a composed-path read until `list_dir` returns is proper agent protocol.
- Bench `query()` pins `temperature: 0.1` regardless of server default — production opencode agents also pin 0.1 (see `opencode.json` agent blocks), ToshLLM chat UI runs server default (currently 0.6).
- Sampling variance is real: expect ±1 test flip on borderline tests (T1.8) between runs.

## 30-second health probes

```bash
# VRAM overflow detector: expect the model's known-good gen t/s (see history table);
# a big drop = Metal silently spilled to shared memory (raise --n-cpu-moe or cut ctx)
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H "Authorization: Bearer $LLAMACPP_API_KEY" -H "Content-Type: application/json" \
  -d '{"model":"<MODEL_PATH>","messages":[{"role":"user","content":"hi"}],"max_tokens":100}' \
  | python3 -c "import json,sys; print('gen:', round(json.load(sys.stdin)['timings']['predicted_per_second'],1), 't/s')"

# spec-decode + cache vitals
curl -s http://127.0.0.1:8080/metrics -H "Authorization: Bearer $LLAMACPP_API_KEY" \
  | grep -E "^llamacpp:(spec_decode_num_(draft|accepted)_tokens_total|predicted_tokens_seconds|prompt_tokens_cached_total)"
```

## Key llama.cpp args — current baseline (ToshLLM 0.87.0, RX 6800 XT 16GB)

```
-ngl 99 -c 32768|65536 -fa 1
-ctk turbo4 -ctv turbo4          # MLA/GQA models: turbo4 both; q8_0 K + turbo4 V = f16-equal quality, use if ctx allows
--load-mode none                 # mlock unnecessary for all-VRAM dense
--jinja                          # embedded chat template (custom qwen38.jinja also OK for tools)
--cache-prompt --cache-reuse 256 --cache-ram 4096 --parallel 1
-b 2048 -ub 512                  # ub 1024 overflows VRAM on 27B
--spec-type draft-mtp --spec-draft-n-max 3
--temp 0.6 --top-p 0.95 --top-k 20 --min-p 0.05    # Qwen official; fixes endless looping
--repeat-penalty 1.0 --repeat-last-n 0             # OFF — token penalties corrupt code/paths
--samplers "min_p;top_p;temperature"               # NO dry, NO penalties in chain
--reasoning off
--chat-template-file ~/.config/llama-cpp/qwen38.jinja
env: GGML_METAL_VRAM_RESERVE_MB=1024 TOSH_FA_AMD=1
```

**Hard-won rules:**
- **NO DRY sampler with agent tool calls** — DRY punishes legitimately-repeated absolute paths/tool-call JSON → mutated paths, corrupt calls. Verified harmful in production despite clean short-prompt A/B.
- **VRAM overflow is silent** — no crash, just 2-3× slowdown. Probe after every config change.
- **Looping fix is the sampler** (temp 0.6 + top-k 20), not output penalties.
- Dense Qwen3.8-27B KV ≈ 75 KB/token (turbo4/turbo4, 65 layers) — 64k ctx = 4.9 GB, 32k = 2.4 GB. Weights + KV + ~1.5 GB compute must stay under 15 GB (16 − 1 reserve).
- `--n-cpu-moe` only matters for MoE models; dense needs ctx/quant levers instead.

## Scoreboard (full bench, same 15 tests)

| Date | Model | ctx | temp | Score | Notes |
|---|---|---|---|---|---|
| 2026-08-28 | Qwen3.6-14B-A3B Q5_K_M | 32k | 0.1 | 11/15 (73%) | old checkers; hallucinated T3.2 |
| 2026-08-28 | DeepSeek-Coder-V2-Lite Q5_K_M | 65k | 0.1 | 12/15 (80%) | ncmoe 10; T3.2 asks for file ✅ |
| 2026-09-10 | Qwen3.8-27B UD-IQ3_XXS | 64k | 0.1* | 12/15 (80%) | tools 6/7; 82.9% MTP |
| 2026-09-10 | Qwen3.8-27B GSQ-RCO-IQ3_XXS-mtp | 64k | 0.1* | 12/15 (80%) | tools 5/7 (TT2 flaky); 82.2% MTP |

\* bench pins temp 0.1; server default 0.6.

Stable expected fails everywhere: T1.6 (no tools raw), T3.1 (overreach). Borderline: T1.8, T2.2.
