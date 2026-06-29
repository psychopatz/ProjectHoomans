#!/usr/bin/env python3
"""
pz_kahlua_lint.py — Project Zomboid Kahlua Compatibility Tool
=============================================================
Subcommands:
  lint      Lint .lua files for Kahlua2 (Lua 5.1) incompatibilities (default)
  api-scan  Scan PZ base-game Lua to build an API manifest (events, globals)
  api-diff  Compare mod .lua files against a manifest for unknown event usage

Run  `pz_kahlua_lint.py <subcommand> --help`  for per-subcommand options.

Exit codes: 0 clean  |  1 issues found  |  2 argument/setup error
"""
import argparse
import os
import sys

# Ensure the scripts/ directory is on the path so sub-packages are importable
# regardless of the caller's working directory.
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from lint import (                                      # noqa: E402
    Severity, Issue,
    lint_file, run_luac,
    print_issues, print_json, list_rules,
    discover_files, DEFAULT_EXCLUDE_PATTERNS,
)
from api.scanner    import scan_base_game, save_manifest, load_manifest, DEFAULT_PZ_LUA_DIR  # noqa: E402
from api.comparator import compare_mod_to_manifest, diff_manifests, print_api_issues, print_diff  # noqa: E402


# ─────────────────────────────────────────────────────────────────────────────
# Sub-command: lint
# ─────────────────────────────────────────────────────────────────────────────

def _add_lint_args(p: argparse.ArgumentParser) -> None:
    p.add_argument('paths', nargs='*', metavar='PATH',
                   help='.lua file(s) or directories to lint')
    p.add_argument('--json',       action='store_true', help='JSON output')
    p.add_argument('--no-color',   action='store_true', help='Disable ANSI colour')
    p.add_argument('--severity',   default='INFO', choices=['INFO', 'WARNING', 'ERROR'],
                   help='Minimum severity (default: INFO)')
    p.add_argument('--luac',       action='store_true', help='Also run luac -p')
    p.add_argument('--no-quality', action='store_true',
                   help='Disable code-quality checks (KAHL-Q*)')
    p.add_argument('--stats',      action='store_true', help='Print summary counts')
    p.add_argument('--exclude',    metavar='PATTERN', action='append', default=[],
                   help='Additional glob patterns to exclude (can repeat). '
                        f'Default excludes: {DEFAULT_EXCLUDE_PATTERNS}')
    p.add_argument('--no-defaults', action='store_true',
                   help='Disable the built-in default exclude patterns')
    p.add_argument('--list-rules', action='store_true', help='Print all rules and exit')


def cmd_lint(args: argparse.Namespace) -> int:
    if args.list_rules:
        list_rules()
        return 0

    if not args.paths:
        print("Error: PATH is required unless using --list-rules.", file=sys.stderr)
        return 2

    exclude = ([] if args.no_defaults else list(DEFAULT_EXCLUDE_PATTERNS)) + args.exclude
    min_sev = Severity[args.severity]
    use_color = not args.json and not args.no_color and sys.stdout.isatty()

    files = discover_files(args.paths, exclude)
    if not files:
        print("No .lua files found.", file=sys.stderr)
        return 2

    all_issues: list = []
    for fp in files:
        issues = lint_file(fp, min_sev, include_quality=not args.no_quality)
        if args.luac:
            issues += run_luac(fp)
        all_issues.extend(issues)

    all_issues.sort(key=lambda i: (i.file, i.line, i.rule_id))

    if args.json:
        print_json(all_issues)
    else:
        print_issues(all_issues, use_color, args.stats)

    return 1 if any(i.severity >= min_sev for i in all_issues) else 0


# ─────────────────────────────────────────────────────────────────────────────
# Sub-command: api-scan
# ─────────────────────────────────────────────────────────────────────────────

def _add_api_scan_args(p: argparse.ArgumentParser) -> None:
    p.add_argument('--pz-dir', default=DEFAULT_PZ_LUA_DIR, metavar='PATH',
                   help=f'PZ media/lua directory (default: {DEFAULT_PZ_LUA_DIR})')
    p.add_argument('--output', default='pz_api_manifest.json', metavar='FILE',
                   help='Output manifest path (default: pz_api_manifest.json)')
    p.add_argument('--diff-prev', action='store_true',
                   help='After scanning, diff against the existing manifest at --output')
    p.add_argument('--no-color', action='store_true', help='Disable ANSI colour')


def cmd_api_scan(args: argparse.Namespace) -> int:
    use_color = not args.no_color and sys.stdout.isatty()

    prev = load_manifest(args.output) if args.diff_prev else None

    print(f"Scanning: {args.pz_dir}", file=sys.stderr)
    try:
        manifest = scan_base_game(args.pz_dir)
    except FileNotFoundError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 2

    save_manifest(manifest, args.output)
    print(f"Manifest saved → {args.output}  "
          f"({manifest.file_count} files, {len(manifest.events)} events, "
          f"{len(manifest.globals)} globals)")

    if prev and args.diff_prev:
        diff = diff_manifests(prev, manifest)
        print_diff(diff, use_color)

    return 0


# ─────────────────────────────────────────────────────────────────────────────
# Sub-command: api-diff
# ─────────────────────────────────────────────────────────────────────────────

def _add_api_diff_args(p: argparse.ArgumentParser) -> None:
    p.add_argument('paths', nargs='+', metavar='PATH',
                   help='.lua file(s) or directories to check')
    p.add_argument('--manifest', default='pz_api_manifest.json', metavar='FILE',
                   help='Manifest to compare against (default: pz_api_manifest.json)')
    p.add_argument('--json',     action='store_true', help='JSON output')
    p.add_argument('--no-color', action='store_true', help='Disable ANSI colour')
    p.add_argument('--exclude',  metavar='PATTERN', action='append', default=[],
                   help='Extra exclude glob patterns')
    p.add_argument('--no-defaults', action='store_true',
                   help='Disable built-in default exclude patterns')


def cmd_api_diff(args: argparse.Namespace) -> int:
    use_color = not args.json and not args.no_color and sys.stdout.isatty()

    manifest = load_manifest(args.manifest)
    if manifest is None:
        print(f"Error: manifest not found or invalid: {args.manifest}\n"
              f"Run 'api-scan' first to generate it.", file=sys.stderr)
        return 2

    print(f"Using manifest: {args.manifest}  "
          f"(PZ {manifest.pz_version}, {len(manifest.events)} events)", file=sys.stderr)

    exclude = ([] if args.no_defaults else list(DEFAULT_EXCLUDE_PATTERNS)) + args.exclude
    issues = compare_mod_to_manifest(args.paths, manifest, exclude)

    if args.json:
        import json as _json
        print(_json.dumps([{
            "kind": i.kind, "name": i.name,
            "file": i.file, "line": i.line, "snippet": i.snippet,
        } for i in issues], indent=2))
    else:
        print_api_issues(issues, use_color)

    return 1 if issues else 0


# ─────────────────────────────────────────────────────────────────────────────
# Entry point
# ─────────────────────────────────────────────────────────────────────────────

def main() -> int:
    parser = argparse.ArgumentParser(
        prog='pz_kahlua_lint.py',
        description='PZ Kahlua compatibility tool',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__)

    sub = parser.add_subparsers(dest='cmd', metavar='SUBCOMMAND')

    p_lint = sub.add_parser('lint',     help='Lint .lua files for Kahlua incompatibilities')
    p_scan = sub.add_parser('api-scan', help='Scan PZ base-game Lua → API manifest')
    p_diff = sub.add_parser('api-diff', help='Compare mod .lua against API manifest')

    _add_lint_args(p_lint)
    _add_api_scan_args(p_scan)
    _add_api_diff_args(p_diff)

    # Backward-compat: if first arg looks like a path (not a subcommand), default to lint
    if len(sys.argv) > 1 and sys.argv[1] not in ('lint', 'api-scan', 'api-diff', '-h', '--help'):
        sys.argv.insert(1, 'lint')

    args = parser.parse_args()
    if args.cmd is None:
        parser.print_help()
        return 2

    dispatch = {'lint': cmd_lint, 'api-scan': cmd_api_scan, 'api-diff': cmd_api_diff}
    return dispatch[args.cmd](args)


if __name__ == '__main__':
    sys.exit(main())
