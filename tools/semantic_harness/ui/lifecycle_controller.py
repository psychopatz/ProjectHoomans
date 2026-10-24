"""Own GUI shutdown and entry-point concerns outside the shell façade."""

from __future__ import annotations

import argparse
import sys
from typing import Any

from ..runtime.config import ConfigurationError
from ..runtime.worker import HarnessError


def close_app(app: Any) -> None:
    if app.closed:
        return
    app.closed = True
    app.activity_log.record("ui", "window_close")
    app._save_ui_state()
    for after_id in (
        app._relationship_preview_after,
        app._personality_preview_after,
        app._auto_replay_after,
        app._auto_apply_after,
        app._splitter_restore_after,
        app._activity_after,
    ):
        if after_id is not None:
            try:
                app.root.after_cancel(after_id)
            except app._tk.TclError:
                pass
    # Tk shutdown must not wait on the serialized worker executor.  The
    # worker/process close operation is bounded and is submitted for cleanup;
    # waiting here can make the window appear frozen when the worker is still
    # draining a request or its stdout reader is unwinding.
    app.session.close(wait=False)
    app.root.destroy()


def run_gui(app_class: Any, arguments: argparse.Namespace) -> int:
    try:
        import tkinter as tk
    except ImportError as error:
        print(
            f"semantic harness GUI unavailable: install Tk or use --no-gui ({error})",
            file=sys.stderr,
        )
        return 2
    try:
        root = tk.Tk()
    except tk.TclError as error:
        print(
            f"semantic harness GUI unavailable: {error}; use --no-gui or run with a display",
            file=sys.stderr,
        )
        return 2
    try:
        app_class(root, arguments)
        root.mainloop()
    except (HarnessError, ConfigurationError, OSError, ValueError) as error:
        print(f"semantic harness GUI error: {error}", file=sys.stderr)
        try:
            root.destroy()
        except tk.TclError:
            pass
        return 2
    return 0
