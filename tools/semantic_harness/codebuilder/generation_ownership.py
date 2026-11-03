"""Owner-aware CodeBuilder output routing for generated semantic artifacts."""

from __future__ import annotations

import os
from pathlib import Path
from typing import Any

CORE_OWNER = "PsychopatzCore"
HOOMANS_OWNER = "ProjectHoomans"

CORE_CONVERSATION_PREFIX = "PsychopatzCore/Semantics/Generated/Conversation"
HOOMANS_CONVERSATION_PREFIX = "PNC/Semantics/Generated/Conversation"

CORE_SHARED_RELATIVE = Path(
    "Contents/mods/PsychopatzCore/common/media/lua/shared"
)
HOOMANS_SHARED_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/lua/shared"
)

CORE_TRANSLATION_RELATIVE = Path(
    "Contents/mods/PsychopatzCore/common/media/translation"
)
HOOMANS_TRANSLATION_RELATIVE = Path(
    "Contents/mods/ProjectHoomans/common/media/translation"
)


def normalize_owner(value: Any) -> str:
    """Return the package owner used for generated artifact routing."""
    raw = str(value or "").strip().lower().replace(" ", "")
    if raw in {"psychopatzcore", "core"}:
        return CORE_OWNER
    return HOOMANS_OWNER


def document_owner(document: dict[str, Any] | None) -> str:
    source = document.get("source") if isinstance(document, dict) else None
    owner = source.get("owner") if isinstance(source, dict) else None
    return normalize_owner(owner)


def source_owner(model: dict[str, Any], source_shard: str | None) -> str:
    documents = model.get("_source_documents") or {}
    document = documents.get(str(source_shard or ""))
    return document_owner(document if isinstance(document, dict) else None)


def conversation_prefix(owner: Any) -> str:
    return (
        CORE_CONVERSATION_PREFIX
        if normalize_owner(owner) == CORE_OWNER
        else HOOMANS_CONVERSATION_PREFIX
    )


def route_module_for_owner(module: str, owner: Any) -> str:
    """Replace the generated Conversation package prefix for one owner."""
    target = conversation_prefix(owner)
    for prefix in (HOOMANS_CONVERSATION_PREFIX, CORE_CONVERSATION_PREFIX):
        if module == prefix:
            return target
        if module.startswith(prefix + "/"):
            return target + module[len(prefix):]
    return module


def module_owner(module: str) -> str:
    if module == CORE_CONVERSATION_PREFIX or module.startswith(
        CORE_CONVERSATION_PREFIX + "/"
    ):
        return CORE_OWNER
    return HOOMANS_OWNER


def resolve_core_repository(
    project_repository: Path,
    *,
    explicit: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    """Resolve the Core checkout without coupling generated paths to Hoomans."""
    if explicit is not None:
        return explicit.expanduser().resolve()
    env = os.environ.get("PZ_TEST_CORE_REPOSITORY")
    if env:
        return Path(env).expanduser().resolve()
    base = (runtime_root or project_repository).expanduser().resolve()
    return (base.parent / "psychopatzCore").resolve()


def owner_repository(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    if normalize_owner(owner) == CORE_OWNER:
        return resolve_core_repository(
            project_repository,
            explicit=core_repository,
            runtime_root=runtime_root,
        )
    return project_repository.expanduser().resolve()


def shared_lua_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        runtime_root=runtime_root,
    )
    relative = (
        CORE_SHARED_RELATIVE
        if normalize_owner(owner) == CORE_OWNER
        else HOOMANS_SHARED_RELATIVE
    )
    return repository / relative


def translation_root(
    project_repository: Path,
    owner: Any,
    *,
    core_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> Path:
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        runtime_root=runtime_root,
    )
    relative = (
        CORE_TRANSLATION_RELATIVE
        if normalize_owner(owner) == CORE_OWNER
        else HOOMANS_TRANSLATION_RELATIVE
    )
    return repository / relative


def module_target(
    project_repository: Path,
    module: str,
    *,
    core_repository: Path | None = None,
    runtime_root: Path | None = None,
) -> tuple[Path, Path]:
    owner = module_owner(module)
    repository = owner_repository(
        project_repository,
        owner,
        core_repository=core_repository,
        runtime_root=runtime_root,
    )
    root = shared_lua_root(
        project_repository,
        owner,
        core_repository=core_repository,
        runtime_root=runtime_root,
    )
    return repository, root / (module + ".lua")
