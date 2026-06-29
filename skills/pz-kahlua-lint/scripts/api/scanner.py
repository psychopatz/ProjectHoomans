"""
scanner.py — Scan the PZ base-game Lua directory and build an API manifest.

The manifest captures:
  - events:   all Event.X names seen in the base game
  - globals:  top-level function and table names defined in shared/
  - bridges:  bare Java-bridge function names (getCell, getPlayer, …)
  - metadata: scan date, PZ version (from Steam ACF), lua dir, file count

Usage (CLI):
    python3 pz_kahlua_lint.py api-scan [--pz-dir PATH] [--output FILE]

The manifest JSON is saved to --output (default: pz_api_manifest.json).
Re-run after each PZ update to detect API changes with api-diff.
"""
import json
import os
import re
from dataclasses import dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, List, Optional, Set


# ─── Default PZ installation path ─────────────────────────────────────────────
DEFAULT_PZ_LUA_DIR = os.path.expanduser(
    "~/.steam/steam/steamapps/common/ProjectZomboid/projectzomboid/media/lua"
)

# Steam ACF for reading installed build ID / version
STEAM_ACF_PATH = os.path.expanduser(
    "~/.steam/steam/steamapps/appmanifest_108600.acf"
)


# ─── Data types ───────────────────────────────────────────────────────────────

@dataclass
class ApiManifest:
    scan_date:  str
    pz_version: str
    lua_dir:    str
    file_count: int
    events:     List[str]   = field(default_factory=list)  # sorted unique
    globals:    List[str]   = field(default_factory=list)  # top-level names
    bridges:    List[str]   = field(default_factory=list)  # Java bridge names


# ─── Helpers ──────────────────────────────────────────────────────────────────

def _read_pz_version(acf_path: str = STEAM_ACF_PATH) -> str:
    """Extract PZ build ID from the Steam ACF manifest, or return 'unknown'."""
    try:
        with open(acf_path, 'r', encoding='utf-8', errors='replace') as fh:
            for line in fh:
                m = re.search(r'"buildid"\s+"(\d+)"', line)
                if m:
                    return f"build-{m.group(1)}"
    except OSError:
        pass
    return "unknown"


def _strip_comments(source: str) -> str:
    """Remove -- line comments (not long comments) for extraction pass."""
    lines = []
    for line in source.splitlines():
        # Remove -- comment from line (simplified; good enough for extraction)
        clean = re.sub(r'--.*$', '', line)
        lines.append(clean)
    return '\n'.join(lines)


# ─── Extraction passes ────────────────────────────────────────────────────────

# Events.X.Add / Events.X.Remove / Events.X.Hook
_EVENT_PAT = re.compile(r'\bEvents\.([A-Za-z_]\w*)\s*[.:]')

# Top-level function: function Foo(  or  function Foo.Bar(
# We only take the first segment (table name or bare function name)
_GLOBAL_FUNC_PAT = re.compile(r'^function\s+([A-Za-z_]\w*)', re.MULTILINE)

# Global table init: Foo = Foo or {}  /  Foo = {}  /  Foo = Foo or false
_GLOBAL_TABLE_PAT = re.compile(r'^([A-Za-z_]\w*)\s*=\s*\1\s*or\s*[{(]', re.MULTILINE)

# Java bridge calls: bare lowercase/mixed functions followed by () that look like PZ bridges
# e.g. getCell(), getPlayer(), getWorld(), getGameTime(), …
_BRIDGE_PAT = re.compile(r'\b(get[A-Z]\w*|instanceof|luautils|xpairs|round2?|strsplit)\s*\(')


def _extract_from_file(filepath: str,
                        events: Set[str],
                        globals_: Set[str],
                        bridges: Set[str]) -> None:
    try:
        with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
            source = fh.read()
    except OSError:
        return

    clean = _strip_comments(source)

    for m in _EVENT_PAT.finditer(clean):
        events.add(m.group(1))

    for m in _GLOBAL_FUNC_PAT.finditer(clean):
        globals_.add(m.group(1))

    for m in _GLOBAL_TABLE_PAT.finditer(clean):
        globals_.add(m.group(1))

    for m in _BRIDGE_PAT.finditer(clean):
        bridges.add(m.group(1))


# ─── Public API ───────────────────────────────────────────────────────────────

def scan_base_game(lua_dir: Optional[str] = None) -> ApiManifest:
    """
    Scan all .lua files under *lua_dir* and return an ApiManifest.
    Raises FileNotFoundError if the directory doesn't exist.
    """
    target = Path(lua_dir or DEFAULT_PZ_LUA_DIR)
    if not target.is_dir():
        raise FileNotFoundError(
            f"PZ Lua directory not found: {target}\n"
            f"Pass --pz-dir to specify the path.")

    events:   Set[str] = set()
    globals_: Set[str] = set()
    bridges:  Set[str] = set()

    lua_files = sorted(target.rglob('*.lua'))
    for f in lua_files:
        _extract_from_file(str(f), events, globals_, bridges)

    return ApiManifest(
        scan_date  = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        pz_version = _read_pz_version(),
        lua_dir    = str(target),
        file_count = len(lua_files),
        events     = sorted(events),
        globals    = sorted(globals_),
        bridges    = sorted(bridges),
    )


def save_manifest(manifest: ApiManifest, output_path: str) -> None:
    Path(output_path).parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, 'w', encoding='utf-8') as fh:
        json.dump({
            "scan_date":  manifest.scan_date,
            "pz_version": manifest.pz_version,
            "lua_dir":    manifest.lua_dir,
            "file_count": manifest.file_count,
            "events":     manifest.events,
            "globals":    manifest.globals,
            "bridges":    manifest.bridges,
        }, fh, indent=2)


def load_manifest(path: str) -> Optional[ApiManifest]:
    try:
        with open(path, 'r', encoding='utf-8') as fh:
            d = json.load(fh)
        return ApiManifest(
            scan_date  = d.get("scan_date",  ""),
            pz_version = d.get("pz_version", "unknown"),
            lua_dir    = d.get("lua_dir",    ""),
            file_count = d.get("file_count", 0),
            events     = d.get("events",     []),
            globals    = d.get("globals",    []),
            bridges    = d.get("bridges",    []),
        )
    except (OSError, json.JSONDecodeError, KeyError):
        return None
