#!/usr/bin/env python3
"""Create a compact Project Hoomans Lua smoke test without versioned paths."""

from __future__ import annotations

import argparse
import re
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("name", help="test name, with or without pnc_ and _smoke")
    parser.add_argument("--layer", choices=("shared", "server", "client"), default="shared")
    parser.add_argument("--subject", required=True, help="Lua path relative to the selected layer")
    options = parser.parse_args()
    stem = re.sub(r"[^a-z0-9_]+", "_", options.name.casefold()).strip("_")
    if not stem.startswith("pnc_"):
        stem = "pnc_" + stem
    if not stem.endswith("_smoke"):
        stem += "_smoke"
    target = ROOT / "tests" / f"{stem}.lua"
    if target.exists():
        parser.error(f"test already exists: {target}")
    source = f'''local T = require "tests/support/test"

local Subject = T.load("ProjectHoomans", "{options.layer}", "{options.subject}")

T.truthy(Subject, "subject did not load")

T.finish("{stem}")
'''
    target.write_text(source, encoding="utf-8")
    print(target.relative_to(ROOT))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
