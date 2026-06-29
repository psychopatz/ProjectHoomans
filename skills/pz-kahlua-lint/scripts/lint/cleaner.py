"""
cleaner.py — Strip Lua string literals and comments before regex analysis.

Returns a list of (cleaned_line, original_line) pairs.
Characters inside strings/comments are replaced with spaces so that:
  - line numbers are preserved
  - regex rules don't fire inside quoted text or comments
"""
import re
from typing import List, Tuple


def clean_lua_source(source: str) -> List[Tuple[str, str]]:
    """
    Walk the source and replace string/comment content with spaces,
    keeping the original line structure intact.
    """
    out: List[str] = []
    i, n = 0, len(source)

    while i < n:
        c = source[i]

        # ── Long comment  --[=*[ ... ]=*] ────────────────────────────────────
        if c == '-' and i + 1 < n and source[i + 1] == '-':
            long_m = re.match(r'--(\[=*\[)', source[i:])
            if long_m:
                bracket = long_m.group(1)
                close   = ']' + '=' * (len(bracket) - 2) + ']'
                end     = source.find(close, i + len(long_m.group(0)))
                if end == -1:
                    out.extend('\n' if ch == '\n' else ' ' for ch in source[i:])
                    break
                segment = source[i : end + len(close)]
                out.extend('\n' if ch == '\n' else ' ' for ch in segment)
                i += len(segment)
            else:
                # Regular line comment: strip to end of line
                end = source.find('\n', i)
                if end == -1:
                    out.extend(' ' * (n - i))
                    break
                out.extend(' ' * (end - i))
                i = end
            continue

        # ── Long string  [=*[ ... ]=*] ───────────────────────────────────────
        if c == '[':
            long_m = re.match(r'\[=*\[', source[i:])
            if long_m:
                bracket = long_m.group(0)
                close   = ']' + '=' * (len(bracket) - 2) + ']'
                end     = source.find(close, i + len(bracket))
                if end == -1:
                    out.extend('\n' if ch == '\n' else ' ' for ch in source[i:])
                    break
                segment = source[i : end + len(close)]
                out.extend('\n' if ch == '\n' else ' ' for ch in segment)
                i += len(segment)
                continue

        # ── Quoted strings (single or double) ────────────────────────────────
        if c in ('"', "'"):
            quote = c
            out.append(' ')
            i += 1
            while i < n:
                ch = source[i]
                if ch == '\\' and i + 1 < n:
                    out.append(' ')
                    out.append(' ')
                    i += 2
                    continue
                if ch == quote:
                    out.append(' ')
                    i += 1
                    break
                out.append('\n' if ch == '\n' else ' ')
                i += 1
            continue

        out.append(c)
        i += 1

    cleaned = ''.join(out)
    c_lines = cleaned.split('\n')
    o_lines = source.split('\n')

    # Pad to equal length
    while len(c_lines) < len(o_lines):
        c_lines.append('')
    while len(o_lines) < len(c_lines):
        o_lines.append('')

    return list(zip(c_lines, o_lines))
