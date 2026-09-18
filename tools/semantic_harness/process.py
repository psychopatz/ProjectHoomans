"""Bounded, correlated JSON-lines client for the persistent Lua worker."""

from __future__ import annotations

import os
import queue
import signal
import subprocess
import threading
import weakref
from collections import deque
from typing import Any

from .config import HarnessConfig
from .protocol import ProtocolError, decode_message, encode_request


_ACTIVE_PROCESSES: weakref.WeakSet["LuaProcess"] = weakref.WeakSet()
_SHUTDOWN_HANDLER_INSTALLED = False


def install_shutdown_handler() -> None:
    """Ensure external termination closes every active Lua child first."""

    global _SHUTDOWN_HANDLER_INSTALLED
    if _SHUTDOWN_HANDLER_INSTALLED or threading.current_thread() is not threading.main_thread():
        return

    def handle_signal(signum: int, _frame: Any) -> None:
        for runtime in list(_ACTIVE_PROCESSES):
            runtime.close()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, handle_signal)
    signal.signal(signal.SIGINT, handle_signal)
    _SHUTDOWN_HANDLER_INSTALLED = True


class HarnessError(RuntimeError):
    """A bounded worker lifecycle or protocol failure."""


class LuaProcess:
    """Own one Lua child process and serialize all requests through it."""

    def __init__(self, config: HarnessConfig) -> None:
        self.config = config
        self.process: subprocess.Popen[bytes] | None = None
        self._state = "STOPPED"
        self._state_lock = threading.RLock()
        self._request_lock = threading.Lock()
        self._pending_lock = threading.Lock()
        self._pending: dict[str, queue.Queue[dict[str, Any]]] = {}
        self._hello: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=1)
        self._stderr: deque[str] = deque(maxlen=32)
        self._failure: str | None = None
        self._request_sequence = 0
        self._reader_thread: threading.Thread | None = None
        self._stderr_thread: threading.Thread | None = None

    @property
    def state(self) -> str:
        with self._state_lock:
            return self._state

    def status(self) -> dict[str, Any]:
        process = self.process
        return {
            "state": self.state,
            "pid": process.pid if process is not None else None,
            "returncode": process.poll() if process is not None else None,
            "failure": self._failure,
            "stderr": list(self._stderr),
        }

    def start(self) -> dict[str, Any]:
        with self._state_lock:
            if self._state not in {"STOPPED", "FAILED"}:
                raise HarnessError(f"worker is already {self._state.lower()}")
            self._state = "STARTING"
            self._failure = None
        environment = os.environ.copy()
        environment.update(
            {
                "PNC_HARNESS_REPOSITORY": str(self.config.repository),
                "PNC_HARNESS_CORE_REPOSITORY": str(self.config.core_repository),
                "PZ_TEST_HOOMANS_RUNTIME": self.config.hoomans_runtime,
                "PZ_TEST_CORE_RUNTIME": self.config.core_runtime,
            }
        )
        try:
            self.process = subprocess.Popen(
                [
                    str(self.config.lua_bin),
                    str(self.config.worker_script),
                    str(self.config.repository),
                    str(self.config.core_repository),
                ],
                cwd=self.config.repository,
                env=environment,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                bufsize=0,
            )
            _ACTIVE_PROCESSES.add(self)
        except OSError as error:
            self._set_failure(f"could not start Lua worker: {error}")
            raise HarnessError(self._failure or str(error)) from error
        self._reader_thread = threading.Thread(
            target=self._read_stdout,
            name="semantic-harness-lua-reader",
            daemon=True,
        )
        self._stderr_thread = threading.Thread(
            target=self._read_stderr,
            name="semantic-harness-lua-stderr",
            daemon=True,
        )
        self._reader_thread.start()
        self._stderr_thread.start()
        try:
            hello = self._hello.get(timeout=self.config.startup_timeout)
        except queue.Empty as error:
            detail = self._failure or self._diagnostic("worker did not send READY")
            self.close()
            raise HarnessError(detail) from error
        if hello.get("ok") is not True or hello.get("type") != "hello":
            detail = hello.get("error", "worker handshake failed")
            self.close()
            raise HarnessError(str(detail))
        with self._state_lock:
            self._state = "READY"
        return hello

    def request(
        self,
        command: str,
        payload: Any = None,
        *,
        timeout: float | None = None,
    ) -> dict[str, Any]:
        with self._request_lock:
            if self.state != "READY":
                raise HarnessError(self._failure or f"worker is {self.state.lower()}")
            process = self.process
            if process is None or process.stdin is None:
                raise HarnessError("Lua worker pipes are unavailable")
            self._request_sequence += 1
            request_id = f"harness-{self._request_sequence}"
            try:
                encoded = encode_request(request_id, command, payload)
            except ProtocolError as error:
                raise HarnessError(str(error)) from error
            if len(encoded) > self.config.max_message_bytes:
                raise HarnessError("request exceeds the message limit")
            response_queue: queue.Queue[dict[str, Any]] = queue.Queue(maxsize=1)
            with self._pending_lock:
                self._pending[request_id] = response_queue
            try:
                process.stdin.write(encoded)
                process.stdin.flush()
            except (BrokenPipeError, OSError) as error:
                self._set_failure(f"could not write Lua request: {error}")
                raise HarnessError(self._diagnostic("Lua worker write failed")) from error
            try:
                response = response_queue.get(timeout=timeout or self.config.request_timeout)
            except queue.Empty as error:
                self._set_failure(f"request timeout: {command}")
                raise HarnessError(self._diagnostic(f"Lua worker timed out on {command}")) from error
            finally:
                with self._pending_lock:
                    self._pending.pop(request_id, None)
            if response.get("ok") is False:
                raise HarnessError(str(response.get("error", "Lua worker request failed")))
            return response

    def _read_stdout(self) -> None:
        process = self.process
        if process is None or process.stdout is None:
            return
        while True:
            line = process.stdout.readline()
            if not line:
                if self.state not in {"STOPPING", "STOPPED"}:
                    self._set_failure(self._diagnostic("Lua worker exited without a response"))
                return
            if len(line) > self.config.max_message_bytes:
                self._set_failure("Lua worker response exceeds the message limit")
                return
            try:
                message = decode_message(line, max_bytes=self.config.max_message_bytes)
            except ProtocolError as error:
                self._set_failure(str(error))
                return
            if message.get("type") == "hello":
                try:
                    self._hello.put_nowait(message)
                except queue.Full:
                    self._set_failure("duplicate Lua worker handshake")
                continue
            request_id = message.get("id")
            if not isinstance(request_id, str):
                self._set_failure("Lua worker response has no request id")
                return
            with self._pending_lock:
                response_queue = self._pending.get(request_id)
            if response_queue is None:
                self._set_failure(f"Lua worker returned unknown request id: {request_id}")
                return
            try:
                response_queue.put_nowait(message)
            except queue.Full:
                self._set_failure(f"duplicate Lua worker response: {request_id}")
                return

    def _read_stderr(self) -> None:
        process = self.process
        if process is None or process.stderr is None:
            return
        for raw_line in iter(process.stderr.readline, b""):
            line = raw_line.decode("utf-8", errors="replace").rstrip()
            if line:
                self._stderr.append(line[:4096])

    def _set_failure(self, reason: str) -> None:
        with self._state_lock:
            if self._state in {"STOPPED", "STOPPING"}:
                return
            self._state = "FAILED"
            self._failure = reason
        failure = {"ok": False, "error": reason}
        with self._pending_lock:
            pending = list(self._pending.values())
        for response_queue in pending:
            try:
                response_queue.put_nowait(failure)
            except queue.Full:
                pass
        process = self.process
        if process is not None and process.poll() is None:
            try:
                process.terminate()
            except OSError:
                pass

    def _diagnostic(self, prefix: str) -> str:
        process = self.process
        returncode = process.poll() if process is not None else None
        stderr = "; ".join(self._stderr)
        suffix = f"; stderr: {stderr}" if stderr else ""
        return f"{prefix} (state={self.state}, returncode={returncode}){suffix}"

    def close(self) -> None:
        process = self.process
        if process is None:
            with self._state_lock:
                self._state = "STOPPED"
            return
        with self._state_lock:
            if self._state != "STOPPED":
                self._state = "STOPPING"
        if process.poll() is None:
            try:
                process.terminate()
                process.wait(timeout=self.config.shutdown_timeout)
            except (OSError, subprocess.TimeoutExpired):
                try:
                    process.kill()
                    process.wait(timeout=self.config.shutdown_timeout)
                except (OSError, subprocess.TimeoutExpired):
                    pass
        for stream in (process.stdin, process.stdout, process.stderr):
            if stream is not None and not stream.closed:
                stream.close()
        for thread in (self._reader_thread, self._stderr_thread):
            if thread is not None and thread is not threading.current_thread():
                thread.join(timeout=0.2)
        with self._state_lock:
            self._state = "STOPPED"
        _ACTIVE_PROCESSES.discard(self)

    def __enter__(self) -> "LuaProcess":
        self.start()
        return self

    def __exit__(self, *_: object) -> None:
        self.close()
