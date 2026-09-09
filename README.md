# dotfiles

My portable shell environment. One command sets up everything on any Linux machine.

## What gets installed

| Component | Details |
|-----------|---------|
| zsh | Set as default shell |
| zsh-autosuggestions | Fish-like command suggestions as you type |
| zsh-syntax-highlighting | Colors valid commands green, invalid red |
| Starship | Tokyo Night prompt with automatic distro logo |
| JetBrains Mono Nerd Font | Installed system-wide for glyph support |
| Kitty | GPU-accelerated terminal, 1984 Dark colors, config synced via dotfiles |
| tty-clock | Full-screen terminal clock, run with `clock` |
| GitHub CLI (`gh`) | Repos, PRs and issues from the terminal. Needs one `gh auth login` per machine |
| Ookla Speedtest CLI | Official client, fetched from the vendor into `~/.local/bin` as `ookla-speedtest`. Run with `speed` |
| Claude Code | Slash commands and the global `CLAUDE.md`, symlinked from this repo |
| aliases.sh | Portable aliases and functions, auto-detects distro |

## Install on a new machine

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
```

The installer skips anything already set up, so it's safe to run multiple times.

> **Fresh machine?** Set up your SSH key first so you can push changes:
> ```bash
> ssh-keygen -t ed25519 -C "your@email.com"
> cat ~/.ssh/id_ed25519.pub
> # paste into: GitHub → Settings → SSH and GPG keys
> ```

### One identity per machine

The installer sets `user.name` / `user.email` **only if git has none**, and
points `mailmap.file` at this repo's `.mailmap` so every repo on the machine
reads one contributor instead of four.

An identity that is already set and *different* is reported and **left alone** —
a work machine that deliberately commits under another name is the mirror image
of the problem this prevents, and silently rewriting it would be the worse of
the two failures. The line repeats on every `update` until the machine is fixed
by hand, which is the same nudge the unlinked-command warning uses.

To install under a different identity on purpose:

```bash
GIT_NAME="..." GIT_EMAIL="..." bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
```

`.mailmap` changes no commit — it is read at display time by `log`, `shortlog`
and `blame`. GitHub's own interface does not read it.

### The one step that stays manual

`gh auth login` needs a device code and a browser, so no installer can do it.
What the installer does instead: it notices, **asks whether to run it now**, and
if you decline it says so again in the closing summary. `update` repeats the
line on every run until the machine is logged in — the same nag mechanism as the
identity warning above, for the same reason: a reminder that fires once is a
reminder you miss once.

## Update on any machine

```bash
update
```

Pulls latest from GitHub and reloads aliases instantly. No restart needed.

## Files

| File | Description |
|------|-------------|
| `aliases.sh` | All aliases, functions, and shell config |
| `countdown.sh` | Full-screen countdown clock, backs the `countdown` alias |
| `claude-statusline.sh` | Claude Code status line — installed by hand, not by `install.sh` |
| `STATUSLINE.md` | Full status line reference: segments, toggles, fonts, Windows, troubleshooting |
| `claude-commands/` | Claude Code slash commands — symlinked into `~/.claude/commands/` (see below) |
| `claude-session-context.sh` | `SessionStart` hook — says whether the context is fresh, counts compactions |
| `claude-global.md` | Global `CLAUDE.md` — symlinked to `~/.claude/CLAUDE.md`, loaded in every project |
| `WINDOWS.md` | Setting up the Claude Code pieces on Windows — by hand, and why |
| `kitty.conf` | Kitty terminal config (1984 Dark + JetBrains Mono) |
| `starship.toml` | Starship prompt config (Tokyo Night) |
| `install.sh` | One-command installer |
| `.mailmap` | Collapses four accumulated git identities into one, for `log`/`shortlog`/`blame` (see below) |
| `dev_log.md` | What each session decided and why, newest first |
| `next_steps.md` | The queue — open items with the reason each is open |
| `local.sh` | Machine-local aliases — gitignored, never pushed (see below) |
| `README.md` | This file |

### Machine-local aliases

This repo is public, so nothing host-specific goes in it — no absolute home
paths, no project shortcuts, no secrets. Put those in `~/.dotfiles/local.sh`,
which is gitignored and sourced automatically at the end of `aliases.sh`:

```bash
# ~/.dotfiles/local.sh
alias myproject='cd /path/on/this/machine && ./run.sh'
```

Keeping it out of the tracked files also keeps `update` working — a dirty
`aliases.sh` makes `git pull --rebase` refuse, which aborts the whole update.

---

## Claude Code status line

```
myproject/src [main] | Opus 5 ⚡ | 124k/1M 12% █░░░░░░░░░ · █████░░░░░ 55% · 3h35m [13:50] · 7d 16%
```

Directory, git branch, model, context window, and both quota windows with the
time until the five-hour one resets. Deliberately **not** installed by
`install.sh` — `~/.claude/settings.json` holds your permission rules and project
paths, and an installer has no business merging itself into it. Two steps:

```bash
ln -sf ~/.dotfiles/claude-statusline.sh ~/.claude/statusline-command.sh
```

then add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

**[STATUSLINE.md](STATUSLINE.md)** has the rest: what every segment means, the
six toggles for narrower terminals, font installation on each platform, how to
get it running on Windows, and troubleshooting.

---

## Claude Code slash commands

Every `.md` file in `claude-commands/` becomes a slash command on every machine,
symlinked into `~/.claude/commands/`. Unlike the status line these need no
`settings.json` edit — a file there is picked up by its name alone — so
`install.sh` sets them up, and `update` links anything the repo has gained since.
`claude-global.md` rides the same mechanism into `~/.claude/CLAUDE.md`, which
Claude Code loads in **every** project on the machine.

That last one is why this repo being public is a live constraint rather than a
formality: a line added to `claude-global.md` is read by every agent in every
project, and published. It is deliberately close to empty — see the file itself
for the bar a rule has to clear before it goes in.

| Command | What it does |
|---------|--------------|
| `/acilis` | Opens a session: stamps the start time, reads the queue, and begins on the top item |
| `/kapanis` | Closes it: writes the log entry with its rationale, updates the queue, commits |

**They are a pair.** `/acilis` writes the start time to `.claude/session-start`
in the project; `/kapanis` reads it back, works out the duration, and deletes the
file. The file's existence *is* the state — present means a session is open — so
neither command has to ask you what time you started, and neither needs a rule
about work that runs past midnight.

Both take the clock from the machine, through Claude Code's
`` !`command` `` injection, which runs before the file reaches the model. So
`/kapanis` on its own is enough; pass `[HH:MM]` only to override the end time
when you are closing a session well after it actually ended.

Run `/clear` **before** `/acilis`. A slash command is a prompt, so it cannot
clear for you — `/clear` would erase the prompt mid-run.

### The session-context hook

`/acilis` does not take your word for it that the context is fresh, because
**`--continue` and `--resume` do not clear it** and a compaction only shortens
it. `claude-session-context.sh` runs on `SessionStart` and prints one line that
Claude reads:

| Line | When |
|---|---|
| `session-context: FRESH` | `startup` or `clear` |
| `session-context: CARRIED OVER` | `resume` or `fork` |
| `session-context: COMPACTED — compaction N` | `compact`, with a running count |

On the second compaction it adds an `ACTION` line telling the agent to say,
unprompted and once, that the session has outgrown its question — and to
**split** it rather than simply close it: name the finished part, close that
with `/kapanis`, queue the rest, then `/clear` and `/acilis`. Closing without
splitting writes a half-entry into the log, which is the failure the warning
exists to prevent rather than a milder form of it. The count resets on the next
`FRESH`. State lives in `.claude/compact-count` next to `.claude/session-start`;
gitignore both.

It takes the kind of start as an argument rather than reading stdin — the
matcher values are documented, a `source` field in the payload is not. Wire it
up by hand, like the status line, since `settings.json` is personal:

```bash
ln -sf ~/.dotfiles/claude-session-context.sh ~/.claude/session-context.sh
```

`SessionStart` goes inside the top-level `"hooks"` object — beside it, it is
still valid JSON and is ignored silently:

```json
"hooks": {
  "SessionStart": [
    { "matcher": "startup|clear",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh startup-or-clear" }] },
    { "matcher": "resume|fork",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh carried-over" }] },
    { "matcher": "compact",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh compact" }] }
  ]
}
```

On **Windows** none of this is automatic — `install.sh` and `update` are not run
there, because `ln -s` quietly copies instead of linking and the automation would
stop working without saying so. **[WINDOWS.md](WINDOWS.md)** is the by-hand
setup: the status line, these commands, the hook, and how to keep them current.

A project can define its own `/acilis` or `/kapanis` in its `.claude/commands/`,
and that copy wins. The ones here are the generic fallback: they search for a
log and a queue by the usual names instead of knowing them. Add
`.claude/session-start` to the project's `.gitignore` — it is state, not history.

Nothing host-specific may go in these files; this repo is public. A command that
needs to name a real project belongs in that project, not here.

---

## Aliases reference

### Navigation
| Alias | Command | Description |
|-------|---------|-------------|
| `..` | `cd ..` | Go up one directory |
| `...` | `cd ../..` | Go up two directories |
| `....` | `cd ../../..` | Go up three directories |
| `ll` | `ls -lah` | Long list with hidden files and human sizes |
| `ls` | `ls --color=auto` | Colorized ls |
| `grep` | `grep --color=auto` | Colorized grep |

### System
| Alias | Description |
|-------|-------------|
| `cls` | Clear the terminal |
| `reload` | Reload shell config without opening new terminal |
| `path` | Print `$PATH` with one directory per line |
| `hist <keyword>` | Search command history — e.g. `hist git` |
| `ports` | Show all open ports and listening services |
| `myip` | Show your public IP address |
| `df` | Disk usage in human readable format |
| `du` | Directory size in human readable format |
| `free` | RAM usage in human readable format |
| `watch` | Run a command every 1s (default is 2s) |
| `cp` | Copy with confirmation prompt and verbose output |
| `mv` | Move with confirmation prompt and verbose output |
| `mkdir` | Create directory including all parents, verbose |
| `clock` | Full-screen terminal clock, centered, blinking colon (`q` to quit) |
| `countdown <HH:MM \| duration> [label]` | Full-screen countdown to a time of day or after a duration — see below |

### Package management (auto-detects distro)
| Alias | Arch (paru) | Debian/Ubuntu (apt) | Fedora (dnf) |
|-------|-------------|---------------------|--------------|
| `up` | Full system upgrade + cleanup | `apt update && upgrade`, then autoremove **only after showing the plan and asking** — see below | `dnf upgrade && autoremove` |
| `i <pkg>` | Install package | `apt install` | `dnf install` |
| `rm-pkg <pkg>` | Remove package + deps | `apt remove --purge` | `dnf remove` |
| `search <pkg>` | Search for package | `apt search` | `dnf search` |
| `pkg-info <pkg>` | Show package info | `apt show` | `dnf info` |
| `als` | List all active aliases | same | same |

On Debian/Ubuntu `up` is a function, not an alias. It upgrades, then prints what
`autoremove` would delete and waits for a `y` — it never removes packages
unattended. A package that has dropped out of the archive is indistinguishable
from garbage to `autoremove`, and an interpreter some venv depends on, or a
library a hand-built binary links against, is exactly that kind of package.

Set `UP_KEEP` in `local.sh` to an extended regex of names that must never be
removed on that machine; a match turns the prompt into a flat refusal:

```bash
# ~/.dotfiles/local.sh
UP_KEEP='python3\.11|libav|libvpx'
```

### Power / reboot
| Alias | Description |
|-------|-------------|
| `r` | Reboot safely |
| `poweroff` | Power off safely |
| `poweroff-timer-on` | Enable auto poweroff at 17:00 on weekdays |
| `poweroff-timer-off` | Disable auto poweroff timer |

### Systemd
| Alias | Description |
|-------|-------------|
| `svs <service>` | Show service status |
| `sr <service>` | Restart a service |
| `sS <service>` | Start a service |
| `st <service>` | Stop a service |
| `sl` | List all running services |
| `jl` | Show recent journal logs with errors |
| `jf <service>` | Follow live logs for a service |

### Editor / sudo
| Alias | Description |
|-------|-------------|
| `e <file>` | Open file in nano |
| `_` | Shorthand for sudo — e.g. `_ reboot` |

### Python
| Alias | Description |
|-------|-------------|
| `py` | Run python |
| `py3` | Run python3 explicitly |
| `venv` | Create `.venv` if missing, then activate it |
| `activate` | Activate existing `.venv` |
| `pipi <pkg>` | pip install with `--break-system-packages` |
| `pipr` | Install from `requirements.txt` |

### Git
| Alias | Description |
|-------|-------------|
| `g` | git |
| `gs` | git status |
| `ga` | git add . |
| `gc "message"` | git commit -m |
| `gp` | git push |
| `gpl` | git pull |
| `gl` | Pretty oneline log with graph and branches |
| `gd` | git diff |
| `gb` | List branches |
| `gco <branch>` | git checkout |

### CAN bus / embedded dev
| Alias | Description |
|-------|-------------|
| `canup [iface] [bps]` | Bring up CAN interface — defaults: `can0`, `500000` |
| `candown [iface]` | Bring down CAN interface — default: `can0` |
| `canlog [iface] [id]` | Dump live CAN traffic — optional CAN ID filter (e.g. `canlog can0 1A0`) |
| `canstat [iface]` | Show detailed CAN interface info — default: `can0` |

### Network
| Alias | Description |
|-------|-------------|
| `ports` | Show all listening ports |
| `myip` | Show public IP |
| `pingg` | Ping Google DNS 4 times |
| `flushdns` | Flush DNS cache |
| `speed` | Internet speed test (~30s); `speed -f json` for machine-readable output, `speed -L` to list servers |

---

## Functions reference

```bash
# Cheat sheet lookup
cs <topic>
# Examples:
cs tar         # show tar usage
cs git         # show git cheatsheet
cs python      # show python cheatsheet

# Make directory and enter it
mkcd <dirname>

# Create and activate virtual environment
# Creates .venv if it doesn't exist, then activates it
venv

# Bring up CAN interface with optional args
canup              # defaults: can0 at 500000 bps
canup can1         # can1 at 500000 bps
canup can0 250000  # can0 at 250000 bps

# Bring down CAN interface
candown            # default: can0
candown can1

# Dump live CAN traffic, optionally filter by CAN ID
canlog                # all frames on can0
canlog can0 1A0       # only frames with ID 0x1A0

# Show detailed CAN interface info (link state, bitrate, error counters)
canstat            # default: can0
canstat can1

# Extract any archive format automatically
extract <file>
# Supports: .tar.gz .tar.bz2 .tar.xz .zip .7z .rar .gz .bz2 .xz

# Countdown to a time of day, or after a duration, full screen
countdown 18:30                  # wall-clock time; tomorrow if already past
countdown 25m                    # 25 minutes from now
countdown 1h30m                  # hours and minutes
countdown 90s                    # seconds
countdown 25                     # a bare number means minutes
countdown 18:30 "Standup"        # second argument is a label above the digits
countdown                        # prints usage
COUNTDOWN_NO_HINT=1 countdown 17:00   # drop the "Ctrl+C to quit" hint from the
                                 # footer — for places the keyboard never reaches
                                 # this process, e.g. behind a locked screensaver
COUNTDOWN_MENU_TIMEOUT=90 countdown 25m    # seconds on 00:00 before the clock
                                 # takes over; 0 stays on 00:00 for good
COUNTDOWN_CMD='mpv ~/alarm.mp3' countdown 25m   # command offered under [x] in
                                 # the menu at zero; unset hides the key
# The rule is one character: an argument containing ":" is a wall-clock time,
# anything else is a duration. So "1:30" is half past one on the clock, not
# one and a half hours — write 1h30m for that. The footer always shows the
# resolved clock time, marked "(tomorrow)" when it landed on the next day,
# so a misread is visible on the first frame.
# Current time sits above the countdown at half scale, with the date in plain
# text above that. The digits scale to whichever axis runs out first, so the
# same script fills a 1024x768 panel and a 1920x1080 one; on a window too short
# for everything it drops the date first, then the clock, and keeps the
# countdown and footer down to a 30x9 terminal.
# Precision adapts — always the two most significant units, so seconds
# only show up once under an hour:
#   05:24  hours : minutes      (more than an hour to go)
#   44:57  minutes : seconds    (inside the last hour)
# Digits go cyan -> yellow (last 30 min) -> red (last 5 min).
# At zero it fires three alert layers, each skipped silently if unavailable:
# terminal bell (PC-speaker buzzer in a bare TTY, window urgency hint in
# kitty), a notify-send desktop notification, and a sound through the sound
# server. Toggle them with ALERT_* at the top of countdown.sh.
# Zero is not the end of the screen — the footer turns into a menu:
#   r  restart, same duration from now or the target's next occurrence
#   c  switch to the clock now
#   x  run $COUNTDOWN_CMD, shown only if one is set
#   q  quit
# Left alone it falls back to a full-screen clock after 30 seconds, so a
# finished countdown leaves something useful on the monitor rather than a
# blinking 00:00. The menu needs a keyboard, so it is skipped where
# COUNTDOWN_NO_HINT is set or stdin is not a terminal — there the clock takes
# over on the same timer.
# Target already passed today means tomorrow.
# The remaining time is mirrored into the terminal title. Ctrl+C to quit.

# Quick file backup
bak <file>         # creates file.bak

# Pull latest dotfiles and reload aliases
update
```

---

## Adding new aliases

```bash
nano ~/.dotfiles/aliases.sh
cd ~/.dotfiles
git add aliases.sh
git commit -m "add new alias"
git push
# then on other machines:
update
```
