# dotfiles — Next Steps

Opened 2026-09-09. Fixed name, repo root — the convention settled in
`becoming_power_user` on 2026-09-08: *every project has `dev_log.md` and
`next_steps.md`; look at the repo root first, then `docs/`.* This repo was the
control case in that decision, the one with a `CLAUDE.md` and neither document.

Items are written when they are born, not at session close. **Filing an item is
not scheduling it** — the three below wait their turn, and the order here is not
a priority call.

---

## 1 — Nothing sources `aliases.sh` on Windows — **DONE 2026-09-14**

The measurement below is kept as the record. What it was buying is now bought.

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

### How it was answered

**The open question was not whether to add the line, it was where.** murty chose
the second option: **a guarded branch in `install.sh`**, over a step in
`WINDOWS.md`. The argument against the page was its own: a step nothing enforces
is forgotten on the next machine, which is what this item *was*.

Both halves are done.

- **This machine**, by hand, 2026-09-14 — the line is in `~/.bashrc` and a login
  shell now reports 54 aliases (52 from `aliases.sh`, plus Git Bash's own `node`
  and `winget`). It went in *before* the installer branch existed, so running
  `install.sh` here now reports *"Already hooked"*, which is correct.
- **The next machine**, by `install.sh` — it recognises MSYS and stops short of
  the sections that need a package manager.

**What the branch turned up, and it is the part worth remembering.** The first
version of it printed three green *"symlinked from dotfiles"* ticks and produced
three plain copies, because the shell running it had no
`winsymlinks:nativestrict`. That is precisely the failure `WINDOWS.md` exists to
warn about — reproduced by the automation written to replace the by-hand install
it warned you to do instead. The branch now exports `nativestrict` for its own
process, **probes** for the privilege before touching anything, and stops with
the Developer Mode instruction if it cannot link. It also appends the export to
`~/.bashrc`, because covering only its own process leaves the machine
half-configured with nothing to show it.

`WINDOWS.md` is updated to match, including its symlink test, which was broken:
`ln -s /etc/hostname /tmp/lntest` fails on Git Bash because there is no
`/etc/hostname` there, so the documented capability check failed on a machine
where the capability works. Met first-hand at the start of this session.

Rationale and verification in `dev_log.md`, 2026-09-14.

## 1c — `update` is not used on Windows — **DECIDED 2026-09-14, not a task**

**murty: *"zaten çalıştırmak gibi bir niyetim de yok, Windows'ta her şey manuel
olabilir."*** So this is closed as a decision, not as a test that was run. It was
filed hours earlier as *"has never been run on Windows"*, which framed it as a
gap to fill; it is not one. `git pull` by hand is the supported path here and
`WINDOWS.md` already says so.

**The scope of that, because it is narrow.** It settles `update` on Windows. It
does not undo the `install.sh` branch — that was chosen deliberately in this same
session, after the trade-off was put, and its argument stands: an installer runs
**once** on a new machine, where a forgotten manual step costs you a box with no
aliases. `update` runs **repeatedly** on a machine already working, where manual
is merely tedious. Different frequency, different answer.

**One thing found by reading it, kept below because it is real.** The
string-vs-file mailmap comparison that `ca9646c` fixed in `install.sh` is still
present in `update()`. It is **inert while nobody runs `update` here** — on Linux
the two spellings agree — so it is recorded rather than chased.

### What reading it turned up (unrun, and now unlikely to run)

It is *reachable* for the first time: the aliases load, so the name
resolves. But `update` does more than `git pull` — it re-checks the symlinks and
warns about files that are copies, and none of that has been exercised under
MSYS. `WINDOWS.md` now says to use `git pull` on this platform until someone
runs `update` here and writes down what happened.

### A prediction, written before the run

Read off the function on 2026-09-14 and **recorded before anyone ran it**, so
the run is a test of the reading and not a description of the result. Four
things are expected, in the order they would print. If the run disagrees, the
run is right.

1. **`kitty.conf` — a false success line.** `~/.config` exists on this box but
   `~/.config/kitty` does not, so `ln -sf` should fail with *No such file or
   directory*. The `echo "→ kitty.conf symlinked"` that follows is **not guarded
   on it**, so the error and the success line should both appear.
2. **`starship.toml` — a pointless symlink that succeeds.** `~/.config` does
   exist, so this one should work, and link a config for a program not installed
   here.
3. **`mailmap` rewritten on every run.** The same string-vs-file comparison that
   `ca9646c` fixed in `install.sh` is **still here**, unfixed — `git config`
   reads back `C:/Users/...` and `$DOTFILES_DIR` says `/c/Users/...`, so the test
   can never match. Expect `→ git mailmap pointed at dotfiles` every single time.
4. **Six lines of package-manager noise.** `ensure_tty_clock`, `ensure_gh` and
   `ensure_speedtest` each print *"not found — installing…"* and then *"No
   supported package manager"*. Expected on this platform, and the pair reads as
   a failure rather than as a skip — the same distinction `install.sh`'s Windows
   summary was given *"Not attempted"* for.

**Item 3 is the one that matters**, because it is a known bug in a second
location: fixing `install.sh` and not `update` is how the two drift, and this
repo already has a refuted-claim entry about exactly that pair being assumed to
be in step when they were not.

**Left unfixed on purpose**, and that is a choice rather than an oversight: the
decision above means the line never executes on the only platform where it is
wrong. Fixing it would be one character of real change and a comment explaining a
platform this function is no longer claimed to serve. If `update` is ever wanted
here, this is the first thing to fix and the prediction above is the test.

## 2 — `venv` and `activate` use the Linux path unconditionally — **DONE 2026-09-14**

Fixed to the spec as filed: `.venv/Scripts/activate` preferred, `.venv/bin/activate`
as the fallback, one branch, inert on Linux.

`activate` is now a **function rather than an alias**, because an alias cannot
carry a branch legibly, and `venv()` calls it instead of repeating the paths.
Two knock-on effects, neither a problem but both worth knowing:

- **The alias count is 52, not 53.** The alias audit's "35 of 53" is unchanged as
  a *result* — `activate` was in the working 35 by resolution only, which was the
  bug — but the denominator has moved, so a re-run compares 52 aliases plus one
  more function.
- **`venv()` reports failure now.** It gained the `else` arm for free, and
  `python -m venv` failing no longer falls through to a confusing `source` error.

Measured on Windows 11 / Python 3.14.3, 2026-09-14: `python -m venv --without-pip
.venv` produces `Include Lib Scripts pyvenv.cfg` and **no** `bin`, and
`Scripts/activate` is a POSIX script Git Bash sources unmodified.

Rationale and the four verification cases in `dev_log.md`, 2026-09-14.

## 2b — `venv()` calls `python`, which some Linux hosts do not have

Born 2026-09-14 while fixing #2, and **not** verified from Windows — noting it
rather than guessing at it.

`python -m venv .venv` was already there and was not touched. It is correct on
this box (`/c/Python314/python`, and there is no `python3` here at all, which is
why the `py3` alias is in #1's broken 18). On a Linux host that ships only
`python3` the same line fails. Whether that is any of murty's machines is a
one-command check *there*, not here:

```bash
command -v python || echo "python absent - venv() needs python3"
```

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
