#!/usr/bin/env python3
"""Compatibility entry point for Semantic Lab's embedded CodeBuilder."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_harness.codebuilder.build import *  # noqa: F401,F403
from tools.semantic_harness.codebuilder import build as _implementation


def __getattr__(name: str):
    """Keep legacy access to private build helpers when required."""
    return getattr(_implementation, name)


if __name__ == "__main__":
    raise SystemExit(_implementation.main())
