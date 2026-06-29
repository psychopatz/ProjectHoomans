"""
rules.py — Severity enum, Issue/Rule dataclasses, and the full RULES list.
"""
from dataclasses import dataclass
from enum import IntEnum
from typing import List


class Severity(IntEnum):
    INFO    = 0
    WARNING = 1
    ERROR   = 2


SEVERITY_LABELS = {
    Severity.ERROR:   "ERROR",
    Severity.WARNING: "WARN ",
    Severity.INFO:    "INFO ",
}

SEVERITY_COLORS = {
    Severity.ERROR:   "\033[31m",
    Severity.WARNING: "\033[33m",
    Severity.INFO:    "\033[36m",
}

RESET = "\033[0m"
BOLD  = "\033[1m"
DIM   = "\033[2m"


@dataclass
class Issue:
    rule_id:  str
    severity: Severity
    file:     str
    line:     int
    col:      int
    message:  str
    snippet:  str
    fix_hint: str


@dataclass
class Rule:
    rule_id:  str
    severity: Severity
    pattern:  str    # regex applied to comment/string-stripped source line
    message:  str
    fix_hint: str


# ─────────────────────────────────────────────────────────────────────────────
# Rule table
# Each pattern is matched against cleaned source lines (comments + string
# literals replaced with spaces). Rules are evaluated line-by-line.
# ─────────────────────────────────────────────────────────────────────────────
RULES: List[Rule] = [

    # ── Lua 5.2+ syntax ──────────────────────────────────────────────────────

    Rule("KAHL-E001", Severity.ERROR,
         r'\bgoto\s+[A-Za-z_]\w*\b',
         "goto statement is Lua 5.2+ — not supported in Kahlua (Lua 5.1)",
         "Refactor using if/else, break, or helper functions"),

    Rule("KAHL-E002", Severity.ERROR,
         r'::[A-Za-z_]\w*::',
         "::label:: goto labels are Lua 5.2+ — not supported in Kahlua",
         "Remove goto labels and restructure control flow"),

    # ── Lua 5.3+ syntax ──────────────────────────────────────────────────────

    # Exclude :// (URLs), leading /, and --- separators
    Rule("KAHL-E003", Severity.ERROR,
         r'(?<![:/\-])//(?![/\-])',
         "// floor-division is Lua 5.3+ — not supported in Kahlua",
         "Use math.floor(a / b) instead of a // b"),

    Rule("KAHL-E004", Severity.ERROR,
         r'(?<![=<>!~&\w])&(?![&=\w])',
         "Bitwise & is Lua 5.3+ — not supported in Kahlua",
         "Use bit.band() or arithmetic equivalents"),

    Rule("KAHL-E005", Severity.ERROR,
         r'(?<![=<>!\|\w])\|(?![|\w])',
         "Bitwise | is Lua 5.3+ — not supported in Kahlua",
         "Use bit.bor() or arithmetic equivalents"),

    # Note: ~= (inequality) is valid Lua 5.1 — exclude it explicitly
    Rule("KAHL-E006", Severity.ERROR,
         r'(?<![=\w])~(?!=)',
         "Bitwise ~ (NOT/XOR) is Lua 5.3+ — note: ~= (inequality) is valid",
         "Use bit.bnot() / bit.bxor() or arithmetic equivalents"),

    Rule("KAHL-E007", Severity.ERROR,
         r'(?<![=<>])>>(?![=])|(?<![=<>])<<(?![=])',
         "Bitwise >> / << are Lua 5.3+ — not supported in Kahlua",
         "Use bit.rshift() / bit.lshift()"),

    # ── Lua 5.2+ standard library ────────────────────────────────────────────

    Rule("KAHL-E008", Severity.ERROR,
         r'\btable\.pack\s*\(',
         "table.pack() is Lua 5.2+ — not in Kahlua",
         "Use: local t = {...}; t.n = select('#', ...)"),

    Rule("KAHL-E009", Severity.ERROR,
         r'\btable\.unpack\s*\(',
         "table.unpack() is Lua 5.2+ — not in Kahlua",
         "Use unpack() (the Lua 5.1 global)"),

    Rule("KAHL-E010", Severity.ERROR,
         r'\btable\.move\s*\(',
         "table.move() is Lua 5.3+ — not in Kahlua",
         "Use a manual loop to copy table elements"),

    Rule("KAHL-E011", Severity.ERROR,
         r'\brawlen\s*\(',
         "rawlen() is Lua 5.2+ — not in Kahlua",
         "Use the # length operator or a manual count loop"),

    # ── Lua 5.3+ standard library ────────────────────────────────────────────

    Rule("KAHL-E012", Severity.ERROR,
         r'\bmath\.type\s*\(',
         "math.type() is Lua 5.3+ — not in Kahlua",
         "Use type() — Kahlua has no integer subtype"),

    Rule("KAHL-E013", Severity.ERROR,
         r'\bmath\.tointeger\s*\(',
         "math.tointeger() is Lua 5.3+ — not in Kahlua",
         "Use math.floor() or tonumber() with validation"),

    Rule("KAHL-E014", Severity.ERROR,
         r'\bstring\.pack\s*\(|\bstring\.unpack\s*\(|\bstring\.packsize\s*\(',
         "string.pack/unpack/packsize are Lua 5.3+ — not in Kahlua",
         "Use manual bit arithmetic or custom serialization"),

    Rule("KAHL-E015", Severity.ERROR,
         r'\butf8\.',
         "utf8 library is Lua 5.3+ — not in Kahlua",
         "Use string.* byte functions or a custom UTF-8 helper"),

    # ── PZ Kahlua sandboxed libraries ────────────────────────────────────────

    Rule("KAHL-E016", Severity.ERROR,
         r'\bcoroutine\.',
         "coroutine library is sandboxed — not available in PZ Kahlua",
         "Use PZ Events.* system or state machines instead"),

    Rule("KAHL-E017", Severity.ERROR,
         r'\bio\.',
         "io library is sandboxed — not available in PZ Kahlua",
         "Use getModFileWriter / getModFileReader instead"),

    Rule("KAHL-E018", Severity.ERROR,
         r'\bos\.',
         "os library is sandboxed — not available in PZ Kahlua",
         "Use getGameTime() or getTimeInMillis() instead"),

    Rule("KAHL-E019", Severity.ERROR,
         r'\bdebug\.',
         "debug library is sandboxed — not available in PZ Kahlua",
         "Use print() or a custom logger"),

    Rule("KAHL-E020", Severity.ERROR,
         r'\bpackage\.',
         "package library is sandboxed — not available in PZ Kahlua",
         "PZ auto-loads all lua files under media/lua/"),

    Rule("KAHL-E021", Severity.ERROR,
         r'\brequire\s*\(',
         "require() is sandboxed — not available in PZ Kahlua",
         "PZ auto-loads all lua files under media/lua/"),

    Rule("KAHL-E022", Severity.ERROR,
         r'\bdofile\s*\(|\bloadfile\s*\(',
         "dofile()/loadfile() are sandboxed — not available in PZ Kahlua",
         "PZ auto-loads lua files from media/lua/"),

    # ── Invalid Lua syntax (common mistakes) ─────────────────────────────────

    Rule("KAHL-E023", Severity.ERROR,
         r'!=',
         "!= is not valid Lua syntax",
         "Use ~= for inequality comparisons"),

    Rule("KAHL-E024", Severity.ERROR,
         r'\bcontinue\b',
         "continue is not a valid Lua keyword",
         "Use repeat/until false with break, or restructure the loop body"),

    # ── Warnings ─────────────────────────────────────────────────────────────

    Rule("KAHL-W001", Severity.WARNING,
         r'\bload\s*\(\s*(?!function)',
         "load(string) changed in Lua 5.2 — use loadstring() in Kahlua",
         "Replace load(str) with loadstring(str)"),

    Rule("KAHL-W002", Severity.WARNING,
         r'\btable\.getn\s*\(',
         "table.getn() deprecated since Lua 5.1",
         "Replace table.getn(t) with #t"),

    Rule("KAHL-W003", Severity.WARNING,
         r'\bstring\.len\s*\(',
         "string.len() works but # operator is idiomatic",
         "Replace string.len(s) with #s"),

    Rule("KAHL-W004", Severity.WARNING,
         r'\bsetfenv\s*\(|\bgetfenv\s*\(',
         "setfenv/getfenv are Lua 5.1-only — verify Kahlua supports them",
         "Avoid environment manipulation; prefer upvalues or module tables"),

    Rule("KAHL-W005", Severity.WARNING,
         r'\bpcall\s*\(\s*\)',
         "pcall() called with no function argument — likely a bug",
         "Pass a function: pcall(myFunc, arg1, ...)"),

    # W006: only fire for bare top-level function (no dot/colon qualifier)
    Rule("KAHL-W006", Severity.WARNING,
         r'^function\s+[A-Za-z_]\w*\s*\(',
         "Top-level bare function creates a global — may pollute namespace",
         "Use 'local function' or assign to a module table"),

    # W007: only fire at column 0, exclude table field lines (trailing ,)
    # Requires the line to NOT end with , (those are table constructor fields)
    Rule("KAHL-W007", Severity.WARNING,
         r'^[A-Za-z_]\w*\s*=\s*(?!nil\b)(?!.*,\s*$)',
         "Assignment at column 0 without 'local' creates/modifies a global",
         "Add 'local' or assign to a module table"),

    # ── Info ─────────────────────────────────────────────────────────────────

    Rule("KAHL-I001", Severity.INFO,
         r'\bunpack\s*\(',
         "unpack() is the correct Lua 5.1 global (not table.unpack) — OK",
         ""),

    Rule("KAHL-I002", Severity.INFO,
         r'\bloadstring\s*\(',
         "loadstring() is correct for Kahlua/Lua 5.1 — OK",
         ""),

    Rule("KAHL-I003", Severity.INFO,
         r'\bEvents\.\w+\.Add\s*\(',
         "PZ event hook — verify event name spelling against base game",
         "Run 'api-diff' to check event names against PZ manifest"),
]
