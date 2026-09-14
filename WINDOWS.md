# Claude Code on a Windows machine

Setting up the three Claude Code pieces of this repo — the status line, the
`/acilis` and `/kapanis` commands, and the session-context hook — on a Windows
box you use occasionally.

**`install.sh` runs here now, and does most of this page for you.** Start at
[Run the installer](#run-the-installer). What is left by hand is the status line
and the session-context hook, and only because both need an edit to
`settings.json` — a file the installer does not touch on any platform, because it
holds your permission rules and model choice and is personal to each host.

**This page used to say the install was by hand on purpose, and that reason was
not wrong — it was answered.** The fact it rested on still holds: Windows does
not reliably do symlinks, `ln -s` falls back to a plain copy, and it returns 0
while doing it, so the automation genuinely would have been lying to you. What
changed on 2026-09-14 is that the installer now **refuses to start** unless it
can create a real symlink. The one thing it used to be able to do silently is
the one thing it can no longer do at all.

It is worth knowing what the by-hand route cost while it stood, because it is
the argument for the change: `next_steps.md` #1 was a Windows machine running
with **zero aliases**, for as long as nobody happened to check. A step that
nothing enforces is a step the next machine misses.

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
d=$(mktemp -d) && : > "$d/target" && ln -s "$d/target" "$d/link" && ls -la "$d/link"; rm -rf "$d"
```

An arrow (`link -> /tmp/…/target`) means real symlinks. A plain file means it
copied.

**The probe makes its own target, and that is not tidiness.** This check used to
read `ln -s /etc/hostname /tmp/lntest`, which fails on Git Bash for a reason that
has nothing to do with symlinks: there is no `/etc/hostname` there. MSYS needs
the target to exist to decide whether to create a file link or a directory link,
so a missing target fails with `No such file or directory` — on a machine where
real symlinks work perfectly. It looked like a failed capability check and was a
failed *command*, which is the same trap as everything else on this page.
`install.sh` uses this same self-contained form for its own preflight.

### The line-ending check lies here too, and it lies in the safe-looking direction

`.gitattributes` pins every shared file in this repo to LF, so the obvious way to
verify a file you edited is to count carriage returns:

```bash
grep -c $'' file        # DO NOT trust this on Git Bash
```

**It matches every line, whatever the file contains.** The `` is lost on its
way into the native `grep.exe`, leaving an effectively empty pattern. Measured
2026-09-14 on a file built to have exactly one CRLF line and one LF line — it
answered **2**.

Both of its answers mislead, which is why it is worth a section:

- On a clean LF file it can report **every line as a CR line**, so a file that is
  fine looks broken.
- Read the other way round — "the count did not go up, so we are clean" — it
  reports a pass it never performed.

Count the bytes instead. This is what `install.sh` and every check in this repo's
log now use:

```bash
python -c "import io;b=io.open('file','rb').read();print(b.count(b'
'))"
```

`0` means LF throughout. The same command works unchanged on Linux, so there is
no reason to keep two forms of the check.

### Route A — turn real symlinks on (recommended, one-time)

Costs one Windows setting and one shell export, and then this machine behaves
like the Linux ones: pull and you are done, forever.

**Step 1 is yours and the installer cannot do it** — it is a Windows setting, not
a file. Steps 2 and 3 are done for you by `install.sh`; they are written out here
because you need to be able to check them, and because a machine set up before
2026-09-14 has them by hand.

1. **Settings → Privacy & security → For developers → Developer Mode: On.**
   This grants the symlink privilege without needing an administrator shell.
   **Do this before running the installer** — it probes for the privilege and
   stops with this instruction if it is missing.
2. In Git Bash, add to `~/.bashrc` (**`install.sh` does this**):

   ```bash
   export MSYS="winsymlinks:nativestrict${MSYS:+ $MSYS}"
   ```

   `nativestrict` makes `ln -s` **fail loudly** if it cannot create a real
   symlink, which is the point — the silent copy is the problem, not the copy.

   Appended rather than assigned, because `MSYS` may already carry something:
   Claude Code exports `MSYS=disable_pcon` into the shells it spawns, and a bare
   assignment throws that away.
3. **Make sure `~/.bash_profile` exists and sources `~/.bashrc`** (**`install.sh`
   does this too**). Git Bash
   starts a *login* shell, and neither `/etc/profile` nor `/etc/bash.bashrc`
   sources `~/.bashrc` — so on a machine that never had one, the export above is
   never read and Route A stays off while looking set up. If the file is
   missing:

   ```bash
   echo '[ -f ~/.bashrc ] && . ~/.bashrc' >> ~/.bash_profile
   ```
4. Re-run the test above, in a **new** Git Bash window so the profile is read.
   Expect an arrow.

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

## Run the installer

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/murty206/dotfiles/main/install.sh)
```

Process substitution, not `curl … | bash` — piping makes the script itself
stdin, so anything that reads from the terminal consumes the script instead and
runs half an installer.

It recognises MSYS and **stops short of the sections that need a package
manager**: zsh and its plugins, Starship, the Nerd Font, Kitty, fastfetch,
tty-clock, `gh` and speedtest are skipped. Its closing summary lists them under
*"Not attempted"* rather than *"NOT installed"*, because those are different
claims and only one of them is true here.

What it does do on this platform:

| | |
|---|---|
| Symlink preflight | Probes for the privilege and **refuses to start** without it |
| Route A | Appends `winsymlinks:nativestrict` to `~/.bashrc`, creates `~/.bash_profile` |
| Git identity | Sets it if unset; **reports and never overwrites** a different one |
| Mailmap | Points `mailmap.file` at this repo's `.mailmap` |
| Clone | Over **HTTPS** here, not SSH — no key needs to exist first |
| Slash commands | Symlinks `acilis.md` and `kapanis.md` |
| Global `CLAUDE.md` | Symlinks it |
| Aliases | Hooks `aliases.sh` into `~/.bashrc` |

Every step is idempotent — a second run warns and skips rather than duplicating.

**Two things it deliberately leaves to you**, both below: the status line and the
session-context hook. Both need an entry in `~/.claude/settings.json`, and that
file is not the installer's business on any platform — it carries your
permission rules, project paths and model choice, and is personal to each host.
Do not copy it between machines.

---

## Setup — the part the installer does not do

### 1. Status line

```bash
ln -s ~/.dotfiles/claude-statusline.sh ~/.claude/statusline-command.sh
```

Then add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

The script itself runs on native Windows unmodified. Four platform differences
were found and fixed inside it, all of which failed with **exit status 0 and a
line that was partly drawn or quietly wrong** — see
[STATUSLINE.md](STATUSLINE.md) → Windows for what they were and which symptom
each produces. Worth reading before you debug anything here, because none of
them looks like an error.

### 2. Slash commands — **done by `install.sh`**

Kept here to check against, and for a machine set up before 2026-09-14.

```bash
mkdir -p ~/.claude/commands
ln -s ~/.dotfiles/claude-commands/acilis.md  ~/.claude/commands/acilis.md
ln -s ~/.dotfiles/claude-commands/kapanis.md ~/.claude/commands/kapanis.md
```

No `settings.json` entry — a file in `~/.claude/commands/` is picked up by its
name alone, which is why the installer can do this one and not the two above.

### 2b. Global CLAUDE.md — **done by `install.sh`**

```bash
ln -s ~/.dotfiles/claude-global.md ~/.claude/CLAUDE.md
```

Loaded in every project on the machine. Also no `settings.json` entry. If a real
file already exists there, move it aside first — the link is what keeps this
machine in step with the others. The installer backs it up to `CLAUDE.md.bak`
rather than deciding for you.

### 3. Session-context hook

```bash
ln -s ~/.dotfiles/claude-session-context.sh ~/.claude/session-context.sh
```

Then add to `~/.claude/settings.json`, merging into any `SessionStart` block that
is already there rather than replacing it. **`SessionStart` belongs inside the
top-level `"hooks"` object**, not beside it — a `"SessionStart"` key at the top
level is still valid JSON, and is ignored without a word:

```json
"hooks": {
  "SessionStart": [
    { "matcher": "startup|clear",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh startup-or-clear" }] },
    { "matcher": "resume|fork",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh carried-over" }] },
    { "matcher": "compact",
      "hooks": [{ "type": "command", "command": "bash ~/.claude/session-context.sh compact" }] }
  ]
}
```

The only symptom of getting that wrong is the missing `session-context:` line at
the top of the next session — same shape as the rest of this page. `/hooks`
inside Claude Code lists what actually registered.

Do **not** copy `settings.json` between machines. The script and the command
files are the shared part; that file holds your permission rules, project paths
and model choice, and is personal to each host.

### 4. Git identity and mailmap — **done by `install.sh`**

This was the one part of the page with nothing to do with Claude Code. It was
here because `install.sh` never ran on Windows, so without doing it by hand the
machine simply never got it. That is no longer the reason it is here — it is
here so you can check it, and because the installer **never overwrites** an
identity that differs from the standard one: it reports it and moves on, which
is deliberate and means a work identity survives.

```bash
git config --global user.name  murty
git config --global user.email murty206@gmail.com
git config --global mailmap.file ~/.dotfiles/.mailmap
```

Check the first two before running them — if this host already commits under a
deliberate work identity, set only the mailmap:

```bash
git config --global user.name; git config --global user.email
```

The mailmap line is the one that matters most on a machine that has been in use
for a while: it collapses every identity in the repos already on this disk,
without touching a single commit. Verify with

```bash
git -C ~/.dotfiles shortlog -sne
```

which should print **one** contributor line, not four.

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
4. **In a new Git Bash window, `alias | wc -l` prints around 54**, not 2. Two
   of those are Git Bash's own (`node`, `winget`); the rest are this repo's.
   `echo $MSYS` should contain `winsymlinks:nativestrict`.

The third check is the one that matters most, because it tests the only
mechanism these commands cannot work without. The fourth is the cheapest, and it
is the one that would have caught `next_steps.md` #1 on the day it happened.

**Of 53 aliases, 35 resolve here** — measured 2026-09-09. The 18 that do not are
twelve systemd tools, three Linux-only utilities (`free`, `ss`, `watch`), two
packages not installed on this box, and `py3`, because Git Bash has `python` and
no `python3`. That is expected, not a broken install.

### One cosmetic difference

`date '+%Y-%m-%d %H:%M %Z'` prints `+03` on Linux. Git Bash may print the long
Windows zone name instead. It lands in the log heading, so it looks different —
nothing reads it back, so nothing breaks. Trim it in the command file if it
bothers you.

---

## Keeping it current

**Route A (real symlinks):** `git -C ~/.dotfiles pull` and you are done. The
live files are the repo files.

The `update` function from `aliases.sh` is now *reachable* here — the aliases
load, so the name resolves. **It has not been exercised on Windows**, and it
does more than pull: it also re-checks the symlinks and warns about files that
are copies. Treat `git pull` as the supported route on this platform until
someone runs `update` here and writes down what happened — `next_steps.md` #1c.

**Route B (copies):** a pull updates the repo and **not** the live files. After
any pull that touched them, copy again:

```bash
cd ~/.dotfiles && git pull --ff-only
cp claude-statusline.sh        ~/.claude/statusline-command.sh
cp claude-session-context.sh   ~/.claude/session-context.sh
cp claude-commands/*.md        ~/.claude/commands/
cp claude-global.md            ~/.claude/CLAUDE.md
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
