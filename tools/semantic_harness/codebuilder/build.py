#!/usr/bin/env python3
"""Build the compact Project Hoomans WordNet alias module."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[3]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

if __package__ in {None, ""}:
    from tools.semantic_harness.codebuilder.lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from tools.semantic_harness.codebuilder.dialogue_contract import (
        load_dialogue_dataset,
    )
    from tools.semantic_harness.codebuilder.dialogue_dataset import (
        compile_dialogue_dataset,
    )
    from tools.semantic_harness.codebuilder.dialogue_rendering import (
        render_dialogue_lua,
        render_dialogue_lua_plan,
        render_dialogue_manifest,
        render_dialogue_translation,
    )
    from tools.semantic_harness.codebuilder.dialogue_content import (
        compile_dialogue_content,
        load_dialogue_content_source,
        write_dialogue_content_output,
    )
    from tools.semantic_harness.codebuilder.semantic_definition_compiler import (
        compile_semantic_definitions,
        load_semantic_source,
        discover_registered_capability_ids,
        render_semantic_lua_plan,
        render_semantic_manifest,
    )
else:
    from .lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from .dialogue_contract import load_dialogue_dataset
    from .dialogue_dataset import compile_dialogue_dataset
    from .dialogue_rendering import (
        render_dialogue_lua,
        render_dialogue_lua_plan,
        render_dialogue_manifest,
        render_dialogue_translation,
    )
    from .dialogue_content import (
        compile_dialogue_content,
        load_dialogue_content_source,
        write_dialogue_content_output,
    )
    from .semantic_definition_compiler import (
        compile_semantic_definitions,
        load_semantic_source,
        discover_registered_capability_ids,
        render_semantic_lua_plan,
        render_semantic_manifest,
    )


DEFAULT_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/"
    / "Generated/Lexicon/Catalog.lua"
)
DEFAULT_DIALOGUE_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/"
    / "Generated/Dialogue/CommonInteractions.lua"
)
CANONICAL_SOURCE_ROOT = (
    ROOT / "tools" / "semantic_harness" / "codebuilder" / "sources"
)
DEFAULT_SEMANTIC_SOURCE = CANONICAL_SOURCE_ROOT / "semantic_definitions.json"
DEFAULT_CONTENT_SOURCE = CANONICAL_SOURCE_ROOT / "semantic_dialogue_content.json"
DEFAULT_SEMANTIC_OUTPUT_ROOT = ROOT


def write_lexicon_output(output: Path, compiled) -> list[Path]:
    """Write the stable lexicon hub and bounded generated data shards."""
    output.parent.mkdir(parents=True, exist_ok=True)
    shared_root = _shared_lua_root(output)
    module_prefix = output.relative_to(shared_root).with_suffix("").as_posix()
    rendered = render_lua_shards(compiled, module_prefix)
    # Keep the catalog's hub sibling directory clean while preserving any
    # future generated catalogs beside it.
    _clean_generated_tree(output.with_suffix(""))
    return _write_modules(shared_root, rendered)


def write_semantic_output(output_root: Path, compiled: dict) -> list[Path]:
    semantic_dir = output_root / (
        "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/"
        "Semantics/Generated/SemanticAuthoring"
    )
    semantic_dir.mkdir(parents=True, exist_ok=True)
    shared_root = output_root / "Contents/mods/ProjectHoomans/common/media/lua/shared"
    module_prefix = "PNC/Semantics/Generated/SemanticAuthoring/Catalog"
    rendered, module_manifest = render_semantic_lua_plan(compiled, module_prefix)
    # Keep the shared SemanticAuthoring directory extensible for additional
    # catalogs; only the Catalog hub's owned subtree is regenerated here.
    _clean_generated_tree(semantic_dir / "Catalog")
    paths: list[Path] = []
    pattern_modules = [module for module, _source in rendered if "/Patterns/" in module]
    flow_modules = [module for module, _source in rendered if "/Flows/" in module]
    response_modules = [module for module, _source in rendered if "/Responses/" in module]
    translation_paths = {
        "EN": ["EN/Conversation/Semantic/Generated.json"],
        "TL": ["TL/Conversation/Semantic/Generated.json"],
    }
    manifest = semantic_dir / "Catalog.lua"
    manifest.write_text(
        render_semantic_manifest(
            compiled,
            pattern_modules,
            flow_modules,
            response_modules,
            translation_paths,
            module_manifest,
        ),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(manifest)
    paths.extend(_write_modules(shared_root, rendered))

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


def _shared_lua_root(path: Path) -> Path:
    parts = path.parts
    for index in range(len(parts) - 2):
        if parts[index:index + 3] == ("media", "lua", "shared"):
            return Path(*parts[:index + 3])
    raise ValueError("generated output must be under a media/lua/shared tree")


def _clean_generated_tree(root: Path) -> None:
    """Remove only Lua artifacts owned by one generated catalog directory."""
    if root.exists():
        for path in sorted(root.rglob("*.lua"), reverse=True):
            path.unlink()
        for directory in sorted(
            (path for path in root.rglob("*") if path.is_dir()),
            key=lambda path: len(path.parts),
            reverse=True,
        ):
            try:
                directory.rmdir()
            except OSError:
                pass
    root.mkdir(parents=True, exist_ok=True)


def _write_modules(shared_root: Path, rendered: list[tuple[str, str]]) -> list[Path]:
    paths: list[Path] = []
    for module, source in rendered:
        path = shared_root / (module + ".lua")
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(source, encoding="utf-8", newline="\n")
        paths.append(path)
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
    for index in range(len(parts) - 4):
        if parts[index:index + 3] != ("Contents", "mods", "ProjectHoomans"):
            continue
        if parts[index + 3] not in {"common", "42.20"}:
            continue
        return Path(*parts[:index]) / (
            "Contents/mods/ProjectHoomans/common/media/translation"
        )
    return None


def _dialogue_translation_stem(output: Path) -> str:
    """Return the stable translation shard name for one dialogue asset."""
    return output.stem or "Dialogue"


def write_dialogue_output(output: Path, compiled: dict) -> list[Path]:
    module_prefix = _dialogue_module_prefix(output)
    shards, module_manifest = render_dialogue_lua_plan(compiled, module_prefix)
    pattern_modules = [module for module, _ in shards if "/Patterns/" in module]
    response_modules = [module for module, _ in shards if "/Responses/" in module]
    # Each named catalog owns its hub sibling directory. Do not clean the
    # shared Dialogue directory: multiple independently generated catalogs
    # live beside one another there.
    _clean_generated_tree(output.with_suffix(""))
    shared_root = _shared_lua_root(output)
    manifest_module = module_prefix + "/Manifest"
    manifest_path = shared_root / (manifest_module + ".lua")
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        render_dialogue_manifest(module_manifest),
        encoding="utf-8",
        newline="\n",
    )
    output.write_text(
        render_dialogue_lua(
            compiled,
            pattern_modules,
            response_modules,
            module_manifest,
            manifest_module,
        ),
        encoding="utf-8",
        newline="\n",
    )
    paths = [output, manifest_path]
    paths.extend(path for path in _write_modules(shared_root, shards) if path != output)
    translation_root = _dialogue_translation_root(output)
    if translation_root is not None:
        translation_stem = _dialogue_translation_stem(output)
        manifest_path = translation_root / "manifests/Conversation.json"
        manifest = json.loads(manifest_path.read_text(encoding="utf-8")) \
            if manifest_path.is_file() else {"version": 1, "languages": {}}
        for language in ("EN", "TL"):
            relative_path = (
                f"{language}/Conversation/Semantic/{translation_stem}.json"
            )
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
        default=DEFAULT_ALLOWLIST,
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
    parser.add_argument(
        "--content-source",
        type=Path,
        default=None,
        help="canonical phrase and player-facing dialogue content source",
    )
    parser.add_argument(
        "--content-output-root",
        type=Path,
        default=ROOT,
        help="repository root receiving generated dialogue content artifacts",
    )
    options = parser.parse_args(arguments)

    if (
        options.wordnet_home is None
        and options.dialogue_source is None
        and options.semantic_source is None
        and options.content_source is None
    ):
        parser.error(
            "provide --wordnet-home, --dialogue-source, --semantic-source, "
            "--content-source, or a combination"
        )

    compiled_lexicon = None
    compiled_dialogue = None
    compiled_semantic = None
    compiled_content = None

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
        if options.content_source is not None:
            compiled_content = compile_dialogue_content(
                load_dialogue_content_source(options.content_source)
            )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    if compiled_lexicon is not None:
        output = options.output.expanduser().resolve()
        paths = write_lexicon_output(output, compiled_lexicon)
        alias_count = sum(
            len(aliases) for aliases in compiled_lexicon.aliases_by_concept.values())
        form_count = len(compiled_lexicon.verb_forms_by_surface)
        print(
            f"wrote {output} plus {len(paths) - 1} data shards "
            f"({alias_count} aliases, {form_count} inflected forms "
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
    if compiled_content is not None:
        output_root = options.content_output_root.expanduser().resolve()
        paths = write_dialogue_content_output(output_root, compiled_content)
        phrase_count = sum(
            len(phrases)
            for family in compiled_content["phraseFamilies"]
            for phrases in family["styles"].values()
        )
        print(
            f"wrote dialogue content registry and {len(paths) - 1} translation artifacts "
            f"({len(compiled_content['phraseFamilies'])} phrase families, "
            f"{phrase_count} phrases, {len(compiled_content['playerChoices'])} player choices)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
