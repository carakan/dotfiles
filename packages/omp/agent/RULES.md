# ECC Workflow Skills

The ECC plugin is installed at `~/.omp/plugins/node_modules/ecc-universal/` (skills are NOT auto-enumerated). Before any non-trivial implementation, refactoring, or bug-fix task:

1. Check for a relevant ECC skill in `~/.omp/plugins/node_modules/ecc-universal/skills/` — key ones: `tdd-workflow` (tests-first with verified RED gate + evidence report), `verification-loop`, `security-review`, `search-first`, `deep-research`, `continuous-learning`.
2. If one applies, `read` its `SKILL.md` and follow its workflow, adapting tool commands to this project (e.g. Minitest for Rails projects, not npm/jest).
3. Skip ECC skills for trivial single-file edits, docs, and commits.
