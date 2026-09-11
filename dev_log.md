# dotfiles — dev log

What each session did and **why**. Newest at the top. An entry is a question and
its answer; the rationale is the part that evaporates from a conversation and the
expensive part to reconstruct, so it goes here rather than in the commit alone.

Opened 2026-09-09, alongside `next_steps.md`, under the naming convention
settled in `becoming_power_user` on 2026-09-08.

---

## 2026-09-11 — `countdown.sh`: the stall at zero, which nobody had fixed

**The question:** murty noticed a momentary stall at zero before this round's
changes and said it appeared to be gone. Was it?

**No. It was still there, unchanged, and the credit was wrong.** `alert()` is
byte-identical between `17fe1ac` and the working tree — `diff` on the two copies
of the function returns nothing. The stall was measured on a pty, both versions,
3-second target, frame timestamps taken off the master fd:

```
eski (17fe1ac)                yeni (çalışma kopyası)
1.91  last countdown frame    1.88  last countdown frame
2.82  \a \a \a \a \a          2.79  \a \a \a \a \a
3.83  zero screen             3.80  zero screen
```

Identical to within noise. **What changed was not the timing but the reading of
it:** the wait used to end on `00:00`, a screen that looks like the one already
up, so it read as a hang; it now ends on a different screen with bells ringing
through the gap, so the same 1.9 seconds read as "the alarm went off". Worth
recording because a perceived fix is the kind of thing that gets built on.

**The cause is one line.** `for _ in 1 2 3 4 5; do printf '\a'; sleep 0.2; done`
— five beeps 0.2s apart is a full second of blocking, and `alert()` runs *before*
the frame is drawn, so the last countdown frame sits on screen for ~1.9s instead
of 1.0s. At exactly the moment the screen is being watched.

**Fixed by backgrounding the bell**, murty's choice between that and deferring
`alert()` until after the draw. Deferring keeps the process count flat but leaves
keys unread for that second; backgrounding makes both the screen and the keyboard
answer immediately, and costs one fork, once, at zero. Re-measured: the zero
screen now lands in the same 10ms as the first beep, and the remaining four ring
against an already-drawn menu.

### What would have shipped silently

**A background job in a non-interactive shell starts with SIGINT ignored.** So
Ctrl+C takes the script down and leaves the beeping running in the terminal it
just handed back — a beep arriving after the alternate screen is gone, with
nothing on screen to explain it. The kill lives in the `EXIT` trap for the same
reason the `stty` restore does: it is the only handler that covers both the `q`
path and the signal path. `tty_restore` became `on_exit` to say so.

Verified on a pty: a full run rings 5 times, quitting 0.3s after zero rings 2
(`q`) and 3 (Ctrl+C), with EOF arriving in the same instant as the quit — a
surviving subshell would hold the slave open and delay it. `stty -g` compared
before and after in one pty on both paths: restored.

### Unverified

The bell is the only alert layer that was ever synchronous; `notify-send` and the
sound players were already backgrounded and were not re-measured this round.

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

**The command runs from `[x]`, not automatically at zero.** murty's call.

*Revised the same day, after review:* the first version took the command only
from `$COUNTDOWN_CMD` and hid the key when it was unset — which contradicted the
reason the menu exists at all. The argument against flags was that the choice is
made *after* the countdown is already running; a command that has to be exported
before it starts is the same flag wearing a different hat. `[x]` is now always
offered and opens a prompt when nothing is configured, keeping what is typed for
the rest of the session. The env var survives as the "don't ask me" path.

The prompt puts the terminal back to its saved settings while it runs — readline
needs echo and canonical mode — and an empty line cancels. Not ESC: readline
reads ESC as the start of a meta sequence, not a keystroke. It also forced the
fallback timer to re-stamp from a *fresh* `date` rather than the frame's clock,
because a prompt can sit open for a minute and the stale stamp dropped the
answer straight onto the clock. Verified with an 8-second prompt against a
3-second timeout.

`[c]` and `[x]` are gated on the menu state. The clock screen's key line offers
only `[r]` and `[q]`, and a key that still fires from a screen carrying no label
for it is a trap — doubly so for the one that runs a command.

**Then the same question came back one level up, and it moved the whole design:
`[x]` is now on screen during the countdown too, and anything armed before zero
fires at zero.** murty's point was that the command had to be settable while the
countdown ran — otherwise a thought at minute 10 of a 25-minute timer costs you
the timer. And once it is settable *before* zero, making it wait for a keypress
*after* zero is incoherent: a command armed before the end is armed by somebody
who expects to be elsewhere when it arrives. It would do nothing in exactly the
case it was set for.

So one rule replaced two: **anything set before zero runs at zero.** `[x]` before
zero arms (prompt pre-filled with what is set; clearing the line disarms) and
never runs now; `[x]` after zero runs it again by hand. `$COUNTDOWN_CMD` is the
same thing set from the shell and fires the same way — including where there is
no keyboard at all, which is the case it was made for.

*This reverses the first decision of the session*, taken before the prompt
existed: "run when picked from the menu, not at zero with the alert." What
changed is that arming and alerting stopped being two different things. Recorded
as a reversal rather than quietly rewritten, because the earlier reasoning is
still sound on its own terms and the next session should see why it stopped
applying.

Three consequences, all paid for:

- **The key line is up in every state**, so it comes out of the vertical budget
  always, and it became the third thing sacrificed on a shrinking window — after
  the date and the clock. Only the line goes; the keys keep working unlabelled.
- **The countdown footer needed the same narrow-screen trim as the other two.**
  It was already wider than 30 columns before today (`target 16:45 · 0m 1s left
  · Ctrl+C to quit`, 46 characters), but until there was a key line under it,
  wrapping cost nothing visible. A labelled countdown still needs ten rows and
  overflows a 9-row terminal — checked against HEAD, it did that before this
  change too.
- **The armed command is named on screen** for the whole countdown
  (`[x] at zero: systemctl suspend`), truncated to the width rather than left to
  wrap. A key that can suspend the machine should not be silently armed.

**`[r]` re-arms, deliberately.** A restart keeps the command and fires it again
at the new zero — the rule is "anything set before zero runs at zero", and a
restart makes a new zero. It is visible for the whole restarted countdown on the
key line, so a repeated `systemctl suspend` announces itself rather than
ambushing. Verified: arm, fire, `[r]`, fire again — two runs.

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

**Two quit mechanisms, kept on purpose.** Ctrl+C while the countdown runs, `[q]`
after zero — and that means `[q]` stops working again after `[r]`. Raised as an
inconsistency and settled by murty: *"tutarsızlık kabul edilir, countdown
tamamlandıysa çıkış kolaylaşır."* Quitting is supposed to get cheaper once the
thing is over, and while it is still running a single stray keystroke should not
be able to end a two-hour countdown. Recorded here because the next session will
otherwise read it as an oversight and "fix" it.

**The alternate screen, not a clear on exit** (`\e[?1049h` / `\e[?1049l`). The
script used to leave its last frame behind, so the shell came back under a
screenful of digits. `\e[2J` at exit would remove those and the user's own screen
with them; the alternate screen restores what was there before, scrollback
included, for both `[q]` and Ctrl+C. A terminal without one — the bare Linux
console — ignores the sequence and gets exactly today's behaviour, which is why
the trailing newline in `cleanup` moved *ahead* of the switch: discarded with the
alternate screen, still doing its old job without one.

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

### `[t]` — point it somewhere else

Asked for next to `[r]` and `[q]`: `[r]` restarts the *same* target, and the
thing missing was a different one. `[t]` opens a prompt taking any spec the
command line takes, pre-filled with the current one.

**It forced `resolve_target` to stop exiting.** Bad input from the command line
is fatal and should be; bad input typed into a menu must not be able to kill the
program. The message cannot go to stderr either — by then the screen belongs to
the alternate buffer, and a stray line scrolls the layout out from under itself.
So the function returns 1 and leaves its complaint in `RESOLVE_ERR`, and the
caller decides whether that is an exit or three seconds in the footer.

The same change fixed a bug that was already there and had never fired:
`if ! TARGET_EPOCH="$(date -d …)"` empties the global on failure. Harmless while
the only caller exited immediately after; with `[t]` a mistyped time would have
taken the running target with it. Everything is computed into locals now and the
globals are assigned together, once it has all worked.

**`[t]` replaces `SPEC`, so a later `[r]` restarts the new target, not the one
the command line started with.** Verified: start 3s → `[c]` → `[t] 6s` → expire
→ `[r]` → 6s again.

**Narrow screens got a third trim level, and the reason is the point.** Five
keys do not fit 30 columns, and cutting the line by characters loses whichever
key sits at the end — which was `[q]`, the way out, invisible on exactly the
screen where the Ctrl+C hint is also suppressed. So the fallback drops whole
keys instead: `[c]` happens by itself after the timeout and `[x]` is a bonus,
while `r`, `t` and `q` stay. Cutting is now the last resort, for an armed
command that outruns any screen.

Both prompts went through one `prompt_line`. The restore-settings / position /
`read -e` / re-disable / flush sequence is the one that already produced the
EXIT-trap bug this session; writing it a second time by hand was not worth the
risk.

`[t]` is offered wherever `[r]` is — the menu and the clock — and not during the
countdown. Retargeting a running countdown ("make it fifteen minutes more") is a
different feature and was not asked for.

### Run on the machine, not just under a pty

Everything above was verified with `script(1)` ptys, which is not what this repo
trusts — validation here is "run it on a machine and see". murty ran the whole
rule end to end in his own terminal: armed a command mid-countdown, let zero fire
it with nobody touching the keyboard, ran it again by hand from the menu, then
pressed `[x]` on the clock screen. `/tmp/x-test.log` came back with exactly two
timestamps nine seconds apart — automatic, then manual, and nothing from the
clock. The timestamps were real rather than frozen at prompt time, which is the
`eval` path proving itself. The `notify-send` layer fired both times.

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
