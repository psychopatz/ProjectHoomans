"""Regression coverage for the bounded Semantic Lab JSON-lines envelope."""

from __future__ import annotations

import json
import unittest

from tools.semantic_harness.runtime.protocol import (
    DEFAULT_MAX_MESSAGE_BYTES,
    ProtocolError,
    decode_message,
)


class ProtocolEnvelopeTests(unittest.TestCase):
    def test_catalog_sized_response_remains_decodable(self) -> None:
        message = json.dumps(
            {"ok": True, "type": "flow_catalog", "catalog": "x" * (270 * 1024)},
            separators=(",", ":"),
        ).encode("utf-8")

        self.assertGreater(len(message), 256 * 1024)
        self.assertLess(len(message), DEFAULT_MAX_MESSAGE_BYTES)
        self.assertEqual(
            decode_message(message)["type"],
            "flow_catalog",
        )

    def test_response_above_bound_is_rejected(self) -> None:
        message = b"{" + b'"ok":true,"payload":"' + b"x" * DEFAULT_MAX_MESSAGE_BYTES + b'"}'

        with self.assertRaisesRegex(ProtocolError, "exceeds the message limit"):
            decode_message(message)
