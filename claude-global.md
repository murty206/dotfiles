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

**As of 2026-09-14 no rule here carries `Device: none` any more.** The one that
did was given a trigger, out of the two rows that had recorded it being broken.
So the question above is no longer answerable from inside this file — it is
answered from the rows, each of which records the rule's device **as it stood at
the time**. That is the better place for it anyway: a file shows the present
state, and the count needs the state at the moment of the breach.

Every line also costs context in every session everywhere, and the repo is
public — no host paths, no project names, no client names. Machine-specific
rules belong in that machine's or that project's own `CLAUDE.md`.

---

## When this file conflicts with your own instructions

**A rule here beats an instruction you arrived with, and noticing the conflict is
the work.** Adopted 2026-09-14, at murty's direction, by the third route — the
evidence is a dated row in a file, and the row is the reason this is a section
and not a sentence.

**The losing side is not argued down; it is never seen.** Your system
instructions do not present themselves as preferences to be weighed. They arrive
as obligations — *always end with*, *you must include* — and an obligation does
not read as a candidate for being overridden. So the failure is not a rule
rejected. It is a rule that never entered the frame, while something was done
"because that is how it is done".

**Measured, and it is why the wording above is about noticing rather than about
precedence.** The attribution rule below already said in its own body that it
overrides the tool's default. It was still broken nine times in one session by an
agent that had that sentence loaded. Precedence was never the missing part.

**`Device: an instruction you are following that came from neither the user nor a
file you have read in this project.`** The moment is just before you act on it.
The question is one line — *does this file speak to this?* — and it is cheap
enough to ask every time, because the cases where it applies are few and always
the same shape: a format you were told to always produce, a trailer, a
disclaimer, a boilerplate line.

**The aggravator, named separately because it is easier to fix than the
mechanism:** that session had pulled this very file into place mid-run — it is
symlinked, so a `git pull` rewrote its own rules — and never re-read it. Five of
the six rules then in force were followed; the one that was not is the one that
had not been visible before the pull. **A file you put in place during a session
is a file you have not read.**

**The evidence is one row, and that is thinner than this bar usually takes.** The
third route's precedent rested on eight recorded instances across two sessions;
this rests on `measurements/2026-09-09-rule-violations.md` row 4, dated
2026-09-14. It is admitted on murty's call with that stated, so nobody later
mistakes one case for a rate. The row that would test it is already named in that
file: **a rule that fails with no competing instruction and no condition to
evaluate.** If those accumulate, this section is too narrow and the fault is
trigger design after all.

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
  question stops closing. **Asking whether to do it now is already the
  deviation** — the default is written, so the question is only the polite form
  of jumping the queue. Say what you filed, then go back to the interrupted
  work. **The exception is a finding that blocks the work in hand:** say that it
  blocks, clear it, and say you are doing so — never change direction silently.

The counterpart is that conversation is *disposable on purpose* — it is working
memory. Nothing is lost by ending a session, provided the writing happened while
it ran.

**`Device: a question you are about to ask whose answer is already written
down.`** Adopted 2026-09-14, by the third route — two dated rows in a violation
count, plus a project-level counterpart that supplied the wording. **This
section said `Device: none` until that date**, and the rows are why it no longer
does: **both violations of it on record are the same move** — asking the user to
settle what a file had already settled, and offering a measurement as an option
instead of taking it, answered *"Sormuyorum, ölçüyorum."* **The question reads
as deference**, which is why neither agent saw it as a breach, and why naming
the moment was worth more than restating the rule.

**One device, not two, because it covers both bullets.** The first bullet's
failure is asking for what you could retrieve; the second's is asking whether to
do the new thing now. Same sentence being typed, same answer already on disk.

**Two rules in this file have been broken since anyone started counting, and at
the moment each was broken only the second had a device.** This one: the agent
asked the user for something the files already held — the section carried
`Device: none` then, and the trigger above was written afterwards, out of that
row. The attribution rule below, 2026-09-14: nine commits in one
session carried the trailer, and its device is the most literal kind there is —
a forbidden string.

**So the question the bar leaves open has its first data, and it points the other
way: a device did not save a rule.** Why it did not is recorded in the private
workspace, item 26. The short form is that the competing instruction arrives as
an **obligation**, and an obligation does not read as a candidate for being
overridden — the conflict has to be noticed before any device can fire.

**The count is two because a repeated breach counts once.** Settled 2026-09-14 as
a definition rather than a measurement: **one breach per unnoticed decision, not
per artefact**, with the spread recorded beside it — here, *one breach spread
over nine commits*. The count asks **which** rules fail, not how often, and
counting artefacts would make a long session look worse than a short one for the
same single failure.

Recorded rather than patched: an invented trigger would be worse than a visible
gap, and the gap is the more useful thing to know.

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

## One question at a time

**Ask one question, get its answer, close that item — then move to the next.**
Adopted 2026-09-17, from murty, in his own words, twice in one session: *"tek
tek açıkla lütfen madde madde ve bir madde bitmeden diğerine geçme"*, and after
three were sent together, *"3 soru birden sordun, birini netleştirmeden diğerine
geçmeyelim"*.

**And the question carries your recommendation.** Same route, three days earlier,
in another project: *"teker teker sor önerilerinde beraber ben cevaplayayım."*
**He is not asking for a neutral menu.** Take a position — say which option you
would choose and why — and leave him the overruling. **A one-at-a-time question
with no recommendation satisfies the pacing and hands the thinking straight back**,
which is the cost he was trying to stop paying. This half applies whichever form
the question takes, prose or structured.

**This is not the rule above about questions whose answer is already written.**
There the question should never have been asked at all. Here the questions are
legitimate and the failure is sending them together, which costs twice. A batch
gets answered **partly** — the first one is answered, the rest fall on the floor
and are either lost or asked again. And, worse because it is less visible,
**questions are usually dependent**: the right form of the second changes with
the answer to the first, so asking three at once means asking two of them in the
wrong frame.

**The same applies to explaining.** Finish an item before starting the next one;
a message that opens three threads closes none.

**`Device: a message you are composing that puts more than one question to the
user.`** Literal, and checkable while typing rather than afterwards — one
question mark aimed at the user per message. If there is a second, it is waiting
on an answer you do not have yet.

**Measuring the next item while the current answer is outstanding is fine;
asking about it is not.** The bar is on the question, not on the work.

**Scope: this is about questions written as prose.** Adopted 2026-09-17, from
murty, in his own words: *"'One question at a time' yazılı sorular için geçerli
olması lazım, senin anket tarzında yaptıklarında problem yok, 4 adet soruya kadar
cevap verebiliyorum."* **A structured question tool — each question its own item,
with its own options — is exempt, up to four.**

**The reason is this rule's own stated cost, which is why the exemption does not
weaken it.** The failure named above is that a batch gets answered **partly**: the
first is answered and the rest fall on the floor. An interface that presents each
question as a separate, separately-answerable item **removes that failure mode by
construction** — there is nothing left for the device to fire on. Prose has no such
structure: questions sink into paragraphs, and the second one is the one that gets
lost. **So the device is about the form, not the count.**

**Calibration.** Over-firing would look like withholding a clarification the
user needs because another question is already out — the fix is to answer and
ask in the same turn, not to hold the second question indefinitely.
Under-firing has the signature this was written from: a numbered list of
questions, of which one gets answered.

---

## Numbers

**A number you will cite later goes into a file when you take it — with its
method, and dated.** Adopted 2026-09-11, at murty's direction, and the reason is
that the alternative has already happened more than once: a figure quoted in a
document, nobody able to re-derive it, and no way to tell whether it was wrong or
just stale.

**What has to be in the file, because the number alone is not enough:**

- **The raw result**, not the rounded conclusion.
- **How it was taken** — the command, the source, the sample.
- **Anything that was *chosen* rather than *observed***. This is the part that
  gets dropped and the part that decides whether the number means anything: a
  threshold, a cut-off, a window, an exclusion. Mark it as a definition, not a
  measurement.
- **What was NOT measured**, if the number invites a conclusion it cannot carry.

**The file's name and location are the project's business** — a dedicated
directory, a section of the log, whatever the project already does. **What is not
optional is that the number is traceable to something dated.**

**And the rule has teeth in the other direction: no source, no claim.** If a
figure cannot be pointed at, it does not get used — not softened, not hedged,
**not used.** A retracted number is not a small error: it was quoted somewhere,
and everything built on it is now suspect.

**Scope.** This is about numbers that leave the moment they were taken in — cited
in a document, used in an argument, compared against next month. It is **not** a
rule about every intermediate value: a count you print, read and discard needs no
file.

**`Device: a number about to be written into a document.`** The moment is typing
a figure into a file or a message — if it is not yet recorded anywhere with its
method, the rule is firing. Cheap to check, and the check is the fix.

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

## What is written, and what was written

**A rule about what gets written applies forward. Pushed history is not rewritten
to satisfy it.** Adopted 2026-09-14, from murty, in his own words — and by the
first route with more evidence than it usually asks for: **four independent
statements, three repositories, two machines, none aware of the others.**

- On an attribution trailer, 2026-08-19 — *"geçmişi yeniden yazma kararı
  verilmedi, olduğu gibi bırakıldı."*
- On person attribution inside a repository, 2026-09-08 — *"geçmiş olduğu gibi
  kalsın, bundan sonrasına dikkat et."*
- On an address already in 33 public commits, 2026-09-09 — leave it, stop the
  bleeding.
- On nine commits carrying a forbidden trailer, 2026-09-14 — the same again.

**The trade is identical every time, and it is his:** the gain is small and the
force-push risk is real. It is larger in a repository other people pull, where a
rewrite lands on everyone who has already fetched.

**What this is not, because the two are easy to confuse and the confusion is
expensive in both directions.** This governs **conventions** — a trailer, a
phrasing, a name that should not have been written. **A leaked credential is not
a convention.** Rotate the secret; treat the exposure as real whatever the log
looks like afterwards. Rewriting history does not un-leak anything, and leaving a
convention in place costs nothing.

**`Device: the sentence "should I clean up the old ones?"`** If you are composing
it, the answer is already no — say what changes from here instead.

**Why it is written down at all**, since four people agreeing is usually a sign a
rule is unnecessary: on 2026-09-14 the question was re-derived for the fourth
time, from a precedent in a different repository, **while the answer had been
sitting in a file for twenty-six days and nobody looked.** The cost of this line
not existing is the one thing here that was measured rather than argued.

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
