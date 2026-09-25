# dotfiles — dev log

What each session did and **why**. Newest at the top. An entry is a question and
its answer; the rationale is the part that evaporates from a conversation and the
expensive part to reconstruct, so it goes here rather than in the commit alone.

Opened 2026-09-09, alongside `next_steps.md`, under the naming convention
settled in `becoming_power_user` on 2026-09-08.

---

## 2026-09-24 08:20 → 2026-09-25 08:59 — The desktop joined the repo, and `install.sh` learned its first non-package-manager condition

**The question arrived in three steps, and each one changed the answer.** It
started as *"bilgisayarımda fotoğraf görüntüleyici yok"*, became *"bu yaptığımız
kde özelleştirmelerini kaybetmek istemiyorum"*, and settled as **"ama makineden
bağımsız her kde kurulumumda bu ayarları almak istiyorum."** The third sentence
is the one that belongs here: it turned a backup problem into a portability
problem, which is this repo's own subject.

### What was decided

- **`kde/` carries configuration, not a copy of `~/.config`.** 14 files, 42,244
  bytes. The line between them is whether a file records a *choice* or a
  *state*: `kwinoutputconfig.json` holds six `edidHash` entries and is monitor
  identity, the automounter file holds disk and USB labels, `kconf_updaterc` is
  KDE's own migration ledger. None of those mean anything on another machine,
  and `kde/README.md` names every exclusion with its reason.
- **`$HOME` is stored literally and substituted at apply time.** murty's
  reason, and it is the whole argument: *"shalafi kullanıcı adı sabit
  olmayabilir."* Hard-coding would work today and fail **silently** on the
  first machine with another user name — KDE does not complain about a
  wallpaper it cannot find, it falls back without a word.
- **`install.sh` section 14 branches on `command -v plasmashell`.** Not
  `XDG_CURRENT_DESKTOP`: that asks whether Plasma is the session running the
  script, which on a fresh machine is usually false, since the installer runs
  from a TTY or over SSH. The branch would have skipped its own reason for
  existing.
- **The config is applied once, then left alone.** A marker file records the
  commit it came from. A second run would discard whatever was tuned by hand
  since the first, and re-applying is available on purpose: `kde/apply.sh`.

### What the measuring changed

**Two numbers were retracted the same day they were taken, and the method note
is the useful part.** The config set was reported first as 204 KB, then as
~186 KB; it is **65.9 KB** for the touched set and **41.3 KB** for what is
carried. Two separate faults: `du` rounds every file up to a 4 KB block, which
on 25 files averaging 2.7 KB more than doubles the answer — and the command had
quietly measured *all* `rc` files in `~/.config` rather than the 25 it claimed.
**Many small files are counted with `find -printf '%s'`, not `du`.**

**The claim that this could not go in a public repo did not survive a grep.**
The first reading was that these files are machine-specific — monitor
identities, hardware names. Measured file by file: of eight, **two** match
`/home/`, `/run/media`, `/dev/disk` or `UUID`, for **ten lines**, all of them
wallpaper paths under `$HOME`. A substitution, not an obstacle. The genuinely
machine-bound files are few, and they are excluded rather than templated.

### The themes are fetched, not vendored — and the obvious tool was the wrong one

Offering to add the 9.6 MB of theme assets to the repo was declined, and the
reason was better than the offer: *"zaten indirebiliyoruz."* They are on the KDE
Store with stable content ids, so the repo carries the **list**, not the bytes.
`themes.tsv` names 16 entries; `themes.sh` resolves each at run time, because the
Store's download URLs are signed and expire.

**The convenient route would have cost seven times the download.** Installing the
global theme the documented way —

```
kpackagetool6 -t Plasma/LookAndFeel -i Beauty-Color-Global-6.tar.gz
```

— resolves the theme's dependencies through KNewStuff and fetches them:
**89,470 files, 817 MB of icon themes**, five of them, and none is the
`Slot-Beauty-Dark-Icons-V-3` the configuration actually selects. The same
archive unpacked with `tar` gives **9 files**. Measured into an empty home,
both ways. The list as written fetches ~140 MB that is used; the convenient
route fetches ~960 MB, most of it never looked at.

**And it answers a question filed earlier the same day.** The five unused icon
sets in `~/.local/share/icons` were noted as a curiosity, with "they may have
been left on purpose" as the charitable reading. They were not chosen at all —
they arrived as dependencies of the global theme, on this machine, the same way.

**The Store rate-limits, and lies about it in a way that misdirects.** A dozen
downloads inside a few minutes gets refused, and the refusal comes back as HTTP
200 with an XML error body written to disk under the archive's filename. Left
undetected it surfaces three steps later as *"unpack failed"*, which points at
the archive instead of the server. Now checked for by name.

### Two bugs that reading would not have found

Both were caught by running the thing, and both are the kind that look correct
on the page:

- `local id="$1" pattern="$2" xml="$tmp/$id.xml"` — bash expands every word of a
  `local` command before assigning any of them, so `$id` is not yet set when
  `xml` is built. Silent normally; fatal under `set -u`.
- The download was saved as `<name>.pkg`. `kpackagetool6` chooses its reader
  from the **extension**, so a perfectly good tarball was refused. `tar` sniffs
  the content and did not care, which is why half the entries worked and half
  did not.

### What is not done, and is written down rather than assumed

**These files have never been restored onto a fresh install.** They were
extracted from a working desktop, which is not the same as knowing they rebuild
one. `apply.sh` backs up everything it replaces for that reason, and the four
branches of section 14 were exercised against scratch `HOME` directories — the
live desktop was never written to. The first real installation is the test.

**The themes are installed by `themes.sh`, added later in the same session —**
see the two sections above. What is still not proven is that the *result looks
right*: every route was exercised into scratch homes, which shows the files land
where the configuration expects them and nothing more.

### The record the ids came from was retired, and it split in two

The list of KDE Store ids had been kept by hand in a note under
`~/.local/share/`. It was retired, and the answer was not "move it" but "split
it", because it had been holding two different kinds of thing:

- **The ids** belong here, in `kde/themes.tsv`, where they are **executed**. A
  wrong id in a note sits there quietly; a wrong id in this file fails the run.
  That is the property a record cannot have. All ten transferred, checked with
  `comm`.
- **The machine-specific residue** — an SDDM theme installed by hand as root
  with two-screen logic, a lock-screen wallpaper history, the settings the
  rounded-corners effect writes into `breezerc` by itself — belongs in the
  machine's own private repository, and went there.

`next_steps.md` #1 pointed at that note as the place to record a new component;
it now points here, and that is the improvement: writing an id into `themes.tsv`
**installs** it, so the record and the action are the same act.

### Session metadata

Ran **24 h 39 m** wall clock across two days, one item at a time, every decision
committed as it landed — all three repositories were clean at close with nothing
to sweep in.

**Compactions: unknown, and that is itself a finding.** `.claude/compact-count`
does not exist on this machine because the `SessionStart` hook that writes it was
never installed here — which is `next_steps.md` **#5**, filed at the very start
of this session when `/acilis` failed its own freshness check. So the one number
that says whether a session was the right size is missing, and the item that
would have supplied it was open the whole time.

---

## 2026-09-21 — `up` logs its runs, and the alias it replaced was never the one running

**The question:** *"up alias'ına log tutması için bir şeyler yapalım mı?"* —
asked after a morning in which `paru` tried to build `webkit2gtk-imgpaste`
from source, failed in CMake, and the failure scrolled out of a terminal that
was later closed. `pacman.log` had the installs and removals; nothing had the
build. Answered yes, and then *"dotfiles deposuna da ekleyelim, diğer
sistemlerde de aktif olsun"* — which moved it from a local script to
`aliases.sh`.

### What was decided

- **`up` is a function on all three distro branches**, wrapping its commands in
  `_up_run`, which runs them under `script -qeac … "$UP_LOG"`. One log per run
  in `~/.local/state/up/`, pruned at 90 days, path printed at the end.
- **`script`, not `tee`.** `tee` puts a pipe on stdout, and paru then drops
  colours, progress bars and the PKGBUILD pager — the review prompt is the one
  place AUR scripts get looked at (commit `346fb0b`), so a logger that quietly
  degraded it would cost more than it kept. `script` gives the child a pty and
  the tools cannot tell. Checked on util-linux 2.42.3: `-a`, `-c`, `-e`, `-q`
  all present; `-e` returns the child's exit code, verified with `exit 3`.
- **The apt branch logs its own prose too** — the autoremove plan, a refusal,
  and the answer typed at the prompt — via `tee -a` / `>>`, so the file reads as
  the whole run. Its `read` stays outside `script`, on the real terminal.
- **`paru -Syu` spelled out** where the alias said bare `paru`. Same command;
  `script` writes the command into the log's header line, and a reader should
  not need to know paru's default.
- **Without `script`** (Git Bash) the command runs via `eval`, unlogged, and
  says so. `up` is undefined there anyway — no paru/apt/dnf — so this is
  belt-and-braces for some future distro branch.

### What was refuted, on the way

- **The local `alias up=` in this machine's `~/.zshrc` and `~/.bashrc` was dead
  code.** Both files source `aliases.sh` *after* it (`.zshrc` line 66 versus the
  alias at 29), and `aliases.sh` redefines `up`. So the alias that ran all along
  was the repo's `paru && paru -c`, identical in effect — deleting the local
  lines changed nothing, and the first version of this work, a
  `~/.local/bin/up` script, **would have been shadowed by that alias in every
  new shell.** The claim that it would take effect "from the next terminal" was
  wrong and is withdrawn; the test that produced it had `unalias up` in it,
  which is the test proving nothing. The script is deleted; the function in
  `aliases.sh` is the only `up`.
- **`pgrep -f makepkg` reporting the build still running** was matching the
  shell that ran the `pgrep`. `ps -eo cmd | grep '[m]akepkg'` showed nothing;
  the build had finished. Two false positives in one morning from the same
  pattern.

### Unverified

- **Only the Arch branch ran for real** (`up` on this box). The apt and dnf
  branches were checked with `bash -n`/`zsh -n` and by exercising the three
  helpers with a stub command; the full functions were not run, since neither
  package manager is here.
- **No Windows check.** `script` is absent on Git Bash; the fallback path was
  reasoned, not run.

### Filed, not done

`next_steps.md` #4 — makepkg `!debug` is set on this box only.

---

## 2026-09-14 — `install.sh` learns Windows, and catches itself lying on the way

**The question:** `next_steps.md` #1 reserved a decision — *"not whether to add
the line, it is where"* — between a step in `WINDOWS.md` and a guarded MSYS
branch in `install.sh`. Put to murty, who **chose the branch.**

The argument against the page is the page's own: a step nothing enforces is a
step the next machine misses, and item #1 *was* that — a Windows box running
with zero aliases for as long as nobody checked. The argument against the branch
was `WINDOWS.md`'s opening sentence, *"this is a by-hand install, on purpose"*.
That sentence is now edited rather than ignored, because a repo holding two
stories about how Windows installs is worse than either story.

### It used to die at line 62

MSYS has none of `paru`/`apt`/`dnf`, so the package-manager detection reached
its `error` and exited 1 **before a single step ran**. Not "install.sh is not
run on Windows" as a policy — it could not run.

### The shape of the change: one guard, not 420 edited lines

Sections 3-12 are contiguous, so they sit inside one
`if [ -z "$IS_MSYS" ]; then ... fi`, and the body is **left at its original
indentation on purpose**. Re-indenting 420 lines would have produced a diff in
which every line of the installer changed and none of it was reviewable, to
express a change that is two lines. The whole commit is 121 insertions and zero
deletions.

Checked before wrapping, because a self-contained region is what makes it safe:

```
functions defined in 126-544      : none
variables assigned there          : 16
of those, read after the region   : ZSH_CUSTOM, once, as ${ZSH_CUSTOM:-$HOME/.zsh}
```

That default is why an unset value is already handled — the summary prints "NOT
installed", which is true. The **Aliases** hook has to stay after the `fi`, and
that is not cosmetic: it appends to `~/.zshrc`, and `~/.zshrc` is created inside
the guarded region. Moving it earlier would have broken Linux on a fresh machine.

### The find: the automation reproduced the exact failure it was replacing

The first working version printed

```
✓ acilis.md symlinked from dotfiles
✓ kapanis.md symlinked from dotfiles
✓ global CLAUDE.md symlinked from dotfiles
```

and produced **three plain copies**. `[ -L ]` on all three: not links. The
shell running it carried `MSYS=disable_pcon` and not
`winsymlinks:nativestrict`, so `ln -s` fell back to copying and returned 0.

This is the failure `WINDOWS.md` was written about, reproduced by the automation
written to replace the by-hand install that page recommends *because* of it. It
is also the argument for the branch rather than against it: the by-hand route
never prevented this, it only told you to go and check. A probe can refuse.

So the branch now:

1. **Exports `nativestrict` for its own process**, making `ln -s` fail loudly.
2. **Probes before touching anything** — creates a target, links it, tests
   `-L`. Failing at the probe costs nothing; failing at section 13 leaves a
   half-installed machine.
3. **Stops with the Developer Mode instruction** if it cannot link, because that
   is a Windows setting only the user can change. Named and handed over, not
   attempted around.
4. **Appends the export to `~/.bashrc`** — the second gap, found on review.
   Covering only its own process leaves the installer's links real and the
   *user's* next `ln -s` silently copying, which is a half-configured machine
   with no tell.

### Also on this platform, each for a stated reason

- **HTTPS clone, not SSH.** The SSH clone needs a key registered on GitHub
  before it runs, and the closing summary only says so *after* the clone has
  had to succeed. Git for Windows ships Git Credential Manager, so HTTPS pushes.
- **`~/.bashrc` and `~/.bash_profile` created when absent.** `hook_shell` is a
  deliberate no-op on a missing file, so without this a fresh box gets a clean
  successful run and no aliases. `~/.bash_profile` is the less obvious one: Git
  Bash opens a *login* shell and nothing in `/etc` sources `~/.bashrc`.
- **A separate closing summary.** The shared one would print "NOT installed" for
  eight things nothing tried to install. `f2f1e67` is the commit that made this
  summary check instead of assert; reporting a skipped step as a failed one is
  the same error one step on. The Windows summary says **"Not attempted"**.
- **The alias line is checked, not asserted.** `present` on the repo's own
  `aliases.sh` proves the clone worked. The claim being made is that the *hook*
  landed, so it greps the file the hook goes into.

### Verified, and the limits of it

On Windows 11 / Git Bash, with `HOME` redirected to a sandbox:

| run | result |
|---|---|
| fresh | exit 0, **three real symlinks**, one export line, hook added |
| second, same HOME | every step warns and skips, exit 0, export line still 1 |
| stub `ln` that cannot link | refuses at the probe, exit 1, **sandbox empty** |
| login shell in that HOME | `MSYS=[winsymlinks:nativestrict disable_pcon]`, 54 aliases |

**A correction to `de32b66`'s own message.** It says "the Linux path is
textually unchanged". The Linux-only *sections* are, but Linux now **executes**
lines it did not before: the `case` detection, the extra `elif`, and the guard
test. `OSTYPE=linux-gnu` and `uname -s`=`Linux` match none of the patterns, so
it is inert — but only `bash -n` has been run against it. **Nobody has run
`install.sh` on Linux since this change.** That is in the handoff.

The summary's "NOT hooked" arm is also **unreachable by a real Windows run** —
the hook step re-adds the line before the summary reads it. Its three cases were
verified in isolation instead. Recorded because a first attempt at a negative
test "passed" for that reason and proved nothing.

### `WINDOWS.md` — and a documented check that was broken

The page is edited rather than contradicted. Its opening reason was **answered,
not wrong**: Windows still copies silently, and what changed is that the
installer now refuses to start when it cannot link. Sections 2, 2b and 4 are
marked as the installer's job and kept as things to check against; the status
line and the session-context hook stay by hand, because both need a
`settings.json` edit the installer does not make on any platform.

**Its symlink test was broken, and it cost this session time at 17:16.**

```bash
ln -s /etc/hostname /tmp/lntest    # documented
# ln: failed to create symbolic link '/tmp/lntest': No such file or directory
```

There is no `/etc/hostname` on Git Bash, and MSYS needs the target to exist to
decide between a file link and a directory link. So the page's capability check
**failed on a machine where the capability works** — read for a moment as a
Route A regression. Replaced with the self-contained probe `install.sh` uses,
which makes its own target, and which demonstrates both outcomes here:

```
without nativestrict : -rw-r--r--  link              (the silent copy)
with nativestrict    : lrwxrwxrwx  link -> target    (real)
```

A fourth check was added to *Check it worked*: `alias | wc -l` prints about 54
in a new window. It is the cheapest check on the page and the one that would
have caught item #1 on the day it happened.

### Found by running it on the real machine, not the sandbox

Every test above used a redirected `HOME`. Run against the actual one, the
installer was **idempotent in every step but one**: the mailmap step reported

```
! replacing mailmap.file — was C:/Users/Y.URGEN/.dotfiles/.mailmap
✓ git mailmap pointed at /c/Users/Y.URGEN/.dotfiles/.mailmap
```

on every run, while replacing the value with itself. **Git for Windows rewrites
the MSYS path it is handed into a drive-letter one**, so `git config` reads back
`C:/Users/...` where `$DOTFILES_DIR` says `/c/Users/...` — one file, two
spellings, and the string comparison could never match on this platform.

Nothing was broken by it: the stored value round-trips to the same path, and the
mapping is live — `git log --format=%an` gives four identities, `%aN` gives one,
and `git shortlog -sne HEAD` is a single line over 85 commits. The cost was a
**false warning on a line that claims a change was made**, which is the one kind
of line this installer was rewritten to get right (`f2f1e67`). Fixed by
comparing with `-ef`, which sees through both spellings and is equally correct on
Linux. The re-run says *"already pointed at dotfiles"*.

The sandbox could not have caught this. A fresh `HOME` has no `mailmap.file`, so
it takes the *set* branch and never reaches the comparison — the bug only exists
on the second run of a machine, which is the run a sandbox test never does.

Worth noting the near-miss in checking it: `git shortlog -sne` with no revision
reads **stdin**, so it printed nothing and briefly looked like the mailmap had
broken. `HEAD` is what makes it answer. The `%an` vs `%aN` pair is the test that
actually discriminates, which the 2026-09-09 entry already had to learn once.

### The last pass: three places still telling the old story

Prompted by murty asking whether already-finished work had been redone. It had
not — the answer is in the next section — but looking for it turned up three
files still describing a Windows install that no longer exists. A repo holding
two stories about the same thing is the failure this session spent its whole
`WINDOWS.md` edit avoiding, so:

- **`README.md`** said *"`install.sh` and `update` are not run there"*. Rewritten
  to say what runs and what is left, keeping the reason — it is handled now,
  not gone.
- **`install.sh`'s own header** listed thirteen steps and no Windows branch. This
  file has a refuted-claim entry against it already, from the session where its
  comment said two things were kept in step and they were not. Six lines added.
- **The Windows summary listed Developer Mode under "Still by hand"**, when the
  preflight refuses to run without it — so by the time that line prints it is
  necessarily already on. Reporting settled work as outstanding is the mirror of
  ticking work that failed, and `f2f1e67` is the commit that decided which side
  of that this installer is on. Replaced with a statement of fact.

A fourth, outside the repo: the comment written into this machine's `~/.bashrc`
earlier in the session said *"install.sh never runs on Windows"* — true when it
was written that afternoon and false two hours later, by this session's own
doing.

### Nothing on this machine was redone, and it was checked rather than asserted

```
~/.claude symlinks       2026-09-08 21:53, untouched — installer said "skipping"
MSYS export in .bashrc   1 occurrence
aliases.sh hook          1 occurrence
~/.bash_profile          1 source line
mailmap.file             C:/Users/Y.URGEN/.dotfiles/.mailmap, before and after
```

The one thing the installer did change on a real run was `mailmap.file`, and it
rewrote it to a value git normalised straight back — net zero, and the false
warning that exposed it is the fix recorded above.

### Filed, not done

`#1c` — `update` has never been run on Windows. Reachable for the first time
now that the aliases load, but it does more than pull: it re-checks symlinks and
warns about copies, none of it exercised under MSYS. `WINDOWS.md` says to use
`git pull` here until someone runs it and writes down what happened.

---

## 2026-09-14 — `aliases.sh`: `activate` on both platforms, and why it stopped being an alias

**The question:** `next_steps.md` #2 said `activate` and `venv()` hardcode
`.venv/bin/activate`, which is wrong on Windows. Prefer `Scripts`, fall back to
`bin`. What does Windows actually lay down?

**Measured rather than assumed.** Windows 11 / Python 3.14.3, 2026-09-14:

```bash
python -m venv --without-pip .venv   # --without-pip: the pip bootstrap
ls .venv                             # timed out at 2 minutes, and the
                                     # layout is all the item needs
# -> Include/  Lib/  Scripts/  pyvenv.cfg
ls .venv/Scripts | grep -i activate
# -> Activate.ps1  activate  activate.bat  activate.fish
ls .venv/bin                         # -> no such directory
```

So the two layouts are **disjoint**, not overlapping — there is no `bin` on
Windows and no `Scripts` on Linux. That is what makes the queue's one-branch fix
safe: each arm is unreachable on the other platform, and a tree with both could
only come from one `.venv` shared across platforms, which does not work anyway.

The second finding is the one that made the fix small: **`Scripts/activate` is a
POSIX sh script**, shipped by Python next to the `.bat` and `.ps1`, so Git Bash
sources it unmodified. Sourcing it set `VIRTUAL_ENV` and put
`.venv/Scripts/python` on `PATH`. No wrapper, no path translation.

### Why it is a function now

An alias cannot hold an `if` legibly, and the alternative —
`source .venv/Scripts/activate 2>/dev/null || source .venv/bin/activate` — hides
a real error inside the fallback. So `activate` became a function and moved down
to live with the other functions, and `venv()` now **calls it** rather than
repeating the branch.

Four cases, all on Windows:

| case | result |
|---|---|
| dir with a Windows `.venv` | `VIRTUAL_ENV` set, `Scripts/python` on `PATH` |
| dir with no venv at all | one message on stderr, exit 1 |
| `venv()` where `.venv` exists | did not recreate, activated |
| synthetic `.venv/bin/activate` | fallback arm taken, `bin` sourced |

The fourth is a **stand-in, not a Linux test** — a hand-made `.venv/bin/activate`
that only exports `VIRTUAL_ENV`. It proves the branch is reachable and picks the
right file. It does not prove a real Linux venv activates, and no zsh exists on
this box either; both stay unverified until the Linux side runs.

### Two knock-on effects, recorded because a number moved

- **`alias | wc -l` now returns 52, not 53.** The audit's "35 of 53" is still a
  true result, but its denominator has changed, and `activate` was only ever in
  the working 35 *by resolving* — which was precisely the bug. A re-run should
  expect 52 aliases and one more function.
- **`venv()` reports failure now**, having gained the `else` arm by reuse.
  `python -m venv` failing used to fall through into a confusing `source` error.

### Filed, not done

`#2b` — `venv()` calls `python`, and some Linux hosts ship only `python3`. The
line was already there and was not touched. It is right on this box, where
`python` is `/c/Python314/python` and `python3` does not exist at all. Whether it
is right on murty's Linux boxes is a check that has to run there.

---

## 2026-09-14 — `aliases.sh`: the zsh history block, and the item that was half a bug

**The question:** `next_steps.md` #3 said four `setopt` lines print
`command not found` on every Git Bash start. Guard them and move on. Was that
the whole of it?

**No — the noisy half was the harmless half.** The block is seven lines, not
four, and the three above the `setopt` calls are not inert under bash:

```
                bash, no aliases.sh        bash, after sourcing
HISTFILE        (unset)                    /c/Users/Y.URGEN/.zsh_history
HISTSIZE        (unset)                    10000
SAVEHIST        (unset)                    10000
```

`HISTFILE` is a **bash** variable as much as a zsh one. Bash takes the
assignment and writes its history to the zsh file, leaving `~/.bash_history`
behind without a word. Verified that the assignment is live rather than merely
set, Windows 11 / Git Bash, 2026-09-14:

```bash
rm -f /tmp/histprobe
bash -lic 'HISTFILE=/tmp/histprobe; history -s probe_marker_xyz; history -w'
grep -c probe_marker_xyz /tmp/histprobe   # -> 2
```

`SAVEHIST` really is inert in bash — it wants `HISTFILESIZE` — and `HISTSIZE`
means the same thing in both. Both are guarded with the rest anyway: the block
is one setting, and splitting it by which lines happen to be portable would
leave the next reader deciding that for themselves.

**So the fix is `if [ -n "$ZSH_VERSION" ]` around all seven lines**, not around
the four the item named. After it, under bash: stderr empty, `HISTFILE` unset,
53 aliases still defined, `bash -n` clean. The zsh path is **unverified** — no
zsh on this box.

### The part worth keeping: the queue had a dependency it did not know about

**#3 had to land before #1**, and nothing in the queue said so. #1 adds
`source ~/.dotfiles/aliases.sh` to `~/.bashrc` on this machine. Done first, with
the block unguarded, it would not merely have printed four errors — it would have
redirected this box's bash history into `~/.zsh_history`.

The tell is that **`~/.zsh_history` does not exist here**, and it does not exist
*because* nothing sources `aliases.sh` yet. Item #1 was the only thing keeping
item #3's silent half asleep. Fixing #1 first would have created the visible bug
and removed the evidence of why at the same time.

`next_steps.md` files items in birth order and says outright that the order "is
not a priority call". That is honest, and this is the cost of it: a queue with no
priority also carries no dependencies, so they have to be found by reading the
items against each other rather than taken off the top.

### Conventions set here, both firsts

- **Closing an item in this queue.** Nothing had ever been closed, so there was
  no pattern. Numbers stay standing and the item is marked `DONE` in place,
  because this log already refers to "#1, #2, #3" by number and renumbering
  would silently break those references.
- **New items keep a letter.** The bash-history preference that surfaced while
  fixing #3 is `#3b`, not `#4` — same reason.

### Filed, not done

`#3b` — whether bash should get `HISTSIZE=10000` and a large
`~/.bash_history` too. A preference, not a defect, so it was written down and
left rather than decided while passing through.

---

## 2026-09-11 — `countdown.sh`: the stall at zero, which nobody had fixed

**The question:** murty noticed a momentary stall at zero before this round's
changes and said it appeared to be gone. Was it?

**No. It was still there, unchanged, and the credit was wrong.** `alert()` is
byte-identical between `17fe1ac` and the working tree — `diff` on the two copies
of the function returns nothing. The stall was measured on a pty, both versions,
3-second target, frame timestamps taken off the master fd:

```
eski (17fe1ac)                yeni (çalışma kopyası)
1.91  last countdown frame    1.88  last countdown frame
2.82  \a \a \a \a \a          2.79  \a \a \a \a \a
3.83  zero screen             3.80  zero screen
```

Identical to within noise. **What changed was not the timing but the reading of
it:** the wait used to end on `00:00`, a screen that looks like the one already
up, so it read as a hang; it now ends on a different screen with bells ringing
through the gap, so the same 1.9 seconds read as "the alarm went off". Worth
recording because a perceived fix is the kind of thing that gets built on.

**The cause is one line.** `for _ in 1 2 3 4 5; do printf '\a'; sleep 0.2; done`
— five beeps 0.2s apart is a full second of blocking, and `alert()` runs *before*
the frame is drawn, so the last countdown frame sits on screen for ~1.9s instead
of 1.0s. At exactly the moment the screen is being watched.

**Fixed by backgrounding the bell**, murty's choice between that and deferring
`alert()` until after the draw. Deferring keeps the process count flat but leaves
keys unread for that second; backgrounding makes both the screen and the keyboard
answer immediately, and costs one fork, once, at zero. Re-measured: the zero
screen now lands in the same 10ms as the first beep, and the remaining four ring
against an already-drawn menu.

### What would have shipped silently

**A background job in a non-interactive shell starts with SIGINT ignored.** So
Ctrl+C takes the script down and leaves the beeping running in the terminal it
just handed back — a beep arriving after the alternate screen is gone, with
nothing on screen to explain it. The kill lives in the `EXIT` trap for the same
reason the `stty` restore does: it is the only handler that covers both the `q`
path and the signal path. `tty_restore` became `on_exit` to say so.

Verified on a pty: a full run rings 5 times, quitting 0.3s after zero rings 2
(`q`) and 3 (Ctrl+C), with EOF arriving in the same instant as the quit — a
surviving subshell would hold the slave open and delay it. `stty -g` compared
before and after in one pty on both paths: restored.

### Is the count itself trustworthy? Measured, because it had not been

Asked directly, and the honest first answer was that only the zero *transition*
had ever been measured, never the counting. So it was measured: an exact
`HH:MM:SS` target — which makes `TARGET_EPOCH` known to the harness rather than
inferred — with every frame's arrival stamped off the pty master.

```
                        idle(44s)   50 keys/s   full load(24 loops, loadavg 14)
frames drawn / expected   44/44       24/24       29/29
repeated or skipped       0           0           0
mean period               1.0000s     1.0007s     1.0000s
phase spread              0.001s      0.085s      0.056s
zero vs target epoch      +0.010s     +0.099s     +0.031s
```

**Accumulating drift is impossible by construction**, which is the part worth
keeping: every frame recomputes `TARGET_EPOCH - $(date +%s)` from the absolute
epoch and re-phases its own sleep off `date +%N`. Nothing is added up, so nothing
accumulates — a late frame is absorbed by the next sleep instead of pushing the
error forward. The key-storm column is the interesting one: `read -t` doubles as
the frame delay, so 50 keys a second return it early 50 times a second, and the
re-phasing still put every frame on its own second.

### Unverified

The bell is the only alert layer that was ever synchronous; `notify-send` and the
sound players were already backgrounded and were not re-measured this round.

Not measured, and each derivable from the code rather than from a run: a **clock
step** (NTP, manual set) shifts a duration target by the size of the step, since
the target is an absolute epoch — for an `HH:MM` target that is the right answer,
for `25m` it is not; **suspend/resume** is handled in the sense that the first
frame after waking shows the true remaining time and a target passed while asleep
fires immediately, but it fires *late*, not at the moment it was due; and `date
+%N` is assumed to work — a `date` without it makes `10#$(date +%N)` an
arithmetic error, `nap` zero, and the loop a busy spin. GNU coreutils is the
stated target, so this last one is a portability note, not a live risk.

---

## 2026-09-09 — `countdown.sh`: what the screen does after zero

**The question:** a finished countdown sat on a blinking `00:00` until someone
killed it. What should be on the screen instead, and how do restart / auto-exit /
run-a-command get offered without turning the script into a flag farm?

### What was decided, and why

**A key menu at zero, not command-line flags.** The firm requirement was "after a
timeout, show a normal clock", and a *timeout* only means anything if something is
waiting for input that never came. So zero is a state change, not an ending:
`count → menu → clock`, with `[r]` sending it back to `count` from either of the
other two. Flags were the alternative and lost — the behaviour is chosen after the
countdown is already running, which is exactly when a flag is no longer reachable.

**The clock is drawn in-process, not handed to `tty-clock`.** The header promises
pure bash and no dependencies, and the screensaver case has to survive; the big
digits are already there, so clock mode is the same `print_digits` with `$now` and
`COLOR_CLOCK`. It also drops the half-scale clock that normally sits on top —
two copies of the same time is the one layout worth vetoing.

**The command runs from `[x]`, not automatically at zero.** murty's call.

*Revised the same day, after review:* the first version took the command only
from `$COUNTDOWN_CMD` and hid the key when it was unset — which contradicted the
reason the menu exists at all. The argument against flags was that the choice is
made *after* the countdown is already running; a command that has to be exported
before it starts is the same flag wearing a different hat. `[x]` is now always
offered and opens a prompt when nothing is configured, keeping what is typed for
the rest of the session. The env var survives as the "don't ask me" path.

The prompt puts the terminal back to its saved settings while it runs — readline
needs echo and canonical mode — and an empty line cancels. Not ESC: readline
reads ESC as the start of a meta sequence, not a keystroke. It also forced the
fallback timer to re-stamp from a *fresh* `date` rather than the frame's clock,
because a prompt can sit open for a minute and the stale stamp dropped the
answer straight onto the clock. Verified with an 8-second prompt against a
3-second timeout.

`[c]` and `[x]` are gated on the menu state. The clock screen's key line offers
only `[r]` and `[q]`, and a key that still fires from a screen carrying no label
for it is a trap — doubly so for the one that runs a command.

**Then the same question came back one level up, and it moved the whole design:
`[x]` is now on screen during the countdown too, and anything armed before zero
fires at zero.** murty's point was that the command had to be settable while the
countdown ran — otherwise a thought at minute 10 of a 25-minute timer costs you
the timer. And once it is settable *before* zero, making it wait for a keypress
*after* zero is incoherent: a command armed before the end is armed by somebody
who expects to be elsewhere when it arrives. It would do nothing in exactly the
case it was set for.

So one rule replaced two: **anything set before zero runs at zero.** `[x]` before
zero arms (prompt pre-filled with what is set; clearing the line disarms) and
never runs now; `[x]` after zero runs it again by hand. `$COUNTDOWN_CMD` is the
same thing set from the shell and fires the same way — including where there is
no keyboard at all, which is the case it was made for.

*This reverses the first decision of the session*, taken before the prompt
existed: "run when picked from the menu, not at zero with the alert." What
changed is that arming and alerting stopped being two different things. Recorded
as a reversal rather than quietly rewritten, because the earlier reasoning is
still sound on its own terms and the next session should see why it stopped
applying.

Three consequences, all paid for:

- **The key line is up in every state**, so it comes out of the vertical budget
  always, and it became the third thing sacrificed on a shrinking window — after
  the date and the clock. Only the line goes; the keys keep working unlabelled.
- **The countdown footer needed the same narrow-screen trim as the other two.**
  It was already wider than 30 columns before today (`target 16:45 · 0m 1s left
  · Ctrl+C to quit`, 46 characters), but until there was a key line under it,
  wrapping cost nothing visible. A labelled countdown still needs ten rows and
  overflows a 9-row terminal — checked against HEAD, it did that before this
  change too.
- **The armed command is named on screen** for the whole countdown
  (`[x] at zero: systemctl suspend`), truncated to the width rather than left to
  wrap. A key that can suspend the machine should not be silently armed.

**`[r]` re-arms, deliberately.** A restart keeps the command and fires it again
at the new zero — the rule is "anything set before zero runs at zero", and a
restart makes a new zero. It is visible for the whole restarted countdown on the
key line, so a repeated `systemctl suspend` announces itself rather than
ambushing. Verified: arm, fire, `[r]`, fire again — two runs.

**`resolve_target()` is a function now**, which is the only reason `[r]` can work:
a duration restarts from now, and a wall-clock target has to resolve to its *next*
occurrence instead of firing again the instant it is restarted. Verified — a
restart at the target minute comes back as `(tomorrow) · 23h 59m left`.

**Any keypress restarts the fallback timer.** The timeout is a test for whether
anybody is present, and a keypress answers it — without the reset, pressing `[x]`
at second 25 of a 30-second window loses the menu five seconds later, with the
command's own confirmation still on screen. One line, and it is the only reason
`[x]` is usable at the end of the window as well as the start.

**The menu is skipped where `COUNTDOWN_NO_HINT` is set or stdin is not a tty**,
and the clock still takes over on the same timer. That half needs nobody present;
the keys do. Same escape clause the hint already had, reused rather than reinvented.

**Two quit mechanisms, kept on purpose.** Ctrl+C while the countdown runs, `[q]`
after zero — and that means `[q]` stops working again after `[r]`. Raised as an
inconsistency and settled by murty: *"tutarsızlık kabul edilir, countdown
tamamlandıysa çıkış kolaylaşır."* Quitting is supposed to get cheaper once the
thing is over, and while it is still running a single stray keystroke should not
be able to end a two-hour countdown. Recorded here because the next session will
otherwise read it as an oversight and "fix" it.

**The alternate screen, not a clear on exit** (`\e[?1049h` / `\e[?1049l`). The
script used to leave its last frame behind, so the shell came back under a
screenful of digits. `\e[2J` at exit would remove those and the user's own screen
with them; the alternate screen restores what was there before, scrollback
included, for both `[q]` and Ctrl+C. A terminal without one — the bare Linux
console — ignores the sequence and gets exactly today's behaviour, which is why
the trailing newline in `cleanup` moved *ahead* of the switch: discarded with the
alternate screen, still doing its old job without one.

### What bit, and would have shipped silently

**Ctrl+C left the terminal with echo off.** Echo is disabled for the whole run
(otherwise anything typed at the countdown prints on top of the digits), so the
settings have to be handed back. Restoring inside the `INT` trap looks right and
is not: `read` is waiting for a menu key when the signal lands, and bash puts back
the settings *it* saved when `read` started — ours, with echo already off — after
the trap has run. The restore had to move to a separate `EXIT` trap, which runs
last. Caught only by comparing `stty -g` before and after inside one pty; the
symptom is a shell with a dead keyboard, and nothing on screen says so.

**Buffered keystrokes.** Without a flush at the transition, the menu opens and
instantly eats a key pressed minutes earlier — and one of the keys it can land on
is `[q]`.

**The key line is a row, and rows are budgeted.** It had to go into both the
scale-fit loop and the `base` centering sum, or it pushes the footer off a short
screen. On a narrow one the footer wraps instead, which costs an unbudgeted row
with the same result — so both footer and key line shorten when they would not
fit (`[r] restart` → `r=restart`). Checked at 80x24, 60x12, 40x14 and 30x9.

### `[t]` — point it somewhere else

Asked for next to `[r]` and `[q]`: `[r]` restarts the *same* target, and the
thing missing was a different one. `[t]` opens a prompt taking any spec the
command line takes, pre-filled with the current one.

**It forced `resolve_target` to stop exiting.** Bad input from the command line
is fatal and should be; bad input typed into a menu must not be able to kill the
program. The message cannot go to stderr either — by then the screen belongs to
the alternate buffer, and a stray line scrolls the layout out from under itself.
So the function returns 1 and leaves its complaint in `RESOLVE_ERR`, and the
caller decides whether that is an exit or three seconds in the footer.

The same change fixed a bug that was already there and had never fired:
`if ! TARGET_EPOCH="$(date -d …)"` empties the global on failure. Harmless while
the only caller exited immediately after; with `[t]` a mistyped time would have
taken the running target with it. Everything is computed into locals now and the
globals are assigned together, once it has all worked.

**`[t]` replaces `SPEC`, so a later `[r]` restarts the new target, not the one
the command line started with.** Verified: start 3s → `[c]` → `[t] 6s` → expire
→ `[r]` → 6s again.

**Narrow screens got a third trim level, and the reason is the point.** Five
keys do not fit 30 columns, and cutting the line by characters loses whichever
key sits at the end — which was `[q]`, the way out, invisible on exactly the
screen where the Ctrl+C hint is also suppressed. So the fallback drops whole
keys instead: `[c]` happens by itself after the timeout and `[x]` is a bonus,
while `r`, `t` and `q` stay. Cutting is now the last resort, for an armed
command that outruns any screen.

Both prompts went through one `prompt_line`. The restore-settings / position /
`read -e` / re-disable / flush sequence is the one that already produced the
EXIT-trap bug this session; writing it a second time by hand was not worth the
risk.

`[t]` is offered wherever `[r]` is — the menu and the clock — and not during the
countdown. Retargeting a running countdown ("make it fifteen minutes more") is a
different feature and was not asked for.

### Run on the machine, not just under a pty

Everything above was verified with `script(1)` ptys, which is not what this repo
trusts — validation here is "run it on a machine and see". murty ran the whole
rule end to end in his own terminal: armed a command mid-countdown, let zero fire
it with nobody touching the keyboard, ran it again by hand from the menu, then
pressed `[x]` on the clock screen. `/tmp/x-test.log` came back with exactly two
timestamps nine seconds apart — automatic, then manual, and nothing from the
clock. The timestamps were real rather than frozen at prompt time, which is the
`eval` path proving itself. The `notify-send` layer fired both times.

### Unverified

Only tested on this Linux box. The `stty` save/restore and `read -rsn1 -t` are
POSIX-ish but the Git Bash behaviour on Windows is untested, and `WINDOWS.md` does
not cover `countdown.sh` at all — it is not one of the five Claude Code artefacts.

---

## 2026-09-08 21:42 → 2026-09-09 00:24 (2h42, 0 compactions)

**The question:** does this repo's Windows story actually hold on a Windows
machine? It had never been run on one by the person who wrote it.

Closed with 7 commits here (`aa0d8f9` → `f752474`) and 3 in
`becoming_power_user`. Opened without `/acilis`, so the start time was read from
the session transcript rather than a stamp — see *Unverified*.

### What was decided, and why

**Route A on this machine, not Route B.** `ln -s` was silently copying, exactly
as `WINDOWS.md` warns. Developer Mode on + `MSYS=winsymlinks:nativestrict`
turned that into real symlinks, so the five Claude Code artefacts now track the
repo instead of drifting from it. Route B was available and rejected: a copy that
stops receiving updates reports nothing, and this machine is used often enough
that the silent staleness would have been paid for repeatedly.

**A fourth Windows difference in the status line, and it is the quietest one**
(`3723a7d`). The directory block already declines to prefix the project name when
the project root is `$HOME`. That test is a string compare, and on Windows it is
handed two spellings of one directory — bash has `/c/Users/x`, the payload
`C:/Users/x` — so it never fires and the username is prefixed onto the line.
Fixed in `wproj()` inside the python block, because the one-python-no-forks
constraint rules out `cygpath`, and because that is where this repo has already
decided platform quirks get settled.

Fixture 14 builds its payload from the running machine's own `$HOME` rather than
a literal: a hard-coded path passes on both platforms and proves nothing. That
choice is the whole value of the test.

**The setup docs were wrong in three places, and all three fail silently**
(`aa0d8f9`). `SessionStart` must sit inside the top-level `"hooks"` object —
beside it the file still parses and the hook never registers. The `MSYS` export
must be appended, not assigned, because Claude Code injects `MSYS=disable_pcon`
into the shells it spawns. And `~/.bashrc` is never read on a machine with no
`~/.bash_profile`, so Route A can look configured and be off.

**One git identity, and history left alone** (`cffdfe6`). Four identities had
accumulated across the account — 33 `Muharrem ARLI`, 17 `Murty`, 9 `murty`, 1
`Shalafi` in this repo alone. `.mailmap` collapses them at read time; mapping is
by email, so no name is written into the file. History was **not** rewritten, and
that was the deliberate call: `dev_log` and `next_steps` in the other repos cite
commit hashes, and a rewrite breaks every one of those references for a cosmetic
gain.

`install.sh` sets the identity only when git has none. An identity that is set
and *different* is reported and left alone — a host that deliberately commits
under a work name is the mirror image of this bug, and rewriting it silently
would be the worse of the two failures.

**The gh login is asked for, not merely mentioned** (`ad80020`). The real gap was
in `ensure_gh`, which opened with `command -v gh && return 0` and so could report
only the case where gh was missing — never the common one, gh present and never
logged in. `install.sh`'s own comment said the two were kept in step; on this
point they had not been.

**The closing summary now checks instead of asserting** (`f2f1e67`). Several
install steps end in a *warning* rather than an install, and a summary that ticks
them anyway is worse than no summary — it is the one screen that gets believed.

### What was refuted

Five claims made during the session and knocked down by measurement. They are
recorded because each cost time and would cost it again:

- **"The global mailmap works in the other repos."** Over-claimed. Wiring it
  changed nothing in `factory-backend`, because that repo already had exactly one
  identity of mine. Where it matters is here and in UAKBSCSD.
- **Two mailmap tests that proved nothing.** `mailmap.file=/dev/null` leaves the
  repo-root `.mailmap` in force; `log.mailmap=false` does not reach `shortlog`,
  which applies the mapping unconditionally. Only `%an` versus `%aN` shows the
  difference.
- **"A live status line run is broken."** It was the payload, mangled by shell
  quoting on the way in — the exact failure `statusline-fixtures.py` documents in
  its own docstring, met while testing the thing that documents it.
- **Two parser bugs in the alias audit**, each producing an impossible result:
  first every alias broken, then `g` working while `ga` did not. `alias` prints
  the body quoted, so a naive split returns one token. Numbers were only
  believable on the third attempt.
- **An inference about which machine a commit came from.** `a694ef4` in
  `becoming_power_user` was read as evidence that the Linux identity had been
  switched; it came from the project agent on *this* machine. Corrected by murty.

### Unverified

- **None of the Linux paths ran.** `wproj()` and fixture 14, the new
  `install.sh` sections, and `update`'s new blocks were all exercised on Windows
  only — the identity/gh blocks in isolation with a stub, not end to end. The
  fixture file's own docstring asks for both platforms. The check that settles
  it: `python3 statusline-fixtures.py ./claude-statusline.sh` on the Linux box,
  expecting 14/14 with case 14 printing `.dotfiles`.
  **RUN 2026-09-09 on the Linux box, and it passes: 14 cases, `cases that exited
  non-zero: 0`, and case 14 prints `.dotfiles [main] | …` — no `$HOME` prefix,
  which is the Windows bug `3723a7d` fixed, confirmed not to have cost anything
  on Linux.** Run by the `becoming_power_user` session immediately after
  fast-forwarding this repo, because the check was written down here rather than
  left in a conversation — which is the only reason it was findable at all.
  **This settles the fixture half and only that half.** `install.sh`'s new
  sections and `update`'s new blocks were **not** run; the two remaining bullets
  below are also untouched. Case 8's `642640h33m` is not a defect — the fixture
  hard-codes `resets_at: 4102444800`, which is 2100-01-01.
- **The session's start time** came from the transcript's first record, not from
  `.claude/session-start` — the session was opened without `/acilis`. Read, not
  invented, but weaker than a stamp.
- **`gh auth login` was never actually driven by the installer.** The prompt's
  four branches were tested with a stub `gh`; the real OAuth flow was not.

### Open

`next_steps.md` #1, #2, #3 — all three from one question at the end of the
session, *"will my aliases work under Windows?"*, answered by sourcing the file
there instead of reasoning about it. 35 of 53 aliases resolve. Two of the three
items are invisible without running it.
