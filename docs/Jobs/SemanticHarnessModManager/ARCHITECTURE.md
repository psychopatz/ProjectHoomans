# Architecture — Modular Semantic Harness Mod Manager

## Ownership

PsychopatzCore owns provider-neutral manifest discovery, schema validation,
dependency/conflict resolution, activation-plan serialization, capability
routing, live shared-runtime bootstrap loading, generic workers, diagnostics,
CLI, and GUI selection.

Providers own domain policy and content. Project Hoomans owns conversation,
identity, suggestions, and world-discovery policy. Dynamic Trading owns its
common, abstract, and Hoomans trading policy. Future expansions contribute
manifests instead of adding Core conditionals.

## Activation contract

The manager emits one deterministic plan consumed by Python and Lua:

```json
{
  "schema": "semantic.harness.activation.v1",
  "enabled": ["PsychopatzCore", "ProjectHoomans", "DTCommon", "DTHoomans"],
  "loadOrder": ["PsychopatzCore", "ProjectHoomans", "DTCommon", "DTHoomans"],
  "runtimeBootstraps": [
    {"providerID": "PsychopatzCore", "id": "PsychopatzCore.shared"},
    {"providerID": "DTCommon", "id": "DTCommon.shared"},
    {"providerID": "DTHoomans", "id": "DTHoomans.shared"}
  ],
  "routes": {
    "semantic.conversation": "ProjectHoomans",
    "semantic.identity": "ProjectHoomans",
    "world.discovery": "ProjectHoomans",
    "trading.interaction": "DTHoomans"
  }
}
```

Provider manifests declare stable IDs, dependencies, conflicts, capabilities,
route claims, materialization modes, module paths, and required live bootstrap
entrypoints. The resolver expands those paths against the selected repository
checkouts and rejects missing required files before worker startup.

## Required compositions

- Project Hoomans: Core + `ProjectHoomans`.
- DTAbstract: Core + `DTCommon` + `DTAbstract`.
- Project Hoomans with DTHoomans: Core + `ProjectHoomans` + `DTCommon` + `DTHoomans`.
- Future combinations: manifest-compatible custom selections.

PsychopatzCore is infrastructure, not a standalone harness profile. The old
provider-registry, profile-loader, and adopter-registration paths are removed;
manifests and `ModManager` are the single composition path. Runtime activation
does not copy fixtures or use scenario `availableMods` as a substitute for the
selected dependency graph.

Required dependency, schema, conflict, route, and bootstrap failures reject a
selection before worker startup. Optional provider failures remain bounded and
are reported through the normal handshake.
