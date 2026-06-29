from __future__ import annotations

"""
checker/runner.py
=================
Orchestration layer. Collects files, dispatches to check plugins,
and returns the assembled report string.

To add a new check:
  1. Add check plugin in checks/my_check.py
  2. Add section formatter in sections/my_section.py
  3. Add run flag to RunOpts in config.py
  4. Register below in run() — no other files need editing.
"""

import sys
from pathlib import Path

from .config import RunOpts
from .path_filter import collect_lua_files
from .i18n.key_collector import collect_all as collect_keys
from .checks.i18n_check import run as run_i18n_check
from .checks.kahlua_check import run as run_kahlua_check
from .checks.token_check import run as run_token_check
from .reporting import build_report


def run(opts: RunOpts) -> str:
    """Execute all enabled checks against the target defined in opts."""
    root = opts.effective_root()

    # ── 1. Resolve file list ──────────────────────────────────────────────
    if opts.single_file:
        if not opts.single_file.is_file():
            return f"ERROR: '{opts.single_file}' is not a file.\n"
        lua_files = [opts.single_file]
        excluded_count = 0
        print(f"[pz_verify] Single-file mode: {opts.single_file}", file=sys.stderr)
    else:
        scan_root = opts.target_dir or opts.mod_dir
        if not scan_root or not scan_root.is_dir():
            return f"ERROR: scan target '{scan_root}' is not a directory.\n"
        lua_files, excluded_count = collect_lua_files(scan_root, opts.excluded_folders)
        print(
            f"[pz_verify] Scanning: {scan_root}  "
            f"({len(lua_files)} files, {excluded_count} excluded)",
            file=sys.stderr,
        )

    total_scanned = len(lua_files)

    # ── 2. Run checks ─────────────────────────────────────────────────────
    known_keys: set[str] = set()
    i18n_results: dict = {}
    kahlua_results: dict = {}
    token_results: dict = {}

    if opts.run_i18n:
        key_root = opts.mod_dir or (opts.target_dir or opts.single_file.parent)
        known_keys = collect_keys(key_root)
        print(f"[pz_verify] i18n: {len(known_keys)} translation keys found.", file=sys.stderr)
        i18n_results = run_i18n_check(lua_files, known_keys)

    if opts.run_kahlua:
        kahlua_results = run_kahlua_check(lua_files, min_severity=opts.severity)

    if opts.run_tokens:
        token_results = run_token_check(
            lua_files,
            threshold=opts.token_threshold,
            chars_per_token=opts.chars_per_token,
        )

    print(
        f"[pz_verify] Done — "
        f"i18n:{len(i18n_results)} files  "
        f"kahlua:{len(kahlua_results)} files  "
        f"bloat:{len(token_results)} files",
        file=sys.stderr,
    )

    # ── 3. Build and return report ────────────────────────────────────────
    return build_report(
        opts=opts,
        root=root,
        total_scanned=total_scanned,
        excluded_count=excluded_count,
        known_keys=known_keys,
        i18n_results=i18n_results,
        kahlua_results=kahlua_results,
        token_results=token_results,
    )
