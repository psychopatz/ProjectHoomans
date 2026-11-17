"""Deterministic warm-worker reuse helpers for PNC imperative test suites."""

from __future__ import annotations

import atexit
from contextlib import contextmanager
from typing import Any, Iterator

from tools.providers.pnc.runtime.scenario import DEFAULT_SCENARIO
from tools.providers.pnc.runtime.worker import LuaSemanticWorker

_REGISTERED_WORKERS: list[LuaSemanticWorker] = []
_SHARED_WORKERS: dict[tuple[bool], LuaSemanticWorker] = {}


def _cleanup_registered_workers() -> None:
    _SHARED_WORKERS.clear()
    while _REGISTERED_WORKERS:
        worker = _REGISTERED_WORKERS.pop()
        try:
            worker.close()
        except Exception:
            pass


def close_all_warm_workers() -> None:
    """Close all process-shared and class-registered warm Lua workers."""
    _cleanup_registered_workers()


atexit.register(_cleanup_registered_workers)


class WarmWorkerTestMixin:
    """Provide a shared warm LuaSemanticWorker reset via import_source()."""

    _warm_worker: LuaSemanticWorker | None = None
    _warm_worker_key: tuple[bool] | None = None

    @classmethod
    def tearDownClass(cls) -> None:
        # Process-shared warm workers remain reusable across sequential classes
        # and are torn down at runner exit / explicit close_warm_worker().
        cls._warm_worker = None
        cls._warm_worker_key = None
        super().tearDownClass()  # type: ignore[misc]

    @classmethod
    def close_warm_worker(cls) -> None:
        key = cls._warm_worker_key
        worker = cls._warm_worker
        cls._warm_worker = None
        cls._warm_worker_key = None
        if worker is None and key is not None:
            worker = _SHARED_WORKERS.get(key)
        if key is not None and _SHARED_WORKERS.get(key) is worker:
            _SHARED_WORKERS.pop(key, None)
        if worker is not None:
            if worker in _REGISTERED_WORKERS:
                _REGISTERED_WORKERS.remove(worker)
            try:
                worker.close()
            except Exception:
                pass

    @classmethod
    @contextmanager
    def warm_worker(
        cls,
        scenario: dict[str, Any] | None = None,
    ) -> Iterator[LuaSemanticWorker]:
        target = scenario if scenario is not None else DEFAULT_SCENARIO
        mods = (target.get("runtime") or {}).get("availableMods") or {}
        key = (bool(mods.get("DTHoomans")),)
        if cls._warm_worker is not None and cls._warm_worker_key != key:
            cls._warm_worker = None
            cls._warm_worker_key = None
        worker = _SHARED_WORKERS.get(key)
        if worker is not None:
            status = getattr(worker, "status", None)
            if callable(status) and not status().get("running", True):
                _SHARED_WORKERS.pop(key, None)
                worker = None
        if worker is None:
            worker = LuaSemanticWorker(target)
            worker.__enter__()
            _SHARED_WORKERS[key] = worker
            if worker not in _REGISTERED_WORKERS:
                _REGISTERED_WORKERS.append(worker)
        else:
            worker.import_source(target)
        cls._warm_worker = worker
        cls._warm_worker_key = key
        try:
            yield worker
        except Exception:
            cls.close_warm_worker()
            raise
