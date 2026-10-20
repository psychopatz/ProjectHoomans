"""Compatibility facade for the canonical CodeBuilder authoring service.

The visual Studio owns workflow and interaction-workbench concerns.  Artifact
preview and generation remain owned by ``codebuilder.authoring`` so the
CodeBuilder package does not depend back on the Studio package.
"""

from __future__ import annotations

from ..codebuilder.authoring import *  # noqa: F401,F403
from ..codebuilder import authoring as _implementation


def __getattr__(name: str):
    """Preserve the historical Studio authoring module surface."""

    return getattr(_implementation, name)
