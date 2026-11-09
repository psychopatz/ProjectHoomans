"""Compatibility path for the Core-owned serialized worker session."""

from __future__ import annotations

import importlib

from .process import _load_core_process


_load_core_process()
_CORE_SESSION = importlib.import_module("semantic_harness.worker_session")

# Keep the public Hoomans import path stable while ensuring there is exactly one
# implementation of worker lifecycle and queue semantics.
SessionClosedError = _CORE_SESSION.SessionClosedError
WorkerReady = _CORE_SESSION.WorkerReady
WorkerResult = _CORE_SESSION.WorkerResult
WorkerSession = _CORE_SESSION.WorkerSession

__all__ = [
    "SessionClosedError",
    "WorkerReady",
    "WorkerResult",
    "WorkerSession",
]
