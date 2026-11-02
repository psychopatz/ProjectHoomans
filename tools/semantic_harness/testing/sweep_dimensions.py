"""Production-backed sweep dimension discovery and normalization.

Discovers sweepable controls from the real Lua worker's simulation control
catalog and persona catalog without hard-coding a second test vocabulary.
Provides strict validation, prerequisite tracking, read-only protection,
and safe projection into isolated scenario fixtures.
"""

from __future__ import annotations

from copy import deepcopy
from dataclasses import dataclass, field
import hashlib
import json
from typing import Any, Mapping

from ..runtime.scenario import DEFAULT_SCENARIO, validate_scenario
from ..ui.dialogs.settings import _delete_path, _path_value, _set_path, _typed_value


class SweepDimensionError(ValueError):
    """Base error for dimension discovery and parameter projection."""


class UnsupportedDimensionError(SweepDimensionError):
    """Raised when an unknown or unsupported dimension is specified."""


class ReadOnlyDimensionError(SweepDimensionError):
    """Raised when attempting to sweep or mutate a read-only or derived dimension."""


class PrerequisiteDimensionError(SweepDimensionError):
    """Raised when a dimension prerequisite is missing or unsatisfied."""


class InvalidDimensionValueError(SweepDimensionError):
    """Raised when a parameter value violates type, range, or enum options."""


@dataclass(frozen=True)
class SweepDimension:
    """A single discoverable parameter dimension backed by production catalogs."""

    id: str
    path: str
    label: str
    value_type: str  # "enum", "boolean", "number", "integer", "text", "array", "object"
    control_kind: str  # "combobox", "slider", "boolean", "text", etc.
    options: tuple[str, ...] = ()
    options_source: str | None = None
    min_value: float | None = None
    max_value: float | None = None
    step: float | None = None
    read_only: bool = False
    derived_from: tuple[str, ...] = ()
    requires_override: str | None = None
    panel: str | None = None
    section: str | None = None
    workbench_tab: str | None = None
    sweepable: bool = True
    production_source: str = "simulation_control_catalog"
    none_value: Any = None
    clear_path: str | None = None

    def validate_value(self, value: Any) -> Any:
        """Validate and return normalized typed value, or raise InvalidDimensionValueError."""
        if self.read_only:
            raise ReadOnlyDimensionError(f"Dimension '{self.id}' is read-only and cannot be mutated")

        if self.value_type == "boolean":
            if not isinstance(value, bool):
                if value in ("true", "True", 1):
                    return True
                if value in ("false", "False", 0):
                    return False
                raise InvalidDimensionValueError(
                    f"Dimension '{self.id}' expects boolean, got {type(value).__name__}: {value!r}"
                )
            return value

        if self.value_type in ("number", "integer"):
            if not isinstance(value, (int, float)) or isinstance(value, bool):
                try:
                    num_val = float(value)
                    if self.value_type == "integer":
                        num_val = int(num_val)
                    value = num_val
                except (ValueError, TypeError) as exc:
                    raise InvalidDimensionValueError(
                        f"Dimension '{self.id}' expects numeric value, got {type(value).__name__}: {value!r}"
                    ) from exc
            if self.value_type == "integer":
                value = int(value)
            else:
                value = float(value)

            if self.min_value is not None and value < self.min_value:
                raise InvalidDimensionValueError(
                    f"Dimension '{self.id}' value {value} is below minimum {self.min_value}"
                )
            if self.max_value is not None and value > self.max_value:
                raise InvalidDimensionValueError(
                    f"Dimension '{self.id}' value {value} exceeds maximum {self.max_value}"
                )
            return value

        if self.value_type == "enum":
            str_val = str(value)
            if self.options and str_val not in self.options:
                raise InvalidDimensionValueError(
                    f"Dimension '{self.id}' value '{str_val}' is not in valid options: {list(self.options)}"
                )
            return str_val

        if self.value_type == "text":
            return str(value)

        if self.value_type == "array":
            if isinstance(value, (list, tuple)):
                return list(value)
            raise InvalidDimensionValueError(
                f"Dimension '{self.id}' expects list/array, got {type(value).__name__}"
            )

        return value


@dataclass(frozen=True)
class SweepDimensionInventory:
    """Production-backed inventory of discoverable sweep dimensions."""

    dimensions: dict[str, SweepDimension]
    production_fingerprint: str
    catalog_schema: str = "semantic.sweep.dimensions.v1"

    def get(self, dimension_id: str) -> SweepDimension | None:
        dim = self.dimensions.get(dimension_id)
        if dim is not None:
            return dim
        # Check standard aliases
        alias_map = {
            "language": "runtime.language",
            "bondKind": "persona.bondKind",
            "player.hunger": "player.needs.hunger",
            "player.thirst": "player.needs.thirst",
            "player.fatigue": "player.needs.fatigue",
            "player.stress": "player.needs.stress",
            "player.boredom": "player.needs.boredom",
            "player.panic": "player.needs.panic",
            "npc.hunger": "npc.needs.hunger",
            "npc.thirst": "npc.needs.thirst",
            "npc.fatigue": "npc.needs.fatigue",
            "npc.stress": "npc.needs.stress",
            "npc.boredom": "npc.needs.boredom",
            "npc.panic": "npc.needs.panic",
        }
        target_id = alias_map.get(dimension_id)
        if target_id:
            return self.dimensions.get(target_id)
        return None

    def __contains__(self, dimension_id: str) -> bool:
        return self.get(dimension_id) is not None

    def sweepable_dimensions(
        self,
        *,
        panel: str | None = None,
        section: str | None = None,
        value_type: str | None = None,
    ) -> list[SweepDimension]:
        """Return list of sweepable dimensions matching optional filters."""
        results = []
        for dim in self.dimensions.values():
            if not dim.sweepable or dim.read_only:
                continue
            if panel and dim.panel != panel:
                continue
            if section and dim.section != section:
                continue
            if value_type and dim.value_type != value_type:
                continue
            results.append(dim)
        return sorted(results, key=lambda d: d.id)

    def validate_parameter_vector(
        self,
        parameters: Mapping[str, Any],
        *,
        auto_enable_prerequisites: bool = True,
    ) -> dict[str, Any]:
        """Validate and normalize a parameter vector against production dimensions.

        Raises:
            UnsupportedDimensionError: if parameter is unknown.
            ReadOnlyDimensionError: if parameter is derived/read-only.
            PrerequisiteDimensionError: if a required override is missing and auto_enable is False.
            InvalidDimensionValueError: if value violates type/bounds/options.
        """
        # Pass 1: Resolve dimensions, check read-only, validate values
        normalized: dict[str, Any] = {}
        resolved_dims: dict[str, SweepDimension] = {}

        for key, raw_val in parameters.items():
            dim = self.get(key)
            if dim is None:
                raise UnsupportedDimensionError(
                    f"Unknown sweep dimension '{key}'. Available dimensions include: "
                    f"{sorted(self.dimensions.keys())[:10]}..."
                )

            canonical_key = dim.id
            if dim.read_only:
                raise ReadOnlyDimensionError(
                    f"Cannot sweep read-only or derived dimension '{key}' (derived from: {dim.derived_from})"
                )

            valid_val = dim.validate_value(raw_val)
            normalized[canonical_key] = valid_val
            resolved_dims[canonical_key] = dim

        # Pass 2: Prerequisite checks (order-independent)
        for canonical_key, dim in list(resolved_dims.items()):
            if dim.requires_override:
                override_key = dim.requires_override
                if override_key not in normalized:
                    if auto_enable_prerequisites:
                        normalized[override_key] = True
                    else:
                        raise PrerequisiteDimensionError(
                            f"Dimension '{canonical_key}' requires '{override_key}=True', but it was not provided."
                        )
                elif not normalized[override_key]:
                    raise PrerequisiteDimensionError(
                        f"Dimension '{canonical_key}' requires '{override_key}=True', but it was explicitly set to {normalized[override_key]!r}."
                    )

        return normalized

    def project_to_scenario(
        self,
        parameters: Mapping[str, Any],
        base_scenario: dict[str, Any] | None = None,
        *,
        auto_enable_prerequisites: bool = True,
    ) -> dict[str, Any]:
        """Project validated parameters into a fresh scenario dictionary."""
        normalized = self.validate_parameter_vector(
            parameters, auto_enable_prerequisites=auto_enable_prerequisites
        )
        scenario = deepcopy(base_scenario if base_scenario is not None else DEFAULT_SCENARIO)

        # Clear derived relationship state before mutating relationship fields
        scenario.setdefault("npc", {}).pop("relationshipState", None)

        for param_id, value in normalized.items():
            dim = self.dimensions.get(param_id)
            if dim is None:
                continue

            path = dim.path
            none_value = dim.none_value
            if none_value is not None and value == none_value:
                clear_path = dim.clear_path or path
                _delete_path(scenario, clear_path)
                continue

            if param_id == "persona.bondKind":
                existing = _path_value(scenario, "npc.startingRelationship")
                existing = existing if isinstance(existing, dict) else {}
                starting_rel = {
                    "kind": value,
                    "source": existing.get("source", "starting_companion_trait"),
                }
                if existing.get("since") is not None:
                    starting_rel["since"] = existing["since"]
                _set_path(scenario, "npc.startingRelationship", starting_rel)
            elif param_id == "runtime.language":
                scenario.setdefault("runtime", {})["language"] = value
            elif path.startswith("scenario."):
                _set_path(scenario, path[len("scenario."):], value)
            else:
                _set_path(scenario, path, value)

        validate_scenario(scenario)
        return scenario


# Built-in explicit adapters for scenario entry points not exposed as simulation controls
EXPLICIT_SCENARIO_ADAPTERS: list[dict[str, Any]] = [
    {
        "id": "scenario.utterance",
        "path": "scenario.utterance",
        "label": "Spoken utterance",
        "valueType": "text",
        "control": "text",
        "page": "Scenario",
        "section": "Interaction",
        "workbenchPanel": "Interaction",
        "workbenchTab": "Speech",
        "source": "scenario_adapter",
    },
    {
        "id": "scenario.rootChoice",
        "path": "scenario.rootChoice",
        "label": "Conversation root choice",
        "valueType": "enum",
        "control": "combobox",
        "options": [
            "orders",
            "wellbeing",
            "companion_status",
            "personal",
            "trade",
            "gift",
            "goodbye",
            "follow",
            "wait",
        ],
        "page": "Scenario",
        "section": "Interaction",
        "workbenchPanel": "Interaction",
        "workbenchTab": "Choice",
        "source": "scenario_adapter",
    },
    {
        "id": "scenario.weather",
        "path": "weather",
        "label": "Weather condition",
        "valueType": "enum",
        "control": "combobox",
        "options": ["normal", "rain", "heavy_rain", "storm", "fog", "snow"],
        "page": "World",
        "section": "Weather",
        "workbenchPanel": "World",
        "workbenchTab": "Environment",
        "source": "scenario_adapter",
    },
]


def extract_dimension_inventory(
    worker: Any | None = None,
    *,
    control_catalog: dict[str, Any] | None = None,
    persona_catalog: dict[str, Any] | None = None,
) -> SweepDimensionInventory:
    """Extract a comprehensive SweepDimensionInventory from production worker catalogs."""
    if worker is not None:
        if control_catalog is None and hasattr(worker, "simulation_control_catalog"):
            control_catalog = worker.simulation_control_catalog()
        if persona_catalog is None and hasattr(worker, "persona_catalog"):
            persona_catalog = worker.persona_catalog()

    if control_catalog is None:
        raise ValueError("control_catalog is required to extract dimension inventory")

    raw_controls = control_catalog.get("controls", [])
    if not isinstance(raw_controls, list):
        raise ValueError("simulation_control_catalog must contain a 'controls' list")

    dimensions: dict[str, SweepDimension] = {}

    for row in raw_controls:
        if not isinstance(row, dict):
            continue
        control_id = str(row.get("id") or "").strip()
        if not control_id:
            continue

        path = str(row.get("path") or control_id)
        label = str(row.get("label") or control_id)
        val_type = str(row.get("valueType") or "text").lower()
        control_kind = str(row.get("control") or "text").lower()
        options = tuple(str(opt) for opt in (row.get("options") or ()))
        options_source = row.get("optionsSource")

        min_val = float(row["min"]) if "min" in row and row["min"] is not None else None
        max_val = float(row["max"]) if "max" in row and row["max"] is not None else None
        step_val = float(row["step"]) if "step" in row and row["step"] is not None else None

        derived = tuple(str(d) for d in (row.get("derivedFrom") or ()))
        is_read_only = bool(control_kind == "read_only" or derived or row.get("readOnly"))
        requires_override = str(row["requiresOverride"]) if row.get("requiresOverride") else None

        panel = row.get("workbenchPanel")
        section = row.get("workbenchSection") or row.get("section")
        tab = row.get("workbenchTab")

        # A dimension is sweepable if it's editable and has a valid path
        is_sweepable = not is_read_only and bool(path)

        dim = SweepDimension(
            id=control_id,
            path=path,
            label=label,
            value_type=val_type,
            control_kind=control_kind,
            options=options,
            options_source=options_source,
            min_value=min_val,
            max_value=max_val,
            step=step_val,
            read_only=is_read_only,
            derived_from=derived,
            requires_override=requires_override,
            panel=panel,
            section=section,
            workbench_tab=tab,
            sweepable=is_sweepable,
            production_source="simulation_control_catalog",
            none_value=row.get("noneValue"),
            clear_path=row.get("clearPath"),
        )
        dimensions[control_id] = dim

    # Enrich bond options from persona catalog if present
    if persona_catalog and "persona.bondKind" in dimensions:
        bond_dim = dimensions["persona.bondKind"]
        kinds = tuple(
            str(r["kind"])
            for r in persona_catalog.get("relationshipKinds", [])
            if isinstance(r, dict) and r.get("kind")
        )
        if kinds:
            all_options = ("none",) + tuple(k for k in kinds if k != "none")
            dimensions["persona.bondKind"] = SweepDimension(
                id=bond_dim.id,
                path=bond_dim.path,
                label=bond_dim.label,
                value_type=bond_dim.value_type,
                control_kind=bond_dim.control_kind,
                options=all_options,
                options_source="persona_catalog.relationshipKinds",
                min_value=bond_dim.min_value,
                max_value=bond_dim.max_value,
                step=bond_dim.step,
                read_only=bond_dim.read_only,
                derived_from=bond_dim.derived_from,
                requires_override=bond_dim.requires_override,
                panel=bond_dim.panel,
                section=bond_dim.section,
                workbench_tab=bond_dim.workbench_tab,
                sweepable=bond_dim.sweepable,
                production_source="persona_catalog",
                none_value=bond_dim.none_value,
                clear_path=bond_dim.clear_path,
            )

    # Add explicit scenario adapters
    for adapter in EXPLICIT_SCENARIO_ADAPTERS:
        adapt_id = adapter["id"]
        if adapt_id not in dimensions:
            dim = SweepDimension(
                id=adapt_id,
                path=adapter["path"],
                label=adapter["label"],
                value_type=adapter["valueType"],
                control_kind=adapter["control"],
                options=tuple(adapter.get("options") or ()),
                options_source="scenario_adapter",
                panel=adapter.get("workbenchPanel"),
                section=adapter.get("section"),
                workbench_tab=adapter.get("workbenchTab"),
                sweepable=True,
                production_source="scenario_adapter",
            )
            dimensions[adapt_id] = dim

    # Calculate deterministic catalog digest
    summary = [
        f"{d.id}:{d.path}:{d.value_type}:{d.min_value}:{d.max_value}:{list(d.options)}"
        for d in sorted(dimensions.values(), key=lambda x: x.id)
    ]
    digest = hashlib.sha256("\n".join(summary).encode("utf-8")).hexdigest()

    return SweepDimensionInventory(
        dimensions=dimensions,
        production_fingerprint=digest,
        catalog_schema="semantic.sweep.dimensions.v1",
    )
