#!/usr/bin/env python3
"""Tool-calling bench: exact paths, tool selection, sequences, restraint.
Usage: python3 tools_bench.py   (tests whatever model is loaded)
"""
import json
import os, time, urllib.request

API = "http://127.0.0.1:8080/v1/chat/completions"
KEY = os.environ.get("LLAMACPP_API_KEY", "lwg2ES6mX5q2scPQRXhmAusKyT5IWom8")
MODEL = None  # whatever is loaded

TOOLS = [
    {"type": "function", "function": {
        "name": "read_file",
        "description": "Read the contents of a file at an absolute path",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string", "description": "Absolute file path"}},
            "required": ["path"]}}},
    {"type": "function", "function": {
        "name": "write_file",
        "description": "Write content to a file at an absolute path",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string"}, "content": {"type": "string"}},
            "required": ["path", "content"]}}},
    {"type": "function", "function": {
        "name": "list_dir",
        "description": "List files in a directory",
        "parameters": {"type": "object", "properties": {
            "path": {"type": "string", "description": "Absolute directory path"}},
            "required": ["path"]}}},
    {"type": "function", "function": {
        "name": "search_web",
        "description": "Search the web for information",
        "parameters": {"type": "object", "properties": {
            "query": {"type": "string"}}, "required": ["query"]}}},
]

def query(messages, max_tokens=600):
    payload = {"model": MODEL, "messages": messages, "tools": TOOLS,
               "tool_choice": "auto", "max_tokens": max_tokens}
    req = urllib.request.Request(API, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {KEY}"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=240) as r:
        body = json.loads(r.read())
    dt = time.time() - t0
    msg = body["choices"][0]["message"]
    calls = msg.get("tool_calls") or []
    parsed = []
    for c in calls:
        f = c.get("function", {})
        try:
            args = json.loads(f.get("arguments", "{}"))
        except Exception:
            args = {"_raw": f.get("arguments", "")}
        parsed.append((f.get("name", "?"), args))
    t = body.get("timings", {})
    return parsed, msg.get("content"), dt, t

def show(label, ok, detail, dt):
    print(f"  {'PASS' if ok else 'FAIL'}  {label}  [{dt:.1f}s]  {detail}")

R = []

# TT1: single call, exact path
calls, content, dt, _ = query([{"role": "user", "content":
    "Read the file /tmp/toolbench/manifest.txt and tell me what it contains."}])
ok = len(calls) == 1 and calls[0][0] == "read_file" and calls[0][1].get("path") == "/tmp/toolbench/manifest.txt"
show("TT1 single tool, exact path", ok, f"calls={calls}", dt); R.append(ok)

# TT2: distractor selection
calls, content, dt, _ = query([{"role": "user", "content":
    "I need to find out who won the 1962 FIFA World Cup."}])
ok = len(calls) >= 1 and calls[0][0] == "search_web"
show("TT2 picks correct tool among 4", ok, f"calls={calls}", dt); R.append(ok)

# TT3: sequence + path composition
calls, content, dt, _ = query([{"role": "user", "content":
    "First list the files in /tmp/toolbench/dirA, then read the file config.json inside it."}])
ok = (len(calls) >= 2 and calls[0][0] == "list_dir"
      and calls[0][1].get("path") == "/tmp/toolbench/dirA"
      and any(c[0] == "read_file" and c[1].get("path") == "/tmp/toolbench/dirA/config.json" for c in calls))
show("TT3 sequence + composed path", ok, f"calls={calls}", dt); R.append(ok)

# TT4: multiple reads, exact paths
calls, content, dt, _ = query([{"role": "user", "content":
    "Read a.txt, b.txt and c.txt from /tmp/toolbench/dirB and summarize each."}])
paths = sorted(c[1].get("path", "") for c in calls if c[0] == "read_file")
expected = sorted(["/tmp/toolbench/dirB/a.txt", "/tmp/toolbench/dirB/b.txt", "/tmp/toolbench/dirB/c.txt"])
ok = paths == expected
show("TT4 three exact paths", ok, f"paths={paths}", dt); R.append(ok)

# TT5: similar paths, no cross-contamination (the DRY-killer scenario)
calls, content, dt, _ = query([{"role": "user", "content":
    "Read both /tmp/toolbench/app/src/main.js and /tmp/toolbench/app2/src/main.js and compare them."}])
paths = [c[1].get("path", "") for c in calls if c[0] == "read_file"]
ok = len(paths) == 2 and sorted(paths) == sorted(["/tmp/toolbench/app/src/main.js", "/tmp/toolbench/app2/src/main.js"])
show("TT5 similar paths, no mutation", ok, f"paths={paths}", dt); R.append(ok)

# TT6: no-tool restraint
calls, content, dt, _ = query([{"role": "user", "content":
    "What is 2+2? Answer briefly."}])
ok = len(calls) == 0 and content is not None
show("TT6 no-tool restraint", ok, f"calls={len(calls)}, content={(content or '')[:40]!r}", dt); R.append(ok)

# TT7: nonexistent file -> must still call the tool, not fabricate
calls, content, dt, _ = query([{"role": "user", "content":
    "Read the file /tmp/toolbench/does_not_exist.txt"}])
ok = len(calls) == 1 and calls[0][0] == "read_file" and calls[0][1].get("path") == "/tmp/toolbench/does_not_exist.txt"
fabricated = content and any(k in content.lower() for k in ["contains", "says", "the file shows", "the content is"])
show("TT7 calls tool for missing file (no fabrication)", ok and not fabricated,
     f"calls={calls}, fabricated={bool(fabricated)}", dt); R.append(ok and not fabricated)

print(f"\nTOOLS BENCH: {sum(R)}/{len(R)}")
