"""
checker/config.py
=================
All shared constants for pz_verify.
Edit ONLY this file to tune triggers, patterns, and exclusions.
"""

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

# ---------------------------------------------------------------------------
# RunOpts — the single config object passed through the entire pipeline
# ---------------------------------------------------------------------------

@dataclass
class RunOpts:
    # Scan target (runner picks the first that is set)
    mod_dir: Optional[Path] = None      # wide: full mod root
    target_dir: Optional[Path] = None   # narrow: specific sub-dir
    single_file: Optional[Path] = None  # single: one .lua file

    # Check selection
    run_i18n: bool = True
    run_kahlua: bool = True
    run_tokens: bool = True

    # Token-bloat tuning
    token_threshold: int = 2000
    chars_per_token: int = 4           # approximation: 1 token ≈ 4 chars

    # Display tuning
    severity: str = "WARNING"          # minimum severity: ERROR | WARNING | INFO
    top_n: int = 10                    # rows in TOP FILES tables
    no_snippets: bool = False          # suppress code snippets
    snippet_max: int = 80              # max chars shown per snippet

    # Exclusion
    excluded_folders: list[str] = field(default_factory=lambda: ["Manuals", "Debug"])

    def effective_root(self) -> Path:
        """Return the path to use as the display root in reports."""
        return self.single_file.parent if self.single_file else (self.target_dir or self.mod_dir)


# ---------------------------------------------------------------------------
# Severity ordering (lower = more severe)
# ---------------------------------------------------------------------------
SEV_ORDER: dict[str, int] = {"ERROR": 0, "WARNING": 1, "INFO": 2}

def sev_passes(finding_sev: str, min_sev: str) -> bool:
    """Return True if finding_sev meets or exceeds min_sev threshold."""
    return SEV_ORDER.get(finding_sev, 9) <= SEV_ORDER.get(min_sev, 9)


# ---------------------------------------------------------------------------
# I18n — UI API triggers
# ---------------------------------------------------------------------------
UI_API_TRIGGERS: list[str] = [
    "addOption(",
    "ISButton:new(",
    "ISLabel:new(",
    "ISPanel:new(",
    "setTitle(",
    "addText(",
    "drawText(",
    "setText(",
    "ISModalDialog(",
    "ISModalDialog.ShowDialog(",
    "playerObj:Say(",
    "self:Say(",
    "player:Say(",
    "addTextBox(",
    "tooltip =",
    "text =",
    "title =",
    "label =",
    "buttonText =",
]

# ---------------------------------------------------------------------------
# I18n — translation wrapper patterns (already routed through i18n)
# ---------------------------------------------------------------------------
TRANSLATION_WRAPPER_PATTERNS: list[str] = [
    r"\bgetText\s*\(",
    r"\bgetTextOrNull\s*\(",
    r"\bT\s*\(",
    r"DynamicTrading\.Text\.Get\s*\(",
    r"DT_Text\s*\[",
    r"Translations\s*\[",
]
WRAPPER_RE = re.compile("|".join(TRANSLATION_WRAPPER_PATTERNS))

# ---------------------------------------------------------------------------
# I18n — lines to skip entirely
# ---------------------------------------------------------------------------
SKIP_LINE_PATTERNS: list[str] = [
    r"^\s*--",
    r"\bprint\s*\(",
    r"\berror\s*\(",
    r"\bwarn\s*\(",
    r"\bLog\s*\(",
    r"DynamicTrading\.Log\s*\(",
    r"ZombieLuaError\s*\(",
    r"\brequire\s*[\"']",
    r"\bpcall\s*\(\s*require",
    r"getTexture\s*\(",
    r"getSoundManager",
    r"ZomboidForge",
    r"ZombieLua",
    r"SandboxVars\.",
    r"ISUIElement",
    r"\bDEBUG\b",
    r"\bTEST\b",
    r'["\'"]DEBUG:',
    r'["\'"]TEST:',
]
SKIP_LINE_RE = re.compile("|".join(SKIP_LINE_PATTERNS))

# ---------------------------------------------------------------------------
# I18n — safe string values (not user-visible)
# ---------------------------------------------------------------------------
SAFE_STRING_PATTERNS: list[str] = [
    r"^$",
    r"^\s+$",
    r"^[\d\.\-\+]+$",
    r"^[A-Z_0-9]{1,10}$",
    r"^[a-z]$",
    r"^media/",
    r"^DT/",
    r"^ISUI/",
    r"\.(png|jpg|ogg|wav|txt|lua|json)$",
    r"^#[0-9a-fA-F]{3,8}$",
    r"^\d+\.\d+\.\d+",
    r"^https?://",
    r"^\w+\.\w+\(\)",
    r"^\w+\s*=\s*\w+",
    r"^(table|string|number|boolean|nil|function|thread|userdata)$",
    r"^[A-Z][A-Za-z0-9]+$",
    r"^[a-z][A-Za-z0-9]+$",
    r"^[\s\[\]\(\)\.,:/@\-]",
    r"[\s\[\]\(\)\.,:/@\-]$",
    r"^[a-z][a-z0-9_]+$",
]
SAFE_STRING_RE = re.compile("|".join(f"(?:{p})" for p in SAFE_STRING_PATTERNS))

# ---------------------------------------------------------------------------
# Shared — Lua literal string extractor
# ---------------------------------------------------------------------------
LUA_STRING_RE = re.compile(
    r'(?:"([^"\\]*(?:\\.[^"\\]*)*)"' + r"|'([^'\\]*(?:\\.[^'\\]*)*)')"
)
