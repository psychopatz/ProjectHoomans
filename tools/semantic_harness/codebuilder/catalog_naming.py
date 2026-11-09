"""Compatibility path for Core-owned generated-module naming."""

from __future__ import annotations

from semantic_harness.codebuilder.catalog_naming import (
    SOURCE_ROOT_SEGMENTS,
    CatalogNameError,
    ModuleNameRegistry,
    compact_hash,
    compact_segment,
    module_file,
    module_path,
    pascal_segment,
    source_owned_module,
)

__all__ = [
    "CatalogNameError",
    "ModuleNameRegistry",
    "SOURCE_ROOT_SEGMENTS",
    "compact_hash",
    "compact_segment",
    "module_file",
    "module_path",
    "pascal_segment",
    "source_owned_module",
]
