---
description: Session closing ritual — log the decisions, update the queue, commit
argument-hint: "(leave empty — the time is taken automatically) or [HH:MM] to override"
allowed-tools: Bash(date:*)
---

Close this session. End time, taken from the machine:

!`date '+%Y-%m-%d %H:%M %Z'`

That line is injected by Claude Code before this file reaches you. It is the
machine's clock, not a guess.

Override, if the user gave one: **$ARGUMENTS**

If that override is non-empty, use it as the end time instead of the injected
one — it is for closing a session some time after it actually ended. If it is
empty, the injected time is the end time. **Either way, do not ask for it.**

This is the generic ritual, available in every directory. **If the current
project defines its own `/kapanis` or documents its own closing procedure,
follow that instead** — it will know the file names and heading formats this one
has to guess at.

---

## The start time

Read `.claude/session-start` in the project root. `/acilis` wrote it, and its
existence is what says a session is open. Take the start time from it and work
out the duration; do not ask the user for either.

**If the file is missing**, the session was opened without `/acilis`. Then, and
only then, **ask** for the start time — do not invent one, and do not silently
log an end time with no duration. A wrong duration is worse than a missing one,
because it will be averaged into a measurement later.

## The session's shape

Also read `.claude/compact-count` if it exists — how many times the context was
compacted. **Record the number in the entry**, even when it is zero, and note
whether the two-compaction warning fired and what happened next: the question
was split, closed whole, or the warning was ignored.

This is the only chance to keep it. The next fresh start resets the counter, so
a number not written into the log at close is a number that never existed. It is
also the one that says whether the session was the right size, which no other
field records.

**Delete the file as the last step**, after the commit. That is what marks the
session closed and lets `/acilis` open the next one cleanly. If anything above
failed, leave it in place — a stamp left standing is a session you can still
close, while a deleted one is a duration that cannot be recovered.

---

In order, skipping nothing:

**1. Find the log.** Look for a running log in this order: `dev_log.md`,
`docs/dev_log.md`, `CHANGELOG.md`, `NOTES.md`. If none exists and the session
produced anything worth remembering, ask whether to start one.

Add a new entry **at the top**, matching the format of the entries already
there. Do not invent a new format for an existing file.

**2. What the entry must contain.**

- What was decided, and **why**. Not "we chose X" but "we chose X because Y".
  The rationale is the first thing that evaporates from a conversation and the
  only part that is expensive to reconstruct later.
- **What was refuted.** A theory that turned out wrong is worth as much as one
  that turned out right — it stops the same road being walked twice.
- Anything **not yet verified**, marked plainly as such. Never let an untested
  change read as a finished one.
- Open items, with their identifiers if the project numbers them.

**3. Update the queue.** If the project keeps one (`next_steps.md`, `TODO.md`,
an issue tracker), move closed items out, number anything newly opened, and if
you reordered the priorities write **why**.

**4. Promote anything permanent.** The test: would an agent in a future session
do the wrong thing without this? If yes it belongs in `CLAUDE.md`, not in the
log. The log is history; `CLAUDE.md` is the rule in force.

**5. Commit.** Follow the repository's existing message style — read
`git log --oneline -10` first rather than assuming one.

**6. Delete `.claude/session-start` and `.claude/compact-count`.** See above.
This is the step that closes the session — and do not delete the counter until
its number is in the entry.

**7. Give a three-line closing summary:**
- Closed this session
- Still open, and the first thing the next session should do
- Anything unverified

---

If you are unsure of something, **ask rather than invent**. A wrong log entry
is worse than a missing one, because it will be trusted later.
