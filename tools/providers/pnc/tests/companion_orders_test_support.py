"""Shared companion Orders hub helpers for PNC tests."""

from __future__ import annotations

from tools.providers.pnc.runtime.worker import LuaSemanticWorker


def response_channel(response: dict) -> dict:
    return response["conversationPresentation"]["responseChannel"]


def open_orders(worker: LuaSemanticWorker) -> dict:
    worker.open_conversation()
    channel = worker.conversation_projection()["presentation"]["responseChannel"]
    hub = next(
        row["frame"] for row in channel["rows"]
        if row["id"] == "companion.orders:open"
    )
    return worker.suggestion_click(hub)
