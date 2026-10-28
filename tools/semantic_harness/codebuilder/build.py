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
    from tools.semantic_harness.codebuilder.translation_support import (
        normalize_language,
        pretty_json,
    )
    from tools.semantic_harness.codebuilder.conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_RUNTIME_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_translation_bundles,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )
else:
    from .lexicon_compiler import (  # noqa: E402
        CompileError,
        DEFAULT_ALLOWLIST,
        compile_wordnet,
        load_allowlist,
        render_lua_shards,
    )
    from .translation_support import normalize_language, pretty_json
    from .conversation_compiler import (
        CONVERSATION_MANIFEST_RELATIVE,
        CONVERSATION_RUNTIME_RELATIVE,
        CONVERSATION_UI_RUNTIME_RELATIVE,
        compile_conversation_sources,
        conversation_translation_bundles,
        render_conversation_registry,
        render_conversation_manifest_lua,
        render_conversation_runtime_plan,
        render_conversation_ui_module,
    )


DEFAULT_OUTPUT = (
    ROOT
    / "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Semantics/"
    / "Generated/Lexicon/Catalog.lua"
)
CONVERSATION_SOURCE_ROOT = (
    ROOT / "tools" / "semantic_harness" / "codebuilder" / "sources"
    / "conversation"
)
DEFAULT_CONVERSATION_MANIFEST = CONVERSATION_SOURCE_ROOT / "manifest.json"


# Suggestions.json remains a source for contextual UI keys merged into the
# generated Conversation/UI.json bundle. Runtime loads only the generated bundle.
_CONVERSATION_SOURCE_ONLY_TRANSLATIONS = frozenset({
    "Conversation/Semantic/Suggestions.json",
})

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


def _conversation_locale_directories(translation_root: Path) -> list[tuple[str, Path]]:
    """Discover locale directories from actual Conversation translation trees."""
    discovered: list[tuple[str, Path]] = []
    if not translation_root.is_dir():
        return discovered
    for directory in translation_root.iterdir():
        if not directory.is_dir() or not (directory / "Conversation").is_dir():
            continue
        try:
            language = normalize_language(directory.name, "translation directory")
        except CompileError:
            continue
        discovered.append((language, directory))
    return sorted(discovered, key=lambda item: item[0])


def _write_conversation_translation_manifest(translation_root: Path) -> Path:
    """Generate Conversation.json from real locale files instead of mutating it."""
    languages: dict[str, list[str]] = {}
    for language, directory in _conversation_locale_directories(translation_root):
        entries: list[str] = []
        for path in sorted((directory / "Conversation").rglob("*.json")):
            relative_from_language = path.relative_to(directory).as_posix()
            if relative_from_language in _CONVERSATION_SOURCE_ONLY_TRANSLATIONS:
                continue
            entries.append(path.relative_to(translation_root).as_posix())
        if entries:
            languages[language] = entries
    manifest_path = translation_root / "manifests/Conversation.json"
    manifest_path.parent.mkdir(parents=True, exist_ok=True)
    manifest_path.write_text(
        pretty_json({"version": 1, "languages": languages}),
        encoding="utf-8",
        newline="\n",
    )
    return manifest_path

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


def write_conversation_output(
    repository: Path,
    model: dict | None = None,
) -> list[Path]:
    """Write the manifest-backed Conversation runtime and audit artifacts."""
    repository = repository.expanduser().resolve()
    model = model or compile_conversation_sources(repository)
    shared_root = repository / "Contents/mods/ProjectHoomans/common/media/lua/shared"
    runtime_dir = repository / CONVERSATION_RUNTIME_RELATIVE
    runtime_dir.mkdir(parents=True, exist_ok=True)
    _clean_generated_tree(runtime_dir)

    rendered, reports = render_conversation_runtime_plan(model)
    paths = _write_modules(shared_root, rendered)
    registry_path = runtime_dir / "Registry.lua"
    registry_path.write_text(
        render_conversation_registry(model, reports),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(registry_path)
    manifest_path = runtime_dir / "Manifest.lua"
    manifest_path.write_text(
        render_conversation_manifest_lua(model, reports),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(manifest_path)

    ui_runtime_path = repository / CONVERSATION_UI_RUNTIME_RELATIVE
    ui_runtime_path.parent.mkdir(parents=True, exist_ok=True)
    ui_runtime_path.write_text(
        render_conversation_ui_module(model),
        encoding="utf-8",
        newline="\n",
    )
    paths.append(ui_runtime_path)

    translation_root = repository / "Contents/mods/ProjectHoomans/common/media/translation"
    bundles = conversation_translation_bundles(model)
    for language in sorted(bundles):
        for domain, values in sorted(bundles[language].items()):
            relative = f"{language}/Conversation/{domain}.json"
            path = translation_root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(
                pretty_json(values),
                encoding="utf-8",
                newline="\n",
            )
            paths.append(path)


    translation_manifest_path = _write_conversation_translation_manifest(
        translation_root
    )
    paths.append(translation_manifest_path)

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
        "--conversation-manifest",
        type=Path,
        default=None,
        help="manifest-backed Conversation source tree to compile and generate",
    )
    parser.add_argument(
        "--conversation-output-root",
        type=Path,
        default=ROOT,
        help="repository root receiving generated Conversation artifacts",
    )
    options = parser.parse_args(arguments)

    if options.wordnet_home is None and options.conversation_manifest is None:
        parser.error("provide --wordnet-home and/or --conversation-manifest")

    compiled_lexicon = None
    compiled_conversation = None
    try:
        if options.wordnet_home is not None:
            compiled_lexicon = compile_wordnet(
                options.wordnet_home,
                load_allowlist(options.allowlist),
            )
        if options.conversation_manifest is not None:
            output_root = options.conversation_output_root.expanduser().resolve()
            manifest_path = options.conversation_manifest.expanduser().resolve()
            compiled_conversation = compile_conversation_sources(
                output_root,
                manifest_path=manifest_path,
                runtime_root=output_root,
            )
    except CompileError as error:
        print(f"semantic compiler error: {error}", file=sys.stderr)
        return 2

    if compiled_lexicon is not None:
        output = options.output.expanduser().resolve()
        paths = write_lexicon_output(output, compiled_lexicon)
        alias_count = sum(
            len(aliases)
            for aliases in compiled_lexicon.aliases_by_concept.values()
        )
        form_count = len(compiled_lexicon.verb_forms_by_surface)
        print(
            f"wrote {output} plus {len(paths) - 1} data shards "
            f"({alias_count} aliases, {form_count} inflected forms "
            f"across {len(compiled_lexicon.aliases_by_concept)} concepts)"
        )

    if compiled_conversation is not None:
        output_root = options.conversation_output_root.expanduser().resolve()
        paths = write_conversation_output(output_root, compiled_conversation)
        print(
            "wrote manifest-backed Conversation output and "
            f"{len(paths) - 1} generated files "
            f"({len(compiled_conversation['content']['phraseFamilies'])} "
            "phrase families, "
            f"{len(compiled_conversation['dialogue']['patterns'])} patterns, "
            f"{len(compiled_conversation['ui'])} UI definitions)"
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
