from __future__ import annotations

"""
checker/checks/i18n_check.py
============================
i18n check plugin.
Exposes: run(files, opts, known_keys) -> dict[Path, list[dict]]

Atomic: receives data, calls scanner, returns raw results.
"""

from pathlib import Path
from ..i18n.string_scanner import scan_file


def run(
    files: list[Path],
    known_keys: set[str],
) -> dict[Path, list[dict]]:
    """Scan all files for hardcoded UI strings. Returns findings keyed by path."""
    results: dict[Path, list[dict]] = {}
    for path in files:
        findings = scan_file(path, known_keys)
        if findings:
            results[path] = findings
    return results
