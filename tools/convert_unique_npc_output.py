#!/usr/bin/env python3
"""Convert Unique NPC Creator JSON into a canonical definition payload.

The creator writes JSON in a ``.txt`` file for Project Zomboid.  This tool is
deliberately independent of the game runtime so it can be used in a build or
mod-authoring workflow.  It accepts both the creator wrapper and a raw
definition, preserves nested item metadata, and never invents a faction.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path
from typing import Iterable

from unique_npc_manager.schema import (
    ConversionError,
    build_payload,
    encode,
    output_name,
    read_definition,
    update_index,
)


def _iter_inputs(path: Path) -> Iterable[Path]:
    if path.is_file():
        yield path
        return
    if path.is_dir():
        for candidate in sorted(path.glob("*.txt")):
            if candidate.name != "UniqueNPCIndex.txt":
                yield candidate
        return
    raise ConversionError(f"input path does not exist: {path}")


def convert_one(input_path: Path, output_path: Path, force: bool) -> Path:
    payload = build_payload(read_definition(input_path))
    if output_path.exists() and not force:
        raise ConversionError(
            f"refusing to overwrite {output_path}; pass --force to replace it"
        )
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(encode(payload), encoding="utf-8")
    return output_path


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input", type=Path, help="creator .txt file or Hoomans directory")
    parser.add_argument(
        "--output",
        type=Path,
        help="output file or directory; omit to print converted JSON",
    )
    parser.add_argument("--stdout", action="store_true", help="print converted JSON")
    parser.add_argument("--force", action="store_true", help="allow overwriting output files")
    parser.add_argument(
        "--update-index",
        action="store_true",
        help="update UniqueNPCIndex.txt beside the output files",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    try:
        inputs = list(_iter_inputs(args.input))
        if not inputs:
            raise ConversionError(f"no .txt inputs found in {args.input}")
        if args.stdout and len(inputs) != 1:
            raise ConversionError("--stdout requires exactly one input file")
        if args.stdout and args.output:
            raise ConversionError("--stdout and --output cannot be combined")
        written: list[Path] = []
        for input_path in inputs:
            payload = build_payload(read_definition(input_path))
            if args.stdout:
                sys.stdout.write(encode(payload))
                continue
            if args.output:
                output_path = (
                    args.output / output_name(payload["definition"])
                    if args.input.is_dir() or len(inputs) > 1 or args.output.is_dir()
                    else args.output
                )
            else:
                raise ConversionError("use --output or --stdout")
            if output_path.resolve() == input_path.resolve() and not args.force:
                raise ConversionError(
                    "output equals input; choose another path or pass --force"
                )
            written.append(convert_one(input_path, output_path, args.force))
        if args.update_index:
            if not written:
                raise ConversionError("--update-index requires --output")
            index_path = update_index(
                written[0].parent, (path.name for path in written)
            )
            print(f"updated {index_path}", file=sys.stderr)
        for path in written:
            print(path)
        return 0
    except ConversionError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
