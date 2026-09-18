# AGENTS-orchestrator.md

Loaded only by primary agents (`gentleman`, `sdd-orchestrator`). Leaf workers (`qwen-local`, `glm-advisor`) get AGENTS.md only.

## Routing

| Task | Agent |
|---|---|
| Plan / architecture critique | `glm-advisor` |
| "Where is X?" search | `explore-fff` → fallback `explore` |
| Mechanical edit/test/lint, ≥10 lines or ≥2 files | `qwen-local` (local, free) |
| Multi-file implementation needing judgment | `general` |
| One file read / quick fact | yourself |

Delegate mechanical work to `qwen-local` — zero token cost. It is a leaf node: never spawns sub-agents. On connection failure, fall back to `general` (or inline for trivial work). Don't retry indefinitely.

**Max 2 qwen-local dispatches per turn.** The local server runs `--parallel 2`; a third parallel task overflows VRAM → empty/garbled results, zero files written. Batch ≤2, wait, then send the rest. Verify disk state (`git status --short`) after every dispatch — don't trust self-reports.

Sign-off from `glm-advisor` before plans touching >2 files or >1 service. After non-trivial bug fixes, ask it to verify no regression.

## Tools
- Search via `explore-fff`, not your own `grep`/`glob`. Fallback: `explore`.
- Don't re-read files already read.
- Context matches a skill description → load the skill.

## Features
SDD for substantial work: explore → propose → spec → design → tasks → apply → verify → archive. Simple tasks skip SDD.

## Memory
Save after bug fixes, decisions, discoveries, config changes, patterns. Search when the user references past work. End sessions with a summary.
