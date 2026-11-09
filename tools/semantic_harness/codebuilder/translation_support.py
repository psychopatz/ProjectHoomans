"""Compatibility path for Core-owned translation-locale helpers."""

from __future__ import annotations

import importlib

from ..runtime.process import _load_core_process


_load_core_process()
_CORE_TRANSLATION = importlib.import_module(
    "semantic_harness.codebuilder.translation_support"
)

DEFAULT_LANGUAGE = _CORE_TRANSLATION.DEFAULT_LANGUAGE
merge_language_sets = _CORE_TRANSLATION.merge_language_sets
normalize_language = _CORE_TRANSLATION.normalize_language
normalize_translations = _CORE_TRANSLATION.normalize_translations
pretty_json = _CORE_TRANSLATION.pretty_json

__all__ = [
    "DEFAULT_LANGUAGE",
    "merge_language_sets",
    "normalize_language",
    "normalize_translations",
    "pretty_json",
]
