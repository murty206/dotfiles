# Global rules

Loaded in every project, on every machine, for every agent. Symlinked to
`~/.claude/CLAUDE.md` from this repo, so a change here reaches everywhere on the
next pull.

**This file is deliberately almost empty**, and it is meant to stay that way for
a while. Its transport was settled on 2026-08-26; its *content* is still an open
item in the private workspace where these decisions are made. Twenty-one of the
twenty-four general rules harvested from five months of feedback remain
unreviewed, and the two that were reviewed one by one both turned out to be
misclassified in the harvest summary. Writing the rest of this file from that
summary would install its errors into every project at once.

**So the bar for adding a line here is high, and it is not "this seems like a
good rule":** either it came directly from murty in his own words, or it has
survived the rule-by-rule review. Nothing arrives here by inference from a
summary.

Every line also costs context in every session everywhere, and the repo is
public — no host paths, no project names, no client names. Machine-specific
rules belong in that machine's or that project's own `CLAUDE.md`.

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
