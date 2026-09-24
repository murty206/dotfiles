# kde — a KDE Plasma configuration that travels

The shell half of this repo makes a new machine feel familiar in a terminal.
This half does the same for the desktop. It is **configuration only**: the
files that record a choice. It is deliberately **not** a backup of `~/.config`,
and the difference is the whole design.

Measured 2026-09-24 on Plasma 6.7.5: the set below is **42,244 bytes — 41.3 KB
across 14 files**. The theme assets the same desktop uses are **1.8 GB**, and
they are not here — see *What this does not carry*.

*That figure replaces a "~186 KB" written earlier the same day, and the
correction is left visible because the mistake is easy to repeat: the first
number came from `du`, which rounds every file up to a 4 KB block. On 25 files
averaging 2.7 KB that more than doubles the answer. Sizes of many small files
are counted with `find -printf '%s'`, not `du`.*

```
bash kde/apply.sh
```

Then log out and back in. Panels, global shortcuts and the root-window cursor
are read once at session start, so a running session shows a half-applied
desktop and is misleading.

---

## Why `$HOME` is written out in these files

The stored files carry the literal string `$HOME` wherever this machine had an
absolute home path; `apply.sh` substitutes the real one. Ten such lines were
found across two files, all of them wallpaper paths.

**It would have worked to hard-code the user name, and that is exactly the
problem.** KDE does not complain about a wallpaper it cannot find — it falls
back to a default without a word. On the first machine with a different user
name the desktop would come up subtly wrong and nothing would say why. The
substitution costs one `sed` and removes a silent failure.

## What is carried, and why each one

| File | What it holds |
|---|---|
| `kdeglobals` | Theme, colour scheme, fonts, icon theme name |
| `kglobalshortcutsrc` | Every global shortcut — the largest single file here |
| `kwinrc` | Window manager: decoration, borders, virtual desktops, effects |
| `kwinrulesrc` | Per-application window rules (remembered positions) |
| `kcminputrc` | Cursor theme, mouse acceleration, NumLock at login |
| `plasma-org.kde.plasma.desktop-appletsrc` | Panel layout and its widgets |
| `plasmashellrc` | Panel geometry: thickness, floating, opacity |
| `breezerc` | Breeze details — outlines, corners, menu opacity |
| `dolphinrc`, `arkrc` | File manager and archiver preferences |
| `kscreenlockerrc` | Lock timeout and the greeter's wallpaper |
| `spectaclerc` | Screenshot behaviour and OCR language |
| `ksmserverrc` | `[General]` only — logout confirmation |
| `icons/default/index.theme` | **Not in `~/.config`.** See below |

**The cursor file is the one worth explaining**, because it is the one a
hand-made copy forgets. KDE's cursor setting reaches KDE applications only.
The empty desktop shows the X server's *root window* cursor, which resolves
through a virtual theme named `default` — and that is what this file points at
`Bibata-Modern-Classic`. Without it the desktop background keeps whatever the
distribution's `default-cursors` package inherits, and the symptom reads as
"the cursor is wrong only on the desktop".

## What is deliberately left out

These are **state**, not choices. Copying them to another machine is useless at
best and wrong at worst.

| Left out | Why |
|---|---|
| `kwinoutputconfig.json` | Monitor identity — 6 `edidHash` + 6 `connectorName` entries |
| `kded_device_automounterrc` | Disk devices and USB labels seen on one machine |
| `kconf_updaterc` | KDE's own migration ledger; the target writes its own |
| `Trolltech.conf` | Derived from the colour scheme, regenerated on apply |
| `gtkrc`, `gtkrc-2.0` | Written by Plasma itself at session start |
| `kdedefaults/` | Ships with the look-and-feel package, not chosen here |
| `[Session:…]` in `ksmserverrc` | Last logout's window list, with client ids |
| `lastImageSaveLocation` in `spectaclerc` | The name of one screenshot |

## The themes: fetched, not carried

**The configuration names themes; the repo does not contain them.** `kdeglobals`
asks for an icon set by name, and if that set is absent KDE falls back silently —
the same failure mode the `$HOME` substitution above exists to avoid. So they are
downloaded on the machine that needs them:

```
bash kde/themes.sh
```

`install.sh` runs it automatically when it finds Plasma. It is safe to re-run:
every entry is skipped once its target exists.

What gets fetched is in `themes.tsv` — KDE Store content ids, two GitHub
repositories, and two AUR packages. The download URLs themselves are signed and
expire, so they are resolved through the Store API at run time and cannot be
written down.

| Component | Name |
|---|---|
| Look and feel | `Beauty-Color-Global-6` |
| Plasma style | `Beauty-Color-Plasma` |
| Icons | `Slot-Beauty-Dark-Icons-V-3` |
| Window decoration | `BonaFides-Rounded-Blur-Dark-Color-Aurorae-6` |
| Cursor | `Bibata-Modern-Classic` (AUR package) |
| Panel widgets | `a2n.blur`, `window-title-reborn`, and two more |

**Two things about this are worth knowing before reading the script.**

**The obvious tool is the wrong one for two of the entries.** Installing the
global theme with `kpackagetool6 -t Plasma/LookAndFeel -i` resolves the theme's
dependencies through KNewStuff and downloads them: measured into an empty home,
**89,470 files and 817 MB of icon themes** — five of them, and *not* the one the
configuration selects. The same archive unpacked with `tar` produces 9 files.
The set as listed fetches roughly 140 MB of things that are used; the
convenient route fetches roughly 960 MB, most of it never looked at. It also
explains the five unused icon sets in this machine's own
`~/.local/share/icons`: nobody chose them.

**The Store rate-limits.** A dozen downloads in a few minutes is enough to be
refused, and the refusal arrives as HTTP 200 with an XML body where the archive
should be — so it has to be detected on purpose or it surfaces as a confusing
unpack error. The script spaces its requests out, names the refusal when it
happens, and says to run it again later; the second run only fetches what is
still missing.

## What has not been tested

**These files have never been restored onto a fresh install.** They were
extracted from a working desktop, and that is not the same as knowing they
reproduce one. `apply.sh` backs up everything it replaces for exactly this
reason. The first real installation is the test, and what it finds belongs
back in this file.

**`themes.sh` has been run end to end into an empty home** — 13 of 16 entries
installed on the first pass, 2 already present as system packages, and 1 refused
by the Store's rate limit, which is what prompted the handling described above.
Every install route was exercised: `tar`, `kpackagetool6`, a `.plasmoid` file,
and two GitHub clones. What that does **not** prove is that the result *looks*
right — only that the files land where the configuration expects them.
