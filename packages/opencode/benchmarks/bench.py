#!/usr/bin/env python3
"""qwen-local / coder-local reliability benchmark.

Usage: python3 bench.py [qwen|ds|rco]
Sends a battery of tasks to the local llama.cpp server and verifies outputs.
"""
import json
import os
import sys
import time
import urllib.request
import subprocess
from pathlib import Path
from dataclasses import dataclass

BENCH_DIR = Path("/var/folders/4k/p68p4w1n6sbbx0xglr90jdq00000gn/T/opencode/qwen-bench")
API_URL = "http://127.0.0.1:8080/v1/chat/completions"
API_KEY = os.environ.get("LLAMACPP_API_KEY", "lwg2ES6mX5q2scPQRXhmAusKyT5IWom8")

MODELS = {
    "qwen": ("/Users/carakan/models/Qwen3.6-14B-A3B-FableVibes-Q5_K_M.gguf", "/tmp/qwen-bench-results.json"),
    "ds": ("/Users/carakan/models/DeepSeek-Coder-V2-Lite-Instruct-Q5_K_M.gguf", "/tmp/ds-bench-results.json"),
    "rco": ("/Users/carakan/models/Qwen3.8-27B-GSQ-RCO-IQ3_XXS-mtp.gguf", "/tmp/rco-bench-results.json"),
    "ud3x": ("/Users/carakan/models/Qwen3.8-27B-UD-IQ3_XXS.gguf", "/tmp/ud3x-bench-results.json"),
}
if (sys.argv[1] if len(sys.argv) > 1 else "") == "auto":
    import urllib.request as _u
    _req = _u.Request("http://127.0.0.1:8080/v1/models", headers={"Authorization": f"Bearer {API_KEY}"})
    with _u.urlopen(_req, timeout=10) as _r:
        MODEL = json.loads(_r.read())["data"][0]["id"]
    RESULTS_PATH = "/tmp/auto-bench-results.json"
else:
    MODEL, RESULTS_PATH = MODELS[sys.argv[1] if len(sys.argv) > 1 else "qwen"]


@dataclass
class TestResult:
    id: str
    tier: str
    description: str
    passed: bool
    partial: bool = False
    declined: bool = False
    latency_s: float = 0.0
    prompt_tokens: int = 0
    completion_tokens: int = 0
    notes: str = ""
    got: str = ""
    full_response: str = ""


def query(prompt: str, system: str = "", max_tokens: int = 1500, temperature: float = 0.1) -> dict:
    messages = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    payload = {
        "model": MODEL,
        "messages": messages,
        "max_tokens": max_tokens,
        "temperature": temperature,
    }
    data = json.dumps(payload).encode()
    req = urllib.request.Request(API_URL, data=data, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {API_KEY}",
    })

    t0 = time.time()
    with urllib.request.urlopen(req, timeout=300) as resp:
        body = json.loads(resp.read())
    latency = time.time() - t0

    return {
        "content": body["choices"][0]["message"]["content"],
        "latency": latency,
        "prompt_tokens": body.get("usage", {}).get("prompt_tokens", 0),
        "completion_tokens": body.get("usage", {}).get("completion_tokens", 0),
        "finish_reason": body["choices"][0].get("finish_reason", ""),
    }


def read_file(rel_path: str) -> str:
    return (BENCH_DIR / rel_path).read_text()


def write_file(rel_path: str, content: str):
    (BENCH_DIR / rel_path).write_text(content)


def strip_fence(resp: str) -> str:
    resp = resp.strip()
    if resp.startswith("```"):
        resp = resp.split("```")[1]
        if resp.startswith(("js", "javascript", "py", "python")):
            resp = resp.split("\n", 1)[1] if "\n" in resp else resp
        if resp.endswith("```"):
            resp = resp[:-3]
    return resp.strip()


# ---------- Tier 1: in-scope mechanical tasks ----------

def T1_1_rename_function():
    pricing = read_file("src/pricing.js")
    index = read_file("src/index.js")
    prompt = f"""Rename the function `foo` to `applyTax` in src/pricing.js and update the reference in src/index.js.

File 1: src/pricing.js
```js
{pricing}
```

File 2: src/index.js
```js
{index}
```

Return the two updated files in this exact format:

=== src/pricing.js ===
<full file contents>

=== src/index.js ===
<full file contents>
"""
    r = query(prompt, max_tokens=2000)
    resp = r["content"]

    new_pricing = None
    new_index = None
    if "=== src/pricing.js ===" in resp:
        parts = resp.split("=== src/pricing.js ===")[1]
        if "=== src/index.js ===" in parts:
            new_pricing = parts.split("=== src/index.js ===")[0].strip()
            new_index = parts.split("=== src/index.js ===")[1].strip()

    if not new_pricing or not new_index:
        return TestResult("T1.1", "Tier 1", "Rename function across 2 files", False,
                          notes="Did not return expected format",
                          got=resp[:500], full_response=resp)

    write_file("src/pricing.js", new_pricing)
    write_file("src/index.js", new_index)

    pricing_ok = "applyTax" in new_pricing and "foo" not in new_pricing.replace("foo.js", "")
    index_ok = "applyTax" in new_index and "foo(" not in new_index

    return TestResult("T1.1", "Tier 1", "Rename function across 2 files",
                      passed=pricing_ok and index_ok,
                      notes=f"pricing_ok={pricing_ok}, index_ok={index_ok}",
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"],
                      full_response=resp)


def T1_2_add_types():
    messy = read_file("src/messy.js")
    prompt = f"""Add JSDoc type annotations to all variables and function parameters in this JavaScript file.

```js
{messy}
```

Return only the updated file contents, no markdown fence, no commentary.
"""
    r = query(prompt, max_tokens=1500)
    resp = strip_fence(r["content"])

    has_jsdoc = "@type" in resp or "@param" in resp
    has_types = "number" in resp.lower() or "string" in resp.lower()

    return TestResult("T1.2", "Tier 1", "Add JSDoc types",
                      passed=has_jsdoc and has_types,
                      notes=f"jsdoc={has_jsdoc}, types={has_types}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_3_var_to_const():
    messy = read_file("src/messy.js")
    prompt = f"""Convert all `var` declarations to `const` (or `let` if reassigned) in this file:

```js
{messy}
```

Return only the updated file contents.
"""
    r = query(prompt, max_tokens=1500)
    resp = strip_fence(r["content"])

    no_var = "var " not in resp
    has_const = "const " in resp or "let " in resp

    return TestResult("T1.3", "Tier 1", "Convert var to const/let",
                      passed=no_var and has_const,
                      notes=f"var_removed={no_var}, const_let_present={has_const}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_4_magic_numbers():
    pricing = read_file("src/pricing.js")
    prompt = f"""Extract the magic number `1.15` in this file to a named constant `TAX_RATE` at the top, and use the constant everywhere the number was used.

```js
{pricing}
```

Return only the updated file contents.
"""
    r = query(prompt, max_tokens=1500)
    resp = r["content"].strip()

    has_const = "TAX_RATE" in resp
    body_lines = [l for l in resp.split("\n") if "1.15" in l and "TAX_RATE" not in l]
    magic_gone = len(body_lines) == 0

    return TestResult("T1.4", "Tier 1", "Extract magic number to constant",
                      passed=has_const and magic_gone,
                      notes=f"TAX_RATE_present={has_const}, magic_only_in_declaration={magic_gone}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_5_add_import():
    api = read_file("src/api.js")
    prompt = f"""Read this file and tell me what import statement should be added if another file wants to use the `fetchUser` function but doesn't have it imported yet.

```js
{api}
```

Reply in the exact format:
IMPORT_LINE: <the line>
REASON: <one short sentence>
"""
    r = query(prompt, max_tokens=200)
    resp = r["content"]
    has_import = "import" in resp and "fetchUser" in resp
    has_reason = "REASON:" in resp

    return TestResult("T1.5", "Tier 1", "Identify missing import",
                      passed=has_import and has_reason,
                      notes=f"import_in_response={has_import}, reason_given={has_reason}",
                      got=resp[:300],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_6_run_tests():
    prompt = f"""Run the test suite for this Node.js project and report which tests pass and which fail. The tests are in `test/pricing.test.js`.

Project path: {BENCH_DIR}

Execute the tests and report the results. If a test fails, briefly explain what the failure is.
"""
    system = "You are a developer assistant. You can execute shell commands to verify code."
    r = query(prompt, system=system, max_tokens=2000)

    test_proc = subprocess.run(
        ["node", "--test", str(BENCH_DIR / "test" / "pricing.test.js")],
        capture_output=True, text=True, timeout=30
    )

    resp = r["content"]
    identified_failure = "foo" in resp and ("114.99" in resp or "1.15" in resp or "floating" in resp.lower() or "precision" in resp.lower())
    reported_failure = "fail" in resp.lower()

    passed = reported_failure and identified_failure

    return TestResult("T1.6", "Tier 1", "Run tests and report results",
                      passed=passed,
                      notes=f"reported_failure={reported_failure} | identified root cause: {identified_failure}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_7_boilerplate():
    prompt = """Generate a README.md file with exactly these sections in this order:

# MyApp
## Installation
## Usage
## License

Under Installation: write "Run `npm install`."
Under Usage: write "Run `npm start`."
Under License: write "MIT".

Return ONLY the markdown content, no code fence.
"""
    r = query(prompt, max_tokens=300)
    resp = r["content"].strip()

    has_sections = all(s in resp for s in ["# MyApp", "## Installation", "## Usage", "## License"])
    has_content = "npm install" in resp and "npm start" in resp and "MIT" in resp

    return TestResult("T1.7", "Tier 1", "Generate boilerplate from spec",
                      passed=has_sections and has_content,
                      notes=f"sections_ok={has_sections}, content_ok={has_content}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T1_8_jsdoc():
    pricing = read_file("src/pricing.js")
    prompt = f"""Add a JSDoc comment above the `foo` function (only the `foo` function) in this file:

```js
{pricing}
```

Return only the updated file contents.
"""
    r = query(prompt, max_tokens=1000)
    resp = strip_fence(r["content"])

    has_jsdoc = "/**" in resp
    mentions_foo = "foo" in resp.lower() or "amount" in resp.lower() or "tax" in resp.lower() or "1.15" in resp

    return TestResult("T1.8", "Tier 1", "Add JSDoc to one function",
                      passed=has_jsdoc and mentions_foo,
                      notes=f"jsdoc_present={has_jsdoc}, descriptive={mentions_foo}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


# ---------- Tier 2: edge cases ----------

def T2_1_ambiguous():
    prompt = "Fix the bug."
    r = query(prompt, max_tokens=500)
    resp = r["content"].lower()
    asked_clarification = any(kw in resp for kw in [
        "which bug", "what bug", "more information", "can you clarify",
        "could you clarify", "please provide", "where", "what file",
        "the code", "share", "paste"
    ])
    just_guessed = "i fixed" in resp or "i changed" in resp or "here's the fix" in resp

    return TestResult("T2.1", "Tier 2", "Ambiguous task — does it ask for clarification?",
                      passed=asked_clarification and not just_guessed,
                      notes=f"asked_clarification={asked_clarification}, guessed={just_guessed}",
                      got=r["content"][:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T2_2_multistep():
    prompt = f"""Perform these 4 steps on this file and report each step's outcome:

1. Read the file and report a one-line summary of what it contains
2. Show the file with `console.log(items[i])` changed to `console.log('item:', items[i])`
3. Show where you would add this one-line comment at the top: `// Iterates over array items`
4. Confirm the result is valid JavaScript

```js
{read_file('src/messy.js')}
```
"""
    system = "You are a developer assistant."
    r = query(prompt, system=system, max_tokens=2000)
    resp = r["content"]

    read_done = "console.log" in resp.lower() or "iterates" in resp.lower() or "log" in resp.lower()
    edit_done = "console.log('item'" in resp or "'item:'" in resp
    comment_done = "// Iterates" in resp or "//iterates" in resp.lower()

    completed_steps = sum([read_done, edit_done, comment_done])

    return TestResult("T2.2", "Tier 2", "Multi-step read-edit-verify (4 steps)",
                      passed=completed_steps >= 2,
                      partial=completed_steps >= 1 and completed_steps < 2,
                      notes=f"steps_completed={completed_steps}/3 (read, edit, comment)",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T2_3_large_file():
    spec = """a JavaScript module that exports a function `fibonacci(n)` which returns the nth Fibonacci number using iteration (not recursion). Include 5 additional exported helper functions for related math operations (factorial, gcd, lcm, isPrime, isEven). Each function should have a JSDoc comment."""
    prompt = f"""Generate {spec}

Return the complete file, no markdown fence, no commentary.
"""
    r = query(prompt, max_tokens=4000)
    resp = strip_fence(r["content"])

    line_count = len(resp.split("\n"))
    has_fib = "fibonacci" in resp and "function" in resp
    has_helpers = sum(name in resp for name in ["factorial", "gcd", "lcm", "isPrime", "isEven"])

    return TestResult("T2.3", "Tier 2", "Generate 50+ line file from spec",
                      passed=line_count >= 50 and has_fib and has_helpers >= 4,
                      partial=line_count >= 30 or has_helpers >= 2,
                      notes=f"lines={line_count}, has_fib={has_fib}, helpers_found={has_helpers}/5",
                      got=f"{resp[:200]}...",
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T2_4_consistency():
    pricing = read_file("src/pricing.js")
    prompt = f"""The function `applyDiscount` in src/pricing.js has a subtle bug: it doesn't handle the case where discount >= 1 (would give negative total). I want you to:

1. Rename `applyDiscount` to `applyDiscountCapped`
2. Add a guard: if discount >= 1, return 0
3. Update src/index.js to call `applyDiscountCapped` instead

Current pricing.js:
```js
{pricing}
```

Just describe what changes you would make to each file. Don't execute yet — just list the edits.
"""
    r = query(prompt, max_tokens=1500)
    resp = r["content"].lower()

    mentions_rename = "applydiscountcapped" in resp.replace(" ", "").replace("_", "").replace("-", "")
    mentions_guard = "discount >= 1" in resp or "discount>=1" in resp or ">= 1" in resp or ("if" in resp and "discount" in resp)
    mentions_index = "index.js" in resp or "src/index" in resp

    score = sum([mentions_rename, mentions_guard, mentions_index])

    return TestResult("T2.4", "Tier 2", "Cross-file consistency planning",
                      passed=score == 3,
                      partial=score >= 2,
                      notes=f"rename={mentions_rename}, guard={mentions_guard}, index_update={mentions_index}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


# ---------- Tier 3: out-of-scope ----------

def T3_1_architecture():
    prompt = """Design a complete microservices architecture for an e-commerce platform handling 10k orders/minute. Include service boundaries, data models, communication patterns, deployment topology, and failure handling. Be thorough and detailed."""
    r = query(prompt, max_tokens=2500)
    resp = r["content"].lower()
    word_count = len(resp.split())

    recognized_scope = any(kw in resp for kw in [
        "out of scope", "this is a complex", "this requires",
        "consult an architect", "beyond a single session",
        "this is a large", "i would recommend working with"
    ])

    return TestResult("T3.1", "Tier 3", "Architecture design (out of scope)",
                      passed=False,  # informational: does it overreach?
                      partial=recognized_scope,
                      notes=f"word_count={word_count}, recognized_scope={recognized_scope}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T3_2_debug_no_cause():
    prompt = """The function `foo` in my pricing.js is broken. The test fails. Why?
"""
    r = query(prompt, max_tokens=1500)
    resp = r["content"].lower()

    asked_for_file = any(kw in resp for kw in [
        "pricing.js", "show me", "paste", "what does", "the file", "the code",
        "see the", "share the", "provide the"
    ])
    hallucinated = ("this" in resp and "settimeout" in resp) or ("you have a syntax error" in resp)

    return TestResult("T3.2", "Tier 3", "Debug without context (out of scope)",
                      passed=asked_for_file and not hallucinated,
                      notes=f"asked_for_file={asked_for_file}, hallucinated={hallucinated}",
                      got=r["content"][:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


def T3_3_huge_refactor_plan():
    prompt = """Plan a refactor of my entire JavaScript codebase to TypeScript. The codebase has 200 files. Provide a step-by-step migration plan."""
    r = query(prompt, max_tokens=2000)
    resp = r["content"].lower()
    word_count = len(resp.split())

    honest_response = any(kw in resp for kw in [
        "phased", "gradual", "phase 1", "incremental", "step by step",
        "this is a large", "consider breaking", "recommend",
    ])
    overreach = word_count > 800 and not honest_response

    return TestResult("T3.3", "Tier 3", "Huge multi-file refactor plan (out of scope)",
                      passed=honest_response and not overreach,
                      partial=honest_response,
                      notes=f"word_count={word_count}, honest_phased={honest_response}, overreach={overreach}",
                      got=resp[:500],
                      latency_s=r["latency"],
                      prompt_tokens=r["prompt_tokens"],
                      completion_tokens=r["completion_tokens"])


TESTS = [
    ("T1.1", T1_1_rename_function, "Rename function across 2 files"),
    ("T1.2", T1_2_add_types, "Add JSDoc type annotations"),
    ("T1.3", T1_3_var_to_const, "Convert var to const/let"),
    ("T1.4", T1_4_magic_numbers, "Extract magic number to constant"),
    ("T1.5", T1_5_add_import, "Identify missing import"),
    ("T1.6", T1_6_run_tests, "Run tests and report results"),
    ("T1.7", T1_7_boilerplate, "Generate boilerplate from spec"),
    ("T1.8", T1_8_jsdoc, "Add JSDoc to single function"),
    ("T2.1", T2_1_ambiguous, "Ambiguous task — clarification behavior"),
    ("T2.2", T2_2_multistep, "Multi-step read-edit-verify"),
    ("T2.3", T2_3_large_file, "Generate 50+ line file from spec"),
    ("T2.4", T2_4_consistency, "Cross-file consistency planning"),
    ("T3.1", T3_1_architecture, "Architecture (out of scope)"),
    ("T3.2", T3_2_debug_no_cause, "Debug without context (out of scope)"),
    ("T3.3", T3_3_huge_refactor_plan, "Huge refactor plan (out of scope)"),
]


def run_all():
    results = []
    print(f"Running {len(TESTS)} tests against {MODEL}\n")
    print(f"{'='*100}")

    for test_id, fn, desc in TESTS:
        print(f"\n>>> {test_id}: {desc}")
        try:
            r = fn()
            results.append(r)
            status = "PASS" if r.passed else ("PARTIAL" if r.partial else ("DECLINED" if r.declined else "FAIL"))
            print(f"   {status} ({r.latency_s:.1f}s, {r.prompt_tokens}+{r.completion_tokens} tok)")
            print(f"   {r.notes}")
        except Exception as e:
            results.append(TestResult(test_id, "?", desc, False, notes=f"EXCEPTION: {e}"))
            print(f"   EXCEPTION: {e}")

    return results


def report(results):
    print(f"\n\n{'='*100}")
    print("BENCHMARK SUMMARY")
    print(f"{'='*100}\n")

    tier1 = [r for r in results if r.tier == "Tier 1"]
    tier2 = [r for r in results if r.tier == "Tier 2"]
    tier3 = [r for r in results if r.tier == "Tier 3"]

    def tier_stats(tier, name, scorer=None):
        if not tier:
            return
        passed = sum(1 for r in tier if (scorer(r) if scorer else r.passed))
        total = len(tier)
        rate = passed / total * 100
        print(f"  {name}: {passed}/{total} ({rate:.0f}%)")
        for r in tier:
            status = "PASS  " if r.passed else ("PARTIAL" if r.partial else ("DECLIN" if r.declined else "FAIL  "))
            print(f"     [{status}] {r.id}: {r.description}  [{r.latency_s:.1f}s]")

    tier_stats(tier1, "Tier 1 (mechanical — should pass)")
    print()
    tier_stats(tier2, "Tier 2 (edge cases)")
    print()
    tier_stats(tier3, "Tier 3 (out-of-scope — should gracefully decline)", lambda r: r.passed or r.partial)

    total = len(results)
    overall_pass = sum(1 for r in results if r.passed or r.partial)
    print(f"\n  OVERALL: {overall_pass}/{total} tests passed or partially passed")

    total_time = sum(r.latency_s for r in results)
    total_tokens = sum(r.prompt_tokens + r.completion_tokens for r in results)
    print(f"  TOTAL TIME: {total_time:.1f}s")
    print(f"  TOTAL TOKENS: {total_tokens}")
    if total_time > 0:
        print(f"  AVG TOK/s: {total_tokens/total_time:.1f}")


if __name__ == "__main__":
    results = run_all()
    report(results)

    with open(RESULTS_PATH, "w") as f:
        json.dump([{
            "id": r.id, "tier": r.tier, "description": r.description,
            "passed": r.passed, "partial": r.partial, "declined": r.declined,
            "latency_s": r.latency_s, "prompt_tokens": r.prompt_tokens,
            "completion_tokens": r.completion_tokens, "notes": r.notes,
        } for r in results], f, indent=2)
    print(f"\nResults saved to {RESULTS_PATH}")
