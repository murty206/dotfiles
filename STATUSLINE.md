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

**Requirements:** `python3`, and bash 4+ for `mapfile`. On macOS that means
Homebrew bash, not the 3.2 the system ships. One python process per redraw,
about 35 ms.

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

Three cases, and two of them need no work.

**WSL** — it is Linux. Follow the Linux install above and you are done. This is
the option that actually gives you one identical status line everywhere.

**Native Windows + Git Bash** — try it unmodified first. Git Bash ships bash 5,
so `mapfile` is fine. The one likely snag is the interpreter name:

```bash
python3 --version   # if this works, change nothing
python  --version   # if only this works, change python3 -> python in the script
```

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
> Keep the six toggles at the top of the file under the same names:
> SHOW_TOKENS, SHOW_SEVEN_DAY, SHOW_SUBPATH, SHOW_FLAGS, DEFAULT_EFFORT,
> BAR_WIDTH.
>
> Test with fixture payloads before declaring it done: normal, `fast_mode` true,
> quota at 100%, `rate_limits` missing entirely, malformed JSON, empty input.
> None may crash; missing data must drop its segment silently.
>
> Do not edit my settings.json — tell me what to add and I will do it.

That last line matters: `settings.json` contains your permission rules and
project paths. Do not hand it to an agent, and do not sync it between machines.

---

## Toggles

Six variables at the top of the script.

| Variable | Default | Effect | Columns saved when off |
|----------|---------|--------|------------------------|
| `SHOW_TOKENS` | `1` | The `124k/1M` token count before the context percentage | ~9 |
| `SHOW_SEVEN_DAY` | `1` | The trailing seven-day quota | ~10 |
| `SHOW_SUBPATH` | `1` | Project-relative path instead of a bare basename | varies |
| `SHOW_FLAGS` | `1` | The `⚡` / effort / thinking markers |
| `SHOW_SESSION_AGE` | `1` | The trailing `sess 13h` age marker |
| `SESSION_WARN_H` | `4` | Hours before the age appears at all, in yellow |
| `SESSION_ALARM_H` | `12` | Hours before it turns red | 0 when normal |
| `DEFAULT_EFFORT` | `high` | Which effort level counts as normal and stays hidden | — |
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
python side is failing — run it without the `2>/dev/null` on the `python3 -c`
call to see the error.

**Wrong numbers, or a stale reset time.** Statusline redraws are driven by
Claude Code, not by a timer. The clock only advances when something else
happens.

**Inspecting the raw payload.** Set `CLAUDE_STATUSLINE_DEBUG=1` and the script
dumps what it receives to `$TMPDIR/claude-statusline-debug.json`, mode `600`.
Off by default and worth leaving off: the payload carries `session_id`,
`transcript_path` and `cwd`, none of which belong in a world-readable file. An
earlier version of this script wrote that dump unconditionally on every redraw.
Delete the file when you are finished with it.
