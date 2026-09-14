# dotfiles — Next Steps

Opened 2026-09-09. Fixed name, repo root — the convention settled in
`becoming_power_user` on 2026-09-08: *every project has `dev_log.md` and
`next_steps.md`; look at the repo root first, then `docs/`.* This repo was the
control case in that decision, the one with a `CLAUDE.md` and neither document.

Items are written when they are born, not at session close. **Filing an item is
not scheduling it** — the three below wait their turn, and the order here is not
a priority call.

---

## 1 — Nothing sources `aliases.sh` on Windows

`install.sh` appends the hook line to `~/.zshrc` and `~/.bashrc`, and it never
runs on Windows. The `~/.bashrc` created on this machine 2026-09-08 carries only
the `MSYS` export, so a Git Bash session there currently has **zero** aliases.

One line fixes it:

```bash
echo '[ -f ~/.dotfiles/aliases.sh ] && source ~/.dotfiles/aliases.sh' >> ~/.bashrc
```

**Measured before filing, so the item knows what it is buying** — sourced under
Git Bash on Windows 11, 2026-09-09: **35 of 53 aliases resolve, 18 do not.**

| Group | Count | Why |
|---|---|---|
| systemd family | 12 | `systemctl` ×9, `journalctl` ×2, `resolvectl` ×1 |
| Linux tools absent from Git Bash | 3 | `free`, `ss` (`ports`), `watch` |
| Simply not installed here | 2 | `tty-clock` (`clock`), `ookla-speedtest` (`speed`) |
| Interpreter name | 1 | `py3` → `python3`, which Git Bash does not have |

Everything else works, including all ten git aliases, the navigation ones,
`ll`/`ls`/`grep`/`cp`/`mv`/`mkdir`, `myip`, `pipi`/`pipr`, `countdown`, `hist`
and `path`. `sudo` resolves too — Windows 11 ships one now.

Functions: `cs`, `bak`, `mkcd` fine; `extract` partial (`tar`/`unzip`/`gunzip`/
`bunzip2` present, `7z`/`unrar` not); the four CAN bus helpers are dead, which
is expected — they need `ip` and `candump`.

**The open question is not whether to add the line, it is where.** Doing it by
hand repeats the `WINDOWS.md` problem: a step nothing enforces, forgotten on the
next machine. Options: a step in `WINDOWS.md` §4 beside the git identity lines,
or a guarded branch in `install.sh` that recognises MSYS and stops short of the
parts that need a package manager.

## 2 — `venv` and `activate` use the Linux path unconditionally

```bash
alias activate='source .venv/bin/activate'
function venv() { [ ! -d .venv ] && python -m venv .venv; source .venv/bin/activate; }
```

On Windows the path is `.venv/Scripts/activate`. Both resolve — `source` is a
builtin, so nothing reports a missing command — and both fail at the moment they
are used. **This is not hypothetical here:** the `factory-backend` project runs
`.venv/Scripts/python.exe` and its Claude Code settings carry
`Bash(.venv/Scripts/pip install:*)`.

The fix is the repo's own rule applied to itself — `feedback_os_aware` in that
project's memory says code runs on both platforms — so: prefer
`.venv/Scripts/activate` when it exists, fall back to `.venv/bin/activate`. One
branch, inert on Linux.

## 3 — The `setopt` block errors on every bash start — **DONE 2026-09-14**

Fixed: the whole *Zsh history* block is now guarded with `[ -n "$ZSH_VERSION" ]`.
Numbers here are left standing rather than closed up, because `dev_log.md`
already cites these items as “#1, #2, #3” and renumbering would break that.

**It was larger than this item said, and the extra part was the silent half.**
The item named the four `setopt` lines, which fail loudly. `HISTFILE` two lines
above them fails *quietly*: it is a bash variable as much as a zsh one, so bash
accepts `~/.zsh_history` and writes its own history there, abandoning
`~/.bash_history` with no message. Measured on Windows 11 / Git Bash,
2026-09-14 — `bash -lic 'HISTFILE=/tmp/p; history -s m; history -w'` puts the
marker in the named file, so the assignment is live and not decorative.

**That reorders the queue: #3 had to land before #1.** Adding the source line
from #1 to a `~/.bashrc` with the block unguarded would not just have printed
the four errors, it would have moved this machine’s bash history into a zsh
file. `~/.zsh_history` does not exist on this box yet — which is only true
*because* nothing sources `aliases.sh` here. Fixing #1 first would have created
the bug and hidden its own cause.

Rationale and the verification in `dev_log.md`, 2026-09-14.

## 3b — Should bash get the large history too?

Born 2026-09-14 while fixing #3, and filed rather than decided — it is a
preference, not a defect.

The guard means bash now keeps bash’s defaults: 500 lines, `~/.bash_history`.
`HISTSIZE=10000` means the same thing in both shells, so a bash arm could have
it for free; `HISTFILE`/`SAVEHIST` could not be shared, they need
`~/.bash_history` and `HISTFILESIZE`. Doing nothing is a defensible answer —
Git Bash here is an occasional shell, and 500 may be plenty.

---

## Notes

**These three were found together**, by asking one question on 2026-09-08 —
*"will my aliases work under Windows?"* — and then measuring instead of
answering from the shape of the file. Two of them (2 and 3) are invisible
without running it: one resolves and fails later, the other fails loudly in a
place nobody reads.
