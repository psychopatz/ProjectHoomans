#!/usr/bin/env python3
"""
Scan files and flag token-bloated files using a local ChatGPT 5.4 tokenizer.

Tokenizer policy:
- Target tokenizer: ChatGPT 5.4 (local approximation)
- Implementation: tiktoken "o200k_base" encoding
- No network/API usage
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from fnmatch import fnmatch
from pathlib import Path
from typing import Iterable, List


DEFAULT_THRESHOLD = 2000
DEFAULT_EXCLUDES = [
    "*/.git/*",
    "*/node_modules/*",
    "*/__pycache__/*",
    "*/.venv/*",
    "*/.codex-venv-*/*",
    "*/dist/*",
    "*/build/*",
    "*/Manuals/*",
    "*/WhatsNew/*",
    "*/Items/*",
]

# Default to files that are likely source/docs; binary files are ignored.
DEFAULT_EXTENSIONS = {
    ".lua", ".py", ".js", ".ts", ".tsx", ".jsx", ".json", ".md", ".txt",
    ".yml", ".yaml", ".toml", ".ini", ".cfg", ".xml", ".sql", ".sh", ".bat",
}


@dataclass
class FileStat:
    path: str
    tokens: int
    chars: int
    lines: int


class ChatGPT54Tokenizer:
    """Local tokenizer wrapper for ChatGPT 5.4-compatible counting."""

    def __init__(self) -> None:
        try:
            import tiktoken  # type: ignore
        except Exception as exc:
            raise RuntimeError(
                "Missing dependency 'tiktoken'. Install it with: pip install tiktoken"
            ) from exc

        # ChatGPT 5.4 tokenizer approximation; no remote calls.
        self._enc = tiktoken.get_encoding("o200k_base")
        self.name = "chatgpt-5.4(o200k_base-local)"

    def count_tokens(self, text: str) -> int:
        return len(self._enc.encode(text))


def is_excluded(path: Path, patterns: List[str]) -> bool:
    path_s = str(path).replace("\\", "/")
    for pat in patterns:
        if fnmatch(path_s, pat):
            return True
    return False


def iter_target_files(paths: Iterable[str], excludes: List[str], include_all: bool) -> Iterable[Path]:
    for raw in paths:
        p = Path(raw)
        if not p.exists():
            continue

        if p.is_file():
            if not is_excluded(p, excludes):
                if include_all or p.suffix.lower() in DEFAULT_EXTENSIONS:
                    yield p
            continue

        for child in p.rglob("*"):
            if not child.is_file():
                continue
            if is_excluded(child, excludes):
                continue
            if include_all or child.suffix.lower() in DEFAULT_EXTENSIONS:
                yield child


def analyze_files(paths: Iterable[Path], tokenizer: ChatGPT54Tokenizer) -> List[FileStat]:
    out: List[FileStat] = []
    for p in paths:
        try:
            text = p.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue

        tokens = tokenizer.count_tokens(text)
        out.append(
            FileStat(
                path=str(p),
                tokens=tokens,
                chars=len(text),
                lines=text.count("\n") + 1 if text else 0,
            )
        )
    return out


def print_table(stats: List[FileStat], threshold: int, top: int) -> None:
    stats_sorted = sorted(stats, key=lambda s: s.tokens, reverse=True)
    shown = stats_sorted[:top] if top > 0 else stats_sorted

    print("Tokenizer:", "chatgpt-5.4(o200k_base-local)")
    print("Threshold:", threshold)
    print()
    print(f"{'TOKENS':>8}  {'LINES':>8}  {'CHARS':>8}  FILE")
    print("-" * 100)

    for s in shown:
        marker = "!" if s.tokens > threshold else " "
        print(f"{s.tokens:>8}{marker}  {s.lines:>8}  {s.chars:>8}  {s.path}")

    over = [s for s in stats if s.tokens > threshold]
    print()
    print(f"Over threshold: {len(over)} / {len(stats)}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Detect bloated files by token count (ChatGPT 5.4 local tokenizer)."
    )
    parser.add_argument(
        "paths",
        nargs="+",
        help="File(s) or directory(ies) to scan",
    )
    parser.add_argument(
        "--threshold",
        type=int,
        default=DEFAULT_THRESHOLD,
        help=f"Token threshold for bloat flagging (default: {DEFAULT_THRESHOLD})",
    )
    parser.add_argument(
        "--top",
        type=int,
        default=200,
        help="Show only top N files by token count (0 = all, default: 200)",
    )
    parser.add_argument(
        "--exclude",
        action="append",
        default=[],
        metavar="GLOB",
        help="Additional exclude glob pattern (repeatable)",
    )
    parser.add_argument(
        "--no-default-excludes",
        action="store_true",
        help="Disable built-in excludes",
    )
    parser.add_argument(
        "--all-files",
        action="store_true",
        help="Include all file extensions (default scans only likely text/source)",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Emit JSON output",
    )

    args = parser.parse_args()

    excludes = ([] if args.no_default_excludes else list(DEFAULT_EXCLUDES)) + list(args.exclude)

    try:
        tokenizer = ChatGPT54Tokenizer()
    except RuntimeError as exc:
        print(f"Error: {exc}")
        return 2

    files = list(iter_target_files(args.paths, excludes, args.all_files))
    if not files:
        print("No files found.")
        return 2

    stats = analyze_files(files, tokenizer)
    stats_sorted = sorted(stats, key=lambda s: s.tokens, reverse=True)
    over = [s for s in stats_sorted if s.tokens > args.threshold]

    if args.json:
        payload = {
            "tokenizer": tokenizer.name,
            "threshold": args.threshold,
            "scanned": len(stats_sorted),
            "over_threshold": len(over),
            "files": [
                {
                    "path": s.path,
                    "tokens": s.tokens,
                    "lines": s.lines,
                    "chars": s.chars,
                    "over_threshold": s.tokens > args.threshold,
                }
                for s in (stats_sorted[: args.top] if args.top > 0 else stats_sorted)
            ],
        }
        print(json.dumps(payload, indent=2))
    else:
        print_table(stats_sorted, args.threshold, args.top)

    # Non-zero means at least one file needs decoupling by threshold policy.
    return 1 if over else 0


if __name__ == "__main__":
    raise SystemExit(main())
