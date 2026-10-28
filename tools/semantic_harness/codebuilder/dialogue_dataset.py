"""Aggregate reviewed dialogue patterns and response pools deterministically."""

from __future__ import annotations

from typing import Any

from .lexicon_compiler import CompileError
from .dialogue_contract import (
    DIALOGUE_MAX_PATTERNS,
    DIALOGUE_MAX_POOLS,
    _normalize_dialogue_utterance,
    _validate_dialogue_source,
 )
from .dialogue_patterns import _compile_dialogue_pattern
from .dialogue_responses import _compile_dialogue_response_pool

def compile_dialogue_dataset(document: dict[str, Any]) -> dict[str, Any]:
    """Compile reviewed Hoomans interactions into bounded Lua data.

    Dataset references supply coverage guidance. Packaged utterances and
    response lines remain Hoomans-authored, and corpus turns are not copied.
    """
    if not isinstance(document, dict) or document.get("schemaVersion") != 1:
        raise CompileError("dialogue dataset requires schemaVersion 1")
    source = _validate_dialogue_source(document.get("source"))
    patterns = document.get("patterns")
    response_pools = document.get("responsePools")
    if not isinstance(patterns, list) or len(patterns) > DIALOGUE_MAX_PATTERNS:
        raise CompileError(
            f"dialogue dataset requires at most {DIALOGUE_MAX_PATTERNS} exact patterns")
    if not isinstance(response_pools, list) or len(response_pools) > DIALOGUE_MAX_POOLS:
        raise CompileError(
            f"dialogue dataset requires at most {DIALOGUE_MAX_POOLS} response pools")

    source_names = {reference["name"] for reference in source["references"]}
    compiled_patterns = []
    seen_pattern_ids: set[str] = set()
    seen_utterances: dict[str, str] = {}
    seen_negatives: dict[str, str] = {}
    for pattern in patterns:
        compiled, negatives = _compile_dialogue_pattern(pattern, source_names)
        if compiled["id"] in seen_pattern_ids:
            raise CompileError(f"duplicate dialogue pattern id {compiled['id']}")
        seen_pattern_ids.add(compiled["id"])
        normalized_utterance, _ = _normalize_dialogue_utterance(
            pattern.get("utterance")
        )
        previous = seen_utterances.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"dialogue utterance {normalized_utterance!r} is mapped by both "
                f"{previous} and {compiled['id']}")
        previous = seen_negatives.get(normalized_utterance)
        if previous is not None:
            raise CompileError(
                f"dialogue positive {normalized_utterance!r} collides with negative pattern {previous}")
        seen_utterances[normalized_utterance] = compiled["id"]
        for negative in negatives:
            previous = seen_utterances.get(negative)
            if previous is not None:
                raise CompileError(
                    f"dialogue negative {negative!r} collides with positive pattern {previous}")
            previous = seen_negatives.get(negative)
            if previous is not None and previous != compiled["id"]:
                raise CompileError(
                    f"dialogue negative {negative!r} is repeated by {previous} and {compiled['id']}")
            seen_negatives[negative] = compiled["id"]
        compiled_patterns.append(compiled)

    compiled_pools = []
    translations: dict[str, dict[str, str]] = {}
    seen_pool_ids: set[str] = set()
    seen_response_ids: set[str] = set()
    for pool in response_pools:
        compiled, pool_translations = _compile_dialogue_response_pool(
            pool, source_names
        )
        if compiled["id"] in seen_pool_ids:
            raise CompileError(f"duplicate dialogue response pool {compiled['id']}")
        seen_pool_ids.add(compiled["id"])
        for variant in compiled["variants"]:
            if variant["id"] in seen_response_ids:
                raise CompileError(f"duplicate dialogue response id {variant['id']}")
            seen_response_ids.add(variant["id"])
        for language, localized in sorted(pool_translations.items()):
            bucket = translations.setdefault(language, {})
            for key, text in localized.items():
                if key in bucket:
                    raise CompileError(f"duplicate dialogue translation key {key}")
                bucket[key] = text
        compiled_pools.append(compiled)

    compiled_patterns.sort(key=lambda item: item["id"])
    compiled_pools.sort(key=lambda item: item["id"])
    return {
        "source": source,
        "patterns": compiled_patterns,
        "responsePools": compiled_pools,
        "translations": {
            language: {key: values[key] for key in sorted(values)}
            for language, values in sorted(translations.items())
        },
    }
