"""
checker/token_counter.py
========================
Zero-dependency token estimator.
Uses a chars-per-token approximation (default: 4 chars ≈ 1 GPT token).

Atomic module: no imports from other checker submodules.
"""

from pathlib import Path


def count_tokens(text: str, chars_per_token: int = 4) -> int:
    """Estimate token count from raw text."""
    return max(1, len(text) // chars_per_token)


def count_file_tokens(path: Path, chars_per_token: int = 4) -> int:
    """Estimate token count for a file on disk. Returns 0 on read error."""
    try:
        return count_tokens(
            path.read_text(encoding="utf-8", errors="ignore"),
            chars_per_token=chars_per_token,
        )
    except Exception:
        return 0
