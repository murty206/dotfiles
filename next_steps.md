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

**Run on this Arch box, 2026-09-24** — `python` is present: `/usr/bin/python`,
owned by `python 3.14.7-1`, resolving to `/usr/bin/python3.14`. `python3` is
there too, at `/usr/bin/python3`. **So `venv()` works here, and the item does
not close on that** — the exposure was never this machine. It is the apt branch:
Debian and Ubuntu ship `python3` and no bare `python` unless `python-is-python3`
is installed, and `aliases.sh` has an apt branch precisely because such a host
is expected.

**Not measured:** any apt or dnf host. Nothing here can speak for them, which is
the whole reason the item says the check belongs *there*.

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

## 3b — Should bash get the large history too? — **DONE 2026-09-14, yes**

murty's call. An `else` arm gives bash `HISTSIZE=10000` and `HISTFILESIZE=10000`.

**`HISTFILE` is deliberately not set in that arm**, and the comment in the file
says why: bash's own default is `~/.bash_history` and it is already correct, so
naming it there would buy nothing and offer one more chance to point it at the
wrong file — which is precisely the bug #3 was fixing.

So the two arms are not symmetric and cannot be: `HISTSIZE` means the same in
both, `SAVEHIST` is zsh's name for what bash calls `HISTFILESIZE`, and `HISTFILE`
belongs to zsh alone here. That asymmetry is the reason it is an `if/else` rather
than three shared lines lifted above the guard.

Verified in a login shell: `HISTSIZE=10000`, `HISTFILESIZE=10000`,
`HISTFILE=~/.bash_history`, `SAVEHIST` empty, stderr clean, 54 aliases.

---

## 4 — makepkg's `debug` option is off on this box only

Filed 2026-09-21. `~/.config/pacman/makepkg.conf` here carries
`OPTIONS=(… !debug lto)`, because with `debug` on, makepkg's *"Copying source
files needed for debug symbols"* step walks every file in the package — measured
that day at 287,040 files for `tela-circle-icon-theme-git` (`find pkg -type f |
wc -l`), several minutes for a package that has no symbols — and it produces
`-debug` packages nobody installs on purpose (`paru-debug` was one). The file is
user-level and machine-local; the next Arch box will not have it.

Open question, not decided: should `install.sh` ship it for hosts where
`makepkg` exists, the way it ships `kitty.conf`? The argument for is item #1's —
a step nothing enforces is a step the next machine misses. The argument against
is that it is a *build* setting, and this repo has stayed out of those.

## 5 — The session-context hook is not installed on this machine

Filed 2026-09-24, found by `/acilis` failing its own first check: no
`session-context:` line was printed, so the freshness check fell back to judging
the conversation by eye.

`claude-session-context.sh` is in the repo and `README.md` documents its
installation — a symlink into `~/.claude/` plus a `hooks` block in
`settings.json`. **Neither exists here.** Verified 2026-09-24 on this Arch box:
`~/.claude/session-context.sh` absent, and `grep -c '"hooks"'` returns **0** for
both `settings.json` and `settings.local.json`.

**This is item #1's shape again, one layer up.** #1 was a step nothing enforces,
missed on the next machine; the answer chosen there was a guarded branch in
`install.sh` over a page in `WINDOWS.md`. This is the same thing: the hook's
install lives in prose and the prose was not followed. The symmetry is the
argument, but the decision is not made here.

Open question, not decided: should `install.sh` write the `hooks` block into
`~/.claude/settings.json`? It already symlinks `CLAUDE.md` and the statusline, so
the symlink half is uncontroversial; the half that needs a call is **editing a
JSON file Claude Code also writes to**, which is a different risk from appending
a line to `~/.zshrc`.

**What it costs while open:** `/acilis` cannot tell a fresh context from a
carried-over one on this machine, which is the check the whole ritual is gated
on. It falls back to reading the conversation, and that fallback is the agent's
judgment rather than a fact from the harness.

**And the second cost landed at the close of the very session that filed this,
which is worth recording because it is not recoverable.** `/kapanis` asks for
`.claude/compact-count` — how many times the context was compacted — and that
counter is written by the same missing hook. So the session's own entry says
*"compactions: unknown"*. It is the one field that says whether a session was the
right size, the next fresh start resets it, and a number not written at close is
a number that never existed. Two sessions in a row have now logged that gap.

## 6 — No image viewer on a fresh KDE box — **DONE 2026-09-24**

Filed 2026-09-24, from a complaint with a one-line cause: *"bilgisayarımda
fotoğraf görüntüleyici yok."* Measured before filing — 19 common viewers
searched on `PATH`, **zero** found, and `xdg-mime query default` returned
`chromium.desktop` for both `image/jpeg` and `image/png`. Every double-clicked
photo was opening in the browser.

**Fixed on this box by hand:** `gwenview` installed (26.08.1-1, 6.62 MiB down,
11.46 MiB installed). Only one of its dependencies was missing — `kimageannotator`;
`baloo`, `cfitsio`, `exiv2`, `libkdcraw`, `purpose` and `qt6-multimedia` were
already present on a Plasma box, which is what made it the cheap choice here.

**No `xdg-mime` call was needed, and that is worth recording rather than
assuming.** The install alone moved all 24 of gwenview's declared `image/*`
types off Chromium — checked one by one afterwards. The plan had been to set the
defaults by hand; the measurement retired the step.

**The extra formats came free, verified not asserted:** `kimageformats` and
`qt6-imageformats` were already installed, and `/usr/lib/qt6/plugins/imageformats/`
carries `kimg_avif`, `kimg_heif`, `kimg_jxl`, `kimg_psd`, `kimg_xcf`, `kimg_raw`,
`kimg_exr` among others. So AVIF/HEIF/JXL/PSD/XCF/RAW open without another package.

Open question, not decided: **should `install.sh` install a viewer on hosts that
have a desktop?** It already installs `kitty`, `fastfetch` and `github-cli` across
all three package-manager branches, so "this repo does not install applications"
is not an available argument — it does. What needs a call is narrower:

- A viewer is **desktop-environment-specific** in a way `kitty` is not. `gwenview`
  is the right answer on KDE and the wrong one on a headless host or a bare WM,
  and `install.sh` currently branches on *package manager*, not on desktop.
- The cheapness measured above is **a property of this box**, not of the package.
  On a GNOME or WM host `gwenview` drags in the KDE stack it found already here.

So the honest form of the question is whether `install.sh` grows a *"is there a
Plasma session"* branch, which is a new kind of condition for it. That is the
same argument as #4 and #5 — a step nothing enforces is a step the next machine
misses.

### How it was answered — murty's call, same day

**Yes, and the branch went in.** *"install.sh'a 'Plasma oturumu var mı' dalını
ekleyelim."* Section 14, the first in the file that branches on something other
than the package manager.

**The test is `command -v plasmashell`, not `XDG_CURRENT_DESKTOP`, and the
difference decides whether the branch ever fires.** `XDG_CURRENT_DESKTOP` asks
whether Plasma is the session *running this script* — usually false on a fresh
machine, where the installer runs from a TTY or over SSH before anyone has
logged into the desktop. Testing it would have skipped exactly the case the
branch exists for. `plasmashell` on `PATH` asks whether Plasma is *installed*,
which is the question.

**It grew a second customer while being written**, and that is what made the
decision cheap: the same branch now carries the desktop configuration in
`kde/`, which was a separate request. One condition, two items.

**Four paths, all exercised before pushing** — against scratch `HOME`s, never
against the live desktop: no Plasma (skips), viewer already present (reports
it), viewer missing and the install failing (warns, and `set -e` does not
abort — verified rather than assumed), and a machine that already has the
config (skips on the marker file, printing the commit it was applied from).

**The summary lines are guarded too.** Listing gwenview unconditionally would
print *"NOT installed"* on every headless box — true, and the exact misreport
the comment above that summary already warns about: nothing tried to install
it.

## Notes

**These three were found together**, by asking one question on 2026-09-08 —
*"will my aliases work under Windows?"* — and then measuring instead of
answering from the shape of the file. Two of them (2 and 3) are invisible
without running it: one resolves and fails later, the other fails loudly in a
place nobody reads.
