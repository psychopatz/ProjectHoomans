"""Hoomans-specific GUI callback behavior for the Core worker session."""

from __future__ import annotations

from concurrent.futures import Future
import unittest
from unittest.mock import Mock

from tools.providers.pnc.lab.ui.shell import SemanticHarnessApp


class WorkerSessionUITests(unittest.TestCase):
    def test_closed_gui_ignores_late_future_callback(self) -> None:
        app = SemanticHarnessApp.__new__(SemanticHarnessApp)
        app.closed = True
        app.root = Mock()
        future = Mock(spec=Future)
        callback = Mock()

        SemanticHarnessApp._poll_future(app, future, callback)

        future.done.assert_not_called()
        future.result.assert_not_called()
        app.root.after.assert_not_called()
        callback.assert_not_called()


if __name__ == "__main__":
    unittest.main()
