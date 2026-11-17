"""Binary global_mod_data.bin test fixture builders for save-backed PNC tests."""

from __future__ import annotations

import struct


def pz_string(value: str) -> bytes:
    raw = value.encode("utf-8")
    return struct.pack(">h", len(raw)) + raw


def pz_table(entries: list[tuple[object, object]]) -> bytes:
    output = [struct.pack(">i", len(entries))]
    for key, value in entries:
        if isinstance(key, str):
            output.extend((b"\x00", pz_string(key)))
        else:
            output.extend((b"\x01", struct.pack(">d", float(key))))
        if isinstance(value, str):
            output.extend((b"\x00", pz_string(value)))
        elif isinstance(value, bool):
            output.extend((b"\x03", bytes((1 if value else 0,))))
        elif isinstance(value, (int, float)):
            output.extend((b"\x01", struct.pack(">d", float(value))))
        elif isinstance(value, dict):
            output.extend((b"\x02", pz_table(list(value.items()))))
        else:
            raise TypeError(value)
    return b"".join(output)


def pz_file(
    tables: list[tuple[str, list[tuple[object, object]]]],
    *,
    world_version: int = 249,
) -> bytes:
    output = [struct.pack(">ii", world_version, len(tables))]
    for name, entries in tables:
        block = pz_string(name) + pz_table(entries)
        output.extend((struct.pack(">i", len(block)), block))
    return b"".join(output)
