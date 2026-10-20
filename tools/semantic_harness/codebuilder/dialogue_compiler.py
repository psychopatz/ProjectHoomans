"""Compatibility facade for the reviewed dialogue compiler pipeline.

The concrete contract, pattern, response, dataset, and rendering stages live
in focused modules. This facade preserves the established CodeBuilder import
surface, including legacy private helper names.
"""

from __future__ import annotations

from .lexicon_compiler import CompileError, _lua_string
from .dialogue_contract import (
    DIALOGUE_ID,
    DIALOGUE_TEMPLATE_ID,
    DIALOGUE_UTTERANCE,
    DIALOGUE_PATTERN_SUBJECTS,
    DIALOGUE_BACKSTORY_KINDS,
    DIALOGUE_BACKSTORY_EXTENSIONS,
    DIALOGUE_BACKSTORY_DISCLOSURES,
    DIALOGUE_CONTEXT_REFERENCE_EXTENSIONS,
    DIALOGUE_PROMISE_SUBJECTS,
    DIALOGUE_PROMISE_EXTENSIONS,
    DIALOGUE_MAPPING_FIELDS,
    DIALOGUE_MAPPING_CONCEPTS,
    DIALOGUE_MAPPING_STATES,
    DIALOGUE_TRANSLATION_ARG_TYPES,
    DIALOGUE_PLAN_UNCERTAINTIES,
    DIALOGUE_RESPONSE_CONDITIONS,
    DIALOGUE_MAX_PATTERNS,
    DIALOGUE_MAX_POOLS,
    DIALOGUE_MAX_VARIANTS_PER_POOL,
    DIALOGUE_MAX_VARIANTS,
    DIALOGUE_MAX_PATTERN_TOKENS,
    DIALOGUE_MATCH_CONCEPTS,
    DIALOGUE_LUA_CHUNK_MAX_CHARS,
    load_dialogue_dataset,
    _normalize_dialogue_utterance,
    _validate_dialogue_source,
    _validate_source_refs,
    _compile_dialogue_match,
)
from .dialogue_patterns import _compile_dialogue_pattern
from .dialogue_responses import (
    _validate_response_condition,
    _validate_translation_args,
    _validate_dialogue_plan,
    _compile_dialogue_response_pool,
)
from .dialogue_dataset import compile_dialogue_dataset
from .dialogue_rendering import (
    _lua_value,
    _render_dialogue_chunk,
    _split_dialogue_records,
    render_dialogue_lua_shards,
    render_dialogue_lua,
    render_dialogue_translation,
)
