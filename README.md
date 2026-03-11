# dotfiles

My portable shell environment. One command sets up everything on any Linux machine.

## What gets installed

| Component | Details |
|-----------|---------|
| zsh | Set as default shell |
| zsh-autosuggestions | Fish-like command suggestions |
| zsh-syntax-highlighting | Command highlighting as you type |
| Starship | Tokyo Night prompt with distro logo |
| JetBrains Mono Nerd Font | Installed system-wide |
| Kitty | GPU terminal, Tokyo Night colors, config synced via dotfiles |
| aliases.sh | Portable aliases and functions |

## Install on a new machine

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
```

The installer skips anything already set up, so it's safe to run multiple times.

## Update aliases on any machine

```bash
update
```

Pulls latest from GitHub and reloads aliases instantly.

## Files

| File | Description |
|------|-------------|
| `aliases.sh` | All aliases, functions, and shell config |
| `kitty.conf` | Kitty terminal config (Tokyo Night + JetBrains Mono) |
| `install.sh` | One-command installer |

## What's in aliases.sh

| Section | Key aliases |
|---------|-------------|
| Navigation | `..` `...` `ll` |
| System | `cls` `reload` `hist` `df` `free` `cp` `mv` `watch` |
| Package management | `up` `i` `rm-pkg` `search` `pkg-info` (auto-detects distro) |
| Power | `r` `poweroff` `poweroff-timer-on/off` |
| Systemd | `svs` `sr` `sS` `st` `sl` `jl` `jf` |
| Python | `py` `venv` `activate` `pipi` `pipr` |
| Git | `g` `gs` `ga` `gc` `gp` `gpl` `gl` `gd` `gb` `gco` |
| CAN bus | `canup` `candown` `canlog` `canstat` |
| Network | `ports` `myip` `pingg` `flushdns` |
| Functions | `cs` `mkcd` `venv` `extract` `bak` `canup` |

### Package manager detection

`up`, `i`, `rm-pkg`, `search`, and `pkg-info` automatically map to the right tool:

| Distro | Tool |
|--------|------|
| Arch Linux | paru |
| Debian / Ubuntu | apt |
| Fedora / RHEL | dnf |

### Useful functions

```bash
cs <topic>          # cheat sheet lookup — cs tar, cs git, cs python
mkcd <dir>          # mkdir + cd in one
venv                # create .venv if needed, then activate
canup [iface] [bps] # bring up CAN interface — defaults: can0, 500000
extract <file>      # extract any archive format
bak <file>          # quick backup — appends .bak
update              # pull latest dotfiles from GitHub and reload
```

## Adding new aliases

```bash
e ~/dotfiles/aliases.sh
cd ~/dotfiles && git add . && git commit -m "new aliases" && git push
# then on other machines:
update
```
