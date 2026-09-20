#!/usr/bin/env python3
"""Build the compact Project Hoomans WordNet alias module."""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_compiler.compiler import (  # noqa: E402
    CompileError,
    compile_wordnet,
    load_allowlist,
    render_lua,
)


DEFAULT_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
    / "PNC_SemanticGeneratedLexicon.lua"
)


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--wordnet-home",
        type=Path,
        required=True,
        help="extracted Princeton WordNet 3.0 package root (contains LICENSE and dict/)",
    )
    parser.add_argument(
        "--allowlist",
        type=Path,
        default=Path(__file__).with_name("wordnet_concepts.json"),
        help="reviewed WordNet synset-to-Hoomans concept mapping",
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    options = parser.parse_args(arguments)

    try:
        compiled = compile_wordnet(
            options.wordnet_home,
            load_allowlist(options.allowlist),
        )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    output = options.output.expanduser().resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write(render_lua(compiled))
    alias_count = sum(len(aliases) for aliases in compiled.aliases_by_concept.values())
    form_count = len(compiled.verb_forms_by_surface)
    print(
        f"wrote {output} ({alias_count} aliases, {form_count} inflected forms "
        f"across {len(compiled.aliases_by_concept)} concepts)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
