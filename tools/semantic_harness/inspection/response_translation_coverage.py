"""Bounded manifest provenance for *loaded Lua* response keys.

This is static source readiness, not an independent translator and not proof
that any untranslated/unobserved variant was selected in a runtime turn.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
from typing import Any

from ..runtime.worker import LuaSemanticWorker

LANGUAGES = ("EN", "TL")
MAX_MANIFEST_ASSETS = 64
MAX_TRANSLATION_ASSET_BYTES = 256 * 1024
MAX_CONVERSATION_MANIFEST_BYTES = 64 * 1024


def translation_coverage(
    worker: LuaSemanticWorker,
    pool_id: str,
    *,
    repository: Path | None = None,
) -> dict[str, Any]:
    root = (repository or worker.config.repository).resolve(strict=True)
    detail = worker.response_pool_detail(pool_id, limit=16)
    if detail.get("hasMore"):
        raise ValueError("translation coverage requires fully bounded pool")
    media = root / "Contents/mods/ProjectHoomans/common/media/translation"
    manifest_path = media / "manifests/Conversation.json"
    if manifest_path.stat().st_size > MAX_CONVERSATION_MANIFEST_BYTES:
        raise ValueError("oversized production Conversation manifest")
    manifest_bytes = manifest_path.read_bytes()
    manifest = json.loads(manifest_bytes.decode("utf-8"))
    if not isinstance(manifest, dict) or not isinstance(manifest.get("languages"), dict):
        raise ValueError("invalid production Conversation manifest")
    index: dict[str, dict[str, list[str]]] = {language: {} for language in LANGUAGES}
    for language in LANGUAGES:
        paths = manifest["languages"].get(language)
        if not isinstance(paths, list) or len(paths) > MAX_MANIFEST_ASSETS:
            raise ValueError("missing or unbounded translation manifest language")
        for name in paths:
            if (not isinstance(name, str)
                    or not name.startswith(language + "/")
                    or not name.endswith(".json")
                    or ".." in name):
                raise ValueError("invalid translation manifest path")
            asset_path = (media / name).resolve(strict=True)
            if not asset_path.is_relative_to(media.resolve()):
                raise ValueError("translation manifest escapes media owner")
            if asset_path.stat().st_size > MAX_TRANSLATION_ASSET_BYTES:
                raise ValueError("oversized manifest-backed translation catalog")
            contents = json.loads(asset_path.read_text(encoding="utf-8"))
            if not isinstance(contents, dict):
                raise ValueError("invalid manifest-backed translation catalog")
            for key, text in contents.items():
                if not isinstance(key, str) or not isinstance(text, str):
                    raise ValueError("translation catalog contains non-text entry")
                index[language].setdefault(key, []).append(name)
    rows = []
    counts = {
        "BOTH_MANIFESTED": 0, "MISSING_EN": 0, "MISSING_TL": 0,
        "NOT_IN_CONVERSATION_MANIFEST": 0, "DUPLICATE_MANIFEST_KEY": 0,
    }
    for variant in detail["variants"]:
        key = variant.get("templateID")
        paths = {language: index[language].get(key, []) if isinstance(key, str)
                 else [] for language in LANGUAGES}
        if any(len(paths[lang]) > 1 for lang in LANGUAGES):
            status = "DUPLICATE_MANIFEST_KEY"
        elif paths["EN"] and paths["TL"]:
            status = "BOTH_MANIFESTED"
        elif paths["EN"]:
            status = "MISSING_TL"
        elif paths["TL"]:
            status = "MISSING_EN"
        else:
            status = "NOT_IN_CONVERSATION_MANIFEST"
        counts[status] += 1
        rows.append({
            "variantID": variant["id"], "templateID": key,
            "sourceKind": variant.get("sourceKind", "UNKNOWN"),
            "status": status, "manifestAssets": paths,
            "actualRuntimeLookupObserved": False,
            "fallbackEvidence": "UNTESTED",
        })
    return {
        "ok": True, "type": "response_translation_manifest_coverage",
        "schemaVersion": 1, "poolID": pool_id,
        "sourceKind": "CANONICAL_MANIFEST_STATIC",
        "manifestSHA256": hashlib.sha256(manifest_bytes).hexdigest(),
        "contentFingerprint": detail["contentFingerprint"],
        "registryRevision": detail["registryRevision"],
        "variantCount": len(rows), "summary": counts, "variants": rows,
        "limitations": [
            "Manifest membership is not a runtime translation lookup",
            "A templateID may intentionally use fallback or nonmanifested keys",
            "Runtime EN/TL text and fallback must be established by Lua replay",
        ],
        "writes": 0,
    }
