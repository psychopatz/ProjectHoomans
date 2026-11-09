"""Compatibility path for Core-owned generated-module naming."""

from __future__ import annotations

import importlib

from ..runtime.process import _load_core_process


_load_core_process()
_CORE_NAMING = importlib.import_module(
    "semantic_harness.codebuilder.catalog_naming"
)

CatalogNameError = _CORE_NAMING.CatalogNameError
ModuleNameRegistry = _CORE_NAMING.ModuleNameRegistry
SOURCE_ROOT_SEGMENTS = _CORE_NAMING.SOURCE_ROOT_SEGMENTS
compact_hash = _CORE_NAMING.compact_hash
compact_segment = _CORE_NAMING.compact_segment
module_file = _CORE_NAMING.module_file
module_path = _CORE_NAMING.module_path
pascal_segment = _CORE_NAMING.pascal_segment
source_owned_module = _CORE_NAMING.source_owned_module

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
