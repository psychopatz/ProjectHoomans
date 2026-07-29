#!/usr/bin/env python3
"""Build Project Zomboid Build 42 translation catalogs from modular sources."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
MOD_ROOT = REPO_ROOT / "Contents/mods/ProjectHoomans/common"
TRANSLATE_ROOT = MOD_ROOT / "media/lua/shared/Translate"
SOURCE_ROOT = REPO_ROOT / "translation-src"
CLIENT_ROOT = MOD_ROOT / "media/lua/client/PNC"
CONVERSATION_KEY = re.compile(
    r'"(UI_PNC_(?:Conversation|Greeting)_[A-Za-z0-9_]+)"'
)


def read_json(path: Path) -> dict[str, str]:
    with path.open("r", encoding="utf-8") as handle:
        values = json.load(handle)
    if not isinstance(values, dict):
        raise ValueError(f"{path} must contain a JSON object")
    output: dict[str, str] = {}
    for key, value in values.items():
        if not isinstance(key, str) or not isinstance(value, str):
            raise ValueError(f"{path} contains a non-string translation entry")
        output[key] = value
    return output


def write_json(path: Path, values: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="\n") as handle:
        json.dump(values, handle, ensure_ascii=False, indent=4)
        handle.write("\n")


def build(language: str) -> tuple[Path, int]:
    source_root = SOURCE_ROOT / language
    paths = sorted(source_root.rglob("*.json"))
    if not paths:
        raise ValueError(f"no translation sources found under {source_root}")

    merged: dict[str, str] = {}
    origins: dict[str, Path] = {}
    for path in paths:
        for key, value in read_json(path).items():
            if not key.startswith("UI_"):
                raise ValueError(
                    f"{path}: {key} must use the UI_ prefix for Build 42 UI.json"
                )
            if key in merged:
                raise ValueError(
                    f"duplicate key {key} in {path} and {origins[key]}"
                )
            merged[key] = value
            origins[key] = path

    referenced_keys: set[str] = set()
    for path in CLIENT_ROOT.rglob("*.lua"):
        referenced_keys.update(CONVERSATION_KEY.findall(path.read_text(encoding="utf-8")))
    missing_keys = sorted(referenced_keys.difference(merged))
    if missing_keys:
        raise ValueError(
            "Lua references missing from the translation catalog: "
            + ", ".join(missing_keys)
        )

    referenced_greetings = {
        key for key in referenced_keys if key.startswith("UI_PNC_Greeting_")
    }
    catalog_greetings = {
        key for key in merged if key.startswith("UI_PNC_Greeting_")
    }
    unused_greetings = sorted(catalog_greetings.difference(referenced_greetings))
    if unused_greetings:
        raise ValueError(
            "Greeting translations missing from Lua pools: "
            + ", ".join(unused_greetings)
        )

    output_path = TRANSLATE_ROOT / language / "UI.json"
    write_json(output_path, dict(sorted(merged.items())))
    return output_path, len(merged)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--language", default="EN")
    args = parser.parse_args()

    language = args.language.upper()
    output_path, count = build(language)
    print(f"wrote {count} translations to {output_path}")


if __name__ == "__main__":
    main()
