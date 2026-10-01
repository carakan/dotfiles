# AGENTS-orchestrator.md

Loaded only by primary agents (`gentleman`, `sdd-orchestrator`). Leaf workers (`qwen-local`, `glm-advisor`) get AGENTS.md only.

## Routing

| Task | Agent |
|---|---|
| Plan / architecture critique, second opinion | `glm-advisor` |
| Review a diff or a worker's claim before accepting it | `glm-advisor` |
| "Where is X?" search | `explore-fff` → fallback `explore` |
| Mechanical edit/test/lint, ≥10 lines or ≥2 files | `qwen-local` (local, free) |
| Multi-file implementation needing judgment | `general` |
| One file read / quick fact | yourself |

Delegate mechanical work to `qwen-local` — zero token cost. It is a leaf node: never spawns sub-agents. On connection failure, fall back to `general` (or inline for trivial work). Don't retry indefinitely.

**Max 2 qwen-local dispatches per turn**, and only while the server's `--parallel` is ≥2. Batch ≤2, wait, then send the rest. A report without pasted output is not evidence: after every dispatch run `git status --short` and `git diff`, and run the tests yourself before acting on it.

Sign-off from `glm-advisor` before plans touching >2 files or >1 service. After non-trivial bug fixes, ask it to verify no regression.

## Local model harness (qwen-local)

- Registered `limit.context` must equal the **per-slot** context: llama.cpp splits `-c` across `--parallel` slots, so `-c 65536 --parallel 2` = 32768 usable per worker.
- **Never enable the DRY sampler** — it penalizes repeated ≥6-token sequences, i.e. it corrupts verbatim copying of paths and identifiers (A/B test: 3/3 corrupted with it, 3/3 exact without). It reads as quant corruption and sends you swapping models for nothing.
- After any GGUF/quant swap, re-run a verbatim-path probe before trusting a dispatch. When two configs differ, suspect the config first.

## Tools
- Search via `explore-fff`, not your own `grep`/`glob`. Fallback: `explore`.
- Don't re-read files already read.
- Context matches a skill description → load the skill.

## Features
SDD for substantial work: explore → propose → spec → design → tasks → apply → verify → archive. Simple tasks skip SDD.

## Memory
Save after bug fixes, decisions, discoveries, config changes, patterns. Search when the user references past work. End sessions with a summary.
