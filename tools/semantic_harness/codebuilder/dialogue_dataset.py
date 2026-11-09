"""Hoomans policy adapter for the Core typed dataset compiler."""

from __future__ import annotations

import importlib
from typing import Any

from ..runtime.process import _load_core_process
from .dialogue_contract import (
    DIALOGUE_MAX_PATTERNS,
    DIALOGUE_MAX_POOLS,
    _normalize_dialogue_utterance,
)
from .dialogue_patterns import _compile_dialogue_pattern
from .dialogue_responses import _compile_dialogue_response_pool


_load_core_process()
_CORE_COMPILER = importlib.import_module(
    "semantic_harness.codebuilder.dataset_compiler"
)


def compile_dialogue_dataset(document: dict[str, Any]) -> dict[str, Any]:
    """Compile Hoomans patterns and response pools through Core mechanics."""
    return _CORE_COMPILER.compile_typed_dataset(
        document,
        pattern_compiler=_compile_dialogue_pattern,
        response_compiler=_compile_dialogue_response_pool,
        utterance_normalizer=_normalize_dialogue_utterance,
        max_patterns=DIALOGUE_MAX_PATTERNS,
        max_response_pools=DIALOGUE_MAX_POOLS,
        label="dialogue dataset",
        error_label="dialogue",
        source_label="dialogue source",
        reference_label="dialogue reference",
    )


__all__ = ["compile_dialogue_dataset"]
