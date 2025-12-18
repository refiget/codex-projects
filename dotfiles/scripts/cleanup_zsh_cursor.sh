#!/usr/bin/env python3
"""
Remove cursor-shape hook from ~/.zshrc (the _set_cursor_shape function and its calls).
Creates a backup ~/.zshrc.bak.cursor-clean before rewriting.
"""
from __future__ import annotations

import shutil
from pathlib import Path

zshrc = Path.home() / ".zshrc"
backup = zshrc.with_suffix(zshrc.suffix + ".bak.cursor-clean")

if not zshrc.exists():
    raise SystemExit(f"zshrc not found at {zshrc}")

print(f"Backup: {backup}")
shutil.copy2(zshrc, backup)

lines = zshrc.read_text().splitlines()


def drop_cursor_function(src: list[str]) -> list[str]:
    out: list[str] = []
    skipping = False
    depth = 0
    for line in src:
        if not skipping and line.lstrip().startswith("_set_cursor_shape()"):
            skipping = True
            depth = line.count("{") - line.count("}")
            continue
        if skipping:
            depth += line.count("{") - line.count("}")
            if depth <= 0:
                skipping = False
            continue
        out.append(line)
    return out


def drop_calls(src: list[str]) -> list[str]:
    return [ln for ln in src if "_set_cursor_shape" not in ln]


cleaned = drop_calls(drop_cursor_function(lines))
zshrc.write_text("\n".join(cleaned) + "\n")
print("Removed cursor-shape function and its calls. Reload your shell or source ~/.zshrc.")
