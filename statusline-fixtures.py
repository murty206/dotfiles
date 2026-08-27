#!/usr/bin/env python3
"""Fixture payloads for claude-statusline.sh.

    python3 statusline-fixtures.py ./claude-statusline.sh

Prints one rendered line per case with the ANSI stripped, and exits non-zero if
any case crashed. Nothing here asserts a specific layout — the point is that no
input kills the script and that missing data drops its own segment and nothing
else. Read the output; the eye catches what an assertion was never told to look
for.

Payloads are built with json.dumps rather than written out in the shell. That is
not fussiness: a fixture mangled by shell quoting renders exactly like a broken
script, and chasing that costs more than the whole test file is worth.

Cases 9-12 use Windows-shaped paths. On Linux they are not paths at all, just
strings with backslashes in them, and the script is expected to leave them
alone — which is the same thing case 13 checks from the other direction. Run
this on both platforms; every case except 9-12 must render identically.
"""
import json
import re
import subprocess
import sys

BS = chr(92)
WINROOT = "C:" + BS + "Users" + BS + "murty" + BS + "projects" + BS + "myproject"
ANSI = re.compile(rb"\x1b\[[0-9;]*m")

BASE = {
    "model": {"display_name": "Opus 5 (1M context)", "id": "claude-opus-5[1m]"},
    "context_window": {"used_percentage": 12, "total_input_tokens": 124000,
                       "context_window_size": 1000000},
    "rate_limits": {"five_hour": {"used_percentage": 55},
                    "seven_day": {"used_percentage": 16}},
    "thinking": {"enabled": True},
}


def at(cwd, project=None):
    return {"workspace": {"current_dir": cwd,
                          "project_dir": cwd if project is None else project}}


def merge(*parts):
    out = {}
    for p in parts:
        out.update(p)
    return out


CASES = [
    ("1  normal", merge(at("/home/murty/projects/myproject/src",
                           "/home/murty/projects/myproject"), BASE)),
    ("2  fast + effort + age", merge(at("/tmp/demo"), BASE, {
        "fast_mode": True, "effort": {"level": "low"},
        "cost": {"total_duration_ms": 46800000}})),
    ("3  quota at 100%", merge(at("/tmp/demo"), BASE, {
        "context_window": {"used_percentage": 100, "total_input_tokens": 1000000,
                           "context_window_size": 1000000},
        "rate_limits": {"five_hour": {"used_percentage": 100},
                        "seven_day": {"used_percentage": 100}}})),
    ("4  no rate_limits", merge(at("/tmp/demo"), {
        "model": BASE["model"], "thinking": {"enabled": True},
        "context_window": {"used_percentage": 30, "total_input_tokens": 300000,
                           "context_window_size": 1000000}})),
    ("5  malformed JSON", '{"workspace":{"current_dir": '),
    ("6  empty input", ""),
    ("7  thinking off", merge(at("/tmp/demo"), BASE,
                              {"thinking": {"enabled": False}})),
    ("8  resets_at present", merge(at("/tmp/demo"), BASE, {
        "rate_limits": {"five_hour": {"used_percentage": 55,
                                      "resets_at": 4102444800},
                        "seven_day": {"used_percentage": 16}}})),
    ("9  win project root", merge(at(WINROOT, WINROOT), BASE)),
    ("10 win subdirectory", merge(at(WINROOT + BS + "src", WINROOT), BASE)),
    ("11 win deep subdir", merge(at(WINROOT + BS + "a" + BS + "b", WINROOT), BASE)),
    ("12 win UNC share", merge(at(BS + BS + "server" + BS + "share" + BS + "proj"),
                               BASE)),
    ("13 backslash in unix path", merge(at("/tmp/odd" + BS + "name"), BASE)),
]


def main():
    if len(sys.argv) != 2:
        print(__doc__.strip().splitlines()[2].strip())
        return 2
    script = sys.argv[1]
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")

    crashed = 0
    for label, payload in CASES:
        raw = payload if isinstance(payload, str) else json.dumps(payload)
        p = subprocess.run(["bash", script], input=raw.encode("utf-8"),
                           capture_output=True)
        line = ANSI.sub(b"", p.stdout).decode("utf-8", "replace")
        if p.returncode != 0:
            crashed += 1
            print("  CRASH rc={}".format(p.returncode))
        print("  {:<26} {}".format(label, line))

    print()
    print("cases that exited non-zero: {}".format(crashed))
    return 1 if crashed else 0


if __name__ == "__main__":
    raise SystemExit(main())
