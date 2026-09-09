# dotfiles — dev log

What each session did and **why**. Newest at the top. An entry is a question and
its answer; the rationale is the part that evaporates from a conversation and the
expensive part to reconstruct, so it goes here rather than in the commit alone.

Opened 2026-09-09, alongside `next_steps.md`, under the naming convention
settled in `becoming_power_user` on 2026-09-08.

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
