#!/bin/bash
# check-fzf.sh — verify that the repo's fzf configuration still parses with the
# installed fzf, and that the installed fzf is new enough for the features the
# config depends on.
#
# WHY THIS EXISTS
# ---------------
# fzf exits 2 with a precise message the moment it meets something it does not
# know:
#
#   unknown option: --not-a-real-option
#   unknown action: not-an-action
#   unsupported key: alt-shift-i
#
# Those messages only appear when the picker starts, i.e. at the moment the
# user presses a key — the worst possible time to find out. fzf also adds and
# (occasionally) removes actions between releases, so a config that parses on
# 0.75.0 can break on the next upgrade, and a flag dropped in a new release
# breaks the picker silently for everyone.
#
# This script turns both classes of breakage into a non-zero exit that is
# reproducible from the repo, without launching an interactive picker.
#
# HOW IT WORKS
# ------------
# fzf parses FZF_DEFAULT_OPTS from the environment itself, so the check puts
# each option set in that variable and starts fzf with --filter (which prints
# matches and exits, never opening the interactive UI, never running a
# preview). A parse failure makes fzf exit 2 with the message above; the
# script turns that into a failure report.
#
# Run it after upgrading fzf, and before blaming fzf for a picker that dies on
# the first keypress.
#
# ELSEWHERE
# ---------
# The floor is a property of this config, not of the machine: the flags below
# (raw mode, toggle-raw, nomatch strip, word wrap, --id-nth, walker follow,
# inline footer border, next preview position, every(N)/FZF_IDLE_TIME,
# non-modal floating pane, mode-2026 sync rendering, info-command actions)
# all landed by fzf 0.75.0. On an older fzf the script exits non-zero and
# says which option is unsupported.
set -uo pipefail

# Minimum fzf this config is written against. Keep in sync with the
# "Requires fzf >= ..." line in packages/sh/fzf.zsh — the check below verifies
# the two agree, so the pair cannot drift apart.
FLOOR="0.75.0"

# Resolve the repo root from this script's own location, not from the cwd.
# $0 is the reliable handle here: BASH_SOURCE[0] is "bash" when the script is
# run through a wrapper that evals it, and the cwd is not the repo root in
# every invocation (it used to look for /Users/packages/sh/fzf.zsh).
SCRIPT_PATH="$0"
case "$SCRIPT_PATH" in
    */*) ;;                                # looks like a path
    *) SCRIPT_PATH="${BASH_SOURCE[0]}" ;;
esac
case "$SCRIPT_PATH" in
    /*) ;;
    *) SCRIPT_PATH="$PWD/$SCRIPT_PATH" ;;
esac
REPO_ROOT="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"
CONFIG="$REPO_ROOT/packages/sh/fzf.zsh"

note() { echo "  $1"; }
fail() { echo "  FAIL: $1"; failures=$((failures + 1)); }
failures=0

echo "fzf configuration check"
echo

# --- fzf must be installed -----------------------------------------------
if ! command -v fzf >/dev/null 2>&1; then
  echo "  FAIL: fzf is not on PATH - install it (brew install fzf)"
  exit 1
fi

FZF_VERSION="$(fzf --version 2>/dev/null | awk '{print $1}')"
note "installed fzf: ${FZF_VERSION:-unknown} (floor ${FLOOR})"

# --- installed version must satisfy the floor ----------------------------
# Compare on the numeric components so 0.100.0 sorts above 0.75.0.
version_ge() { # $1=candidate $2=minimum -> 0 if candidate >= minimum
  [ "$(printf '%s\n%s\n' "$2" "$1" | sort -t. -k1,1n -k2,2n -k3,3n | head -1)" = "$2" ]
}
if ! printf '%s' "$FZF_VERSION" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+$'; then
  fail "cannot parse fzf version '${FZF_VERSION}'"
elif ! version_ge "$FZF_VERSION" "$FLOOR"; then
  fail "fzf ${FZF_VERSION} is older than the ${FLOOR} floor this config needs"
fi

# --- the config file must exist ------------------------------------------
if [ ! -f "$CONFIG" ]; then
  fail "missing ${CONFIG}"
  echo
  echo "FAILED: ${failures} problem(s)"
  exit 1
fi

# --- the documented floor and the script's floor must agree ----------------
# A mismatch means one of the two was updated without the other, and the
# script would silently check the wrong thing.
DOCUMENTED_FLOOR="$(sed -n 's/.*Requires fzf >= \([0-9][0-9.]*\)\(\.[0-9][0-9.]*\)*.*/\1/p' "$CONFIG" | head -1)"
if [ -z "$DOCUMENTED_FLOOR" ]; then
  fail "no 'Requires fzf >= X.Y.Z' line found in ${CONFIG}"
elif [ "$DOCUMENTED_FLOOR" != "$FLOOR" ]; then
  fail "config documents floor ${DOCUMENTED_FLOOR} but this script checks ${FLOOR}"
fi

# --- every option set the config ships must parse ------------------------
# Sourcing the config in a subshell is the only way to get the composed
# strings (they interpolate FZF_COLORS and $HOME), and it is what the shell
# integration does too. TMUX is unset so the config's tmux env push does not
# touch the live server; the tmux block is irrelevant to parsing.
OPTS_VARS="FZF_DEFAULT_OPTS FZF_CTRL_T_OPTS FZF_CTRL_R_OPTS FZF_ALT_C_OPTS \
FZF_COMPLETION_OPTS FZF_COMPLETION_PATH_OPTS FZF_COMPLETION_DIR_OPTS"

for var in $OPTS_VARS; do
  value="$(env -u TMUX zsh -c '
    source "$1" >/dev/null 2>&1
    print -r -- "${(P)2-}"
  ' _ "$CONFIG" "$var" 2>/dev/null)"

  if [ -z "$value" ]; then
    fail "${var} is empty or unset - the picker would start unconfigured"
    continue
  fi

  # --filter makes fzf print matches and exit instead of opening the UI.
  # The probe text is fed on stdin and stdin is closed after it, so fzf
  # finishes on its own. The filter query deliberately matches nothing, so
  # fzf exits 1 (no match) - that is the healthy result. Exit 2 is what fzf
  # returns when it refuses to parse an option, action or key.
  err="$(printf 'probe\n' | env -u TMUX FZF_DEFAULT_OPTS="$value" \
    fzf --filter zzz-no-such-match < /dev/null 2>&1 >/dev/null)"
  status=$?

  case "$status" in
    0|1)
      note "${var}: parses"
      ;;
    2)
      fail "${var}: $(printf '%s' "$err" | head -1)"
      ;;
    *)
      fail "${var}: fzf exited ${status} while parsing: $(printf '%s' "$err" | head -1)"
      ;;
  esac

  # A fatal COMBINATION that per-set parsing cannot catch: fzf 0.75 accepts
  # --border and --popup on their own, but with both set it exits
  # immediately and draws nothing, so every picker (Ctrl-T, Ctrl-R, Alt-C,
  # the tmux-fzf plugin's pickers) dies silently. The set still parses, so
  # the case above passes and the breakage only appears in the picker.
  case "$value" in
    *--border*--popup*|*--popup*--border*)
      fail "${var} combines --border with --popup: fzf exits silently, the picker never opens"
      ;;
  esac
done

# --- the 0.75-only actions this config relies on must exist --------------
# change-info-command is the headline feature of 0.75.0; the label transforms
# use the bg- family that arrived with the same generation. If a future fzf
# renames them, the binds above still parse but the feature is gone, so name
# them explicitly.
for action in change-info-command bg-transform-list-label \
bg-transform-preview-label bg-transform-header; do
  if printf '' | fzf --bind "ctrl-a:${action}:echo ok" >/dev/null 2>&1; then
    note "action ${action}: available"
  else
    fail "action ${action}: not supported by fzf ${FZF_VERSION}"
  fi
done

# --- the events the config binds to must exist ---------------------------
# Events are named in the KEY position of a bind ("result-final:action:..."),
# not the action position, so they need their own probe. result-final is the
# event the list label is bound to: it fires once the input stream closes,
# where result fires on every intermediate snapshot.
for event in result result-final focus; do
  if printf '' | fzf --bind "${event}:transform-list-label:echo ok" >/dev/null 2>&1; then
    note "event ${event}: available"
  else
    fail "event ${event}: not supported by fzf ${FZF_VERSION}"
  fi
done

# --- bind bodies must be POSIX, not bash ---------------------------------
# fzf runs every --bind command through $SHELL -c. This config is shared
# with a Linux box whose $SHELL may be dash, where bash-only syntax fails:
# [[ -n {} ]] is "not found" and an unquoted $FZF_QUERY splits into extra
# test operands ("unexpected operator"). fzf's own parser does not care -
# it passes the body to the shell verbatim - so the option-parsing check
# above passes on a body that dies at runtime. Run each transform body
# under bash AND dash, and require it to exit 0 in both with identical
# output. Exit 0 matters on its own: an unquoted $FZF_QUERY fails in
# BOTH shells, with the same exit code and only the wording of the error
# differing, so comparing output alone can miss it.
#
# The bodies are read out of the composed option strings (the config
# interpolates FZF_COLORS and $HOME, so only the composed form is real),
# and the shell placeholder {} is replaced with a quoted sample item, the
# way fzf substitutes it (fzf quotes it, so a multi-word item stays one
# word). FZF_QUERY is set to two words on purpose.
POSIX_SHELL=""
for candidate in dash /bin/dash /usr/bin/dash; do
  if command -v "$candidate" >/dev/null 2>&1; then
    POSIX_SHELL="$candidate"
    break
  fi
done

if [ -z "$POSIX_SHELL" ]; then
  note "no dash found - skipping the POSIX portability check"
else
  note "POSIX portability check (comparing bash against ${POSIX_SHELL})"

  # Print each transform/command body of an option string, one record per
  # body, delimited so the bodies can contain anything.
  extract_bodies() {
    env -u TMUX zsh -c '
      source "$1" >/dev/null 2>&1
      v=${(P)2}
      for w in "${(@z)v}"; do
        u=${(Q)w}
        case "$u" in
          --bind=*)
            b=${u#--bind=}
            rest=${b#*:}
            act=${rest%%:*}; body=${rest#*:}
            act=${act#+}
            case "$act" in
              bg-transform-*|transform-*|change-info-command)
                print -r -- "###REC### $2 :: $act"
                print -r -- "$body"
                print -r -- "###END###"
                ;;
            esac
            ;;
        esac
      done
    ' _ "$CONFIG" "$1" 2>/dev/null
  }

  # Run a body under one shell with the fzf variables the bodies read.
  # {} becomes a quoted item, as fzf substitutes it (single-quoted, so a
  # multi-word item stays one word). FZF_QUERY is deliberately two words:
  # an unquoted $FZF_QUERY would split into extra test operands.
  # The output lands in RB_OUT and the exit status in RB_RC, so the two are
  # never parsed back out of a combined string.
  run_body() {
    local shell=$1 body=$2
    local cmd
    cmd=${body//\{\}/\'sample-item\'}
    RB_OUT=$(FZF_QUERY='two words' FZF_MATCH_COUNT=7 FZF_INFO='7/7' FZF_POS=1 \
      "$shell" -c "$cmd" 2>&1)
    RB_RC=$?
  }

  # Process substitution, not a pipeline: a `| while` loop runs in a subshell,
  # where the failure counter would be lost and the script would still exit 0.
  for var in $OPTS_VARS; do
    while IFS= read -r line; do
      case "$line" in
        '###REC###'*)
          meta=${line#\#\#\#REC### }
          body=""
          ;;
        '###END###')
          run_body bash "$body"
          out_bash=$RB_OUT
          rc_bash=$RB_RC
          run_body "$POSIX_SHELL" "$body"
          out_posix=$RB_OUT
          rc_posix=$RB_RC
          # A transform body must SUCCEED. Comparing bash and dash output
          # alone is not enough: an unquoted $FZF_QUERY fails in both shells,
          # with the same exit code and only the wording of the error
          # differing, so an agreement-only check can miss it. Exit 0 in
          # every shell is the invariant.
          if [ "$rc_bash" != 0 ]; then
            fail "${meta}: fails under bash (exit ${rc_bash}) - bash=[${out_bash}]"
          elif [ "$rc_posix" != 0 ]; then
            fail "${meta}: fails under ${POSIX_SHELL} (exit ${rc_posix}) - ${POSIX_SHELL}=[${out_posix}]"
          elif [ "$out_bash" != "$out_posix" ]; then
            fail "${meta}: differs between shells - bash=[${out_bash}] ${POSIX_SHELL}=[${out_posix}]"
          else
            note "${meta}: runs cleanly under bash and ${POSIX_SHELL}"
          fi
          ;;
        *)
          body="${body}${line}
"
          ;;
      esac
    done < <(extract_bodies "$var")
  done
fi

echo
if [ "$failures" -eq 0 ]; then
  echo "OK: fzf ${FZF_VERSION} accepts every option this repo's config uses"
  exit 0
fi
echo "FAILED: ${failures} problem(s)"
exit 1
