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
| Kitty | GPU-accelerated terminal, Tokyo Night colors, config synced via dotfiles |
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
| `kitty.conf` | Kitty terminal config (Tokyo Night + JetBrains Mono) |
| `install.sh` | One-command installer |
| `README.md` | This file |

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

### Package management (auto-detects distro)
| Alias | Arch (paru) | Debian/Ubuntu (apt) | Fedora (dnf) |
|-------|-------------|---------------------|--------------|
| `up` | Full system upgrade + cleanup | `apt update && upgrade && autoremove` | `dnf upgrade && autoremove` |
| `i <pkg>` | Install package | `apt install` | `dnf install` |
| `rm-pkg <pkg>` | Remove package + deps | `apt remove --purge` | `dnf remove` |
| `search <pkg>` | Search for package | `apt search` | `dnf search` |
| `pkg-info <pkg>` | Show package info | `apt show` | `dnf info` |
| `als` | List all active aliases | same | same |

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
| `candown` | Bring down can0 |
| `canlog` | Dump live CAN traffic on can0 |
| `canstat` | Show detailed can0 interface info |

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

# Extract any archive format automatically
extract <file>
# Supports: .tar.gz .tar.bz2 .tar.xz .zip .7z .rar .gz .bz2 .xz

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
