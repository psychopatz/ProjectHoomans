"""
comparator.py — Compare mod Lua against an ApiManifest to surface:

  1. Unknown events: Events.X.Add() where X is not in the manifest
  2. Manifest diff:  events/globals added or removed between two manifests
                     (run after a PZ update to see what changed)

The comparator does NOT re-lint files — it is purely about API membership.
"""
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

from .scanner import ApiManifest, load_manifest

# colours
RESET  = "\033[0m"
BOLD   = "\033[1m"
RED    = "\033[31m"
YELLOW = "\033[33m"
GREEN  = "\033[32m"
CYAN   = "\033[36m"
DIM    = "\033[2m"


# ─── Data types ───────────────────────────────────────────────────────────────

@dataclass
class ApiIssue:
    kind:    str   # "unknown_event" | "unknown_global"
    name:    str   # the unrecognised API name
    file:    str
    line:    int
    snippet: str


@dataclass
class ManifestDiff:
    old_version:    str
    new_version:    str
    events_added:   List[str]
    events_removed: List[str]
    globals_added:  List[str]
    globals_removed: List[str]


# ─── Event usage extraction ───────────────────────────────────────────────────

# Match Events.X.Add / Events.X.Remove / Events.X.Hook  (any method)
_EVENT_USE_PAT = re.compile(r'\bEvents\.([A-Za-z_]\w*)\s*[.:]')
# Comment stripping (simplified)
_COMMENT_PAT   = re.compile(r'--.*$')


def _strip_line(line: str) -> str:
    return _COMMENT_PAT.sub('', line)


# ─── Comparator ───────────────────────────────────────────────────────────────

def compare_mod_to_manifest(
    mod_paths:       List[str],
    manifest:        ApiManifest,
    exclude_patterns: Optional[List[str]] = None,
) -> List[ApiIssue]:
    """
    Scan mod .lua files and flag Events.X usages where X is not in the manifest.
    Returns a list of ApiIssue (one per unique event-name per file).
    """
    from lint.discovery import discover_files, DEFAULT_EXCLUDE_PATTERNS
    excl = exclude_patterns if exclude_patterns is not None else DEFAULT_EXCLUDE_PATTERNS

    known_events: Set[str] = set(manifest.events)
    issues: List[ApiIssue] = []
    seen_per_file: Dict[Tuple[str, str], bool] = {}  # (file, event_name) dedup

    files = discover_files(mod_paths, excl)
    for filepath in files:
        try:
            with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
                lines = fh.readlines()
        except OSError:
            continue

        for lineno, raw in enumerate(lines, start=1):
            clean = _strip_line(raw)
            for m in _EVENT_USE_PAT.finditer(clean):
                event_name = m.group(1)
                key = (filepath, event_name)
                if key in seen_per_file:
                    continue
                seen_per_file[key] = True

                if event_name not in known_events:
                    issues.append(ApiIssue(
                        kind="unknown_event",
                        name=event_name,
                        file=filepath,
                        line=lineno,
                        snippet=raw.strip()[:120],
                    ))

    return sorted(issues, key=lambda i: (i.file, i.line))


# ─── Manifest diff ────────────────────────────────────────────────────────────

def diff_manifests(old: ApiManifest, new: ApiManifest) -> ManifestDiff:
    old_ev  = set(old.events);  new_ev  = set(new.events)
    old_gl  = set(old.globals); new_gl  = set(new.globals)
    return ManifestDiff(
        old_version     = old.pz_version,
        new_version     = new.pz_version,
        events_added    = sorted(new_ev - old_ev),
        events_removed  = sorted(old_ev - new_ev),
        globals_added   = sorted(new_gl - old_gl),
        globals_removed = sorted(old_gl - new_gl),
    )


# ─── Output ───────────────────────────────────────────────────────────────────

def print_api_issues(issues: List[ApiIssue], use_color: bool) -> None:
    if not issues:
        msg = f"{GREEN}No unknown API usages found.{RESET}" if use_color else "No unknown API usages found."
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

        kind_label = "UNKNOWN EVENT"
        color = YELLOW if use_color else ""
        reset = RESET  if use_color else ""
        bold  = BOLD   if use_color else ""
        dim   = DIM    if use_color else ""

        print(f"{color}{bold}{kind_label}{reset} [{iss.name}] {bold}{iss.file}:{iss.line}{reset}")
        print(f"       Event not found in PZ manifest — typo or removed in this PZ version")
        if iss.snippet:
            print(f"       {dim}→ {iss.snippet}{reset}")

    print(f"\n  Total unknown events: {len(issues)}")


def print_diff(diff: ManifestDiff, use_color: bool) -> None:
    bold  = BOLD  if use_color else ""
    reset = RESET if use_color else ""
    green = GREEN if use_color else ""
    red   = RED   if use_color else ""
    dim   = DIM   if use_color else ""

    print(f"{bold}Manifest diff: {diff.old_version} → {diff.new_version}{reset}")

    def section(title: str, items: List[str], color: str) -> None:
        if not items:
            return
        print(f"\n{bold}{title} ({len(items)}){reset}")
        for name in items:
            print(f"  {color}{name}{reset}")

    section("Events ADDED   (new in PZ)", diff.events_added,   green)
    section("Events REMOVED (gone from PZ — check mod usage)", diff.events_removed, red)
    section("Globals ADDED",   diff.globals_added,   green)
    section("Globals REMOVED (check mod usage)", diff.globals_removed, red)

    total_removed = len(diff.events_removed) + len(diff.globals_removed)
    if total_removed == 0:
        msg = f"{green}No breaking removals detected.{reset}" if use_color else "No breaking removals detected."
        print(f"\n{msg}")
    else:
        msg = f"{red}{total_removed} removal(s) may break existing mods.{reset}" if use_color else f"{total_removed} removal(s) may break existing mods."
        print(f"\n{msg}")
