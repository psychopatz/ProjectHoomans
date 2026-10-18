"""Pure Semantic Lab adapter for previewing canonical semantic source."""

from __future__ import annotations

from pathlib import Path
from typing import Any

from tools.semantic_compiler.compiler import (
    CompileError,
    compile_semantic_definitions,
    discover_registered_capability_ids,
    load_semantic_source,
    render_semantic_lua_shards,
)


REPOSITORY = Path(__file__).resolve().parents[2]
SEMANTIC_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Semantics"
)
TRANSLATION_RELATIVE_ROOT = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)


def _planned_paths(compiled: dict[str, Any]) -> list[str]:
    base_name = "PNC_SemanticGeneratedDefinitions"
    rendered = render_semantic_lua_shards(compiled, "PNC/Semantics/" + base_name)
    paths = [str(SEMANTIC_RELATIVE_ROOT / (base_name + ".lua"))]
    paths.extend(
        str(SEMANTIC_RELATIVE_ROOT / (Path(module).name + ".lua"))
        for module, _source in rendered
    )
    paths.extend([
        str(TRANSLATION_RELATIVE_ROOT / "EN/Conversation/Semantic/Generated.json"),
        str(TRANSLATION_RELATIVE_ROOT / "TL/Conversation/Semantic/Generated.json"),
        str(TRANSLATION_RELATIVE_ROOT / "manifests/Conversation.json"),
    ])
    return paths


def preview_semantic_source(
    source_path: Path,
    *,
    repository: Path | None = None,
    runtime_root: Path | None = None,
) -> dict[str, Any]:
    """Compile canonical source in memory and return an effect-free report."""
    repository = (repository or REPOSITORY).expanduser().resolve()
    runtime_root = (runtime_root or repository).expanduser().resolve()
    source_path = source_path.expanduser().resolve()
    try:
        source = load_semantic_source(source_path)
        compiled = compile_semantic_definitions(
            source,
            discover_registered_capability_ids(runtime_root),
        )
    except (CompileError, OSError, ValueError) as error:
        return {
            "ok": False,
            "type": "semantic_compile_preview",
            "sourcePath": str(source_path),
            "previewOnly": True,
            "effectFree": True,
            "diagnostics": [{"severity": "error", "message": str(error)}],
            "generatedPaths": [],
            "writes": [],
        }

    definitions = source.get("definitions", [])
    return {
        "ok": True,
        "type": "semantic_compile_preview",
        "schema": compiled["schema"],
        "sourcePath": str(source_path),
        "source": compiled["source"],
        "previewOnly": True,
        "effectFree": True,
        "diagnostics": [],
        "definitionIDs": [definition["id"] for definition in definitions],
        "capabilityIDs": sorted({
            definition["capability"] for definition in definitions
            if isinstance(definition, dict) and isinstance(definition.get("capability"), str)
        }),
        "patternIDs": [pattern["id"] for pattern in compiled["patterns"]],
        "flowIDs": [flow["id"] for flow in compiled["flows"]],
        "responsePoolIDs": [pool["id"] for pool in compiled["responsePools"]],
        "translationKeys": {
            language: sorted(values)
            for language, values in compiled["translations"].items()
        },
        "generatedPaths": _planned_paths(compiled),
        "writes": [],
    }
