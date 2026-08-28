#!/usr/bin/env bash
# SessionStart hook — says whether the context Claude is about to work in is
# fresh, and counts compactions so a session that has outgrown itself says so
# instead of quietly getting more expensive.
#
# Install: see README. Nothing here is host-specific; safe on a shared machine.
#
#   "SessionStart": [
#     { "matcher": "startup|clear",
#       "hooks": [{ "type": "command",
#                   "command": "bash ~/.claude/session-context.sh startup-or-clear" }] },
#     { "matcher": "resume|fork",
#       "hooks": [{ "type": "command",
#                   "command": "bash ~/.claude/session-context.sh carried-over" }] },
#     { "matcher": "compact",
#       "hooks": [{ "type": "command",
#                   "command": "bash ~/.claude/session-context.sh compact" }] }
#   ]
#
# The kind of start arrives as $1 rather than being read from stdin. The matcher
# values are documented; a "source" field in the SessionStart payload is not, and
# a hook that guesses at an undocumented field fails silently the day it changes.
#
# stdout from a SessionStart hook is inserted into the context Claude can read,
# which is the whole delivery mechanism here — /acilis reads the FRESH line and
# refuses to open a session on a context that is carrying yesterday's work.
#
# Never exits non-zero and never blocks: a hook that fails at session start is a
# session that starts wrong, and the cost of being wrong here is a false warning
# on every single launch.

set -u

KIND="${1:-unknown}"

# Where the counter lives. CLAUDE_PROJECT_DIR is exported for hook commands;
# PWD is the fallback for a launch that has no project.
STATE_DIR="${CLAUDE_PROJECT_DIR:-$PWD}/.claude"
COUNTER="$STATE_DIR/compact-count"

# How many compactions before the session is called too long. Two, because one
# is normal on a working afternoon and the second is the one that says the
# session stopped being a question and started being a container.
COMPACT_LIMIT=2

mkdir -p "$STATE_DIR" 2>/dev/null || true

case "$KIND" in
    startup-or-clear)
        # A fresh context is also a fresh compaction count.
        rm -f "$COUNTER" 2>/dev/null || true
        printf 'session-context: FRESH — this session began at startup or /clear\n'
        ;;

    carried-over)
        printf 'session-context: CARRIED OVER — resumed or forked; the previous context is still loaded, NOT a fresh start\n'
        ;;

    compact)
        n=0
        [ -f "$COUNTER" ] && n=$(cat "$COUNTER" 2>/dev/null)
        case "$n" in ''|*[!0-9]*) n=0 ;; esac
        n=$((n + 1))
        printf '%s\n' "$n" > "$COUNTER" 2>/dev/null || true

        printf 'session-context: COMPACTED — compaction %d of this session; NOT a fresh context\n' "$n"
        if [ "$n" -ge "$COMPACT_LIMIT" ]; then
            printf 'session-context: ACTION — %d compactions. Tell the user, unprompted and before continuing, that this session has run long enough to close: /kapanis to write the log and commit, then /clear, then /acilis. Say it once, plainly, and do not repeat it every turn.\n' "$n"
        fi
        ;;

    *)
        printf 'session-context: UNKNOWN start kind (%s)\n' "$KIND"
        ;;
esac

exit 0
