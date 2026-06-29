"""
checker/path_filter.py
======================
File discovery and exclusion logic.
Excluded folders are configurable via RunOpts.excluded_folders.

Atomic module: only imports from config (RunOpts type hint only).
"""

from pathlib import Path


def is_excluded(path: Path, excluded_folders: list[str]) -> bool:
    """Return True if any path part matches an excluded folder name."""
    for part in path.parts:
        if part in excluded_folders:
            return True
    return False


def collect_lua_files(
    root: Path,
    excluded_folders: list[str],
) -> tuple[list[Path], int]:
    """
    Walk root recursively, return (included_files, excluded_count).
    Works for both mod-root and sub-directory scans.
    """
    included: list[Path] = []
    excluded_count: int = 0

    for lua_path in sorted(root.rglob("*.lua")):
        if is_excluded(lua_path, excluded_folders):
            excluded_count += 1
        else:
            included.append(lua_path)

    return included, excluded_count
