#!/usr/bin/env python3
"""Deep bench: long-context needle recall + multi-hop reasoning + knowledge breadth.

History note: the first version of this test had an insertion bug (needles keyed
by word index, loop counts lines) that made it look like models couldn't recall
mid-context facts. Fixed 2026-09-21: needles are placed by LINE index.
Always re-verify an anomaly with a control before blaming the model.

Usage: python3 deep_bench.py [n_lines ...]   (default: 2200 560 80)
Grades needles exactly; reasoning/knowledge answers are printed for review.
"""
import json, random, sys, time, urllib.request

API = "http://127.0.0.1:8080/v1/chat/completions"
KEY = __import__("os").environ.get("LLAMACPP_API_KEY", "lwg2ES6mX5q2scPQRXhmAusKyT5IWom8")

def ask(content, max_tokens=300, temperature=0.1):
    payload = {"model": "local", "max_tokens": max_tokens,
               "temperature": temperature, "messages": [{"role": "user", "content": content}]}
    req = urllib.request.Request(API, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {KEY}"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=1500) as r:
        body = json.loads(r.read())
    t = body.get("timings", {})
    return {"text": body["choices"][0]["message"]["content"], "prompt_n": t.get("prompt_n", 0),
            "prefill_tps": t.get("prompt_per_second", 0),
            "gen_tps": t.get("predicted_per_second", 0), "wall": time.time() - t0}

# ---- haystack (filler ~48 tok/line at 2.5 tok/word — numeric-heavy text) ----
random.seed(42)
ZONES = ["Dock A", "Dock B", "Warehouse 3", "Yard North", "Yard South", "Cold Store", "Gate 4", "Gate 9", "Pier 5", "Pier 11", "Depot 2", "Depot 8"]
EQUIP = ["forklift 7", "crane 2", "conveyor 5", "loader 1", "scanner 9", "pump 3", "truck 12", "hoist 6"]
ACTIONS = ["routine inspection", "filter replacement", "calibration check", "load transfer", "pallet recount", "sensor cleaning", "belt tension test", "fuel top-up", "shift handover", "inventory scan"]
STATUS = ["completed", "completed", "completed", "deferred", "in progress", "scheduled"]

def log_line(i):
    return (f"[{i:05d}] Shift report {random.randint(100,999)}-{random.randint(10,99)}: "
            f"{random.choice(ZONES)} — {random.choice(EQUIP)}: {random.choice(ACTIONS)} "
            f"({random.choice(STATUS)}). Parts used: {random.randint(0,14)}. "
            f"Operator note ref {random.choice('KXTV')}–{random.randint(1000,9999)}.")

NEEDLES = [
    (0.02, "During the night audit, the maintenance access code for gate 7 was reset to XQ-4417 by security."),
    (0.25, "Visiting chef Marlow presented a saffron risotto at the canteen trial and was awarded the golden whisk."),
    (0.50, "The freighter docked at pier 12 this quarter is the Kestrel-7741, registered out of Tallinn."),
    (0.75, "Week 31 intake included exactly 1,208 crates of titanium valves, all routed to Warehouse 3."),
    (0.98, "Final entry of the log: the outgoing shift passphrase is AMBER-ORCHID-9, valid until the next audit."),
]
NEEDLE_MATCH = ["xq-4417", "risotto", "kestrel-7741", lambda t: "1,208" in t or "1208" in t, "amber-orchid-9"]

def build(n_lines):
    needle_at = {int(n_lines * p): txt for p, txt in NEEDLES}   # LINE index — the fix
    return "\n".join(needle_at.get(i) or log_line(i) for i in range(n_lines))

QUESTION = ("Answer with JUST the exact values, numbered 1-5:\n"
            "1. maintenance access code for gate 7\n2. dish that won Chef Marlow the golden whisk\n"
            "3. registry name+number of freighter at pier 12\n4. crates of titanium valves in week 31\n"
            "5. outgoing shift passphrase")

REASONING = [
    ("Q1 kinship", "Anna's father is Ben. Ben's sister is Carla. Carla's daughter is Dina. "
     "What relation is Dina to Anna? Answer with the word only.", 80, "cousin"),
    ("Q2 apples", "X sold 12 apples at $3 each and 8 apples at $5 each. Y sold twice as many apples "
     "as X, each at half of X's average price per apple. Who earned more, X or Y, and by how much? "
     "Answer concisely in plain text, then state the conclusion.", 1200, "equal / $76 each"),
    ("Q3 boxes", "Five boxes: red, blue, green, white, black in a row (positions 1-5). Clues: red is not "
     "at position 1 or 5. Blue is immediately right of red. Green is at position 5. White is not adjacent "
     "to green. Black is somewhere left of blue. What color is at position 3? Answer concisely.", 1200, "red"),
]
FACTS = ["Author of 'One Hundred Years of Solitude'", "Chemical symbol for tungsten",
         "Capital of Australia", "Year the Berlin Wall fell", "HTTP status 418 means",
         "Largest moon of Saturn", "Speed of light in vacuum (m/s)", "Year git was first released",
         "Language of the Spring Framework",
         "Theoretical computer scientist who proved the Church-Turing thesis' namesake lambda calculus (first name)"]

if __name__ == "__main__":
    sizes = [int(x) for x in sys.argv[1:]] or [2200, 560, 80]
    r = ask("Write a 100-word story about a lighthouse.")
    print(f"PROBE: gen {r['gen_tps']:.1f} t/s\n")
    print("=== A. NEEDLE RECALL (5 exact-value needles, line-indexed) ===")
    for nl in sizes:
        r = ask("Below is a facility operations log.\n\n" + build(nl) + "\n\n" + QUESTION)
        t, low = r["text"], r["text"].lower()
        hits = [(m in low if isinstance(m, str) else m(t)) for m in NEEDLE_MATCH]
        print(f"{nl} lines (prompt_n={r['prompt_n']}): {sum(hits)}/5 {hits} | "
              f"prefill {r['prefill_tps']:.0f} t/s | gen {r['gen_tps']:.1f} t/s | wall {r['wall']:.0f}s")
    print("\n=== B. MULTI-HOP REASONING ===")
    for name, q, mt, expected in REASONING:
        r = ask(q, max_tokens=mt)
        ok = expected.split(" / ")[0].lower() in r["text"].lower() or expected.lower() in r["text"].lower()
        print(f"--- {name} [expected: {expected}] {'PASS' if ok else 'CHECK'} [{r['wall']:.0f}s]")
        print("   " + r["text"].strip()[-220:].replace("\n", "\n   "))
    print("\n=== C. KNOWLEDGE BREADTH ===")
    r = ask("Answer each in under 6 words, numbered:\n" +
            "\n".join(f"{n}. {f}?" for n, f in enumerate(FACTS, 1)))
    print(r["text"].strip())
