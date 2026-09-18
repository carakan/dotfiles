#!/usr/bin/env python3
"""Vision bench: sends images to the server's OpenAI-compatible API, captures
timings + answers. Run against whatever vision model/mmproj is loaded.
Usage: python3 vision_bench.py [image1 image2 ...]  (defaults built-in pair)
"""
import base64
import json
import mimetypes
import os
import sys
import time
import urllib.request

API = "http://127.0.0.1:8080/v1/chat/completions"
KEY = os.environ.get("LLAMACPP_API_KEY", "lwg2ES6mX5q2scPQRXhmAusKyT5IWom8")

CASES = [
    ("/Users/carakan/Downloads/image-20250701-203917.png",
     "Read EXACTLY, verbatim: (1) the title of the popup dialog, (2) the URL in the address bar, "
     "(3) the brand name top-left of the web page, (4) the weather text near the clock in the taskbar, "
     "(5) the laptop brand visible below the screen."),
    ("/Users/carakan/Downloads/433485762_939324391526784_859446327984595866_n.jpg",
     "Answer precisely: (1) how many people are in the photo, (2) which country's flag is behind them "
     "(name the country), (3) the colors of the costumes left vs right, (4) any watermark or photographer "
     "text visible, verbatim."),
]

def data_uri(path):
    mime = mimetypes.guess_type(path)[0] or "image/png"
    with open(path, "rb") as f:
        return f"data:{mime};base64,{base64.b64encode(f.read()).decode()}"

def vision_query(img_path, question):
    payload = {
        "model": "local", "max_tokens": 400, "temperature": 0.2,
        "messages": [{"role": "user", "content": [
            {"type": "text", "text": question},
            {"type": "image_url", "image_url": {"url": data_uri(img_path)}}]}]}
    req = urllib.request.Request(API, data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json", "Authorization": f"Bearer {KEY}"})
    t0 = time.time()
    with urllib.request.urlopen(req, timeout=300) as r:
        body = json.loads(r.read())
    wall = time.time() - t0
    t = body.get("timings", {})
    answer = body["choices"][0]["message"]["content"]
    return {"answer": answer, "wall": wall,
            "prompt_n": t.get("prompt_n", 0), "cache_n": t.get("cache_n", 0),
            "prompt_tps": t.get("prompt_per_second", 0), "gen_tps": t.get("predicted_per_second", 0)}

if __name__ == "__main__":
    cases = list(zip(sys.argv[1::2], sys.argv[2::2])) or CASES
    for img, q in cases:
        name = os.path.basename(img)
        print(f"\n=== {name} ===")
        r = vision_query(img, q)
        print(f"prefill {r['prompt_n']} tok ({r['cache_n']} cached) @ {r['prompt_tps']:.0f} t/s | "
              f"gen @ {r['gen_tps']:.1f} t/s | wall {r['wall']:.1f}s")
        print(f"ANSWER:\n{r['answer']}")
