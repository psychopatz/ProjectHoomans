#!/usr/bin/env python3
"""
pz_verify.py — Swiss Army Knife PZ Mod Debugger
================================================
Checks Lua files for:
  • Hardcoded UI strings not routed through i18n (--i18n)
  • Kahlua2 / Lua 5.1 incompatibilities (--kahlua)
  • Files exceeding a token threshold (--tokens, default 2000)

Scan modes (one required):
  --mod-dir PATH   Wide scan: entire mod root
  --dir PATH       Narrow scan: specific sub-directory
  --file PATH      Single-file scan (skips path filter)

Exit codes: 0=clean  1=issues found  2=argument error
"""

import argparse
import os
import sys
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from checker.config import RunOpts
from checker.runner import run


def build_parser() -> argparse.ArgumentParser:
    p = argparse.ArgumentParser(
        prog="pz_verify.py",
        description="pz_verify — PZ mod i18n + Kahlua + token-bloat debugger",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )

    # ── Scan target (mutually exclusive) ──────────────────────────────────
    target = p.add_mutually_exclusive_group(required=True)
    target.add_argument("--mod-dir", metavar="PATH",
                        help="Wide scan: full mod root directory")
    target.add_argument("--dir", metavar="PATH",
                        help="Narrow scan: specific sub-directory")
    target.add_argument("--file", metavar="PATH",
                        help="Single-file scan (skips path filter)")

    # ── Check selection ───────────────────────────────────────────────────
    checks = p.add_argument_group("Check selection (default: all enabled)")
    checks.add_argument("--i18n", action="store_true", default=False,
                        help="Run ONLY the i18n check")
    checks.add_argument("--kahlua", action="store_true", default=False,
                        help="Run ONLY the Kahlua check")
    checks.add_argument("--tokens", action="store_true", default=False,
                        help="Run ONLY the token-bloat check")

    # ── Tuning ────────────────────────────────────────────────────────────
    tune = p.add_argument_group("Tuning")
    tune.add_argument("--token-threshold", type=int, default=2000, metavar="N",
                      help="Flag files with > N tokens (default: 2000)")
    tune.add_argument("--chars-per-token", type=int, default=4, metavar="N",
                      help="Chars per token approximation (default: 4)")
    tune.add_argument("--severity", choices=["ERROR", "WARNING", "INFO"],
                      default="WARNING", help="Minimum severity to display (default: WARNING)")
    tune.add_argument("--top", type=int, default=10, metavar="N",
                      help="Rows in TOP FILES tables (default: 10)")
    tune.add_argument("--no-snippets", action="store_true", default=False,
                      help="Suppress code snippets (reduces output tokens)")
    tune.add_argument("--snippet-max", type=int, default=80, metavar="N",
                      help="Max chars per snippet (default: 80)")
    tune.add_argument("--exclude", metavar="FOLDERS",
                      default="Manuals,Debug",
                      help="Comma-separated folder names to exclude (default: Manuals,Debug)")

    # ── Output ────────────────────────────────────────────────────────────
    p.add_argument("--output", metavar="FILE", default=None,
                   help="Write report to file instead of stdout")

    return p


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    # Resolve check flags — if none specified, enable all.
    any_check = args.i18n or args.kahlua or args.tokens
    opts = RunOpts(
        mod_dir=Path(args.mod_dir).resolve() if args.mod_dir else None,
        target_dir=Path(args.dir).resolve() if args.dir else None,
        single_file=Path(args.file).resolve() if args.file else None,
        run_i18n=args.i18n or not any_check,
        run_kahlua=args.kahlua or not any_check,
        run_tokens=args.tokens or not any_check,
        token_threshold=args.token_threshold,
        chars_per_token=args.chars_per_token,
        severity=args.severity,
        top_n=args.top,
        no_snippets=args.no_snippets,
        snippet_max=args.snippet_max,
        excluded_folders=[f.strip() for f in args.exclude.split(",") if f.strip()],
    )

    report = run(opts)

    if args.output:
        out = Path(args.output)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(report, encoding="utf-8")
        print(f"[pz_verify] Report → {out}", file=sys.stderr)
    else:
        print(report)

    has_issues = any(
        marker in report
        for marker in ("NOT IN TRANSLATE", "KAHL-E", "KAHL-W", "TOKEN BLOAT")
    )
    return 1 if has_issues else 0


if __name__ == "__main__":
    sys.exit(main())
