"""Approved-source *preview*, never publication or automatic source promotion.

One reviewed existing authored variant is copied into a disposable, isolated
worker overlay. Production Lua and the actual Core translation loader render
both language candidates; no mock Python selector or second compiler is used.
"""
from __future__ import annotations

import difflib
import hashlib
import json
from pathlib import Path
import re
import tempfile
from typing import Any

from ..runtime.scenario import DEFAULT_SCENARIO, merge
from ..runtime.worker import LuaSemanticWorker
from .conversation_inspector import build_conversation_inspector
from .response_observatory import review_variant_proposal, source_evidence


def _sha256(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _authored_variant_patch(
    source: str, variant_id: str, old: str, new: str,
) -> tuple[str, list[str]]:
    """Edit exact fallback literals inside exactly one Lua variant definition.

    Refuse anything structurally unfamiliar: this is a conservative source
    patcher for existing authored responses, NOT a general Lua parser.
    """
    match = re.search(
        r'(?m)^(?P<indent>[ ]+)id[ ]*=[ ]*'
        + re.escape(json.dumps(variant_id, ensure_ascii=False))
        + r'[ ]*,[ ]*$',
        source,
    )
    if match is None:
        raise ValueError("variant ID missing in canonical authored Lua source")
    indent = match.group("indent")
    if len(re.findall(
        r'(?m)^' + re.escape(indent) + r'id[ ]*=[ ]*'
        + re.escape(json.dumps(variant_id, ensure_ascii=False)) + r'[ ]*,[ ]*$',
        source,
    )) != 1:
        raise ValueError("ambiguous Lua variant ownership")
    next_variant = re.search(
        r'(?m)^' + re.escape(indent) + r'id[ ]*=[ ]*"[^"]+"[ ]*,[ ]*$',
        source[match.end():],
    )
    end = match.end() + next_variant.start() if next_variant else len(source)
    block = source[match.start():end]
    old_literal = "fallback = " + json.dumps(old, ensure_ascii=False)
    new_literal = "fallback = " + json.dumps(new, ensure_ascii=False)
    occurrences = block.count(old_literal)
    if occurrences not in (1, 2) or source.count(old_literal) != occurrences:
        raise ValueError("fallback occurrence count is ambiguous in authored Lua")
    updated = source[:match.start()] + block.replace(old_literal, new_literal) + source[end:]
    if updated == source:
        raise ValueError("proposal did not change Lua fallback")
    changes = list(difflib.unified_diff(
        source.splitlines(), updated.splitlines(),
        fromfile="original/authored.lua", tofile="isolated/candidate.lua",
        lineterm="",
    ))
    if len(changes) > 64:
        raise ValueError("source patch exceeds bounded diff")
    return updated, changes


def _verified_translation_asset(
    repository: Path, language: str, key: str,
) -> tuple[Path, str, dict[str, str]]:
    """Lookup the *actual manifest listed* translator source for the real key."""
    media = repository / "Contents/mods/ProjectHoomans/common/media"
    manifest = json.loads(
        (media / "translation/manifests/Conversation.json").read_text(
            encoding="utf-8"
        )
    )
    files = manifest["languages"][language]
    found: list[tuple[Path, str, dict[str, str]]] = []
    for relative in files:
        if not relative.startswith(f"{language}/Conversation/Semantic/"):
            continue
        if not relative.endswith(".json") or ".." in relative:
            raise ValueError("invalid manifest translation asset path")
        path = media / "translation" / relative
        data = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(data, dict):
            raise ValueError("manifest translation asset is not an object")
        if key in data:
            found.append((path, "media/translation/" + relative, data))
    if len(found) != 1:
        raise ValueError("translation source absent or ambiguous in canonical manifest")
    return found[0]


def _real_case(
    scenario: dict[str, Any],
    utterance: str,
    *,
    candidate_overlay_root: Path | None = None,
    candidate_overlay_module: str | None = None,
) -> dict[str, Any]:
    with LuaSemanticWorker(
        scenario,
        candidate_overlay_root=candidate_overlay_root,
        candidate_overlay_module=candidate_overlay_module,
    ) as worker:
        turn = worker.input(utterance)
        inspector = build_conversation_inspector(turn)
    responses = [
        m["payload"] for m in turn.get("messages", [])
        if m.get("speaker") == "npc" and isinstance(m.get("payload"), dict)
    ]
    side = inspector.get("effects", {}).get("sideEffects", {})
    return {
        "accepted": turn.get("accepted"),
        "messages": [{
            "id": m.get("key"), "translationKey": m.get("translationKey"),
            "text": m.get("text"),
        } for m in responses[-4:]],
        "actionCount": side.get("actionCount"),
        "transportCount": side.get("transportCount"),
    }


def preview_authored_variant(
    proposal: dict[str, Any], *,
    repository: Path,
) -> dict[str, Any]:
    """Test a *single* approved-source candidate in an ephemeral real-Lua tree.

    This routine NEVER promotes, accepts or rewrites source files. Invalid
    proposals or Lua failures propagate, with TemporaryDirectory cleanup.
    """
    repository = repository.resolve(strict=True)
    if not isinstance(proposal, dict):
        raise ValueError("proposal must be an object")
    entries = proposal.get("variants")
    if not isinstance(entries, list) or len(entries) != 1:
        raise ValueError("isolated preview requires exactly one existing variant")
    case = proposal.get("case")
    if not isinstance(case, dict) or set(case) - {"utterance", "scenario"}:
        raise ValueError("isolated preview requires one bounded case")
    utterance = case.get("utterance")
    if not isinstance(utterance, str) or not 1 <= len(utterance) <= 200:
        raise ValueError("isolated preview utterance must be 1 to 200 characters")
    overrides = case.get("scenario") or {}
    if not isinstance(overrides, dict):
        raise ValueError("isolated preview scenario must be a JSON object")

    variant_id = entries[0].get("id")
    with LuaSemanticWorker(merge(DEFAULT_SCENARIO, overrides),
                           repository=repository) as worker:
        review = review_variant_proposal(worker, proposal)
        if not review["ok"]:
            raise ValueError(f"proposal preflight rejected: {review['reason']}")
        details = worker.response_pool_detail(proposal["poolID"], limit=16)
        candidates = [v for v in details["variants"] if v["id"] == variant_id]
        if len(candidates) != 1:
            raise ValueError("selected variant was not registered")
        variant = candidates[0]
        origin = variant["sourcePath"]
        if variant["sourceKind"] != "AUTHORED_LUA":
            raise ValueError("no verified canonical authored Lua owner")
        source = (repository / origin).resolve(strict=True)
        root = (repository / "Contents/mods/ProjectHoomans").resolve()
        if not source.is_relative_to(root) or not source.name.endswith(".lua"):
            raise ValueError("source ownership is outside the checked-out mod")
        module = origin.split("/media/lua/shared/", 1)[-1].removesuffix(".lua")
        if not re.fullmatch(
            r"PNC/Semantics/SemanticDialogueResponseCatalog/"
            r"PNC_SemanticDialogueResponseCatalog_[A-Za-z0-9_]+", module,
        ):
            raise ValueError("unsupported authored module overlay")

        original_bytes = source.read_bytes()
        original = original_bytes.decode("utf-8")
        updated, source_diff = _authored_variant_patch(
            original, variant_id, variant["fallback"], entries[0]["EN"],
        )
        evidence = source_evidence(worker)

    original_hash = _sha256(original_bytes)
    original_translation_hashes: dict[str, tuple[Path, str]] = {}
    cases: list[tuple[str, dict[str, Any], dict[str, Any], str]] = []
    for language in ("EN", "TL"):
        scenario = merge(DEFAULT_SCENARIO, overrides)
        scenario.setdefault("runtime", {})["language"] = language
        observed = _real_case(scenario, utterance)
        selection = [
            m for m in observed["messages"] if m["id"] == variant_id
        ]
        if len(selection) != 1 or not isinstance(
            selection[0]["translationKey"], str
        ):
            raise ValueError("fixture did not realize precisely the proposed variant")
        key = selection[0]["translationKey"]
        src, relative, content = _verified_translation_asset(
            repository, language, key
        )
        if not isinstance(content.get(key), str):
            raise ValueError("missing canonical translation text")
        original_translation_hashes[language] = (
            src, _sha256(src.read_bytes())
        )
        cases.append((language, scenario, observed, relative))

    with tempfile.TemporaryDirectory(prefix="pnc-observatory-proposal-") as dirname:
        overlay = Path(dirname)
        lua_destination = overlay / (module + ".lua")
        lua_destination.parent.mkdir(parents=True, exist_ok=True)
        lua_destination.write_text(updated, encoding="utf-8")
        translation_diff: list[dict[str, str]] = []
        for language, _scenario, observed, relative in cases:
            key = next(m["translationKey"] for m in observed["messages"]
                       if m["id"] == variant_id)
            src, confirmed, data = _verified_translation_asset(
                repository, language, key)
            if relative != confirmed:
                raise ValueError("translation source changed during review")
            before = data[key]
            data[key] = entries[0][language]
            dest = overlay / relative
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")
            translation_diff.append({
                "language": language, "key": key, "manifestPath": relative,
                "before": before, "candidate": entries[0][language],
            })

        result_cases = []
        selected_fingerprint = None
        for language, scenario, baseline, _ in cases:
            # Run the exact production worker with only the two staged
            # authoritative source files substituted; all other behavior
            # remains loaded from the actual checkout and installed Core.
            with LuaSemanticWorker(
                scenario, repository=repository,
                candidate_overlay_root=overlay,
                candidate_overlay_module=module,
            ) as worker:
                candidate_turn = worker.input(utterance)
                final_inspector = build_conversation_inspector(candidate_turn)
                candidate_detail = worker.response_pool_detail(
                    proposal["poolID"], limit=16)
            candidate_messages = [
                m["payload"] for m in candidate_turn.get("messages", [])
                if m.get("speaker") == "npc"
                and isinstance(m.get("payload"), dict)
            ]
            candidate = {
                "accepted": candidate_turn.get("accepted"),
                "messages": [{
                    "id": m.get("key"), "translationKey": m.get("translationKey"),
                    "text": m.get("text"),
                } for m in candidate_messages[-4:]],
                "actionCount": final_inspector.get("effects", {})
                    .get("sideEffects", {}).get("actionCount"),
                "transportCount": final_inspector.get("effects", {})
                    .get("sideEffects", {}).get("transportCount"),
            }
            candidate_variant = next(
                v for v in candidate_detail["variants"]
                if v["id"] == variant_id
            )
            base_variant = dict(variant)
            new_variant = dict(candidate_variant)
            for ignored in ("fallback", "sourceKind", "sourcePath"):
                base_variant.pop(ignored, None)
                new_variant.pop(ignored, None)
            if base_variant != new_variant:
                raise ValueError("candidate unexpectedly changed variant metadata")
            if candidate_variant["fallback"] != entries[0]["EN"]:
                raise ValueError("candidate registered Lua fallback did not update")
            expected_new = entries[0][language]
            before_text = [m["text"] for m in baseline["messages"]
                           if m["id"] == variant_id]
            after_text = [m["text"] for m in candidate["messages"]
                          if m["id"] == variant_id]
            if (len(after_text) != 1 or after_text[0] != expected_new
                    or before_text == after_text):
                raise ValueError("real-Lua candidate did not change target translation")
            if (baseline["actionCount"] != candidate["actionCount"]
                or baseline["transportCount"] != candidate["transportCount"]
                or baseline["accepted"] != candidate["accepted"]
                or [m["id"] for m in baseline["messages"]]
                   != [m["id"] for m in candidate["messages"]]):
                raise ValueError("candidate altered gameplay effects or selected keys")
            selected_fingerprint = candidate_detail["contentFingerprint"]
            result_cases.append({
                "language": language, "status": "PASS",
                "baseline": baseline, "candidate": candidate,
            })
    if _sha256(source.read_bytes()) != original_hash or any(
        _sha256(path.read_bytes()) != sha for path, sha
        in original_translation_hashes.values()
    ):
        raise ValueError("production source files changed during candidate review")
    return {
        "ok": True, "schemaVersion": 1, "type": "response_candidate_isolated_preview",
        "sourceKind": "FIXTURE", "workerKind": "production_lua",
        "poolID": proposal["poolID"], "variantID": variant_id,
        "baselineFingerprint": details["contentFingerprint"],
        "candidateFingerprint": selected_fingerprint,
        "sourcePath": origin, "canonicalOwnerVerified": True,
        "sourceSHA256": original_hash, "sourceDiff": source_diff,
        "translationDiff": translation_diff,
        "languageCases": result_cases, "checks": {
            "sameSelectedKey": True, "unchangedGameplayEffects": True,
            "authoritativeWorkerRenderedENandTL": True,
            "productionSourceUnchanged": True,
        },
        "sourceEvidence": evidence,
        "approved": False, "writesToProduction": 0,
        "candidateOverlayCleaned": True,
    }
