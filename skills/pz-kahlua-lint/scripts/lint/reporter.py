"""
reporter.py — Output formatters: terminal (colour/plain), JSON, rule list.
"""
import json
import sys
from typing import List

from .rules import Issue, Rule, Severity, RULES, SEVERITY_LABELS, SEVERITY_COLORS, RESET, BOLD, DIM
from .quality import QUALITY_RULES


def format_issue(issue: Issue, use_color: bool) -> str:
    sev   = SEVERITY_LABELS[issue.severity]
    color = SEVERITY_COLORS[issue.severity] if use_color else ""
    reset = RESET if use_color else ""
    bold  = BOLD  if use_color else ""
    dim   = DIM   if use_color else ""

    loc   = f"{issue.file}:{issue.line}:{issue.col}"
    lines = [f"{color}{bold}{sev}{reset} [{issue.rule_id}] {bold}{loc}{reset}"]
    lines.append(f"       {issue.message}")
    if issue.snippet:
        lines.append(f"       {dim}→ {issue.snippet}{reset}")
    if issue.fix_hint:
        lines.append(f"       {dim}Fix: {issue.fix_hint}{reset}")
    return '\n'.join(lines)


def print_issues(issues: List[Issue], use_color: bool, show_stats: bool) -> None:
    if not issues:
        msg = f"\033[32mNo issues found.{RESET}" if use_color else "No issues found."
        print(msg)
        return

    last_file = None
    for iss in issues:
        if iss.file != last_file:
            sep = '─' * 72
            if use_color:
                print(f"\n{BOLD}{sep}{RESET}\n{BOLD}{iss.file}{RESET}")
            else:
                print(f"\n{sep}\n{iss.file}")
            last_file = iss.file
        print(format_issue(iss, use_color))

    if show_stats:
        by_sev = {s: 0 for s in Severity}
        for iss in issues:
            by_sev[iss.severity] += 1
        print()
        for sev in reversed(list(Severity)):
            if by_sev[sev]:
                color = SEVERITY_COLORS[sev] if use_color else ""
                reset = RESET if use_color else ""
                print(f"  {color}{SEVERITY_LABELS[sev].strip()}{reset}: {by_sev[sev]}")
        print(f"  Total : {len(issues)}")


def print_json(issues: List[Issue]) -> None:
    print(json.dumps([{
        "rule":     iss.rule_id,
        "severity": SEVERITY_LABELS[iss.severity].strip(),
        "file":     iss.file,
        "line":     iss.line,
        "col":      iss.col,
        "message":  iss.message,
        "snippet":  iss.snippet,
        "fix_hint": iss.fix_hint,
    } for iss in issues], indent=2))


def list_rules() -> None:
    print(f"{'ID':<14} {'SEV':<8} MESSAGE")
    print('-' * 80)
    for r in RULES:
        sev = SEVERITY_LABELS[r.severity].strip()
        print(f"{r.rule_id:<14} {sev:<8} {r.message}")
    for r in QUALITY_RULES:
        sev = SEVERITY_LABELS[r.severity].strip()
        print(f"{r.rule_id:<14} {sev:<8} {r.message}")
