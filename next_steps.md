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

## 3 — The `setopt` block errors on every bash start

`aliases.sh` lines 20-23 set zsh history options. Bash does not have `setopt`,
so a Git Bash session prints four `command not found` lines before it gets to
anything useful. Harmless — the file is sourced to the end and every alias below
still lands — but it is noise on every single shell open, and noise on startup
is how a real error learns to hide.

Guard the block with `[ -n "$ZSH_VERSION" ]`. Nothing else in the file is
shell-specific; this is the only place bash is asked to run zsh syntax.

---

## Notes

**These three were found together**, by asking one question on 2026-09-08 —
*"will my aliases work under Windows?"* — and then measuring instead of
answering from the shape of the file. Two of them (2 and 3) are invisible
without running it: one resolves and fails later, the other fails loudly in a
place nobody reads.
