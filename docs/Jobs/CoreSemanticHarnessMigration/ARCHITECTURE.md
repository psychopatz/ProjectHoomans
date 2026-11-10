# Core Semantic Harness Migration Architecture

## Ownership

PsychopatzCore owns reusable mechanisms and public contracts. Project Hoomans/PNC and Dynamic Trading/DT own gameplay policy, provider adapters, and provider content. A provider may register with Core, but it may not copy or privately own the harness.

```text
PsychopatzCore/tools/semantic_harness/
    canonical harness, CLI, worker, CodeBuilder, UI, inspection, tests

ProjectHoomans/tools/providers/pnc/
    PNC adapter, PNC fixtures/content, PNC policy

DynamicTrading/tools/providers/dt/
    DTCommon/DTAbstract/DTHoomans adapters and DT policy/content
```

The `tools/semantic_harness` directory exists only in Core after cutover.

## Runtime and profile boundaries

- `core`: Core only; no adopter imports or files required.
- `pnc`: Core plus the PNC provider; no DT dependency.
- `dtabstract`: Core plus DT provider; no PNC dependency.
- `dthoomans`: Core plus the DTCommon/DTHoomans providers; PNC is not required.
- `combined`: Core plus both providers and shared world-discovery/radio composition.

Core loads provider registrars through explicit profile composition and validated manifests. It must not use hardcoded adopter imports or path aliases that recreate the old bridge.

## Shared semantic foundations

Core owns the provider-neutral identity and knowledge model: stable identity seed, firstname, surname, nickname, faction, knowledge state, disclosure rules, and display projection. Nicknames may be deterministic aliases derived from a known name (for example Patrick → Pat), but an explicit nickname remains distinct from a derived suggestion.

Core also owns bounded semantic suggestion records and world-discovery/radio event contracts. Providers contribute facts, templates, and gameplay reactions. They do not create parallel suggestion, identity, or radio registries.

## Failure and compatibility policy

There is no permanent compatibility bridge. During migration, replacement paths may coexist only until all callers are cut over. After the cutover gate, `core_*_bridge.py`, old entrypoints, and adopter harness namespaces are deleted. Missing optional providers must produce a clear profile error or a degraded provider-free mode, never a silent fallback to an adopter copy.
