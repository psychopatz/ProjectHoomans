from __future__ import annotations

"""
checker/checks/kahlua_check.py
==============================
Kahlua check plugin.
Exposes: run(files, opts) -> dict[Path, list[dict]]

Atomic: receives data, calls scanner, filters by severity, returns results.
"""

from pathlib import Path
from ..kahlua.kahlua_scanner import scan_file
from ..config import sev_passes


def run(
    files: list[Path],
    min_severity: str = "WARNING",
) -> dict[Path, list[dict]]:
    """Scan all files for Kahlua2 incompatibilities filtered to min_severity."""
    results: dict[Path, list[dict]] = {}
    for path in files:
        findings = [
            f for f in scan_file(path)
            if sev_passes(f["severity"], min_severity)
        ]
        if findings:
            results[path] = findings
    return results
