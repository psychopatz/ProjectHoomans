"""Shared hermetic helpers for Semantic Lab Tk integration tests."""

from __future__ import annotations

from pathlib import Path
import gc
import tempfile
import time
import tkinter as tk
import unittest
from typing import Any, Callable, Iterable

from tools.semantic_harness.cli import _parser
from tools.semantic_harness.ui.shell import SemanticHarnessApp


class SemanticLabGuiTestCase(unittest.TestCase):
    """Create GUI tests with isolated, fixture-first UI state by default."""

    def new_ui_state_path(self, prefix: str = "semantic-lab-test-") -> Path:
        directory = tempfile.TemporaryDirectory(prefix=prefix)
        self.addCleanup(directory.cleanup)
        return Path(directory.name) / "ui-state.json"

    def gui_arguments(
        self,
        *extra_args: str,
        ui_state_path: Path | None = None,
        reset: bool = True,
    ) -> Any:
        """Build arguments that cannot read the developer's default state."""

        state_path = ui_state_path or self.new_ui_state_path()
        values = ["--gui", "--ui-state", str(state_path)]
        if reset:
            values.append("--reset-ui-state")
        values.extend(extra_args)
        return _parser().parse_args(values)

    def make_gui_app(
        self,
        root: tk.Misc,
        *extra_args: str,
        ui_state_path: Path | None = None,
        reset: bool = True,
    ) -> SemanticHarnessApp:
        """Construct and clean up a fixture-first Semantic Lab application."""

        app = SemanticHarnessApp(
            root,
            self.gui_arguments(
                *extra_args,
                ui_state_path=ui_state_path,
                reset=reset,
            ),
        )
        self.addCleanup(self.close_gui_app, app, root)
        return app

    @staticmethod
    def close_gui_app(app: SemanticHarnessApp, root: tk.Misc) -> None:
        if not getattr(app, "__dict__", None):
            try:
                root.destroy()
            except tk.TclError:
                pass
            return
        # SemanticHarnessApp deliberately uses a nonblocking production close
        # so an interactive window never freezes while a serialized worker
        # request drains.  Tests own the process boundary, so finish any
        # queued work before destroying the last Tk references.
        session = getattr(app, "session", None)
        if session is not None:
            session.close(wait=True)
        try:
            app.close()
        except tk.TclError:
            pass
        try:
            root.destroy()
        except tk.TclError:
            pass
        # Release Tk variables/widgets while this fixture is still executing
        # on the main thread.  Otherwise cyclic app state can be collected by
        # a later worker-thread teardown and tkinter reports a wrong-thread
        # async-handler deletion when the next test creates its root.
        app.__dict__.clear()
        gc.collect()

    def wait_for(
        self,
        root: tk.Misc,
        predicate: Callable[[], bool],
        message: str,
        *,
        timeout: float = 20.0,
    ) -> None:
        deadline = time.monotonic() + timeout
        while not predicate() and time.monotonic() < deadline:
            try:
                root.update()
            except tk.TclError:
                break
            time.sleep(0.01)
        self.assertTrue(predicate(), message)

    def wait_for_worker_ready(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: app.worker_ready,
            "timed out waiting for the production Lua worker",
            timeout=timeout,
        )

    def wait_for_explore_loaded(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: app.observatory.catalog_ready
            and not app.observatory.loading,
            "timed out waiting for the bounded Explore catalog page",
            timeout=timeout,
        )

    def wait_for_operation(
        self, root: tk.Misc, app: SemanticHarnessApp, *, timeout: float = 20.0
    ) -> None:
        self.wait_for(
            root,
            lambda: not app.busy,
            "timed out waiting for the foreground worker operation",
            timeout=timeout,
        )


__all__ = ["SemanticLabGuiTestCase"]
