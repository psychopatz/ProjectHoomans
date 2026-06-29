from __future__ import annotations

"""
checker/sections/kahlua_section.py
===================================
Report section for Kahlua2 compatibility findings.
Exposes: format(kahlua_by_file, total_scanned, opts, root) -> str
"""

import os
from pathlib import Path
from ..config import SEV_ORDER

SEP = "=" * 72
SUB = "-" * 56


def format(
    kahlua_by_file: dict,
    total_scanned: int,
    opts,
    root: Path,
) -> str:
    total = sum(len(v) for v in kahlua_by_file.values())
    flagged = len(kahlua_by_file)
    error_count = sum(
        1 for fl in kahlua_by_file.values() for f in fl if f["severity"] == "ERROR"
    )
    warn_count = total - error_count

    lines = [SEP, "KAHLUA — LUA 5.1 COMPATIBILITY REPORT", SEP]
    lines += [
        f"Files scanned : {total_scanned}",
        f"Files flagged : {flagged}",
        f"Errors        : {error_count}",
        f"Warnings      : {warn_count}",
        "",
    ]

    if total == 0:
        lines.append("✅  No Kahlua compatibility issues detected.")
        return "\n".join(lines)

    sorted_files = sorted(kahlua_by_file.items(), key=lambda x: len(x[1]), reverse=True)

    lines.append(f"TOP {opts.top_n} FILES:")
    for path, flist in sorted_files[: opts.top_n]:
        e = sum(1 for f in flist if f["severity"] == "ERROR")
        w = len(flist) - e
        lines.append(f"  {len(flist):>4}  {os.path.relpath(path, root)}  (E:{e} W:{w})")
    lines.append("")

    for path, flist in sorted_files:
        sorted_findings = sorted(flist, key=lambda f: (f["line"], SEV_ORDER.get(f["severity"], 9)))
        lines.append(f"\n📄 {os.path.relpath(path, root)}")
        lines.append(SUB)
        for f in sorted_findings:
            sev_badge = f"[{f['severity']:<7}]"
            lines.append(f"  L{f['line']:<5} {sev_badge} {f['rule_id']}  {f['message']}")
            if f.get("fix"):
                lines.append(f"           ↳ Fix: {f['fix']}")
            if not opts.no_snippets and f.get("snippet"):
                snippet = f["snippet"].strip()[: opts.snippet_max]
                lines.append(f"           ↳ Code: {snippet}")

    lines.append("")
    return "\n".join(lines)
