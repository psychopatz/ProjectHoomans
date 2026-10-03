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
    compile_dialogue_dataset,
    compile_wordnet,
    load_dialogue_dataset,
    load_allowlist,
    render_dialogue_lua,
    render_dialogue_lua_shards,
    render_lua,
)


DEFAULT_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
    / "PNC_SemanticGeneratedLexicon.lua"
)
DEFAULT_DIALOGUE_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics/"
    / "PNC_SemanticGeneratedDialogue.lua"
)


def _dialogue_module_prefix(output: Path) -> str:
    parts = output.parts
    for index in range(len(parts) - 2):
        if parts[index:index + 3] != ("media", "lua", "shared"):
            continue
        root = Path(*parts[:index + 3])
        return output.relative_to(root).with_suffix("").as_posix()
    raise ValueError(
        "dialogue output must be under a Project Zomboid media/lua/shared tree")


def _write_dialogue_output(output: Path, compiled: dict) -> list[Path]:
    module_prefix = _dialogue_module_prefix(output)
    shards = render_dialogue_lua_shards(compiled, module_prefix)
    pattern_modules = [
        module for module, _ in shards if "_Patterns_" in module]
    response_modules = [
        module for module, _ in shards if "_Responses_" in module]
    stale_patterns = output.parent.glob(output.stem + "_Patterns_*.lua")
    stale_responses = output.parent.glob(output.stem + "_Responses_*.lua")
    for stale in (*stale_patterns, *stale_responses):
        stale.unlink()
    output.write_text(
        render_dialogue_lua(compiled, pattern_modules, response_modules),
        encoding="utf-8",
        newline="\n",
    )
    paths = [output]
    for module, source in shards:
        shard_path = output.parent / (Path(module).name + ".lua")
        shard_path.write_text(source, encoding="utf-8", newline="\n")
        paths.append(shard_path)
    return paths


def main(arguments: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--wordnet-home",
        type=Path,
        default=None,
        help="extracted Princeton WordNet 3.0 package root (contains LICENSE and dict/)",
    )
    parser.add_argument(
        "--allowlist",
        type=Path,
        default=Path(__file__).with_name("wordnet_concepts.json"),
        help="reviewed WordNet synset-to-Hoomans concept mapping",
    )
    parser.add_argument("--output", type=Path, default=DEFAULT_OUTPUT)
    parser.add_argument(
        "--dialogue-source",
        type=Path,
        default=None,
        help="reviewed Hoomans interaction dataset JSON (compiled into bounded Lua data)",
    )
    parser.add_argument(
        "--dialogue-output",
        type=Path,
        default=DEFAULT_DIALOGUE_OUTPUT,
        help="generated dialogue catalog output path",
    )
    options = parser.parse_args(arguments)

    if options.wordnet_home is None and options.dialogue_source is None:
        parser.error("provide --wordnet-home, --dialogue-source, or both")

    compiled_lexicon = None
    compiled_dialogue = None

    try:
        if options.wordnet_home is not None:
            compiled_lexicon = compile_wordnet(
                options.wordnet_home,
                load_allowlist(options.allowlist),
            )
        if options.dialogue_source is not None:
            compiled_dialogue = compile_dialogue_dataset(
                load_dialogue_dataset(options.dialogue_source)
            )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    if compiled_lexicon is not None:
        output = options.output.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        with output.open("w", encoding="utf-8", newline="\n") as stream:
            stream.write(render_lua(compiled_lexicon))
        alias_count = sum(
            len(aliases) for aliases in compiled_lexicon.aliases_by_concept.values())
        form_count = len(compiled_lexicon.verb_forms_by_surface)
        print(
            f"wrote {output} ({alias_count} aliases, {form_count} inflected forms "
            f"across {len(compiled_lexicon.aliases_by_concept)} concepts)"
        )

    if compiled_dialogue is not None:
        output = options.dialogue_output.expanduser().resolve()
        output.parent.mkdir(parents=True, exist_ok=True)
        paths = _write_dialogue_output(output, compiled_dialogue)
        pattern_count = len(compiled_dialogue["patterns"])
        variant_count = sum(
            len(pool["variants"]) for pool in compiled_dialogue["responsePools"])
        print(
            f"wrote {output} and {len(paths) - 1} data shards "
            f"({pattern_count} exact interaction patterns, {variant_count} "
            "response variants)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
