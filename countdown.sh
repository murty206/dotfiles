#!/usr/bin/env bash
# =============================================================================
# countdown.sh — full-screen countdown to a time or duration, tty-clock style
# Repo:   https://github.com/murty206/dotfiles
# Usage:  countdown <HH:MM | duration> [label]
#
# An argument containing ":" is read as a wall-clock time, anything else as a
# duration from now. Current time is shown above at half scale. Ctrl+C quits.
#
# Pure bash + coreutils — no dependencies, works in a bare TTY.
# Run with bash explicitly; it uses bash arrays and is not zsh-compatible.
# =============================================================================

set -uo pipefail

usage() {
    cat <<'USAGE'
countdown — full-screen countdown to a time of day, or after a duration

  countdown 16:45              wall-clock time; tomorrow if already past today
  countdown 25m                25 minutes from now
  countdown 1h30m              hours and minutes
  countdown 90s                seconds
  countdown 25                 a bare number means minutes
  countdown 16:45 "Standup"    second argument is a label above the digits

The rule is one character: an argument containing ":" is a wall-clock time,
anything else is a duration. So "1:30" means half past one on the clock, not
one and a half hours — write 1h30m when you mean the duration. The resolved
target and the time left appear in the footer from the first frame, and a
target that landed on the next day is marked "(tomorrow)", so a misread shows
up immediately rather than an hour later.
USAGE
}

[[ $# -eq 0 || "${1:-}" == -h || "${1:-}" == --help ]] && { usage; exit 0; }

SPEC="$1"
LABEL="${2:-}"

# ---- colors (ANSI background codes)
COLOR_CLOCK=44      # current time         : blue
COLOR_NORMAL=46     # countdown            : cyan
COLOR_WARN=43       # last 30 minutes      : yellow
COLOR_URGENT=41     # last 5 minutes       : red
COLOR_DONE=47       # alternating frame once time is up

# ---- alert when time is up; each layer is optional and degrades silently
ALERT_BELL=1        # terminal bell: PC-speaker buzzer in a bare TTY,
                    # window urgency hint in kitty (kitty.conf has
                    # enable_audio_bell no, so it flashes rather than beeps)
ALERT_NOTIFY=1      # desktop notification via notify-send, needs a graphical session
ALERT_SOUND=1       # actual audible sound through the sound server
ALERT_SOUNDS=(
    /usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga
    /usr/share/sounds/freedesktop/stereo/complete.oga
)

# ---- 3x5 digit bitmaps, one space-separated word per row
declare -A SEG
SEG[0]="111 101 101 101 111"
SEG[1]="010 110 010 010 111"
SEG[2]="111 001 111 100 111"
SEG[3]="111 001 111 001 111"
SEG[4]="101 101 111 001 001"
SEG[5]="111 100 111 001 111"
SEG[6]="111 100 111 101 111"
SEG[7]="111 001 001 001 001"
SEG[8]="111 101 111 101 111"
SEG[9]="111 101 111 001 111"
SEG[:]="0 1 0 1 0"

# ---- resolve target: ":" means a clock time, anything else a duration
TOMORROW=""

if [[ "$SPEC" == *:* ]]; then
    if ! TARGET_EPOCH="$(date -d "$SPEC" +%s 2>/dev/null)"; then
        echo "Invalid time: $SPEC   (example: 16:45)" >&2
        exit 1
    fi
    if [[ "$TARGET_EPOCH" -le "$(date +%s)" ]]; then
        TARGET_EPOCH="$(date -d "tomorrow $SPEC" +%s)"
        TOMORROW=" (tomorrow)"
    fi
else
    secs=0; rest="$SPEC"; ok=0
    if [[ "$rest" =~ ^[0-9]+$ ]]; then
        secs=$(( rest * 60 )); ok=1                     # bare number = minutes
    else
        while [[ "$rest" =~ ^([0-9]+)([hms])(.*)$ ]]; do
            case "${BASH_REMATCH[2]}" in
                h) secs=$(( secs + BASH_REMATCH[1] * 3600 ));;
                m) secs=$(( secs + BASH_REMATCH[1] * 60   ));;
                s) secs=$(( secs + BASH_REMATCH[1]        ));;
            esac
            rest="${BASH_REMATCH[3]}"; ok=1
        done
        [[ -n "$rest" ]] && ok=0                        # trailing junk
    fi
    if [[ "$ok" -ne 1 || "$secs" -le 0 ]]; then
        echo "Invalid duration: $SPEC   (examples: 25m, 1h30m, 90s, 25)" >&2
        exit 1
    fi
    TARGET_EPOCH=$(( $(date +%s) + secs ))
    [[ "$(date -d "@$TARGET_EPOCH" +%F)" != "$(date +%F)" ]] && TOMORROW=" (tomorrow)"
fi

# What the footer and title call the target — always a clock time, so a
# duration shows you the wall-clock moment it resolved to.
TARGET="$(date -d "@$TARGET_EPOCH" '+%H:%M')"

# ---- terminal title: without this the tab just shows "bash countdown.sh"
# Terminated with ST (ESC \), not BEL — a BEL-terminated OSC would emit a
# bell character every second, which rings on terminals with the audio bell on.
set_title() { [[ -t 1 ]] && printf '\e]0;%s\e\\' "$1"; }

cleanup() {
    set_title "${SHELL##*/}"        # hand the title back to the shell
    printf '\e[?25h\e[0m\n'         # cursor on, attributes reset
    exit 0
}
trap cleanup INT TERM
printf '\e[?25l\e[2J'

pad() { printf '%*s' "$1" ''; }

# Fire every configured alert layer once. Anything unavailable is skipped
# without noise, so the same script works in a bare TTY and on a desktop.
alert() {
    local msg="$1" f

    if [[ "$ALERT_BELL" == 1 ]]; then
        for _ in 1 2 3 4 5; do printf '\a'; sleep 0.2; done
    fi

    if [[ "$ALERT_NOTIFY" == 1 ]] && command -v notify-send >/dev/null 2>&1 \
       && [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        notify-send -u critical -i alarm -a countdown \
            "${LABEL:-Countdown}" "$msg" >/dev/null 2>&1 &
    fi

    # Players are wrapped in timeout: with no real sink (a dummy auto_null
    # output, e.g. nothing plugged in) they block forever instead of failing.
    if [[ "$ALERT_SOUND" == 1 ]]; then
        local run=""
        command -v timeout >/dev/null 2>&1 && run="timeout 10"
        for f in "${ALERT_SOUNDS[@]}"; do
            [[ -r "$f" ]] || continue
            if   command -v pw-play >/dev/null 2>&1; then $run pw-play "$f" >/dev/null 2>&1 &
            elif command -v paplay  >/dev/null 2>&1; then $run paplay  "$f" >/dev/null 2>&1 &
            elif command -v aplay   >/dev/null 2>&1; then $run aplay -q "$f" >/dev/null 2>&1 &
            fi
            break
        done
    fi
}

# emit one big-digit string, row by row
draw() {
    local text="$1" hs="$2" vs="$3" color="$4"
    local r i b v c seg line
    local -a parts
    for ((r=0; r<5; r++)); do
        line=""
        for ((i=0; i<${#text}; i++)); do
            c="${text:i:1}"
            read -ra parts <<< "${SEG[$c]}"
            seg="${parts[$r]}"
            for ((b=0; b<${#seg}; b++)); do
                if [[ "${seg:b:1}" == "1" ]]; then
                    line+="\e[${color}m$(pad "$hs")\e[0m"
                else
                    line+="$(pad "$hs")"
                fi
            done
            line+="$(pad "$hs")"
        done
        for ((v=0; v<vs; v++)); do printf '%b\n' "$line"; done
    done
}

# on-screen width of a big-digit string
width() {
    local text="$1" hs="$2" i c w=0
    local -a parts
    for ((i=0; i<${#text}; i++)); do
        c="${text:i:1}"
        read -ra parts <<< "${SEG[$c]}"
        w=$(( w + ${#parts[0]} * hs + hs ))
    done
    echo $(( w - hs ))
}

print_digits() {
    local text="$1" hs="$2" vs="$3" color="$4" cols="$5"
    local w left
    w="$(width "$text" "$hs")"
    left=$(( (cols - w) / 2 )); [[ "$left" -lt 0 ]] && left=0
    draw "$text" "$hs" "$vs" "$color" | while IFS= read -r l; do
        printf '\e[K%*s%b\n' "$left" '' "$l"
    done
}

print_text() {
    local text="$1" cols="$2" style="${3:-2}"
    local left=$(( (cols - ${#text}) / 2 )); [[ "$left" -lt 0 ]] && left=0
    printf '\e[K%*s\e[%sm%s\e[0m\n' "$left" '' "$style" "$text"
}

expired=0
while :; do
    cols="$(tput cols  2>/dev/null || echo 80)"
    rows="$(tput lines 2>/dev/null || echo 24)"

    # every state renders 5 characters (HH:MM or MM:SS) = 18 cells wide
    # countdown at full scale, clock at half
    hs=$(( (cols - 4) / 18 ));   [[ "$hs" -lt 1 ]] && hs=1;   [[ "$hs" -gt 8 ]] && hs=8
    vs=$(( (hs + 1) / 2 ));      [[ "$vs" -lt 1 ]] && vs=1
    hs_s=$(( hs / 2 ));          [[ "$hs_s" -lt 1 ]] && hs_s=1
    vs_s=$(( (hs_s + 1) / 2 ));  [[ "$vs_s" -lt 1 ]] && vs_s=1

    now="$(date '+%H:%M')"
    left_secs=$(( TARGET_EPOCH - $(date +%s) ))

    # Adaptive precision: always the two most significant units. Seconds are
    # noise while hours remain, so they only appear inside the last hour.
    if [[ "$left_secs" -le 0 ]]; then
        digits="00:00"
        units="minutes : seconds"
        color=$COLOR_URGENT
        if [[ "$expired" -eq 0 ]]; then
            expired=1
            alert "$TARGET reached."
        fi
        [[ $(( $(date +%s) % 2 )) -eq 0 ]] && color=$COLOR_DONE
        footer="TIME'S UP  —  target $TARGET  ·  Ctrl+C to quit"
        set_title "TIME'S UP - $TARGET"
    else
        if [[ "$left_secs" -ge 3600 ]]; then
            printf -v digits '%02d:%02d' \
                $(( left_secs / 3600 )) $(( left_secs % 3600 / 60 ))
            units="hours : minutes"
            remaining="$(( left_secs / 3600 ))h $(( left_secs % 3600 / 60 ))m left"
        else
            printf -v digits '%02d:%02d' \
                $(( left_secs / 60 )) $(( left_secs % 60 ))
            units="minutes : seconds"
            remaining="$(( left_secs / 60 ))m $(( left_secs % 60 ))s left"
        fi
        if   [[ "$left_secs" -lt 300  ]]; then color=$COLOR_URGENT
        elif [[ "$left_secs" -lt 1800 ]]; then color=$COLOR_WARN
        else                                   color=$COLOR_NORMAL
        fi
        footer="target $TARGET$TOMORROW  ·  $remaining  ·  Ctrl+C to quit"
        set_title "${LABEL:+$LABEL — }$remaining -> $TARGET"
    fi

    # vertical centering
    label_h=0; [[ -n "$LABEL" ]] && label_h=2
    total=$(( 5 * vs_s + 1 + label_h + 5 * vs + 1 + 2 ))
    top=$(( (rows - total) / 2 )); [[ "$top" -lt 0 ]] && top=0

    {
        printf '\e[H'
        for ((k=0; k<top; k++)); do printf '\e[K\n'; done

        print_digits "$now" "$hs_s" "$vs_s" "$COLOR_CLOCK" "$cols"
        printf '\e[K\n'

        if [[ -n "$LABEL" ]]; then
            print_text "$LABEL" "$cols" "1"
            printf '\e[K\n'
        fi

        print_digits "$digits" "$hs" "$vs" "$color" "$cols"
        print_text "$units" "$cols" "2"

        printf '\e[K\n'
        print_text "$footer" "$cols" "2"
        printf '\e[J'
    }

    sleep 1
done
