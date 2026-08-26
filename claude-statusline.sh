#!/usr/bin/env bash
# Claude Code status line.
#
#   dotfiles [main] | Opus 5 · 1M | 91k/1M 9% ░░░░░░░░░░ · █░░░░░░░░░ 10% · 3h57m [13:50] · 7d 16%
#   └ dir     └ git   └ model      └ context window       └ 5h quota    └ resets      └ 7d quota
#
# Install: see README. Nothing here is host-specific; the whole file is safe to
# read on a shared machine.

# --- toggles ------------------------------------------------------------------
SHOW_TOKENS=1        # raw token count ("91k/1M") before the context percentage
SHOW_SEVEN_DAY=1     # weekly quota at the end of the line
SHOW_SUBPATH=1       # "project/sub/dir" when below the project root, else basename
SHOW_FLAGS=1         # markers for fast mode / non-default effort / thinking off
DEFAULT_EFFORT=high  # effort level considered normal — only deviations are shown
BAR_WIDTH=10         # cells per bar
# ------------------------------------------------------------------------------

input=$(cat)

# Opt-in payload dump for debugging. Off by default: the payload carries
# session_id, transcript_path and cwd, which do not belong in a world-readable
# file. Enable with CLAUDE_STATUSLINE_DEBUG=1 and delete the file afterwards.
if [ -n "${CLAUDE_STATUSLINE_DEBUG:-}" ]; then
    ( umask 077; printf '%s' "$input" > "${TMPDIR:-/tmp}/claude-statusline-debug.json" ) 2>/dev/null
fi

# One python process for the whole payload. Percentages arrive pre-rounded and
# the reset time pre-formatted, so bash never touches a float — that keeps the
# output identical under a locale with a comma decimal separator.
mapfile -t F < <(printf '%s' "$input" | python3 -c '
import sys, json, time
from datetime import datetime

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

def sub(parent, key):
    v = (parent or {}).get(key)
    return v if isinstance(v, dict) else {}

ws  = sub(d, "workspace")
cw  = sub(d, "context_window")
rl  = sub(d, "rate_limits")
fh  = sub(rl, "five_hour")
sd  = sub(rl, "seven_day")

mdl = d.get("model")
if isinstance(mdl, dict):
    name, mid = mdl.get("display_name") or "", mdl.get("id") or ""
else:
    name, mid = mdl or "", ""

def pct(o):
    v = o.get("used_percentage", o.get("percent_used"))
    try:
        return str(int(round(float(v))))
    except (TypeError, ValueError):
        return ""

def num(v):
    try:
        return str(int(v))
    except (TypeError, ValueError):
        return ""

reset = ""
try:
    at = int(fh["resets_at"])
    clock = "[" + datetime.fromtimestamp(at).strftime("%H:%M") + "]"
    left = at - int(time.time())
    if left > 0:
        h, m = left // 3600, (left % 3600) // 60
        reset = ("%dh%02dm " % (h, m) if h else "%dm " % m) + clock
    else:
        reset = "~reset " + clock
except (KeyError, TypeError, ValueError):
    pass

print("\n".join([
    ws.get("current_dir") or d.get("cwd") or "",
    ws.get("project_dir") or "",
    name,
    mid,
    pct(cw),
    num(cw.get("total_input_tokens")),
    num(cw.get("context_window_size")),
    pct(fh),
    reset,
    pct(sd),
    "yes" if d.get("fast_mode") else "",
    sub(d, "effort").get("level") or "",
    "" if sub(d, "thinking").get("enabled", True) is False else "yes",
    "END",
]))
' 2>/dev/null)

cwd="${F[0]-}"     ; proj="${F[1]-}"    ; model="${F[2]-}"   ; model_id="${F[3]-}"
used="${F[4]-}"    ; tokens="${F[5]-}"  ; ctxsize="${F[6]-}"
quota="${F[7]-}"   ; reset="${F[8]-}"   ; quota7="${F[9]-}"
fastmode="${F[10]-}"; effort="${F[11]-}"; thinking="${F[12]-}"

# --- helpers (no subshells: this runs on every redraw) ------------------------

# 91404 -> 91k, 1000000 -> 1M, 1500000 -> 1.5M
human() {
    local n=$1 t
    if [ "$n" -ge 1000000 ]; then
        t=$(( n / 100000 ))
        if [ $(( t % 10 )) -eq 0 ]; then printf '%dM' $(( t / 10 ))
        else printf '%d.%dM' $(( t / 10 )) $(( t % 10 )); fi
    elif [ "$n" -ge 1000 ]; then printf '%dk' $(( n / 1000 ))
    else printf '%d' "$n"; fi
}

bar() {
    local filled=$1 empty s=''
    [ "$filled" -gt "$BAR_WIDTH" ] && filled=$BAR_WIDTH
    [ "$filled" -lt 0 ] && filled=0
    empty=$(( BAR_WIDTH - filled ))
    while [ "$filled" -gt 0 ]; do s="${s}█"; filled=$(( filled - 1 )); done
    while [ "$empty"  -gt 0 ]; do s="${s}░"; empty=$((  empty  - 1 )); done
    printf '%s' "$s"
}

# green under 50%, yellow to 79%, red at 80% and above
heat() {
    if   [ "$1" -ge 80 ]; then printf '\033[31m'
    elif [ "$1" -ge 50 ]; then printf '\033[33m'
    else                       printf '\033[32m'; fi
}

is_num() { case "$1" in ''|*[!0-9]*) return 1;; *) return 0;; esac; }

# --- directory ----------------------------------------------------------------
if [ -n "$cwd" ]; then
    # Prefix with the project name only when that says something: below the
    # project root, and the root is an actual project rather than $HOME or /.
    if [ "$SHOW_SUBPATH" = 1 ] && [ -n "$proj" ] && [ "$proj" != "$cwd" ] \
       && [ "$proj" != "$HOME" ] && [ "$proj" != "/" ] \
       && [ "${cwd#"$proj"/}" != "$cwd" ]; then
        dir="${proj##*/}/${cwd#"$proj"/}"
    else
        dir="${cwd##*/}"
    fi
else
    dir="${PWD##*/}"
fi

# --- git branch ---------------------------------------------------------------
git_dir="${cwd:-$PWD}"
branch=$(git -C "$git_dir" symbolic-ref --short HEAD 2>/dev/null \
      || git -C "$git_dir" rev-parse --short HEAD 2>/dev/null)
[ -n "$branch" ] && branch_display=" \033[35m[${branch}]\033[0m" || branch_display=""

# --- model, plus markers for anything left switched away from normal ----------
model_display=""
if [ -n "$model" ] && [ "$model" != "None" ]; then
    # "Opus 5 (1M context)" is a quarter of the line; the id already tells us
    # the window size, so drop the parenthetical and re-add it as a tag.
    short="${model%% (*}"
    case "$model_id" in *'[1m]'*) short="${short} · 1M" ;; esac

    flags=""
    if [ "$SHOW_FLAGS" = 1 ]; then
        [ "$fastmode" = yes ] && flags="${flags} ⚡"
        [ -n "$effort" ] && [ "$effort" != "$DEFAULT_EFFORT" ] && flags="${flags} ·${effort}"
        [ "$thinking" != yes ] && flags="${flags} ·no-think"
    fi
    [ -n "$flags" ] && flags="\033[33m${flags}\033[0m"

    model_display=" \033[36m| \033[34m${short}\033[0m${flags}"
fi

# --- context window + quotas --------------------------------------------------
# Quiet labels here reset to the default foreground rather than using 90m
# (bright black). Plenty of dark themes — 1984 Dark in kitty.conf among them —
# map bright black to pure #000000, which is invisible on a dark background.
ctx_display=""
if is_num "$used"; then
    c=$(heat "$used")
    ctx_display=" \033[36m| "

    if [ "$SHOW_TOKENS" = 1 ] && is_num "$tokens" && is_num "$ctxsize" && [ "$ctxsize" -gt 0 ]; then
        ctx_display="${ctx_display}\033[0m$(human "$tokens")/$(human "$ctxsize") "
    fi

    ctx_display="${ctx_display}${c}${used}%\033[0m ${c}$(bar $(( used * BAR_WIDTH / 100 )))"

    if is_num "$quota"; then
        q=$(heat "$quota")
        ctx_display="${ctx_display}\033[36m · ${q}$(bar $(( quota * BAR_WIDTH / 100 )))\033[0m ${q}${quota}%"
    fi

    [ -n "$reset" ] && ctx_display="${ctx_display}\033[36m · \033[34m${reset}"

    # The seven-day window is the one that costs days rather than hours when it
    # fills, so it earns a number even though there is no room for a bar.
    if [ "$SHOW_SEVEN_DAY" = 1 ] && is_num "$quota7"; then
        q7=$(heat "$quota7")
        ctx_display="${ctx_display}\033[36m · \033[0m7d ${q7}${quota7}%"
    fi

    ctx_display="${ctx_display}\033[0m"
fi

printf "\033[33m%s\033[0m%b%b%b" "$dir" "$branch_display" "$model_display" "$ctx_display"
