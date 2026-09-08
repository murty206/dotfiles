# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Personal portable shell environment (zsh + Starship + Kitty + aliases) deployed to any Linux machine via one curl-piped installer. Repo lives at `~/.dotfiles` once installed; remote is `git@github.com:murty206/dotfiles.git`.

## Common commands

- `update` — shell function defined in `aliases.sh`: `git pull --rebase`, re-creates missing symlinks for `kitty.conf` and `starship.toml`, runs the `ensure_*` dependency bootstrap, then `source`s `aliases.sh` back into the current shell. This is how changes propagate to a running session — no restart, no relog. Note the `git pull --rebase` refuses on a dirty working tree and `update` returns early — so a tracked file left modified silently disables the whole function (this is why machine-local edits belong in `local.sh`, below).
- `bash install.sh` — idempotent bootstrap. Safe to re-run; every step checks before acting.
- `source ~/.dotfiles/aliases.sh` — reload aliases manually (also exposed as `reload`).

There is no build, lint, or test suite. Validation is "run it on a machine and see."

## Architecture

Three moving parts, plus the installer that wires them together:

1. **`aliases.sh`** — sourced from `~/.zshrc` and `~/.bashrc` via a hook line the installer appends. Contains all aliases, the package-manager-detecting block (paru → apt → dnf, picked at source time via `command -v`), and shell functions (`update`, `ensure_tty_clock`, `canup`/`candown`/`canlog`/`canstat`, `venv`, `extract`, `mkcd`, `cs`, `bak`). The CAN bus helpers exist because this dotfiles set targets embedded/STM32 work. Its last statement sources `local.sh` if present.

   `ensure_*` functions are the dependency bootstrap: each installs one package only if `command -v` says it is missing, and `update` calls them so machines that were set up before a tool was added catch up without re-running `install.sh`. Every such function needs a matching guarded section in `install.sh`.

   **`local.sh`** — gitignored, not in the repo, may not exist. Holds machine-specific aliases (absolute paths, project shortcuts). The repo is public: nothing host-specific may be committed to a tracked file. If a user asks for an alias containing a real home path or a private project name, it goes here, not in `aliases.sh`.

2. **`kitty.conf`** and **`starship.toml`** — config files that live in this repo and are **symlinked** into `~/.config/kitty/kitty.conf` and `~/.config/starship.toml` by the installer. Editing them in the repo immediately affects the running system; no copy step. If a real file already exists at the symlink target, the installer backs it up to `*.bak` before symlinking.

3. **`claude-statusline.sh`** — the Claude Code status line, symlinked to `~/.claude/statusline-command.sh` and pointed at by a `statusLine` key in `~/.claude/settings.json`. Deliberately **not** installed by `install.sh`: `settings.json` holds personal permission rules, hooks and project paths, so the installer stays out of it, and the script is also used on machines the rest of this installer does not cover. Reads the payload JSON on stdin, writes one ANSI line to stdout, and is re-run on every redraw — so it uses exactly one python process (`$PY`, resolved once by a `command -v` builtin: `python3`, falling back to `python` for Git Bash on Windows) and no other forks beyond `git`. This is the constraint that rules out fixing anything with a `tr`/`sed` in the pipeline; platform quirks get fixed inside the python block instead. Five traps worth remembering: percentages are rounded inside python so bash never runs `printf %.0f` on a float (which breaks under a comma decimal separator); quiet labels reset to the default foreground instead of using `90m`, which is pure black in this repo's kitty theme; `sys.stdout.reconfigure(newline="\n")` must stay, or native Windows python emits `\r\n`, `mapfile` leaves a `\r` on every field, and every numeric segment silently disappears; and `wp()` folds a Windows drive-letter/UNC path to forward slashes because `${cwd##*/}` cannot strip a backslash — it is gated on the drive letter precisely so Unix paths containing a backslash are left alone; and `wproj()` returns `""` for a `project_dir` that is the home directory, because the shell's own "root is not `$HOME`" test compares strings and on Windows gets `/c/Users/x` from bash against `C:/Users/x` from the payload — two spellings of one directory, so it never fires and the username is prefixed onto the line. The last three fail with exit status 0 and a line that is partly drawn or plausibly wrong, so they are invisible without fixture tests; the `wproj()` one is checked by case 14, which builds its payload from the running machine's own `$HOME` rather than a literal, since that is the only way the mismatch appears.

   User-facing docs live in **`STATUSLINE.md`**, not `README.md` — the README carries only the sample line, the two install steps and a link. Changing a segment, a colour, a toggle name or a default means updating `STATUSLINE.md`, same hand-sync rule as the README tables below.

   **`WINDOWS.md`** covers the Claude Code side of the repo on Windows — statusline, commands and hook — as a deliberate by-hand install. Decided 2026-08-28: `install.sh` and `update` are not run there because Git Bash's `ln -s` falls back to a plain copy without failing, so the symlink-based automation would appear to work and then silently stop propagating. That makes `update`'s "exists as a real file" warning the *expected* state on a copy-installed Windows box rather than a fault, which is why the message points at `WINDOWS.md`. Anything added to `claude-commands/` or any new `~/.claude/` artefact needs a step there too, or that machine simply never gets it.

4. **`claude-commands/`** — Claude Code slash commands, one `.md` per command, each symlinked into `~/.claude/commands/`. Unlike `claude-statusline.sh` these are installed by `install.sh` and topped up by `update`, because a command file is picked up by its name alone and needs no `settings.json` edit — the reason the statusline stays manual does not apply. Both loops link only what is missing; `update` refuses to clobber a real file at the target and says so, since a hand-written file there means that machine has silently stopped receiving updates for that command.

   `acilis.md` and `kapanis.md` are **one pair sharing one piece of state**: `.claude/session-start` in whatever project is open. `/acilis` creates it and `/kapanis` deletes it after committing, so the file's existence means "a session is open" and its contents are the start time. Break that and the failure is quiet — a duration that cannot be reconstructed, which is exactly what the sessions are measured on. Two traps worth remembering: the clock comes from `` !`date …` `` [dynamic context injection](https://code.claude.com/docs/en/slash-commands), which runs the command through the Bash tool *before* the file reaches the model — so `allowed-tools: Bash(date:*)` has to stay in the frontmatter or the command stalls on a permission prompt, and **a failed injected command aborts the whole invocation**, which is why nothing more complicated than `date` is injected and every file lookup is done with normal tools instead. A project that defines its own `/acilis` or `/kapanis` shadows these; the repo copies are the generic fallback and must stay free of project names, since the repo is public.

5. **`claude-session-context.sh`** — `SessionStart` hook, symlinked to `~/.claude/session-context.sh` and wired by three `SessionStart` entries in `~/.claude/settings.json`. Manual like the statusline, and for the same reason: `settings.json` is personal. Prints one `session-context:` line that lands in Claude's context (`SessionStart` is one of the three events whose stdout does), which is how `/acilis` knows whether the context is fresh. Two design constraints that look arbitrary until they bite: the kind of start arrives as **`$1`, not from stdin** — the matcher values are documented, a `source` field in the payload is not, and a hook that reads an undocumented field breaks silently the day it moves; and the script **always exits 0** and never blocks, because a hook that fails at session start makes every launch wrong. It also counts compactions in `.claude/compact-count`, resetting on the next fresh start, and emits an `ACTION` line at two — the threshold is a variable at the top, and changing it means changing `README.md` too.

6. **`install.sh`** — bootstrap-only. Detects the package manager once at the top, then walks through numbered sections: git **plus the one git identity and the `mailmap.file` wiring**, clone repo, zsh + plugins (zsh-autosuggestions, zsh-syntax-highlighting cloned to `$ZSH_CUSTOM` = `~/.zsh`), Starship, JetBrains Mono Nerd Font, Kitty, fastfetch, tty-clock, **GitHub CLI, Ookla Speedtest, the Claude Code command symlinks**, and the aliases hook. Each section is guarded so re-runs are safe. Note the section numbers in the file are not in reading order — 13 sits above 8 — so add to the list by outcome rather than renumbering.

   **Two rules the identity block encodes, and both are load-bearing.** `git config --get` exits 1 on an unset key while `set -e` is on, so every read is guarded with `|| true` — an unguarded read kills the installer on exactly the fresh machine it exists for. And an identity that is already set and *different* is reported, **never overwritten**: a host that deliberately commits under a work name is the mirror image of the bug this prevents. Same shape as the `update` warning for an unlinked command — the nag is the mechanism, repeated until a human acts.

   The gh step **asks** rather than advises, because `gh auth login` needs a device code and a browser and no installer can do it. It reads from `/dev/tty`, never stdin: under `curl … | bash` stdin *is* the script, and a plain `read` swallows the rest of it and runs half an installer. That is also why the invocation everywhere is `bash <(curl …)` and not a pipe.

   The closing summary **checks every row** rather than asserting it — binaries with `command -v`, the rest by path. Several steps above end in a warning instead of an install, and the summary is the one screen that gets believed.

   Note: `install.sh` contains an embedded fallback `kitty.conf` heredoc that only triggers if the repo's `kitty.conf` is missing. Keep it in sync with the real `kitty.conf` (currently 1984 Dark with customizations) so fresh installs get the same colors as `update`d machines.

7. **`dev_log.md`** and **`next_steps.md`** — opened 2026-09-09, at the repo root. Fixed names and root-first search, the convention settled in `becoming_power_user` on 2026-09-08; this repo was the control case in that decision, the one with a `CLAUDE.md` and neither document.

   `dev_log.md` is history, newest at the top: what a session decided **and why**, what it **refuted**, and what it left **unverified**. `next_steps.md` is the queue. Neither is a place for a rule that is still in force — that belongs here, in this file. The test for promoting something out of the log and into `CLAUDE.md`: *would an agent in a future session do the wrong thing without it?*

   **Write to them during the session, not at its close.** An interrupted session loses whatever was still waiting to be written, and the rationale is the expensive half.

8. **`.mailmap`** — collapses the four git identities in this repo's history (`Muharrem ARLI`, `Murty`, `murty`, `Shalafi`) into one, for `log`, `shortlog` and `blame`. Mapping is **by email**, so no name appears in the file. It changes no commit, and GitHub's own interface does not read it. History was deliberately not rewritten: `dev_log` and `next_steps` in the other repos cite commit hashes.

   It has no extension, so `.gitattributes` names it explicitly — git parses this file itself and a CRLF checkout puts a trailing `\r` inside the email being matched, at which point nothing maps and nothing says so.

## Editing workflow

Edits to `aliases.sh`, `kitty.conf`, or `starship.toml` only need to be committed + pushed; `update` on any other machine pulls them in. Because the config files are symlinked, local edits in the repo take effect immediately on the editing machine — no need to run `update` locally after `git pull`.

When adding a new alias or function, put it in the matching section of `aliases.sh` and update the corresponding table in `README.md` — the README is the user-facing reference and is kept in sync by hand.
