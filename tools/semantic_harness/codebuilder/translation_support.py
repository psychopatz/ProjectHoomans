"""Compatibility path for Core-owned translation-locale helpers."""

from __future__ import annotations

from semantic_harness.codebuilder.translation_support import (
    DEFAULT_LANGUAGE,
    merge_language_sets,
    normalize_language,
    normalize_translations,
    pretty_json,
)

__all__ = [
    "DEFAULT_LANGUAGE",
    "merge_language_sets",
    "normalize_language",
    "normalize_translations",
    "pretty_json",
]
