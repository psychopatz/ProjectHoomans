"""
engine.py — Core lint engine: runs rules against a file and optionally luac.
"""
import re
import subprocess
from typing import List

from .rules import Issue, Severity, RULES
from .cleaner import clean_lua_source
from .quality import run_quality_checks


def lint_file(
    filepath: str,
    min_severity: Severity = Severity.INFO,
    include_quality: bool = True,
) -> List[Issue]:
    """Run all rules against *filepath* and return a deduplicated Issue list."""
    issues: List[Issue] = []

    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
            source = fh.read()
    except OSError as exc:
        return [Issue(
            rule_id="KAHL-SYS", severity=Severity.ERROR,
            file=filepath, line=0, col=0,
            message=f"Cannot read file: {exc}", snippet="", fix_hint="")]

    line_pairs = clean_lua_source(source)

    for rule in RULES:
        if rule.severity < min_severity:
            continue
        pat = re.compile(rule.pattern)
        for lineno, (clean, orig) in enumerate(line_pairs, start=1):
            for m in pat.finditer(clean):
                issues.append(Issue(
                    rule_id=rule.rule_id,
                    severity=rule.severity,
                    file=filepath,
                    line=lineno,
                    col=m.start() + 1,
                    message=rule.message,
                    snippet=orig.strip()[:120],
                    fix_hint=rule.fix_hint,
                ))

    if include_quality:
        issues.extend(run_quality_checks(filepath, source, min_severity))

    # Deduplicate: keep first occurrence of (rule, line)
    seen:    set  = set()
    deduped: List[Issue] = []
    for iss in issues:
        key = (iss.rule_id, iss.line)
        if key not in seen:
            seen.add(key)
            deduped.append(iss)

    return sorted(deduped, key=lambda i: (i.line, i.rule_id))


def run_luac(filepath: str) -> List[Issue]:
    """Run `luac -p` against *filepath* for baseline syntax validation."""
    issues: List[Issue] = []
    try:
        proc = subprocess.run(
            ["luac", "-p", filepath],
            capture_output=True, text=True, timeout=10)
        if proc.returncode != 0:
            for line in proc.stderr.splitlines():
                m = re.match(r'luac:\s+.+?:(\d+):\s+(.+)', line)
                if m:
                    issues.append(Issue(
                        rule_id="LUAC-SYN", severity=Severity.ERROR,
                        file=filepath, line=int(m.group(1)), col=1,
                        message=f"luac: {m.group(2).strip()}",
                        snippet="", fix_hint="Fix the syntax error shown"))
                elif line.strip():
                    issues.append(Issue(
                        rule_id="LUAC-SYN", severity=Severity.ERROR,
                        file=filepath, line=0, col=0,
                        message=f"luac: {line.strip()}",
                        snippet="", fix_hint=""))
    except (FileNotFoundError, subprocess.TimeoutExpired):
        pass
    return issues
