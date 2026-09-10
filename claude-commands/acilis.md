---
description: Session opening ritual — check the context is fresh, stamp the start time, open on the top queue item
argument-hint: "(leave empty — the time is taken automatically)"
allowed-tools: Bash(date:*)
---

Open a session. Start time, taken from the machine:

!`date '+%Y-%m-%d %H:%M %Z'`

That line is injected by Claude Code before this file reaches you. It is the
machine's clock, not a guess — use it verbatim and never ask for it.

This is the generic ritual, available in every directory. **If the current
project defines its own `/acilis`, follow that instead** — it will know the file
names this one has to guess at.

---

## 0. Is this a fresh context? Check before anything else

A `SessionStart` hook prints one of these lines at the very top of the
conversation:

| Line | Means |
|---|---|
| `session-context: FRESH` | The session began at startup or `/clear` |
| `session-context: CARRIED OVER` | Resumed, compacted or forked — the old context is still loaded |

**Two things have to be true to go on**, and they are not the same thing:

1. The marker says `FRESH`.
2. There is no substantial work in the conversation above this command.

The second matters because a session that *began* fresh stops being empty the
moment work happens in it. `--continue` and `--resume` do **not** clear the
context; neither does a compaction, which only shortens it.

**If either check fails, stop here.** Do not stamp, do not read the queue. Say
which check failed, and tell the user to run `/clear` and then `/acilis` again.
This command cannot clear for them: a slash command is a prompt, and `/clear`
would erase the prompt mid-run.

**If the marker is missing entirely**, the hook is not installed on this
machine. Say so — do not treat a missing marker as a pass — then fall back to
judging the conversation above on its own and proceed only if it is empty.

---

## 1. The stamp

`/acilis` and `/kapanis` are one pair, and `.claude/session-start` is what joins
them. Its existence is the state:

| | |
|---|---|
| **File absent** | No session is open |
| **File present** | A session is open, and the file holds its start time |

`/acilis` creates it. `/kapanis` reads it and then **deletes** it. That is the
whole mechanism — it is why neither command has to ask how long the session ran,
and why neither needs a rule about work that runs past midnight.

Write the injected line into `.claude/session-start` in the project root, on its
own, exactly as injected. Create `.claude/` if it is missing. Add the file to
the project's `.gitignore` if it is not there already — it is state, not history.

**If the file already exists, do not overwrite it.** A session is open. Read it,
report the start time that is standing, and go on to the next step. A `/clear` or
a restart does not begin a new session — it continues the one the stamp names.

The one case that needs a question: the stamp is from a **previous day** and
nothing suggests work ran overnight. Then the last session was never closed. Say
so plainly and ask whether to overwrite it or to run `/kapanis` for that session
first. Do not decide this alone — an overwritten stamp is a session whose length
can no longer be reconstructed.

## 2. The repository's state

**Run `git fetch` first, then report three things.** Not one "the repo is fine" —
three, because they fail independently:

1. **Is there a remote at all?** `git remote`. A project with no remote has no
   backup, and `/kapanis` needs to know before it promises a push.
2. **Ahead or behind?** `git status -sb`, **after** the fetch.
3. **Is the working tree clean?** Same command. If it is not, **name the files**.

**Why the fetch is not optional.** `git status`'s *ahead / behind* is computed
against the **local** `origin/*` ref and makes **no network call** — it is only as
fresh as the last fetch. Without one, work pushed from another machine is
reported as *"0 behind"*: a silent wrong answer, which is worse than no answer.

**The offline objection does not survive contact.** An agent runs over the
network, so a session able to execute this command already has one. The narrow
residual is that the host could be unreachable while the model API is not — then
the fetch fails **visibly** and the pre-fetch answer still stands. Say so and go
on.

**A dirty tree is reported, not refused, and the files are named.** This is
deliberately weaker than the freshness check above, and the asymmetry is the
point: a carried-over context **poisons the session that is starting**, while
uncommitted work is someone else's unfinished business that this session may have
no business touching. `/acilis` cannot commit for the user either way.

**The real damage is at close, not at open** — which is why naming the files
matters more than blocking. If `/kapanis` later commits files this session never
touched, another project's work goes into the record under this session's
message, and the log stops being true. The counterpart rule lives in `/kapanis`.

**Do not assume the dirt is the user's own.** A tree can go dirty **after** the
ritual that pronounced it clean, and the writer can be a *different project's*
session writing into this repository — the one case no single project's
discipline catches, and the reason this check belongs at open and not only at
close.

## 3. Read the queue

`next_steps.md`, `TODO.md`, or whatever this project keeps. Name the item at the
top — by its number if the project numbers them, and by the reason it is at the
top if that reason is written down. The queue usually explains its own ordering;
quote it rather than re-deriving it.

## 4. Read the top entry of the log

`dev_log.md`, `docs/dev_log.md`, `CHANGELOG.md`, `NOTES.md` — the first that
exists. One or two lines on where the last session stopped, so the thread is
picked up instead of re-derived.

## 5. Open with that item

Report in five lines:

- Start time
- The repository's state — remote, ahead/behind, working tree
- The top item, and why it is top
- Where the last session left off
- The first concrete step

Then take that step. Beginning is not the same as deciding: if the item calls
for a decision, the first step is putting the decision to the user — not making
it for them.

---

If the queue's top item is blocked, say which item blocks it and open on the
blocker instead — but say that you moved, and why.

If the queue is empty, or there is no queue, say so and ask what the session is
for. **Do not invent a task.** A session opened on work nobody chose is worse
than one that opened with a question.
