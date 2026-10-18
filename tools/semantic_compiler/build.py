#!/usr/bin/env python3
"""Build the compact Project Hoomans WordNet alias module."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.semantic_compiler.compiler import (  # noqa: E402
    CompileError,
    compile_dialogue_dataset,
    compile_semantic_definitions,
    compile_wordnet,
    load_dialogue_dataset,
    load_allowlist,
    load_semantic_source,
    discover_registered_capability_ids,
    render_dialogue_lua,
    render_dialogue_lua_shards,
    render_dialogue_translation,
    render_semantic_lua_shards,
    render_semantic_manifest,
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
DEFAULT_SEMANTIC_SOURCE = Path(__file__).with_name("semantic_definitions.json")
DEFAULT_SEMANTIC_OUTPUT_ROOT = ROOT


def write_semantic_output(output_root: Path, compiled: dict) -> list[Path]:
    semantic_dir = (
        output_root
        / "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics"
    )
    semantic_dir.mkdir(parents=True, exist_ok=True)
    base_name = "PNC_SemanticGeneratedDefinitions"
    module_prefix = "PNC/Semantics/" + base_name
    rendered = render_semantic_lua_shards(compiled, module_prefix)
    stale = semantic_dir.glob(base_name + "_*.lua")
    for path in stale:
        path.unlink()
    paths: list[Path] = []
    pattern_modules = [module for module, _source in rendered if "_Patterns_" in module]
    flow_modules = [module for module, _source in rendered if "_Flows_" in module]
    response_modules = [module for module, _source in rendered if "_Responses_" in module]
    translation_paths = {
        "EN": ["EN/Conversation/Semantic/Generated.json"],
        "TL": ["TL/Conversation/Semantic/Generated.json"],
    }
    manifest = semantic_dir / (base_name + ".lua")
    manifest.write_text(
        render_semantic_manifest(
            compiled,
            pattern_modules,
            flow_modules,
            response_modules,
            translation_paths,
        ),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(manifest)
    for module, source in rendered:
        path = semantic_dir / (Path(module).name + ".lua")
        path.write_text(source, encoding="utf-8", newline="\n")
        paths.append(path)

    translation_root = output_root / "Contents/mods/ProjectHoomans/common/media/translation"
    for language in ("EN", "TL"):
        directory = translation_root / language / "Conversation" / "Semantic"
        directory.mkdir(parents=True, exist_ok=True)
        path = directory / "Generated.json"
        path.write_text(
            json.dumps(
                compiled["translations"][language],
                ensure_ascii=False,
                sort_keys=True,
                separators=(",", ":"),
            )
            + "\n",
            encoding="utf-8",
            newline="\n",
        )
        paths.append(path)

    manifest_path = translation_root / "manifests" / "Conversation.json"
    if manifest_path.is_file():
        translation_manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
        for language, relative_paths in translation_paths.items():
            entries = translation_manifest.setdefault("languages", {}).setdefault(language, [])
            for relative_path in relative_paths:
                if relative_path not in entries:
                    entries.append(relative_path)
        manifest_path.write_text(
            json.dumps(translation_manifest, ensure_ascii=False, indent=2)
            + "\n",
            encoding="utf-8",
            newline="\n",
        )
        paths.append(manifest_path)
    return paths


def _dialogue_module_prefix(output: Path) -> str:
    parts = output.parts
    for index in range(len(parts) - 2):
        if parts[index:index + 3] != ("media", "lua", "shared"):
            continue
        root = Path(*parts[:index + 3])
        return output.relative_to(root).with_suffix("").as_posix()
    raise ValueError(
        "dialogue output must be under a Project Zomboid media/lua/shared tree")


def _dialogue_translation_root(output: Path) -> Path | None:
    parts = output.parts
    for index in range(len(parts) - 3):
        if parts[index:index + 3] != ("Contents", "mods", "ProjectHoomans"):
            continue
        if "42.20" not in parts[index + 3:]:
            continue
        return Path(*parts[:index]) / (
            "Contents/mods/ProjectHoomans/common/media/translation"
        )
    return None


def write_dialogue_output(output: Path, compiled: dict) -> list[Path]:
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
    translation_root = _dialogue_translation_root(output)
    if translation_root is not None:
        manifest_path = translation_root / "manifests/Conversation.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8")) \
            if manifest_path.is_file() else {"version": 1, "languages": {}}
        for language in ("EN", "TL"):
            relative_path = f"{language}/Conversation/Semantic/GeneratedDialogue.json"
            translation_path = translation_root / relative_path
            translation_path.parent.mkdir(parents=True, exist_ok=True)
            translation_path.write_text(
                render_dialogue_translation(compiled, language),
                encoding="utf-8",
                newline="\n",
            )
            paths.append(translation_path)
            entries = manifest.setdefault("languages", {}).setdefault(language, [])
            if relative_path not in entries:
                entries.append(relative_path)
        manifest_path.parent.mkdir(parents=True, exist_ok=True)
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
            newline="\n",
        )
        paths.append(manifest_path)
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
    parser.add_argument(
        "--semantic-source",
        type=Path,
        default=None,
        help="canonical pnc.semantic_authoring.v1 definition source",
    )
    parser.add_argument(
        "--semantic-output-root",
        type=Path,
        default=DEFAULT_SEMANTIC_OUTPUT_ROOT,
        help="repository root receiving modular semantic source and translations",
    )
    parser.add_argument(
        "--semantic-runtime-root",
        type=Path,
        default=ROOT,
        help="repository root used to discover existing capability registrations",
    )
    options = parser.parse_args(arguments)

    if (
        options.wordnet_home is None
        and options.dialogue_source is None
        and options.semantic_source is None
    ):
        parser.error("provide --wordnet-home, --dialogue-source, --semantic-source, or a combination")

    compiled_lexicon = None
    compiled_dialogue = None
    compiled_semantic = None

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
        if options.semantic_source is not None:
            compiled_semantic = compile_semantic_definitions(
                load_semantic_source(options.semantic_source),
                registered_capability_ids=discover_registered_capability_ids(
                    options.semantic_runtime_root.expanduser().resolve()
                ),
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
        paths = write_dialogue_output(output, compiled_dialogue)
        pattern_count = len(compiled_dialogue["patterns"])
        variant_count = sum(
            len(pool["variants"]) for pool in compiled_dialogue["responsePools"])
        print(
            f"wrote {output} and {len(paths) - 1} data shards "
            f"({pattern_count} exact interaction patterns, {variant_count} "
            "response variants)"
        )
    if compiled_semantic is not None:
        output_root = options.semantic_output_root.expanduser().resolve()
        paths = write_semantic_output(output_root, compiled_semantic)
        print(
            f"wrote semantic source manifest and {len(paths) - 1} generated files "
            f"({len(compiled_semantic['patterns'])} patterns, "
            f"{len(compiled_semantic['flows'])} flows, "
            f"{sum(len(pool['variants']) for pool in compiled_semantic['responsePools'])} responses)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
