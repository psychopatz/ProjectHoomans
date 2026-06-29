from __future__ import annotations

"""
checker/sections/i18n_section.py
=================================
Report section for i18n hardcoded-string findings.
Exposes: format(i18n_by_file, known_keys, total_scanned, opts, root) -> str
"""

import os
from pathlib import Path

SEP = "=" * 72
SUB = "-" * 56


def format(
    i18n_by_file: dict,
    known_keys: set,
    total_scanned: int,
    opts,
    root: Path,
) -> str:
    total = sum(len(v) for v in i18n_by_file.values())
    flagged = len(i18n_by_file)

    lines = [SEP, "I18N — HARDCODED STRING REPORT", SEP]
    lines += [
        f"Files scanned   : {total_scanned}",
        f"Files flagged   : {flagged}",
        f"Hardcoded strs  : {total}",
        f"Known keys      : {len(known_keys)}",
        "",
    ]

    if total == 0:
        lines.append("✅  No hardcoded UI strings detected.")
        return "\n".join(lines)

    sorted_files = sorted(i18n_by_file.items(), key=lambda x: len(x[1]), reverse=True)

    lines.append(f"TOP {opts.top_n} FILES:")
    for path, flist in sorted_files[: opts.top_n]:
        lines.append(f"  {len(flist):>4}  {os.path.relpath(path, root)}")
    lines.append("")

    for path, flist in sorted_files:
        lines.append(f"\n📄 {os.path.relpath(path, root)}")
        lines.append(SUB)
        for f in flist:
            tag = "[KNOWN KEY]      " if f["is_known_key"] else "[NOT IN TRANSLATE]"
            line = f"  L{f['line']:<5} [{f['context']:<24}] {tag}  \"{f['string']}\""
            lines.append(line)

    lines += [
        "",
        "LEGEND:",
        "  [KNOWN KEY]        — Key registered but string passed RAW (not via getText).",
        "  [NOT IN TRANSLATE] — No translation key exists for this string.",
        "",
    ]
    return "\n".join(lines)
