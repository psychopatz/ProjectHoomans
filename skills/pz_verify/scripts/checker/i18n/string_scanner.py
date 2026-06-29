from __future__ import annotations

"""
checker/i18n/string_scanner.py
==============================
Per-line detection of hardcoded UI-facing strings that bypass the i18n system.
Finding dict: {line, context, string, is_known_key}

Atomic module: imports only from checker.config.
"""

from pathlib import Path
from ..config import (
    UI_API_TRIGGERS, WRAPPER_RE, SKIP_LINE_RE,
    SAFE_STRING_RE, LUA_STRING_RE,
)


def scan_line(line: str, line_no: int, known_keys: set[str]):
    """Yield finding dicts for every hardcoded UI-facing string on this line."""
    if SKIP_LINE_RE.search(line):
        return

    triggered_context: str | None = None
    for trigger in UI_API_TRIGGERS:
        if trigger in line:
            triggered_context = trigger.rstrip("(= ")
            break

    if triggered_context is None:
        return

    if WRAPPER_RE.search(line):
        return

    for m in LUA_STRING_RE.finditer(line):
        raw = m.group(1) if m.group(1) is not None else m.group(2)
        if not raw or len(raw) <= 1:
            continue
        if SAFE_STRING_RE.match(raw):
            continue
        yield {
            "line": line_no,
            "context": triggered_context,
            "string": raw,
            "is_known_key": raw in known_keys,
        }


def scan_file(lua_path: Path, known_keys: set[str]) -> list[dict]:
    """Return all i18n findings for one Lua file."""
    findings: list[dict] = []
    try:
        for line_no, line in enumerate(
            lua_path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1
        ):
            findings.extend(scan_line(line, line_no, known_keys))
    except Exception as exc:
        findings.append({"line": 0, "context": "READ_ERROR", "string": str(exc), "is_known_key": False})
    return findings
