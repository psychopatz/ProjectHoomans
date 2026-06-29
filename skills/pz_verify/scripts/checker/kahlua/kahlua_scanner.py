from __future__ import annotations

"""
checker/kahlua/kahlua_scanner.py
=================================
Per-line Kahlua2 compatibility checker.
Finding dict: {line, rule_id, severity, message, snippet, fix}

Atomic module: imports only from .rules.
"""

import re
from pathlib import Path
from .rules import KAHLUA_RULES, _COMMENT_RE

_STRING_RE = re.compile(r'"[^"\\]*(?:\\.[^"\\]*)*"|\'[^\'\\]*(?:\\.[^\'\\]*)*\'')
_TRAILING_COMMENT_RE = re.compile(r"--.*$")


def _strip_content(line: str) -> str:
    """Replace string literals and trailing comments with spaces to prevent false positives."""
    line = _TRAILING_COMMENT_RE.sub("", line)
    return _STRING_RE.sub(lambda m: " " * len(m.group()), line)


def scan_line(line: str, line_no: int) -> list[dict]:
    """Check one source line against all Kahlua rules."""
    if _COMMENT_RE.match(line):
        return []
    check_line = _strip_content(line)
    return [
        {
            "line": line_no,
            "rule_id": rule.id,
            "severity": rule.severity,
            "message": rule.message,
            "snippet": line.rstrip(),
            "fix": rule.fix,
        }
        for rule in KAHLUA_RULES
        if rule.pattern.search(check_line)
    ]


def scan_file(lua_path: Path) -> list[dict]:
    """Return all Kahlua findings for one Lua file."""
    findings: list[dict] = []
    try:
        for line_no, line in enumerate(
            lua_path.read_text(encoding="utf-8", errors="ignore").splitlines(), start=1
        ):
            findings.extend(scan_line(line, line_no))
    except Exception as exc:
        findings.append({
            "line": 0, "rule_id": "READ_ERROR", "severity": "ERROR",
            "message": str(exc), "snippet": "", "fix": "",
        })
    return findings
