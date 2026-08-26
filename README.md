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
| `kitty.conf` | Kitty terminal config (1984 Dark + JetBrains Mono) |
| `starship.toml` | Starship prompt config (Tokyo Night) |
| `install.sh` | One-command installer |
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
myproject/src [main] | Opus 5 · 1M ⚡ | 124k/1M 12% █░░░░░░░░░ · █████░░░░░ 55% · 3h35m [13:50] · 7d 16%
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
