"""
quality.py — Lightweight code-quality checks for Lua maintainability.
"""
import re
from dataclasses import dataclass
from typing import List, Optional, Tuple

from .rules import Issue, Severity
from .cleaner import clean_lua_source


@dataclass
class QualityRule:
    rule_id: str
    severity: Severity
    message: str
    fix_hint: str


QUALITY_RULES: List[QualityRule] = [
    QualityRule(
        "KAHL-Q001",
        Severity.WARNING,
        "Line exceeds recommended length (140 chars)",
        "Split long expressions or strings across multiple lines",
    ),
    QualityRule(
        "KAHL-Q002",
        Severity.INFO,
        "Trailing whitespace",
        "Remove trailing spaces for cleaner diffs",
    ),
    QualityRule(
        "KAHL-Q003",
        Severity.WARNING,
        "Mixed tabs and spaces in indentation",
        "Use a single indentation style per line",
    ),
    QualityRule(
        "KAHL-Q004",
        Severity.WARNING,
        "Deep indentation level (>4)",
        "Extract helper functions to reduce nesting",
    ),
    QualityRule(
        "KAHL-Q005",
        Severity.INFO,
        "TODO/FIXME/HACK marker left in code",
        "Resolve or convert to a tracked issue before release",
    ),
    QualityRule(
        "KAHL-Q006",
        Severity.WARNING,
        "Function is too long (>120 lines)",
        "Split into smaller helper functions with focused responsibilities",
    ),
    QualityRule(
        "KAHL-Q007",
        Severity.WARNING,
        "Function has too many parameters (>6)",
        "Pass a context/options table instead of many positional parameters",
    ),
]


_QUALITY_BY_ID = {r.rule_id: r for r in QUALITY_RULES}
_TODO_PAT = re.compile(r'--\s*(TODO|FIXME|HACK)\b', re.IGNORECASE)
_FN_LEN_THRESHOLD = 120
_FN_PARAM_THRESHOLD = 6

# Common Lua function declaration forms.
_FN_DECL_PATTERNS = [
    re.compile(r'^\s*local\s+function\s+([A-Za-z_]\w*)\s*\(([^)]*)\)'),
    re.compile(r'^\s*function\s+([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*\(([^)]*)\)'),
    re.compile(r'^\s*([A-Za-z_]\w*(?:[.:][A-Za-z_]\w*)*)\s*=\s*function\s*\(([^)]*)\)'),
]
_KEYWORD_PAT = re.compile(r'\b(function|end)\b')


def _indent_depth(indent: str) -> int:
    # Treat tabs as one level and every 4 spaces as one level.
    tabs = indent.count("\t")
    spaces = len(indent.replace("\t", ""))
    return tabs + (spaces // 4)


def _parse_params(param_src: str) -> List[str]:
    params = [p.strip() for p in param_src.split(',') if p.strip()]
    # varargs are fine and should not count against readability threshold
    return [p for p in params if p != '...']


def _find_decl(line: str) -> Optional[Tuple[str, List[str]]]:
    for pat in _FN_DECL_PATTERNS:
        m = pat.match(line)
        if m:
            return m.group(1), _parse_params(m.group(2))
    return None


def _find_function_end(clean_lines: List[str], start_idx: int) -> Optional[int]:
    depth = 0
    for i in range(start_idx, len(clean_lines)):
        for m in _KEYWORD_PAT.finditer(clean_lines[i]):
            kw = m.group(1)
            if kw == 'function':
                depth += 1
            else:
                depth -= 1
                if depth == 0:
                    return i
    return None


def run_quality_checks(filepath: str, source: str, min_severity: Severity) -> List[Issue]:
    issues: List[Issue] = []
    cleaned_pairs = clean_lua_source(source)
    clean_lines = [c for c, _ in cleaned_pairs]
    orig_lines = [o for _, o in cleaned_pairs]

    for lineno, raw in enumerate(source.splitlines(), start=1):
        line = raw.rstrip("\n")
        stripped = line.lstrip(" \t")
        indent = line[:len(line) - len(stripped)]

        if len(line) > 140:
            rule = _QUALITY_BY_ID["KAHL-Q001"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=141,
                    message=rule.message,
                    snippet=line.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

        if line.rstrip(" \t") != line:
            rule = _QUALITY_BY_ID["KAHL-Q002"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=max(1, len(line.rstrip(" \t")) + 1),
                    message=rule.message,
                    snippet=line.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

        if indent and (" " in indent and "\t" in indent):
            rule = _QUALITY_BY_ID["KAHL-Q003"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=1,
                    message=rule.message,
                    snippet=line.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

        if _indent_depth(indent) > 4:
            rule = _QUALITY_BY_ID["KAHL-Q004"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=1,
                    message=rule.message,
                    snippet=line.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

        if _TODO_PAT.search(line):
            rule = _QUALITY_BY_ID["KAHL-Q005"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=max(1, line.find("--") + 1),
                    message=rule.message,
                    snippet=line.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

    # Function-level structural checks (length / argument count).
    for idx, clean in enumerate(clean_lines):
        decl = _find_decl(clean)
        if decl is None:
            continue

        fn_name, params = decl
        start_line = idx + 1

        if len(params) > _FN_PARAM_THRESHOLD:
            rule = _QUALITY_BY_ID["KAHL-Q007"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=start_line,
                    col=max(1, clean.find('(') + 1),
                    message=f"{rule.message}: {fn_name}({len(params)} params)",
                    snippet=orig_lines[idx].strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

        end_idx = _find_function_end(clean_lines, idx)
        if end_idx is None:
            continue

        fn_len = (end_idx - idx) + 1
        if fn_len > _FN_LEN_THRESHOLD:
            rule = _QUALITY_BY_ID["KAHL-Q006"]
            if rule.severity >= min_severity:
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=start_line,
                    col=1,
                    message=f"{rule.message}: {fn_name} ({fn_len} lines)",
                    snippet=orig_lines[idx].strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

    return issues
