"""Declarative PNC provider registration for the Core semantic harness."""

from __future__ import annotations

from pathlib import Path

from tools.semantic_harness.providers.profile_loader import ProfileSelection, compose_profile
from tools.semantic_harness.providers.provider_registry import (
    CORE_PROVIDER_ID,
    SEMANTIC_EXECUTION_CALLBACKS,
    ProfileDescriptor,
    ProviderDescriptor,
    ProviderRegistry,
)


PNC_PROVIDER_ID = "ProjectHoomans"
_CAPABILITIES = (
    "semantic.conversation",
    "semantic.identity",
    "semantic.interaction",
    "semantic.suggestions",
    "world.discovery",
    "world.radio",
)


def provider_descriptor() -> ProviderDescriptor:
    return ProviderDescriptor(
        provider_id=PNC_PROVIDER_ID,
        display_name="PNC",
        repository_kind="project_hoomans",
        requires=(CORE_PROVIDER_ID,),
        capabilities=_CAPABILITIES,
        materialization_modes=("physical",),
        execution_callbacks=SEMANTIC_EXECUTION_CALLBACKS,
    )


def register_pnc_profiles(registry: ProviderRegistry) -> ProviderRegistry:
    registry.register_provider(provider_descriptor())
    registry.register_profile(
        ProfileDescriptor(
            profile_id="pnc",
            display_name="PNC",
            provider_ids=(CORE_PROVIDER_ID, PNC_PROVIDER_ID),
            materialization_mode="physical",
        )
    )
    return registry


def compose_pnc_profile(*, available_provider_ids: tuple[str, ...] | None = None) -> ProfileSelection:
    return compose_profile(
        "pnc",
        registrars=(register_pnc_profiles,),
        available_provider_ids=available_provider_ids,
    )


def provider_worker_launch_values(repository: str | Path) -> dict[str, object]:
    root = Path(repository).expanduser().resolve()
    return {
        "provider_module_paths": (str(root / "tools/providers/pnc/lua/?.lua"),),
        "provider_modules": ("provider/PNC",),
        "execution_provider_id": PNC_PROVIDER_ID,
    }


__all__ = [
    "PNC_PROVIDER_ID",
    "compose_pnc_profile",
    "provider_descriptor",
    "provider_worker_launch_values",
    "register_pnc_profiles",
]
