from __future__ import annotations

"""
checker/sections/token_section.py
===================================
Report section for token-bloat findings.
Exposes: format(bloat_files, opts, root) -> str
"""

import os
from pathlib import Path

SEP = "=" * 72


def format(
    bloat_files: dict,
    opts,
    root: Path,
) -> str:
    if not bloat_files:
        return ""  # Omit section entirely when no files exceed threshold

    lines = [SEP, f"TOKEN BLOAT — FILES > {opts.token_threshold} TOKENS (est.)", SEP]
    lines.append(f"{'Tokens':>8}  File")
    lines.append("-" * 60)

    for path, count in sorted(bloat_files.items(), key=lambda x: x[1], reverse=True):
        rel = os.path.relpath(path, root)
        lines.append(f"{count:>8}  {rel}")

    lines += [
        "",
        f"  Token estimate: len(file_bytes) / {opts.chars_per_token} chars per token.",
        "  Files above threshold may exhaust LLM context when read whole.",
        "  Consider splitting before further analysis.",
        "",
    ]
    return "\n".join(lines)
