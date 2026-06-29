from __future__ import annotations

"""
checker/reporting.py
====================
Final report assembly. Calls each section formatter and joins them.
To add a new section: import formatter, call it here, append result.
"""

from pathlib import Path
from .config import RunOpts
from .sections import summary_section, i18n_section, kahlua_section, token_section


def build_report(
    opts: RunOpts,
    root: Path,
    total_scanned: int,
    excluded_count: int,
    known_keys: set,
    i18n_results: dict,
    kahlua_results: dict,
    token_results: dict,
) -> str:
    parts = [
        summary_section.format(opts, total_scanned, excluded_count),
    ]

    if opts.run_i18n:
        parts.append(i18n_section.format(i18n_results, known_keys, total_scanned, opts, root))

    if opts.run_kahlua:
        parts.append(kahlua_section.format(kahlua_results, total_scanned, opts, root))

    if opts.run_tokens:
        section = token_section.format(token_results, opts, root)
        if section:
            parts.append(section)

    return "\n\n".join(parts)
