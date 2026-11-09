"""Compatibility re-export for the Core-owned worker protocol."""

from __future__ import annotations

import importlib

from .process import _load_core_process


_load_core_process()
_CORE_PROTOCOL = importlib.import_module("semantic_harness.protocol")

DEFAULT_MAX_MESSAGE_BYTES = _CORE_PROTOCOL.DEFAULT_MAX_MESSAGE_BYTES
PROTOCOL_VERSION = _CORE_PROTOCOL.PROTOCOL_VERSION
ProtocolError = _CORE_PROTOCOL.ProtocolError
decode_message = _CORE_PROTOCOL.decode_message
encode_request = _CORE_PROTOCOL.encode_request

__all__ = [
    "DEFAULT_MAX_MESSAGE_BYTES",
    "PROTOCOL_VERSION",
    "ProtocolError",
    "decode_message",
    "encode_request",
]
