#!/usr/bin/env bash

# "omp session strategy" for tmux-persist.
#
# `omp` starts a fresh conversation on a bare launch; `-c`/`--continue` resumes
# the most recent one for the pane's working directory. Restore rewrites the
# captured command into that form instead of replaying a bare launch.
#
# Behavior:
#   - If the saved command already resumes (--continue/-c, --resume/-r,
#     --restore), pass it through unchanged so a pinned session wins.
#   - Otherwise append `--continue`, preserving every other captured flag
#     (--model, --session-dir, ...) and positional prompt.
#
# Installed into ~/.tmux/plugins/tmux-persist/strategies/ by tmux.conf (see the
# tmux-persist block); the plugin only looks for strategies in its own tree.

ORIGINAL_COMMAND="$1"
DIRECTORY="$2"

original_command_already_resumes() {
	# Whole-token match so `--session-dir` never counts as a resume selector.
	[[ "$ORIGINAL_COMMAND" =~ (^|[[:space:]])(--continue|--resume|--restore|-c|-r)([[:space:]=]|$) ]]
}

main() {
	if original_command_already_resumes; then
		echo "$ORIGINAL_COMMAND"
	else
		echo "$ORIGINAL_COMMAND --continue"
	fi
}
main
