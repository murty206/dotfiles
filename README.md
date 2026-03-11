# dotfiles

My portable shell aliases and configuration, works on any Linux distro.

## Contents

| File | Description |
|------|-------------|
| `aliases.sh` | All aliases, functions, and shell config |
| `install.sh` | One-command installer for new machines |

## Install on a new machine

```bash
curl -fsSL https://raw.githubusercontent.com/<your-username>/dotfiles/main/install.sh | bash
```

Then reload your shell:
```bash
source ~/.zshrc   # or source ~/.bashrc
```

The installer will:
- Install git if missing (supports apt, dnf, paru)
- Clone this repo to `~/.dotfiles`
- Hook `aliases.sh` into `~/.zshrc` and `~/.bashrc`

## Update aliases on any machine

```bash
update
```

Pulls latest from GitHub and reloads aliases instantly.

## What's in aliases.sh

| Section | Key aliases |
|---------|-------------|
| Navigation | `..` `...` `ll` |
| System | `cls` `reload` `hist` `df` `free` `cp` `mv` |
| Package management | `up` `i` `rm-pkg` `search` (auto-detects distro) |
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
```

## Adding new aliases

1. Edit `aliases.sh`
2. Commit and push to GitHub
3. Run `update` on any machine to pull changes
