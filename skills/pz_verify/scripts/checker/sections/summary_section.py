"""
checker/sections/summary_section.py
=====================================
Report header / summary section formatter.
Exposes: format(opts, total_scanned, excluded_count) -> str
"""

import os
from pathlib import Path


def format(opts, total_scanned: int, excluded_count: int) -> str:
    SEP = "=" * 72
    lines = [
        SEP,
        "PZ VERIFY — REPORT",
        SEP,
        f"Target    : {opts.effective_root()}",
        f"Scanned   : {total_scanned} files  ({excluded_count} excluded)",
        f"Checks    : "
        + "  ".join(filter(None, [
            "i18n" if opts.run_i18n else "",
            "kahlua" if opts.run_kahlua else "",
            f"tokens(>{opts.token_threshold})" if opts.run_tokens else "",
        ])),
        f"Severity  : {opts.severity}+",
        "",
    ]
    return "\n".join(lines)
