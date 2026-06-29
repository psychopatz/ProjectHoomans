from __future__ import annotations

"""
checker/checks/token_check.py
==============================
Token-bloat check plugin.
Exposes: run(files, threshold, chars_per_token) -> dict[Path, int]

Atomic: zero imports from other checker submodules.
"""

from pathlib import Path
from ..token_counter import count_file_tokens


def run(
    files: list[Path],
    threshold: int = 2000,
    chars_per_token: int = 4,
) -> dict[Path, int]:
    """Return {path: token_count} for files exceeding threshold."""
    results: dict[Path, int] = {}
    for path in files:
        count = count_file_tokens(path, chars_per_token)
        if count > threshold:
            results[path] = count
    return results
