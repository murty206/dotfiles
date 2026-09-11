# Global rules

Loaded in every project, on every machine, for every agent. Symlinked to
`~/.claude/CLAUDE.md` from this repo, so a change here reaches everywhere on the
next pull.

**This file is deliberately almost empty**, and it is meant to stay that way for
a while. Its transport was settled on 2026-08-26; its *content* is still an open
item in the private workspace where these decisions are made.

*Status corrected 2026-09-09. This paragraph used to say ten of the twenty-four
general rules were unreviewed and that the harvest's summary was wrong about
twelve of the fourteen read. Both are stale: the review finished on 2026-09-08 at
**24 of 24**, and the "12 of 14" figure was **retracted** the same day — it could
not be re-derived and it counted verdict entries where another count read files.
A withdrawn number should not have been sitting in the one file every project
loads. The qualitative statement survives and is the reason for the bar below:
of the rules read one by one, the harvest's disposition survived in only a small
minority. A second corpus of 33 rules, from another machine, is still unread.*

Writing this file from an unreviewed summary would install its errors into every
project at once.

The review keeps finding the same shape: the summary is not a lie, it is a
*compression*, and what it drops is the part that made the rule work — an escape
clause, a named check, a scope trigger, the sentence that says what to do instead
of the forbidden thing. That is why nothing arrives here by summary.

**So the bar for adding a line here is high, and it is not "this seems like a
good rule":** either it came directly from murty in his own words, or it has
survived the rule-by-rule review, **or it was derived from evidence recorded in a
file anyone can go and check.** Nothing arrives here by inference from a summary.

**The third route was written down on 2026-09-11, and it was already in use before
it was written.** The rule below on *your own earlier output* says only *"Adopted
2026-09-09"* — not *"from murty, in his own words"*, which the other three do say
— and its calibration rests on **eight recorded instances across two sessions**.
It came in by measurement, and the bar did not admit that at the time. **An
unacknowledged exception is worse than a wider bar**: a bar that keeps rules out
while quietly letting one through has stopped being a bar. So the route is now
written, with its own condition — **the evidence is in a file, dated, and readable
by someone who was not in the conversation.** Argument alone is not the third
route; argument plus a checkable record is.

**Every line also names its device — or says it has none.** Adopted 2026-09-09.
Being *followable* and being *noticeable* are different properties: every rule
ever written is followable, and the ones that survive a long session are the ones
that fire **while the mistake is being made** — a sentence you catch yourself
typing, a command that has to run before you speak, a word from the user that
means a dial is mis-set. So each rule below carries a `Device:` line naming that
trigger.

**A rule with no device still gets in — it says `Device: none` instead.** That is
information, not a demerit. A bar that rejected undeviced rules would filter for
*catchability* rather than for truth, and some true rules have no nameable
moment. Writing the absence down costs nothing and buys the question that matters
later: are the undeviced rules the ones that get broken? That is answerable by
counting, and the counting has started.

Every line also costs context in every session everywhere, and the repo is
public — no host paths, no project names, no client names. Machine-specific
rules belong in that machine's or that project's own `CLAUDE.md`.

---

## What survives a session

**The conversation is temporary. Files are permanent.**
Adopted 2026-09-07, from murty, in his own words — and he stated the scope
himself: *not one workspace's convention, but the rule he works by with an agent
everywhere.*

So a decision, a rationale or an open question that exists **only** in the
conversation does not exist. Write it into a file at the moment it is made, not
at the end — an interrupted session loses whatever was still waiting to be
written down, and the rationale is the expensive half. "X because Y" — Y is what
evaporates first and costs the most to reconstruct.

Two things follow, and they are the practical half of the rule:

- **Do not ask the user to re-supply what a file already holds.** If it is
  retrievable, retrieve it.
- **When something new surfaces mid-work, write it down and leave it.** Filing it
  is not the same as doing it; it waits its turn. Chasing it is how the current
  question stops closing.

The counterpart is that conversation is *disposable on purpose* — it is working
memory. Nothing is lost by ending a session, provided the writing happened while
it ran.

**`Device: none.`** This rule describes how to behave generally and names no
instant at which it fires. **It is also the only rule in this file that has been
broken since anyone started counting** — the agent asked the user for something
the files already held. Recorded rather than patched: an invented trigger would
be worse than a visible gap, and the gap is the more useful thing to know.

### The same rule one layer out: commit and push when the decision lands

**A decision written into a file is committed and pushed at that moment, not
saved up for the end of the session.** Adopted 2026-09-11, by the third route —
the evidence is below and it is dated.

**Three layers, and each one survives a different failure.** Writing the file
survives the **conversation** ending. Committing survives the **working tree** —
another session, another project, or a later edit reaching into the same files.
Pushing survives the **machine**. A commit that never left the disk is not a
backup, and the day it matters is the day you cannot check.

**The failure it was written from, and it is on record.** Two measurement files
sat uncommitted in a shared repository while a **different project's** session
closed into that same repository. They ended on no branch, in no stash, and on no
remote — not *unpushed*, but **never recorded at all**, and nobody noticed for
two days. Uncommitted work has no author: `git` cannot tell whose it was, so
whoever commits next either sweeps it into their own history under the wrong
message or leaves it to be lost.

**Scope, and it is the part a summary would drop.** This is about files that
record **decisions and rationale** — logs, queues, measurements, notes. **It is
not a rule about committing code mid-change**, where a half-finished commit
breaks a build and the ordinary discipline applies instead. A half-written
rationale on the remote costs nothing; a half-written function costs the next
person an hour.

**The side effect worth having:** one message per decision turns the history into
a record of *why*, which a single end-of-session commit flattens into one line.

**`Device: a turn in which you edited a file and did not commit it.`** The moment
is the end of the turn, not the end of the session — if a file changed and
nothing was committed, the rule is already broken. Literal, and checkable
afterwards with `git log` against the file's own timestamps.

**Calibration, since this one has a dial.** Over-firing looks like a commit per
typo and a history nobody can read — fix it by grouping the edits that belong to
**one decision**, not by waiting. Under-firing is the failure above: a tree full
of uncommitted decisions at closing time, swept into a single commit whose
message can only name one of them.

---

## Your own earlier output

**Apply the same scrutiny to what you produced earlier as to what the user tells
you.** A number, a conclusion or a name does not become reliable because you were
the one who wrote it. Adopted 2026-09-09.

**The reason, and it does not rest on the user working alone.** A reviewer — a
teammate, a pull request, a second pair of eyes — reads the **artefact**: the
code, the diff, the merged file. Nobody reads the agent's earlier turns, the
reasoning that produced them, or the notes it wrote along the way. And review
arrives *after* the errors have compounded, not while they are compounding. **Team
size changes what the failure costs, not whether it happens** — and in a shared
repository it costs more, because a wrong claim in a file several people read
propagates as fact.

**`Device: before reusing one of your own earlier results, re-derive it from the
source.`** The moment is the sentence that starts *"as we found earlier…"* — a
number, a conclusion or a name you produced yourself and are about to build on.
It is not *re-audit everything you have said*, which cannot be finished. Only the
re-use.

**Calibration, since this one has a dial.** Over-firing looks like re-deriving
trivia and never closing a turn — correct it in conversation, and only tighten
the wording here if it repeats. Under-firing has a signature worth naming: a
chain of conclusions each built on the last, every one refuted by a later
measurement, with the premise never re-examined. That is the failure this rule
was written from — eight recorded instances across two sessions, three of them in
one afternoon.

---

## Working with the shell

**Commands that need root are handed to the user to run, not attempted first.**
Adopted 2026-08-28, from murty. An attempt that fails on a password prompt tells
you nothing you did not already know — `apt install` needs root, and knowing
that is not the same as knowing whether this host's `sudo` prompts. It costs a
round-trip and, worse, it gets reported back as a discovery. Say which command
needs running and why, and let the user run it.

The same holds for anything else the agent cannot complete on its own:
interactive logins, browser confirmations, hardware that has to be power-cycled.
Name the step, hand it over, and say what happens next — do not probe first.

**`Device: a command class, checked before the command runs.`** `sudo`, a package
install, an interactive login, a browser confirmation, hardware that has to be
power-cycled. If what you are about to run belongs to that class, it is handed
over — there is nothing to evaluate and nothing to try first.

---

## Git

**Commit messages carry no attribution trailer.** No `Co-Authored-By`, no
"generated with" line. Adopted 2026-09-09, from murty, in his own words — and he
stated the scope himself when asked whether it was one project's preference or
general: *"tercihim genel tabii ki."*

**This overrides the tool's own default**, which asks for the trailer, and that
is the only reason the line has to exist: without it every agent re-adds the
trailer from its system instructions and nobody notices.

**The preference is for the line to be absent, not corrected.** It was recorded
on 2026-08-19, when he noticed the agent had stopped adding it: *"eklemeyi
bırakman iyi oldu"* — the version he approved of was the one with no line at all.

**`Device: a forbidden string.`** `Co-Authored-By`, and "generated with". If
either one is in a commit message you are composing, the rule is already broken.
Literal, and checkable after the fact with `git log --grep`.
