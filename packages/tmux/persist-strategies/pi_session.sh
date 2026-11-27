#!/usr/bin/env bash

# "pi session strategy" for tmux-persist.
#
# `pi` (pi-coding-agent) starts a brand-new conversation on a bare launch; the
# CLI's own `--continue` reopens the most recent session for the pane's working
# directory, which is what restore wants and needs no sidecar files or knowledge
# of pi's session layout.
#
# Behavior:
#   - If the saved command already selects a session (--continue/-c,
#     --resume/-r, --session, --session-id), pass it through unchanged so the
#     explicit choice wins.
#   - Otherwise append `--continue`, preserving every other captured flag
#     (--model, --session-dir, ...). Positional prompts are kept, matching the
#     CLI's documented "continue previous session" form.
#
# Installed into ~/.tmux/plugins/tmux-persist/strategies/ by tmux.conf (see the
# tmux-persist block); the plugin only looks for strategies in its own tree.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

original_command_already_resumes() {
	# Whole-token match so `--session-dir` never counts as `--session`, and a
	# `-c` inside a prompt argument never trips it.
	[[ "$ORIGINAL_COMMAND" =~ (^|[[:space:]])(--continue|--resume|--session|--session-id|-c|-r)([[:space:]=]|$) ]]
}

main() {
	if original_command_already_resumes; then
		echo "$ORIGINAL_COMMAND"
	else
		echo "$ORIGINAL_COMMAND --continue"
	fi
}
main
