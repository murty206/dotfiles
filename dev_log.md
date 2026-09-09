# dotfiles — dev log

What each session did and **why**. Newest at the top. An entry is a question and
its answer; the rationale is the part that evaporates from a conversation and the
expensive part to reconstruct, so it goes here rather than in the commit alone.

Opened 2026-09-09, alongside `next_steps.md`, under the naming convention
settled in `becoming_power_user` on 2026-09-08.

---

## 2026-09-09 — `countdown.sh`: what the screen does after zero

**The question:** a finished countdown sat on a blinking `00:00` until someone
killed it. What should be on the screen instead, and how do restart / auto-exit /
run-a-command get offered without turning the script into a flag farm?

### What was decided, and why

**A key menu at zero, not command-line flags.** The firm requirement was "after a
timeout, show a normal clock", and a *timeout* only means anything if something is
waiting for input that never came. So zero is a state change, not an ending:
`count → menu → clock`, with `[r]` sending it back to `count` from either of the
other two. Flags were the alternative and lost — the behaviour is chosen after the
countdown is already running, which is exactly when a flag is no longer reachable.

**The clock is drawn in-process, not handed to `tty-clock`.** The header promises
pure bash and no dependencies, and the screensaver case has to survive; the big
digits are already there, so clock mode is the same `print_digits` with `$now` and
`COLOR_CLOCK`. It also drops the half-scale clock that normally sits on top —
two copies of the same time is the one layout worth vetoing.

**The command runs from `[x]`, not automatically at zero.** murty's call. It comes
from `$COUNTDOWN_CMD` because a keypress cannot supply command text, and the key
is hidden when the variable is empty rather than offered and inert.

**`resolve_target()` is a function now**, which is the only reason `[r]` can work:
a duration restarts from now, and a wall-clock target has to resolve to its *next*
occurrence instead of firing again the instant it is restarted. Verified — a
restart at the target minute comes back as `(tomorrow) · 23h 59m left`.

**Any keypress restarts the fallback timer.** The timeout is a test for whether
anybody is present, and a keypress answers it — without the reset, pressing `[x]`
at second 25 of a 30-second window loses the menu five seconds later, with the
command's own confirmation still on screen. One line, and it is the only reason
`[x]` is usable at the end of the window as well as the start.

**The menu is skipped where `COUNTDOWN_NO_HINT` is set or stdin is not a tty**,
and the clock still takes over on the same timer. That half needs nobody present;
the keys do. Same escape clause the hint already had, reused rather than reinvented.

### What bit, and would have shipped silently

**Ctrl+C left the terminal with echo off.** Echo is disabled for the whole run
(otherwise anything typed at the countdown prints on top of the digits), so the
settings have to be handed back. Restoring inside the `INT` trap looks right and
is not: `read` is waiting for a menu key when the signal lands, and bash puts back
the settings *it* saved when `read` started — ours, with echo already off — after
the trap has run. The restore had to move to a separate `EXIT` trap, which runs
last. Caught only by comparing `stty -g` before and after inside one pty; the
symptom is a shell with a dead keyboard, and nothing on screen says so.

**Buffered keystrokes.** Without a flush at the transition, the menu opens and
instantly eats a key pressed minutes earlier — and one of the keys it can land on
is `[q]`.

**The key line is a row, and rows are budgeted.** It had to go into both the
scale-fit loop and the `base` centering sum, or it pushes the footer off a short
screen. On a narrow one the footer wraps instead, which costs an unbudgeted row
with the same result — so both footer and key line shorten when they would not
fit (`[r] restart` → `r=restart`). Checked at 80x24, 60x12, 40x14 and 30x9.

### Unverified

Only tested on this Linux box. The `stty` save/restore and `read -rsn1 -t` are
POSIX-ish but the Git Bash behaviour on Windows is untested, and `WINDOWS.md` does
not cover `countdown.sh` at all — it is not one of the five Claude Code artefacts.

---

## 2026-09-08 21:42 → 2026-09-09 00:24 (2h42, 0 compactions)

**The question:** does this repo's Windows story actually hold on a Windows
machine? It had never been run on one by the person who wrote it.

Closed with 7 commits here (`aa0d8f9` → `f752474`) and 3 in
`becoming_power_user`. Opened without `/acilis`, so the start time was read from
the session transcript rather than a stamp — see *Unverified*.

### What was decided, and why

**Route A on this machine, not Route B.** `ln -s` was silently copying, exactly
as `WINDOWS.md` warns. Developer Mode on + `MSYS=winsymlinks:nativestrict`
turned that into real symlinks, so the five Claude Code artefacts now track the
repo instead of drifting from it. Route B was available and rejected: a copy that
stops receiving updates reports nothing, and this machine is used often enough
that the silent staleness would have been paid for repeatedly.

**A fourth Windows difference in the status line, and it is the quietest one**
(`3723a7d`). The directory block already declines to prefix the project name when
the project root is `$HOME`. That test is a string compare, and on Windows it is
handed two spellings of one directory — bash has `/c/Users/x`, the payload
`C:/Users/x` — so it never fires and the username is prefixed onto the line.
Fixed in `wproj()` inside the python block, because the one-python-no-forks
constraint rules out `cygpath`, and because that is where this repo has already
decided platform quirks get settled.

Fixture 14 builds its payload from the running machine's own `$HOME` rather than
a literal: a hard-coded path passes on both platforms and proves nothing. That
choice is the whole value of the test.

**The setup docs were wrong in three places, and all three fail silently**
(`aa0d8f9`). `SessionStart` must sit inside the top-level `"hooks"` object —
beside it the file still parses and the hook never registers. The `MSYS` export
must be appended, not assigned, because Claude Code injects `MSYS=disable_pcon`
into the shells it spawns. And `~/.bashrc` is never read on a machine with no
`~/.bash_profile`, so Route A can look configured and be off.

**One git identity, and history left alone** (`cffdfe6`). Four identities had
accumulated across the account — 33 `Muharrem ARLI`, 17 `Murty`, 9 `murty`, 1
`Shalafi` in this repo alone. `.mailmap` collapses them at read time; mapping is
by email, so no name is written into the file. History was **not** rewritten, and
that was the deliberate call: `dev_log` and `next_steps` in the other repos cite
commit hashes, and a rewrite breaks every one of those references for a cosmetic
gain.

`install.sh` sets the identity only when git has none. An identity that is set
and *different* is reported and left alone — a host that deliberately commits
under a work name is the mirror image of this bug, and rewriting it silently
would be the worse of the two failures.

**The gh login is asked for, not merely mentioned** (`ad80020`). The real gap was
in `ensure_gh`, which opened with `command -v gh && return 0` and so could report
only the case where gh was missing — never the common one, gh present and never
logged in. `install.sh`'s own comment said the two were kept in step; on this
point they had not been.

**The closing summary now checks instead of asserting** (`f2f1e67`). Several
install steps end in a *warning* rather than an install, and a summary that ticks
them anyway is worse than no summary — it is the one screen that gets believed.

### What was refuted

Five claims made during the session and knocked down by measurement. They are
recorded because each cost time and would cost it again:

- **"The global mailmap works in the other repos."** Over-claimed. Wiring it
  changed nothing in `factory-backend`, because that repo already had exactly one
  identity of mine. Where it matters is here and in UAKBSCSD.
- **Two mailmap tests that proved nothing.** `mailmap.file=/dev/null` leaves the
  repo-root `.mailmap` in force; `log.mailmap=false` does not reach `shortlog`,
  which applies the mapping unconditionally. Only `%an` versus `%aN` shows the
  difference.
- **"A live status line run is broken."** It was the payload, mangled by shell
  quoting on the way in — the exact failure `statusline-fixtures.py` documents in
  its own docstring, met while testing the thing that documents it.
- **Two parser bugs in the alias audit**, each producing an impossible result:
  first every alias broken, then `g` working while `ga` did not. `alias` prints
  the body quoted, so a naive split returns one token. Numbers were only
  believable on the third attempt.
- **An inference about which machine a commit came from.** `a694ef4` in
  `becoming_power_user` was read as evidence that the Linux identity had been
  switched; it came from the project agent on *this* machine. Corrected by murty.

### Unverified

- **None of the Linux paths ran.** `wproj()` and fixture 14, the new
  `install.sh` sections, and `update`'s new blocks were all exercised on Windows
  only — the identity/gh blocks in isolation with a stub, not end to end. The
  fixture file's own docstring asks for both platforms. The check that settles
  it: `python3 statusline-fixtures.py ./claude-statusline.sh` on the Linux box,
  expecting 14/14 with case 14 printing `.dotfiles`.
  **RUN 2026-09-09 on the Linux box, and it passes: 14 cases, `cases that exited
  non-zero: 0`, and case 14 prints `.dotfiles [main] | …` — no `$HOME` prefix,
  which is the Windows bug `3723a7d` fixed, confirmed not to have cost anything
  on Linux.** Run by the `becoming_power_user` session immediately after
  fast-forwarding this repo, because the check was written down here rather than
  left in a conversation — which is the only reason it was findable at all.
  **This settles the fixture half and only that half.** `install.sh`'s new
  sections and `update`'s new blocks were **not** run; the two remaining bullets
  below are also untouched. Case 8's `642640h33m` is not a defect — the fixture
  hard-codes `resets_at: 4102444800`, which is 2100-01-01.
- **The session's start time** came from the transcript's first record, not from
  `.claude/session-start` — the session was opened without `/acilis`. Read, not
  invented, but weaker than a stamp.
- **`gh auth login` was never actually driven by the installer.** The prompt's
  four branches were tested with a stub `gh`; the real OAuth flow was not.

### Open

`next_steps.md` #1, #2, #3 — all three from one question at the end of the
session, *"will my aliases work under Windows?"*, answered by sourcing the file
there instead of reasoning about it. 35 of 53 aliases resolve. Two of the three
items are invisible without running it.
