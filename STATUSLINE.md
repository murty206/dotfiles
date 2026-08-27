# Claude Code status line

```
myproject/src [main] | Opus 5 · 1M ⚡ | 124k/1M 12% █░░░░░░░░░ · █████░░░░░ 55% · 3h35m [13:50] · 7d 16% · sess 13h
```

One line, `claude-statusline.sh`, symlinked into `~/.claude/`. Same file on every
machine — that is the whole point, so resist the urge to fork it per host.

| Segment | Meaning |
|---------|---------|
| `myproject/src` | Current directory. Prefixed with the project name when you are below the project root — plain basename otherwise, and never prefixed with `$HOME` |
| `[main]` | Git branch, or the short SHA when detached. Absent outside a repo |
| `Opus 5 · 1M` | Model. The `(1M context)` suffix is rewritten as a `· 1M` tag to save a quarter of the line |
| `⚡` | Fast mode is on. Only shown when it is |
| `·low` `·no-think` | Reasoning effort left somewhere other than `DEFAULT_EFFORT`, or thinking switched off. Only shown when abnormal — these are easy to toggle and easy to forget |
| `124k/1M 12% █░░░░░░░░░` | Context window: tokens used, percentage, bar |
| `· █████░░░░░ 55%` | Five-hour quota |
| `· 3h35m [13:50]` | Time until the five-hour quota resets, and the clock time it happens |
| `· 7d 16%` | Seven-day quota. No bar — but this is the window that costs you days rather than hours when it fills |
| `· sess 13h` | How long this session has been running. Hidden below `SESSION_WARN_H`, yellow from there, red from `SESSION_ALARM_H`, switching to days past four times the alarm |

Bars and percentages run green under 50%, yellow to 79%, red at 80% and above.
The full line is about 105 columns; see [Toggles](#toggles) if that is too wide.

---

## Install — Linux and WSL

Deliberately **not** part of `install.sh`. `~/.claude/settings.json` holds your
permission rules, hooks and project paths; an installer has no business merging
itself into it. Two steps:

```bash
ln -sf ~/.dotfiles/claude-statusline.sh ~/.claude/statusline-command.sh
```

then add to `~/.claude/settings.json`:

```json
"statusLine": { "type": "command", "command": "bash ~/.claude/statusline-command.sh" }
```

Check it renders before restarting anything:

```bash
echo '{"workspace":{"current_dir":"/tmp/demo","project_dir":"/tmp/demo"},
       "model":{"display_name":"Opus 5 (1M context)","id":"claude-opus-5[1m]"},
       "context_window":{"used_percentage":12,"total_input_tokens":124000,
                         "context_window_size":1000000},
       "rate_limits":{"five_hour":{"used_percentage":55},"seven_day":{"used_percentage":16}},
       "fast_mode":true}' | bash ~/.claude/statusline-command.sh
```

The symlink means `update` propagates changes with no reinstall.

**Requirements:** python 3.7+ under either name — the script prefers `python3`
and falls back to `python`, which is what Git Bash on Windows provides — and
bash 4+ for `mapfile`. On macOS that means Homebrew bash, not the 3.2 the system
ships. One python process per redraw, about 35 ms.

Do **not** copy `settings.json` between machines. The script is the shared part;
the settings file is personal to each host.

---

## Fonts

Four non-ASCII characters, all of them plain Unicode — **no Nerd Font
private-use icons**, so this is far less fussy than a Starship prompt:

| Glyph | Codepoint | Name |
|-------|-----------|------|
| `█` | U+2588 | Full block — filled bar cells |
| `░` | U+2591 | Light shade — empty bar cells |
| `·` | U+00B7 | Middle dot — separators |
| `⚡` | U+26A1 | High voltage — fast mode marker |

Any competent monospace Unicode font covers all four. JetBrains Mono Nerd Font
does, including U+26A1, which Nerd Fonts patch in as a monochrome glyph. So does
stock DejaVu Sans Mono. You do not need a patched font for the status line
alone — but you do need one for the Starship prompt, so you will end up with it
anyway.

**Linux:** `install.sh` already handles this. To do it by hand:

```bash
mkdir -p ~/.local/share/fonts
curl -fsSL -o /tmp/JetBrainsMono.tar.xz \
  https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
tar -xf /tmp/JetBrainsMono.tar.xz -C ~/.local/share/fonts
fc-cache -f ~/.local/share/fonts
```

Verify a specific glyph is actually reachable:

```bash
fc-list ':charset=26A1' family | head    # who provides the lightning bolt
fc-list | grep -c 'JetBrainsMono.*Nerd'  # non-zero once installed
```

**Windows:** download `JetBrainsMono.zip` from the
[Nerd Fonts releases](https://github.com/ryanoasis/nerd-fonts/releases/latest),
extract, select the `.ttf` files, right-click → **Install for all users**. Then
point your terminal at it — in Windows Terminal, Settings → your profile →
Appearance → Font face → `JetBrainsMono Nerd Font Mono`.

**macOS:** `brew install --cask font-jetbrains-mono-nerd-font`.

If a glyph still renders as a box:

- The bars are the load-bearing part. If `█ ░` are broken, fix the font.
- If only `⚡` is broken, set `SHOW_FLAGS=0` and move on.
- A colour-emoji fallback may draw `⚡` double-width and shift the line by one
  cell. Harmless, but a monochrome font avoids it.

---

## Windows

Three cases, and only the last one needs work.

**WSL** — it is Linux. Follow the Linux install above and you are done. This is
the option that actually gives you one identical status line everywhere.

**Native Windows + Git Bash** — works unmodified. It did not always. Three
things differ from Linux, all three are now handled in the script, and **not one
of them announced itself**: the script exited 0 and drew a line every time, with
pieces quietly missing. They are written down because the symptoms are the only
way to recognise them, and because anyone running a copy from before this was
fixed will see exactly these.

| What differs on Windows | Symptom | Handled by |
|---|---|---|
| Git Bash finds `python`, not `python3` | nothing renders at all | `command -v python3` picks the name — a builtin, so no extra process per redraw |
| Native Windows python writes `\r\n` on stdout | context and quota segments vanish; `·no-think` sticks on permanently | `sys.stdout.reconfigure(newline="\n")`, behind a `hasattr` guard for python < 3.7 |
| Claude Code passes `C:\Users\...` | the entire path prints instead of the basename | backslashes folded to `/`, gated on a drive letter or UNC prefix so Unix paths keep theirs |

The middle one is worth understanding rather than copying. `mapfile` splits the
python output on `\n`, so a producer emitting `\r\n` leaves a trailing `\r` on
every single field. `is_num "12\r"` is then false, which drops the whole context
and quota block, and `"yes\r"` never equals `"yes"`, which pins the no-think
marker on. The directory and the model name still render perfectly — that is
what makes it hard to see. If you ever meet a status line that has a directory
and a model and nothing else, suspect line endings before anything else.

All three changes are inert on Linux: the interpreter check finds `python3`, the
reconfigure call is a no-op on a stream that already uses `\n`, and the path
fold never fires without a drive letter. Verified by running the fixture set on
both.

**Anything else** — hand the script to an agent. It is public, so give the URL
rather than the file:

```
https://raw.githubusercontent.com/murty206/dotfiles/main/claude-statusline.sh
```

A prompt that produces a usable port:

> This is the Claude Code status line I use on Linux:
> https://raw.githubusercontent.com/murty206/dotfiles/main/claude-statusline.sh
>
> I want it running on this Windows machine and looking **identical**. The
> segment meanings and colour thresholds are documented in STATUSLINE.md in the
> same repo — follow it.
>
> First work out: which shell Claude Code uses to run the `statusLine` command
> here, whether Git Bash is available, and whether the interpreter is `python3`
> or `python`. Prefer the smallest change that works over a rewrite.
>
> Three platform differences already bit me once on native Windows, and none of
> them produced an error — the script exited 0 with pieces of the line missing.
> Check all three explicitly rather than trusting that it looks fine:
> the interpreter name; whether python writes `\r\n` on stdout (`mapfile` splits
> on `\n`, so a trailing `\r` makes every numeric test fail); and the path
> separator in `current_dir` (the script strips to a basename with `/`).
> Fix these in the producer, not by adding a `tr` or `sed` to the pipeline —
> the script is built around exactly one python process and no other forks.
>
> Keep the nine toggles at the top of the file under the same names:
> SHOW_TOKENS, SHOW_SEVEN_DAY, SHOW_SUBPATH, SHOW_FLAGS, SHOW_SESSION_AGE,
> SESSION_WARN_H, SESSION_ALARM_H, DEFAULT_EFFORT, BAR_WIDTH.
>
> Test with fixture payloads before declaring it done: normal, `fast_mode` true,
> quota at 100%, `rate_limits` missing entirely, malformed JSON, empty input,
> a path below the project root, and an absolute path in this platform's own
> format. None may crash; missing data must drop its segment silently.
> Build the payloads in a real language, not by hand in the shell — a fixture
> mangled by quoting looks exactly like a broken script and will send you after
> the wrong bug.
>
> Do not edit my settings.json — tell me what to add and I will do it.

That last line matters: `settings.json` contains your permission rules and
project paths. Do not hand it to an agent, and do not sync it between machines.

---

## Toggles

Nine variables at the top of the script.

| Variable | Default | Effect | Columns saved when off |
|----------|---------|--------|------------------------|
| `SHOW_TOKENS` | `1` | The `124k/1M` token count before the context percentage | ~9 |
| `SHOW_SEVEN_DAY` | `1` | The trailing seven-day quota | ~10 |
| `SHOW_SUBPATH` | `1` | Project-relative path instead of a bare basename | varies |
| `SHOW_FLAGS` | `1` | The `⚡` / effort / thinking markers | 0 when normal |
| `SHOW_SESSION_AGE` | `1` | The trailing `sess 13h` age marker | 0 below the threshold |
| `SESSION_WARN_H` | `4` | Hours before the age appears at all, in yellow | — |
| `SESSION_ALARM_H` | `12` | Hours before it turns red | — |
| `DEFAULT_EFFORT` | `xhigh` | Which effort level counts as normal and stays hidden. Set it to whatever `effortLevel` your `settings.json` uses, or the marker you wanted as a warning becomes permanent furniture | — |
| `BAR_WIDTH` | `10` | Cells per bar | 2 per cell removed |

The script cannot detect terminal width: Claude Code runs it without a
controlling terminal, so `tput cols` reports a meaningless default and
`/dev/tty` does not exist. Hence toggles rather than automatic reflow.

---

## Troubleshooting

**Text is invisible, or some of it is.** Do not use `90m` (bright black) for
anything. Plenty of dark themes — including 1984 Dark in this repo's
`kitty.conf` — map bright black to pure `#000000`, which vanishes on a dark
background. Quiet labels in the script reset to the default foreground instead,
which is readable by definition in any theme.

**The line wraps.** Turn off `SHOW_TOKENS` first, then `SHOW_SEVEN_DAY`.

**Why a session-age marker at all.** A session that has been open for days is
the most expensive habit there is — every turn re-reads the whole accumulated
context, and repeated compaction quietly degrades what the model remembers.
Nothing else in the UI reports it: the context percentage resets after each
compaction, so a three-month session can sit at a comfortable 30% forever.
The marker stays hidden for normal sessions and only speaks up once the number
is worth acting on.

**Nothing appears at all.** Run the fixture command from the install section by
hand. If that prints a line, the script is fine and the problem is the
`statusLine` entry in `settings.json`. If it prints only a directory name, the
python side is failing — run it without the `2>/dev/null` on the `"$PY" -c`
call to see the error.

**A directory and a model, and nothing after them.** Every numeric segment gone,
`·no-think` showing even with thinking on, and exit status 0. That is a line
ending problem: python is emitting `\r\n`, `mapfile` splits on `\n`, and the
`\r` left on each field makes `is_num "12\r"` false and `"yes\r" != "yes"`.
Handled in the script since the Windows fixes, so this only appears on an older
copy — `update`, or check that the `sys.stdout.reconfigure` line is present.

**The whole absolute path where a basename belongs.** The path separator is not
`/`, so `${cwd##*/}` had nothing to strip. Same fix, same version — the script
folds a Windows drive-letter or UNC path to forward slashes before the shell
sees it.

**Wrong numbers, or a stale reset time.** Statusline redraws are driven by
Claude Code, not by a timer. The clock only advances when something else
happens.

**Inspecting the raw payload.** Set `CLAUDE_STATUSLINE_DEBUG=1` and the script
dumps what it receives to `$TMPDIR/claude-statusline-debug.json`, mode `600`.
Off by default and worth leaving off: the payload carries `session_id`,
`transcript_path` and `cwd`, none of which belong in a world-readable file. An
earlier version of this script wrote that dump unconditionally on every redraw.
Delete the file when you are finished with it.
