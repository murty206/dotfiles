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

## What this does not carry: the themes themselves

**The configuration names themes; it cannot install them.** `kdeglobals` asks
for an icon set by name, and if that set is absent KDE falls back silently —
the same failure mode the `$HOME` substitution above exists to avoid.

The set these files expect:

| Component | Name |
|---|---|
| Look and feel | `Beauty-Color-Global-6` |
| Icons | `Slot-Beauty-Dark-Icons-V-3` |
| Window decoration | `BonaFides-Rounded-Blur-Dark-Color-Aurorae-6` |
| Cursor | `Bibata-Modern-Classic` |

Method, settled before this directory existed: **look for an AUR package
first** — it then belongs to the package manager, updates with everything else
and uninstalls without a trace. Only if there is none does the component get
downloaded from the KDE Store into the home directory, and then it is recorded
file by file, because nothing else will remember it is there.

## What has not been tested

**These files have never been restored onto a fresh install.** They were
extracted from a working desktop, and that is not the same as knowing they
reproduce one. `apply.sh` backs up everything it replaces for exactly this
reason. The first real installation is the test, and what it finds belongs
back in this file.
