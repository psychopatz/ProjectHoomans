"""Stable, compact names for generated semantic catalog modules."""

from __future__ import annotations

import hashlib
import re
from collections.abc import Iterable


class CatalogNameError(ValueError):
    """Raised when generated catalog names cannot be made unambiguous."""


def pascal_segment(value: str) -> str:
    """Convert a semantic identifier fragment into a readable Lua segment."""
    words = re.findall(
        r"[A-Z]+(?=[A-Z][a-z]|\d|$)|[A-Z]?[a-z]+|\d+",
        str(value),
    )
    if not words:
        return "Catalog"
    return "".join(word[:1].upper() + word[1:].lower() for word in words)


def compact_hash(value: str, length: int = 8) -> str:
    """Return a deterministic, compact collision suffix."""
    return hashlib.sha1(value.encode("utf-8")).hexdigest()[:length]


def compact_segment(
    value: str,
    canonical_id: str,
    *,
    maximum: int = 32,
) -> str:
    """Create a readable segment, hashing only when the label is too long."""
    slug = pascal_segment(value)
    if len(slug) <= maximum:
        return slug
    suffix = "__" + compact_hash(canonical_id)
    return slug[: max(1, maximum - len(suffix))] + suffix


class ModuleNameRegistry:
    """Detect same-directory name collisions without relying on file order."""

    def __init__(self) -> None:
        self._names: dict[tuple[str, str], str] = {}

    def child(
        self,
        parent: str,
        label: str,
        canonical_id: str,
    ) -> str:
        segment = compact_segment(label, canonical_id)
        key = (parent, segment)
        previous = self._names.get(key)
        if previous is not None and previous != canonical_id:
            segment = f"{segment}__{compact_hash(canonical_id)}"
            key = (parent, segment)
            previous = self._names.get(key)
            if previous is not None and previous != canonical_id:
                raise CatalogNameError(
                    "generated catalog module collision between "
                    f"{previous!r} and {canonical_id!r} at {parent}/{segment}"
                )
        self._names[key] = canonical_id
        return f"{parent}/{segment}"


def module_path(
    parent: str,
    segments: Iterable[str],
    canonical_id: str,
    registry: ModuleNameRegistry,
) -> str:
    """Build a scoped module path with collision checks on the final segment."""
    values = list(segments)
    if not values:
        raise CatalogNameError("generated catalog module requires a path segment")
    current = parent
    for segment in values[:-1]:
        current = f"{current}/{pascal_segment(segment)}"
    return registry.child(current, values[-1], canonical_id)


def module_file(relative_module: str) -> str:
    """Convert a Lua module path into its repository-relative source path."""
    return relative_module.replace("/", "/") + ".lua"
