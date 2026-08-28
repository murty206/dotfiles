# Claude Code on a Windows machine

Setting up the three Claude Code pieces of this repo — the status line, the
`/acilis` and `/kapanis` commands, and the session-context hook — on a Windows
box you use occasionally.

**This is a by-hand install, on purpose.** `install.sh` and `update` are not run
here. The reason is the one fact on this page that changes everything else:
Windows does not reliably do symlinks, so the automation those two provide would
be lying to you. Doing it by hand once, knowingly, is better than automation
that silently stops working.

If you use **WSL**, stop reading. WSL is Linux: run `install.sh` there and every
part of this repo works exactly as it does on the Linux machines.

---

## The one thing that is different

On Linux, everything in this repo is symlinked into place. Edit the file in the
repo, `git pull` on another machine, and the live config changes with no copy
step. That is the whole design.

**On Windows, `ln -s` usually copies the file instead of linking it, and does
not tell you.** NTFS has symlinks, but creating one needs a privilege that is
off by default, and the MSYS layer under Git Bash falls back to a plain copy
rather than failing. Exit status 0, file present, everything looks right.

It bites one step later: a copy does not track the repo. You `git pull`, the
repo file changes, and the live file does not. Nothing reports this.

**Find out which one you have** before choosing a route:

```bash
ln -s /etc/hostname /tmp/lntest && ls -la /tmp/lntest && rm /tmp/lntest
```

An arrow (`lntest -> /etc/hostname`) means real symlinks. A plain file means it
copied.

### Route A — turn real symlinks on (recommended, one-time)

Costs one Windows setting and one shell export, and then this machine behaves
like the Linux ones: pull and you are done, forever.

1. **Settings → Privacy & security → For developers → Developer Mode: On.**
   This grants the symlink privilege without needing an administrator shell.
2. In Git Bash, add to `~/.bashrc`:

   ```bash
   export MSYS=winsymlinks:nativestrict
   ```

   `nativestrict` makes `ln -s` **fail loudly** if it cannot create a real
   symlink, which is the point — the silent copy is the problem, not the copy.
3. Re-run the test above. Expect an arrow.

Then follow the setup below using the `ln -s` lines as written.

### Route B — accept copies

Fine for a machine you touch rarely. Use `cp` instead of `ln -s` throughout, and
**read [Keeping it current](#keeping-it-current) — it is the whole cost of this
route.**

---

## What you need first

- **Git Bash.** Not optional, and not only for the status line: `/acilis` and
  `/kapanis` run a shell command to read the clock, and without a `shell:`
  override Claude Code runs that through bash. No bash, and the command fails
  before its content is ever read.
- **Python 3.7+**, under either name. The status line prefers `python3` and
  falls back to `python`, which is what Git Bash provides.
- This repo cloned. The paths below assume `~/.dotfiles`.

All commands below are **Git Bash**, not PowerShell or `cmd`. In Git Bash `~`
is your Windows user profile, so `~/.claude` is the same directory Claude Code
uses.

---

## Setup

### 1. Status line

```bash
ln -s ~/.dotfiles/claude-statusline.sh ~/.claude/statusline-command.sh
```

Then add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

The script itself runs on native Windows unmodified. Three platform differences
were found and fixed inside it, all of which failed with **exit status 0 and a
partly-drawn line** — see [STATUSLINE.md](STATUSLINE.md) → Windows for what they
were and which symptom each produces. Worth reading before you debug anything
here, because none of them looks like an error.

### 2. Slash commands

```bash
mkdir -p ~/.claude/commands
ln -s ~/.dotfiles/claude-commands/acilis.md  ~/.claude/commands/acilis.md
ln -s ~/.dotfiles/claude-commands/kapanis.md ~/.claude/commands/kapanis.md
```

No `settings.json` entry — a file in `~/.claude/commands/` is picked up by its
name alone.

### 3. Session-context hook

```bash
ln -s ~/.dotfiles/claude-session-context.sh ~/.claude/session-context.sh
```

Then add to `~/.claude/settings.json`, merging into any `SessionStart` block that
is already there rather than replacing it:

```json
"SessionStart": [
  { "matcher": "startup|clear",
    "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh startup-or-clear" }] },
  { "matcher": "resume|fork",
    "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh carried-over" }] },
  { "matcher": "compact",
    "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh compact" }] }
]
```

Do **not** copy `settings.json` between machines. The script and the command
files are the shared part; that file holds your permission rules, project paths
and model choice, and is personal to each host.

---

## Check it worked

Open Claude Code in any directory and, in order:

1. **The status line is drawn**, and has numbers in it — not just a directory
   and a model name. If that is all you see, go straight to
   [STATUSLINE.md](STATUSLINE.md) → Troubleshooting; it is almost certainly the
   line-ending trap.
2. **The top of the conversation says `session-context: FRESH`.** If it does
   not, the hook is not wired — `/acilis` will tell you so rather than assume
   the context is clean.
3. **Type `/acilis`.** It should print a real date and time. If you instead see
   the literal text `` !`date ...` ``, bash was not available to run it.

That third check is the one that matters most, because it tests the only
mechanism these commands cannot work without.

### One cosmetic difference

`date '+%Y-%m-%d %H:%M %Z'` prints `+03` on Linux. Git Bash may print the long
Windows zone name instead. It lands in the log heading, so it looks different —
nothing reads it back, so nothing breaks. Trim it in the command file if it
bothers you.

---

## Keeping it current

**Route A (real symlinks):** `git -C ~/.dotfiles pull` and you are done. The
live files are the repo files.

**Route B (copies):** a pull updates the repo and **not** the live files. After
any pull that touched them, copy again:

```bash
cd ~/.dotfiles && git pull --ff-only
cp claude-statusline.sh        ~/.claude/statusline-command.sh
cp claude-session-context.sh   ~/.claude/session-context.sh
cp claude-commands/*.md        ~/.claude/commands/
```

You will not get a reminder from Windows. You will get one from the Linux side:
`update` prints

```
! kapanis.md exists as a real file — not linked, not updating
```

for every command file that is a copy rather than a link. On Linux that line is
a warning. On a Route B Windows box it is the normal state, and it is your cue
that this machine needs the copy step above.

If a command ever behaves like an older version of itself, this is why. Check
the copy before you debug the file.
