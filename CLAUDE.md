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

3. **`claude-statusline.sh`** — the Claude Code status line, symlinked to `~/.claude/statusline-command.sh` and pointed at by a `statusLine` key in `~/.claude/settings.json`. Deliberately **not** installed by `install.sh`: `settings.json` holds personal permission rules, hooks and project paths, so the installer stays out of it, and the script is also used on machines the rest of this installer does not cover. Reads the payload JSON on stdin, writes one ANSI line to stdout, and is re-run on every redraw — so it uses exactly one python process (`$PY`, resolved once by a `command -v` builtin: `python3`, falling back to `python` for Git Bash on Windows) and no other forks beyond `git`. This is the constraint that rules out fixing anything with a `tr`/`sed` in the pipeline; platform quirks get fixed inside the python block instead. Four traps worth remembering: percentages are rounded inside python so bash never runs `printf %.0f` on a float (which breaks under a comma decimal separator); quiet labels reset to the default foreground instead of using `90m`, which is pure black in this repo's kitty theme; `sys.stdout.reconfigure(newline="\n")` must stay, or native Windows python emits `\r\n`, `mapfile` leaves a `\r` on every field, and every numeric segment silently disappears; and `wp()` folds a Windows drive-letter/UNC path to forward slashes because `${cwd##*/}` cannot strip a backslash — it is gated on the drive letter precisely so Unix paths containing a backslash are left alone. The last two fail with exit status 0 and a partially-drawn line, so they are invisible without fixture tests.

   User-facing docs live in **`STATUSLINE.md`**, not `README.md` — the README carries only the sample line, the two install steps and a link. Changing a segment, a colour, a toggle name or a default means updating `STATUSLINE.md`, same hand-sync rule as the README tables below.

4. **`claude-commands/`** — Claude Code slash commands, one `.md` per command, each symlinked into `~/.claude/commands/`. Unlike `claude-statusline.sh` these are installed by `install.sh` and topped up by `update`, because a command file is picked up by its name alone and needs no `settings.json` edit — the reason the statusline stays manual does not apply. Both loops link only what is missing; `update` refuses to clobber a real file at the target and says so, since a hand-written file there means that machine has silently stopped receiving updates for that command.

   `acilis.md` and `kapanis.md` are **one pair sharing one piece of state**: `.claude/session-start` in whatever project is open. `/acilis` creates it and `/kapanis` deletes it after committing, so the file's existence means "a session is open" and its contents are the start time. Break that and the failure is quiet — a duration that cannot be reconstructed, which is exactly what the sessions are measured on. Two traps worth remembering: the clock comes from `` !`date …` `` [dynamic context injection](https://code.claude.com/docs/en/slash-commands), which runs the command through the Bash tool *before* the file reaches the model — so `allowed-tools: Bash(date:*)` has to stay in the frontmatter or the command stalls on a permission prompt, and **a failed injected command aborts the whole invocation**, which is why nothing more complicated than `date` is injected and every file lookup is done with normal tools instead. A project that defines its own `/acilis` or `/kapanis` shadows these; the repo copies are the generic fallback and must stay free of project names, since the repo is public.

5. **`claude-session-context.sh`** — `SessionStart` hook, symlinked to `~/.claude/session-context.sh` and wired by three `SessionStart` entries in `~/.claude/settings.json`. Manual like the statusline, and for the same reason: `settings.json` is personal. Prints one `session-context:` line that lands in Claude's context (`SessionStart` is one of the three events whose stdout does), which is how `/acilis` knows whether the context is fresh. Two design constraints that look arbitrary until they bite: the kind of start arrives as **`$1`, not from stdin** — the matcher values are documented, a `source` field in the payload is not, and a hook that reads an undocumented field breaks silently the day it moves; and the script **always exits 0** and never blocks, because a hook that fails at session start makes every launch wrong. It also counts compactions in `.claude/compact-count`, resetting on the next fresh start, and emits an `ACTION` line at two — the threshold is a variable at the top, and changing it means changing `README.md` too.

6. **`install.sh`** — bootstrap-only. Detects the package manager once at the top, then walks through numbered sections: git, clone repo, zsh + plugins (zsh-autosuggestions, zsh-syntax-highlighting cloned to `$ZSH_CUSTOM` = `~/.zsh`), Starship, JetBrains Mono Nerd Font, Kitty, fastfetch, and the aliases hook. Each section is guarded so re-runs are safe.

   Note: `install.sh` contains an embedded fallback `kitty.conf` heredoc that only triggers if the repo's `kitty.conf` is missing. Keep it in sync with the real `kitty.conf` (currently 1984 Dark with customizations) so fresh installs get the same colors as `update`d machines.

## Editing workflow

Edits to `aliases.sh`, `kitty.conf`, or `starship.toml` only need to be committed + pushed; `update` on any other machine pulls them in. Because the config files are symlinked, local edits in the repo take effect immediately on the editing machine — no need to run `update` locally after `git pull`.

When adding a new alias or function, put it in the matching section of `aliases.sh` and update the corresponding table in `README.md` — the README is the user-facing reference and is kept in sync by hand.
