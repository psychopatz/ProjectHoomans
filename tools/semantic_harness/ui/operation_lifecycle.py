"""Async worker-operation lifecycle adapters for the semantic harness UI."""

from __future__ import annotations

from concurrent.futures import Future
from typing import Any, Callable

from ..runtime.config import ConfigurationError
from ..runtime.worker import HarnessError, LuaSemanticWorker
from ..runtime.worker_session import WorkerResult


def poll_future(
    app: Any,
    future: Future[Any],
    callback: Callable[[Any], None],
) -> None:
    """Poll a worker future through Tk without blocking the UI thread."""

    if app.closed:
        return
    if not future.done():
        app.root.after(25, app._poll_future, future, callback)
        return
    app.busy = False
    try:
        result = future.result()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        app._set_status("Worker failed")
        app._set_controls(False)
        app._set_text(app.trace, str(error))
        app._messagebox.showerror("Semantic harness startup/error", str(error))
        return
    callback(result)


def start_operation(
    app: Any,
    operation: Callable[[LuaSemanticWorker], Any],
    callback: Callable[[Any], None],
) -> bool:
    """Submit one worker operation and attach its UI completion adapter."""

    if app.closed or not app.session.ready or app.busy:
        return False
    app.busy = True
    app._set_status("Working…")
    app._set_controls(False)
    app._future = app.session.submit(operation)
    app._poll_future(app._future, operation_finished(app, callback))
    return True


def operation_finished(
    app: Any,
    callback: Callable[[Any], None],
) -> Callable[[Any], None]:
    """Adapt a worker result into the UI callback contract."""

    def finish(result: WorkerResult[Any]) -> None:
        app._set_controls(True)
        app._set_status(f"Ready · Lua PID {result.status.get('pid')}")
        callback(result.value)

    return finish


def show_operation_error(app: Any, error: Exception) -> None:
    """Render an operation failure using the shell's existing UI controls."""

    app.busy = False
    app._set_controls(app.session.ready)
    app._set_status("Worker error")
    app._set_text(app.trace, str(error))
    app._messagebox.showerror("Harness error", str(error))
