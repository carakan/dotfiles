#!/usr/bin/env python3
"""Dual-agent concurrency bench: two simulated agents (distinct stable system
prompts) hitting the server simultaneously — measures per-stream t/s, aggregate
throughput, and per-request KV cache reuse (timings.cache_n).

Usage: python3 dual_agent_bench.py   (tests whatever model is loaded)
"""
import json
import os
import threading
import time
import urllib.request

API = "http://127.0.0.1:8080/v1/chat/completions"
KEY = os.environ.get("LLAMACPP_API_KEY", "lwg2ES6mX5q2scPQRXhmAusKyT5IWom8")

def loaded_model():
    req = urllib.request.Request("http://127.0.0.1:8080/v1/models",
                                 headers={"Authorization": f"Bearer {KEY}"})
    with urllib.request.urlopen(req, timeout=10) as r:
        return json.loads(r.read())["data"][0]["id"]

MODEL = loaded_model()

def query(system, user, max_tokens=300):
    payload = {"model": MODEL, "max_tokens": max_tokens, "messages": [
        {"role": "system", "content": system},
        {"role": "user", "content": user}]}
    req = urllib.request.Request(API, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {KEY}"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=300) as r:
        body = json.loads(r.read())
    wall = time.time() - t0
    t = body.get("timings", {})
    return {
        "gen_tps": t.get("predicted_per_second", 0),
        "prompt_tps": t.get("prompt_per_second", 0),
        "cache_n": t.get("cache_n", 0),
        "prompt_n": t.get("prompt_n", 0),
        "gen_tokens": t.get("predicted_n", 0),
        "wall": wall,
    }

SYS_A = ("You are worker ALPHA, a Python coding assistant. Style: type hints everywhere, "
         "docstrings, no comments unless asked. Prefer dataclasses. Answer tersely. " * 4)
SYS_B = ("You are worker BETA, a JavaScript coding assistant. Style: ESM imports, const only, "
         "arrow functions, JSDoc on exports. Answer tersely. " * 4)

results = {}
barrier = threading.Barrier(2)

def worker(tag, system, user, max_tokens=300):
    barrier.wait()
    results[tag] = query(system, user, max_tokens)

def run_pair(a_user, b_user, max_tokens=300, label=""):
    ta = threading.Thread(target=worker, args=("A", SYS_A, a_user, max_tokens))
    tb = threading.Thread(target=worker, args=("B", SYS_B, b_user, max_tokens))
    t0 = time.time()
    ta.start(); tb.start(); ta.join(); tb.join()
    wall = time.time() - t0
    a, b = results["A"], results["B"]
    agg = (a["gen_tokens"] + b["gen_tokens"]) / wall if wall else 0
    print(f"{label}")
    print(f"  A: gen {a['gen_tps']:.1f} t/s | cache_n {a['cache_n']}/{a['cache_n']+a['prompt_n']} | {a['gen_tokens']} tok in {a['wall']:.1f}s")
    print(f"  B: gen {b['gen_tps']:.1f} t/s | cache_n {b['cache_n']}/{b['cache_n']+b['prompt_n']} | {b['gen_tokens']} tok in {b['wall']:.1f}s")
    print(f"  wall {wall:.1f}s | aggregate {agg:.1f} tok/s")
    return a, b, agg

print(f"Model: {MODEL.split('/')[-1]}\n")

print("=== Phase 1: single-stream baseline (one agent alone) ===")
r = query(SYS_A, "Write a one-line Python function that reverses a string.")
print(f"  gen {r['gen_tps']:.1f} t/s | {r['gen_tokens']} tok in {r['wall']:.1f}s | cache_n {r['cache_n']}")
baseline = r["gen_tps"]

print("\n=== Phase 2: two agents, cold (first turn each — prefills both prefixes) ===")
run_pair("Write a Python function fib(n).", "Write a JS function fib(n).", 250, "COLD:")

print("\n=== Phase 3: two agents, warm (same prefixes + new turn — cache should hit) ===")
run_pair("Now add memoization to fib.", "Now make fib iterative.", 250, "WARM:")

print("\n=== Phase 4: sustained concurrent generation (400 tok each) ===")
run_pair("Explain Python generators in exactly 3 sentences.",
         "Explain JS closures in exactly 3 sentences.", 400, "SUSTAINED:")

print("\n=== Metrics snapshot ===")
req = urllib.request.Request("http://127.0.0.1:8080/metrics",
                             headers={"Authorization": f"Bearer {KEY}"})
with urllib.request.urlopen(req, timeout=10) as r:
    for line in r.read().decode().splitlines():
        if line.startswith("llamacpp:") and any(k in line for k in (
                "spec_decode_num_draft_tokens_total", "spec_decode_num_accepted_tokens_total",
                "prompt_tokens_cached_total", "predicted_tokens_seconds", "prompt_tokens_seconds")):
            print(" ", line)

print(f"\nBaseline single-stream was {baseline:.1f} t/s — compare Phase 4 per-stream and aggregate.")
