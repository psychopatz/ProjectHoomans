"""
checker/kahlua/rules.py
=======================
Kahlua2 / Lua 5.1 incompatibility rules.
To add a rule: append to KAHLUA_RULES. No other files need changes.
"""

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class KahluaRule:
    id: str
    severity: str        # ERROR | WARNING | INFO
    pattern: re.Pattern
    message: str
    fix: str = ""


def _r(pattern: str, flags: int = 0) -> re.Pattern:
    return re.compile(pattern, flags)


_COMMENT_RE = re.compile(r"^\s*--")

KAHLUA_RULES: list[KahluaRule] = [
    # ── ERROR rules ────────────────────────────────────────────────────────
    KahluaRule("KAHL-E001", "ERROR", _r(r"\bgoto\b"),
               "'goto' is Lua 5.2+ — not supported in Kahlua2",
               "Refactor with if/else, break, or repeat/until false"),
    KahluaRule("KAHL-E002", "ERROR", _r(r"::[A-Za-z_]\w*::"),
               "goto label '::label::' is Lua 5.2+ — not supported",
               "Remove goto labels; use structured control flow"),
    KahluaRule("KAHL-E003", "ERROR", _r(r"(?<![\"'])//(?![\"'])"),
               "'//' floor division is Lua 5.3+",
               "Use math.floor(a / b)"),
    KahluaRule("KAHL-E004", "ERROR", _r(r"(?<![=<>~!])&(?!=)"),
               "'&' bitwise AND is Lua 5.3+",
               "Use bit.band(a, b)"),
    KahluaRule("KAHL-E005", "ERROR", _r(r"(?<![=<>~!])\|(?!=)"),
               "'|' bitwise OR is Lua 5.3+",
               "Use bit.bor(a, b)"),
    KahluaRule("KAHL-E006", "ERROR", _r(r"~(?!=)"),
               "'~' bitwise NOT/XOR is Lua 5.3+ (note: '~=' inequality is valid)",
               "Use bit.bnot() or bit.bxor()"),
    KahluaRule("KAHL-E007", "ERROR", _r(r">>|<<"),
               "'>>/<< bitwise shift is Lua 5.3+",
               "Use bit.rshift() / bit.lshift()"),
    KahluaRule("KAHL-E008", "ERROR", _r(r"\btable\.pack\s*\("),
               "'table.pack()' is Lua 5.2+",
               "Use local t = {...}"),
    KahluaRule("KAHL-E009", "ERROR", _r(r"\btable\.unpack\s*\("),
               "'table.unpack()' is Lua 5.2+ — use unpack()",
               "Use unpack(t)"),
    KahluaRule("KAHL-E010", "ERROR", _r(r"\btable\.move\s*\("),
               "'table.move()' is Lua 5.3+",
               "Implement a manual copy loop"),
    KahluaRule("KAHL-E011", "ERROR", _r(r"\brawlen\s*\("),
               "'rawlen()' is Lua 5.2+",
               "Use the # operator"),
    KahluaRule("KAHL-E012", "ERROR", _r(r"\bmath\.type\s*\("),
               "'math.type()' is Lua 5.3+",
               "Use type(x) == 'number'"),
    KahluaRule("KAHL-E013", "ERROR", _r(r"\bmath\.tointeger\s*\("),
               "'math.tointeger()' is Lua 5.3+",
               "Use math.floor(x)"),
    KahluaRule("KAHL-E014", "ERROR", _r(r"\bstring\.(pack|unpack|packsize)\s*\("),
               "'string.pack/unpack/packsize' is Lua 5.3+",
               "Use manual bit arithmetic"),
    KahluaRule("KAHL-E015", "ERROR", _r(r"\butf8\."),
               "'utf8.*' library is Lua 5.3+",
               "Use string.* byte functions"),
    KahluaRule("KAHL-E016", "ERROR", _r(r"\bcoroutine\."),
               "'coroutine.*' not implemented in Kahlua2",
               "Use PZ Events.* or a state machine"),
    KahluaRule("KAHL-E017", "ERROR", _r(r"\bio\."),
               "'io.*' is sandboxed in PZ",
               "Use getModFileWriter() / getModFileReader()"),
    KahluaRule("KAHL-E018", "ERROR", _r(r"\bos\."),
               "'os.*' is sandboxed in PZ",
               "Use getGameTime()"),
    KahluaRule("KAHL-E019", "ERROR", _r(r"\bdebug\."),
               "'debug.*' is sandboxed in PZ",
               "Use print() or DynamicTrading.Log()"),
    KahluaRule("KAHL-E020", "ERROR", _r(r"\bpackage\."),
               "'package.*' is sandboxed in PZ",
               "PZ auto-loads Lua files"),
    KahluaRule("KAHL-E021", "ERROR", _r(r"\brequire\s*\("),
               "'require()' (function form) is sandboxed in PZ",
               'Use: require "ModName/Path"'),
    KahluaRule("KAHL-E022", "ERROR", _r(r"\b(dofile|loadfile)\s*\("),
               "'dofile()'/'loadfile()' are sandboxed in PZ",
               "PZ auto-loads lua files by directory convention"),
    KahluaRule("KAHL-E023", "ERROR", _r(r"!="),
               "'!=' is not valid Lua — use '~='",
               "Replace != with ~="),
    KahluaRule("KAHL-E024", "ERROR", _r(r"\bcontinue\b"),
               "'continue' is not a Lua keyword",
               "Use repeat/until false with break, or restructure loop body"),
    # ── WARNING rules ──────────────────────────────────────────────────────
    KahluaRule("KAHL-W001", "WARNING", _r(r"\bload\s*\("),
               "'load(string)' signature changed in Lua 5.2",
               "Use loadstring()"),
    KahluaRule("KAHL-W002", "WARNING", _r(r"\btable\.getn\s*\("),
               "'table.getn()' deprecated since Lua 5.1",
               "Use the # operator"),
    KahluaRule("KAHL-W003", "WARNING", _r(r"\bstring\.len\s*\("),
               "'string.len()' works but #s is idiomatic",
               "Use #s"),
    KahluaRule("KAHL-W004", "WARNING", _r(r"\b(set|get)fenv\s*\("),
               "'setfenv()'/'getfenv()' — verify Kahlua support"),
    KahluaRule("KAHL-W005", "WARNING", _r(r"\bpcall\s*\(\s*\)"),
               "'pcall()' called with no function — likely a bug"),
]
