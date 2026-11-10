# Architecture — Modular Semantic Harness and Mod Manager

## Ownership

PsychopatzCore owns reusable mechanisms: manifest discovery, schema
validation, selection resolution, dependency/conflict checks, activation-plan
serialization, capability routing, generic workers, diagnostics, and the CLI.

Providers own domain policy and content: Project Hoomans semantic behavior and
world discovery, Dynamic Trading merchant/trader behavior, and future
expansion-specific capabilities.

Core must not contain product-specific branches for Project Hoomans, Dynamic
Trading, or future provider IDs. Presets are data, not Python conditionals.

## Contracts

The manager produces one deterministic activation plan consumed by Python and
Lua:

```json
{
  "schema": "semantic.harness.activation.v1",
  "enabled": ["PsychopatzCore", "ProjectHoomans", "DTCommon", "DTHoomans"],
  "loadOrder": ["PsychopatzCore", "ProjectHoomans", "DTCommon", "DTHoomans"],
  "routes": {
    "semantic.conversation": "ProjectHoomans",
    "semantic.identity": "ProjectHoomans",
    "world.discovery": "ProjectHoomans",
    "trading.interaction": "DTHoomans"
  }
}
```

Provider manifests declare stable provider ID, display name, dependencies,
optional dependencies, conflicts, capabilities, entrypoints, materialization
modes, route claims, and discovery metadata. Provider IDs are not inferred
from directory order.

## Required selections

- Core only: `PsychopatzCore`
- Project Hoomans: Core + `ProjectHoomans`
- DTAbstract: Core + `DTCommon` + `DTAbstract`
- Project Hoomans + DTHoomans: Core + `ProjectHoomans` + `DTCommon` + `DTHoomans`
- Custom selections: any manifest-compatible future expansion combination.

`combined` may remain a compatibility alias, but it must resolve to an
explicit selection and must not be claimed by individual providers.

## Failure policy

Required dependency, schema, conflict, route, or load-order failures reject a
selection before worker startup. Optional provider failures produce a bounded
degraded diagnostic and leave unrelated providers usable. Activation is
validate -> prepare -> activate -> commit; a failed activation cannot leave a
partial route table.
