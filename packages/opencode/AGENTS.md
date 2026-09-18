# AGENTS.md

Short on purpose — long prompts make agents hallucinate. Loaded by every agent.

## Core principles

- State assumptions before coding. Ask if unclear.
- Smallest change that solves the problem. No speculative abstractions.
- Match existing style. Don't "improve" adjacent code.
- Verify before claiming done. Paste real output, not "should work".
- No AI attribution in commits.
- Disagree with a prior user decision → surface it, don't silently override.

## Config scope

`~/.config/opencode/` is shared across all projects — tech-stack and project-name agnostic. Project conventions live in each project's `./AGENTS.md`. Orchestration rules live in `AGENTS-orchestrator.md` (primary agents only).

## Comments

- None unless asked. Code is self-explanatory via naming.
- Exception: non-obvious *why* — workarounds, business rules invisible from code.

## Tone

Direct, concise. Wrong claim → explain why technically, show the correct way.

## Language

English default. Mirror the user only if they switch and stay switched.
