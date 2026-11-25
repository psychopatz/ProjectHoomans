"""Parser & static validator for compact .convo dialogue and lexicon scripts."""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

from .schema import resolve_predicate

HEADER_RE = re.compile(r"^(pool|beat|flow|extend)(?:\s+pool)?\s+([a-zA-Z0-9_.-]+)\s*$")
BLUEPRINT_HEADER_RE = re.compile(r"^(?:extend\s+)?blueprint\s+([a-zA-Z0-9_.-]+)\s*$")
USE_RE = re.compile(r"^use\s+([a-zA-Z0-9_.-]+)\s*$")
LEX_HEADER_RE = re.compile(r"^(?:extend\s+)?(?:lexicon|lex)\s+([a-zA-Z0-9_.-]+)\s*$")
LEX_ENTRY_RE = re.compile(
    r"^(?:\[([^\]]*)\])?(?:\s*\((?:priority|pri)\s+(\d+)\))?\s*:\s*(.+?)\s*$"
)
SAY_RE = re.compile(
    r'^say(?:\s+\[([^\]]*)\])?(?:\s+\((?:priority|pri)\s+(\d+)\))?(?:\s+as\s+([a-zA-Z0-9_.-]+))?\s*:\s*(?:"(.*)")?\s*$'
)
OFFER_RE = re.compile(r"^offer\s+([a-zA-Z0-9_.-]+)\s*:\s*$")
KV_RE = re.compile(r"^([a-zA-Z0-9_]+)\s*:\s*(.+?)\s*$")
TOKEN_RE = re.compile(r"\{([^}]+)\}")

RUNTIME_TOKEN_PREFIXES = (
    "speaker.",
    "addressee.",
    "location.",
    "subj.",
    "gram.",
    "target.",
    "claimed.",
    "player.",
    "scene.",
    "slot.",
    "threat.",
    "mention.",
    "place.",
    "state.",
    "world.",
    "know.",
    "mem.",
    "floor.",
    "group.",
    "rel.",
)
RUNTIME_EXACT_TOKENS = {"end", "content", "role", "destination", "direction", "eta"}


@dataclass
class LexEntryNode:
    words: list[str]
    when: dict[str, Any] = field(default_factory=dict)
    priority: int = 6
    line_no: int = 0


@dataclass
class LexNode:
    lex_id: str
    entries: list[LexEntryNode] = field(default_factory=list)
    line_no: int = 0


@dataclass
class VariantNode:
    variant_id: str
    fallback: str
    when: dict[str, Any] = field(default_factory=dict)
    priority: int = 6
    line_no: int = 0


@dataclass
class OfferNode:
    offer_id: str
    label: str = ""
    say: str = ""
    intent: str = "INFORM"
    subject: str = ""
    action: str | None = None
    claim: str | None = None
    style: str | None = None
    utility: str | None = None
    when: dict[str, Any] = field(default_factory=dict)
    line_no: int = 0


@dataclass
class BlueprintNode:
    blueprint_id: str
    offers: list[OfferNode] = field(default_factory=list)
    line_no: int = 0


@dataclass
class PoolNode:
    kind: str  # "pool" | "beat" | "flow"
    pool_id: str
    variants: list[VariantNode] = field(default_factory=list)
    offers: list[OfferNode] = field(default_factory=list)
    uses: list[str] = field(default_factory=list)
    line_no: int = 0


@dataclass
class ConvoScript:
    source_path: str
    namespace: str
    language: str = "EN"
    lexicons: list[LexNode] = field(default_factory=list)
    blueprints: list[BlueprintNode] = field(default_factory=list)
    pools: list[PoolNode] = field(default_factory=list)


def _strip_quotes(raw: str) -> str:
    s = raw.strip()
    if len(s) >= 2 and s[0] == '"' and s[-1] == '"':
        return s[1:-1].replace('\\"', '"')
    return s


def _parse_word_list(raw: str, source: str, line_no: int) -> list[str]:
    words: list[str] = []
    parts: list[str] = []
    buf: list[str] = []
    in_quotes = False
    escaped = False
    for ch in raw:
        if escaped:
            buf.append(ch)
            escaped = False
        elif ch == "\\" and in_quotes:
            buf.append(ch)
            escaped = True
        elif ch == '"':
            in_quotes = not in_quotes
            buf.append(ch)
        elif ch == "|" and not in_quotes:
            parts.append("".join(buf))
            buf = []
        else:
            buf.append(ch)
    parts.append("".join(buf))
    for part in parts:
        p = part.strip()
        if not (len(p) >= 2 and p[0] == '"' and p[-1] == '"'):
            raise ValueError(f"{source}:{line_no}: expected quoted string in lex list, got '{p}'")
        words.append(_strip_quotes(p))
    if not words:
        raise ValueError(f"{source}:{line_no}: empty lex word list")
    return words


def _parse_predicates(raw_preds: str | None, source: str, line_no: int) -> dict[str, Any]:
    if not raw_preds or raw_preds.strip() in ("", "default"):
        return {}
    out: dict[str, Any] = {}
    for token in raw_preds.split(","):
        token = token.strip()
        if not token or token == "default":
            continue
        lua_key, val = resolve_predicate(token, source, line_no)
        out[lua_key] = val
    return out


def extract_token_refs(text: str) -> list[str]:
    refs: list[str] = []
    for raw in TOKEN_RE.findall(text or ""):
        expr = raw[1:] if raw.startswith("?") else raw
        key = expr.split("|", 1)[0].strip()
        if key:
            refs.append(key)
    return refs


def parse_convo_text(text: str, source_path: str = "<memory>") -> ConvoScript:
    namespace = "hoomans"
    language = "EN"
    lexicons: list[LexNode] = []
    blueprints: list[BlueprintNode] = []
    pools: list[PoolNode] = []
    current_lex: LexNode | None = None
    current_blueprint: BlueprintNode | None = None
    current_pool: PoolNode | None = None
    current_offer: OfferNode | None = None
    in_story = False
    pending_say: tuple[dict[str, Any], int, str | None, int] | None = None
    pending_say_count = 0

    lines = text.splitlines()
    for idx, raw_line in enumerate(lines, start=1):
        stripped = raw_line.strip()
        if not stripped or stripped.startswith("#"):
            continue

        if pending_say is not None:
            if stripped.startswith('"') and stripped.endswith('"'):
                when, pri, explicit_id, say_line = pending_say
                pending_say_count += 1
                if current_pool is not None:
                    if explicit_id:
                        vid = explicit_id if pending_say_count == 1 else f"{explicit_id}_{pending_say_count}"
                    else:
                        vid = f"v{len(current_pool.variants) + 1}"
                    current_pool.variants.append(
                        VariantNode(
                            variant_id=vid,
                            fallback=_strip_quotes(stripped),
                            when=when,
                            priority=pri,
                            line_no=say_line,
                        )
                    )
                continue
            if pending_say_count == 0:
                raise ValueError(f"{source_path}:{idx}: expected quoted dialogue line after 'say:'")
            pending_say = None
            pending_say_count = 0

        if stripped.startswith("story ") or stripped.startswith("extend story "):
            current_lex = None
            current_blueprint = None
            current_pool = None
            current_offer = None
            in_story = True
            continue

        if in_story:
            # Story blocks are validated & compiled directly by Lua ConvoDSL_StoryCompiler.
            is_top_level = not raw_line.startswith((" ", "\t"))
            if is_top_level and (
                LEX_HEADER_RE.match(stripped)
                or BLUEPRINT_HEADER_RE.match(stripped)
                or HEADER_RE.match(stripped)
            ):
                in_story = False
            else:
                continue

        if stripped.startswith("namespace "):
            namespace = stripped.split(None, 1)[1].strip()
            if not re.match(r"^[a-zA-Z0-9_.-]+$", namespace):
                raise ValueError(f"{source_path}:{idx}: invalid namespace '{namespace}'")
            continue

        if stripped.startswith("language ") or stripped.startswith("lang "):
            language = stripped.split(None, 1)[1].strip().upper()
            if not re.match(r"^[A-Z]{2,8}$", language):
                raise ValueError(f"{source_path}:{idx}: invalid language '{language}'")
            continue

        if stripped.startswith("theme ") or stripped.startswith("pack "):
            directive, val = stripped.split(None, 1)
            val = val.strip()
            if not re.match(r"^[a-zA-Z0-9_.-]+$", val):
                raise ValueError(f"{source_path}:{idx}: invalid {directive} '{val}'")
            continue

        m_lex = LEX_HEADER_RE.match(stripped)
        if m_lex:
            current_pool = None
            current_blueprint = None
            current_offer = None
            current_lex = LexNode(lex_id=m_lex.group(1), line_no=idx)
            lexicons.append(current_lex)
            continue

        m_bp = BLUEPRINT_HEADER_RE.match(stripped)
        if m_bp:
            current_lex = None
            current_pool = None
            current_offer = None
            current_blueprint = BlueprintNode(blueprint_id=m_bp.group(1), line_no=idx)
            blueprints.append(current_blueprint)
            continue

        m_header = HEADER_RE.match(stripped)
        if m_header:
            current_lex = None
            current_blueprint = None
            current_offer = None
            kind, pool_id = m_header.group(1), m_header.group(2)
            current_pool = PoolNode(kind=kind, pool_id=pool_id, line_no=idx)
            pools.append(current_pool)
            continue

        if current_lex is not None:
            m_entry = LEX_ENTRY_RE.match(stripped)
            if not m_entry:
                raise ValueError(f"{source_path}:{idx}: invalid lex entry '{stripped}'")
            raw_preds, raw_pri, raw_words = m_entry.groups()
            when = _parse_predicates(raw_preds, source_path, idx)
            pri = int(raw_pri) if raw_pri is not None else 6
            words = _parse_word_list(raw_words, source_path, idx)
            current_lex.entries.append(
                LexEntryNode(words=words, when=when, priority=pri, line_no=idx)
            )
            continue

        if current_pool is None and current_blueprint is None:
            raise ValueError(f"{source_path}:{idx}: expected lex/blueprint/pool/beat/flow header before '{stripped}'")

        m_use = USE_RE.match(stripped)
        if m_use and current_pool is not None:
            current_offer = None
            current_pool.uses.append(m_use.group(1))
            continue

        m_offer = OFFER_RE.match(stripped)
        if m_offer:
            current_offer = OfferNode(offer_id=m_offer.group(1), line_no=idx)
            if current_blueprint is not None:
                current_blueprint.offers.append(current_offer)
            else:
                assert current_pool is not None
                current_pool.offers.append(current_offer)
            continue

        if current_offer is not None:
            m_kv = KV_RE.match(stripped)
            if m_kv and m_kv.group(1) in ("label", "say", "intent", "subject", "action", "claim", "style", "utility", "when"):
                key, val = m_kv.group(1), m_kv.group(2)
                if key == "label":
                    current_offer.label = _strip_quotes(val)
                elif key == "say":
                    current_offer.say = _strip_quotes(val)
                elif key == "intent":
                    current_offer.intent = _strip_quotes(val)
                elif key == "subject":
                    current_offer.subject = _strip_quotes(val)
                elif key == "action":
                    current_offer.action = _strip_quotes(val)
                elif key == "claim":
                    current_offer.claim = _strip_quotes(val)
                elif key == "style":
                    current_offer.style = _strip_quotes(val)
                elif key == "utility":
                    current_offer.utility = _strip_quotes(val)
                elif key == "when":
                    inner = val.strip()
                    if inner.startswith("[") and inner.endswith("]"):
                        inner = inner[1:-1]
                    current_offer.when = _parse_predicates(inner, source_path, idx)
                continue

        m_say = SAY_RE.match(stripped)
        if m_say:
            current_offer = None
            raw_preds, raw_pri, explicit_id, inline_text = m_say.groups()
            when = _parse_predicates(raw_preds, source_path, idx)
            pri = int(raw_pri) if raw_pri is not None else 6
            if inline_text is not None:
                vid = explicit_id or f"v{len(current_pool.variants) + 1}"
                current_pool.variants.append(
                    VariantNode(
                        variant_id=vid,
                        fallback=inline_text.replace('\\"', '"'),
                        when=when,
                        priority=pri,
                        line_no=idx,
                    )
                )
            else:
                pending_say = (when, pri, explicit_id, idx)
                pending_say_count = 0
            continue

        raise ValueError(f"{source_path}:{idx}: unrecognized statement '{stripped}'")

    if pending_say is not None and pending_say_count == 0:
        raise ValueError(f"{source_path}:{pending_say[3]}: dangling 'say:' without text line")

    seen_lex: set[str] = set()
    for lx in lexicons:
        if lx.lex_id in seen_lex:
            raise ValueError(f"{source_path}:{lx.line_no}: duplicate lex '{lx.lex_id}'")
        seen_lex.add(lx.lex_id)
        if not lx.entries:
            raise ValueError(f"{source_path}:{lx.line_no}: lex '{lx.lex_id}' has no entries")

    seen_pools: set[str] = set()
    for pool in pools:
        if pool.pool_id in seen_pools:
            raise ValueError(f"{source_path}:{pool.line_no}: duplicate pool '{pool.pool_id}'")
        seen_pools.add(pool.pool_id)
        if not pool.variants:
            raise ValueError(f"{source_path}:{pool.line_no}: pool '{pool.pool_id}' has no 'say' variants")
        seen_vars: set[str] = set()
        for v in pool.variants:
            if v.variant_id in seen_vars:
                raise ValueError(
                    f"{source_path}:{v.line_no}: duplicate variant '{v.variant_id}' in pool '{pool.pool_id}'"
                )
            seen_vars.add(v.variant_id)

    return ConvoScript(
        source_path=source_path,
        namespace=namespace,
        language=language,
        lexicons=lexicons,
        blueprints=blueprints,
        pools=pools,
    )


def validate_language_pack(scripts: list[ConvoScript]) -> None:
    """Validate cross-file lex/blueprint references, duplicate IDs, and cycles."""
    lex_graph: dict[str, set[str]] = {}
    lex_owners: dict[str, str] = {}
    bp_owners: dict[str, str] = {}
    pool_owners: dict[str, str] = {}

    for script in scripts:
        for lx in script.lexicons:
            if lx.lex_id in lex_owners:
                raise ValueError(
                    f"duplicate lex '{lx.lex_id}' across {lex_owners[lx.lex_id]} and {script.source_path}"
                )
            lex_owners[lx.lex_id] = script.source_path
            lex_graph[lx.lex_id] = set()
        for bp in script.blueprints:
            if bp.blueprint_id in bp_owners:
                raise ValueError(
                    f"duplicate blueprint '{bp.blueprint_id}' across {bp_owners[bp.blueprint_id]} and {script.source_path}"
                )
            bp_owners[bp.blueprint_id] = script.source_path
        for pool in script.pools:
            if pool.kind == "extend":
                continue
            if pool.pool_id in pool_owners:
                raise ValueError(
                    f"duplicate pool '{pool.pool_id}' across {pool_owners[pool.pool_id]} and {script.source_path}"
                )
            pool_owners[pool.pool_id] = script.source_path

    def check_refs(text: str, source: str, line_no: int, owner_lex: str | None = None) -> None:
        for ref in extract_token_refs(text):
            if ref in RUNTIME_EXACT_TOKENS or any(ref.startswith(p) for p in RUNTIME_TOKEN_PREFIXES):
                continue
            if ref not in lex_owners:
                raise ValueError(f"{source}:{line_no}: unknown lex/token reference '{{{ref}}}'")
            if owner_lex is not None:
                lex_graph[owner_lex].add(ref)

    for script in scripts:
        for lx in script.lexicons:
            for entry in lx.entries:
                for w in entry.words:
                    check_refs(w, script.source_path, entry.line_no, owner_lex=lx.lex_id)
        for bp in script.blueprints:
            for o in bp.offers:
                check_refs(o.label, script.source_path, o.line_no)
                check_refs(o.say, script.source_path, o.line_no)
        for pool in script.pools:
            for u in pool.uses:
                if u not in bp_owners:
                    raise ValueError(f"{script.source_path}:{pool.line_no}: unknown blueprint '{u}'")
            for v in pool.variants:
                check_refs(v.fallback, script.source_path, v.line_no)
            for o in pool.offers:
                check_refs(o.label, script.source_path, o.line_no)
                check_refs(o.say, script.source_path, o.line_no)

    # Static cycle detection (DFS)
    visiting: set[str] = set()
    visited: set[str] = set()

    def dfs(node: str, stack: list[str]) -> None:
        visiting.add(node)
        stack.append(node)
        for nxt in sorted(lex_graph.get(node, ())):
            if nxt in visiting:
                cycle = " -> ".join(stack[stack.index(nxt) :] + [nxt])
                raise ValueError(f"cyclic lex reference detected: {cycle}")
            if nxt not in visited:
                dfs(nxt, stack)
        stack.pop()
        visiting.remove(node)
        visited.add(node)

    for lx_id in sorted(lex_graph.keys()):
        if lx_id not in visited:
            dfs(lx_id, [])


def parse_convo_file(path: Path) -> ConvoScript:
    return parse_convo_text(path.read_text(encoding="utf-8"), source_path=str(path))
