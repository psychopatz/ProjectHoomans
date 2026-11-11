# Unified Semantic Catalog Architecture

## Ownership

PsychopatzCore owns the semantic harness, schemas, compiler, validators,
shared catalogs, and generated semantic contracts. Project Hoomans owns
Hoomans-specific dialogue policy and content. Dynamic Trading owns trading
provider packs. Physical source hosting in Core does not imply gameplay
ownership; every shard and auxiliary bundle declares its package owner.

External packs mount into the Core CodeBuilder input graph. They are not copied
into adopter repositories and do not create a second compiler.

## Canonical source model

```text
tools/semantic_harness/codebuilder/sources/conversation/
├── manifest.json
├── content/ responses/ patterns/ flows/ behaviors/ beats/ realization/ ui/
├── conversation_bundles.json
└── translations/
    ├── EN.json
    ├── TL.json
    └── <locale>.json
```

Each semantic shard uses `psychopatz.semantic.shard.v2`. The envelope owns
identity and provenance; the typed payload is selected by `kind`.
`shardId`, record IDs, and translation keys are stable semantic identities,
not physical paths.

The manifest owns source ordering, source roots, external mounts,
`sourceProfiles`, and auxiliary bundle manifests. Source roots and auxiliary
bundles declare their package owner explicitly.

## Compiler module boundaries

`conversation_compiler.py` is the stable public orchestration API.
`conversation_manifest.py` owns filesystem and manifest boundaries.
`conversation_validation.py` owns shard-local contracts and merge rules.
`conversation_catalog.py` owns locale hydration and inline-translation
rejection. `conversation_assembly.py` owns semantic source assembly.
`conversation_rendering.py`, `conversation_discovery.py`,
`conversation_health.py`, and `conversation_registry.py` own output
rendering, indexing, health evidence, and registry serialization respectively.

Modules import their direct owner; there is one loader and one validation path.
No permanent compatibility shim or duplicate harness is part of the design.

## Translation model

CodeBuilder authoring uses one complete, self-contained JSON catalog per
locale. Runtime translation directories are package-specific generated
artifacts, not authoring sources.

```json
{
  "schema": "psychopatz.semantic.translation.v1",
  "language": "EN",
  "fallback": "EN",
  "entries": {
    "conversation.social.reactions.greeting.001": {
      "text": "Good morning.",
      "context": "NPC greeting",
      "sourceShard": "conversation.content.social.reactions"
    }
  }
}
```

## Runtime bundle rendering

`conversation_bundle_catalog.py` is the CodeBuilder materialization boundary.
It validates the canonical bundle manifest, resolves wording from the complete
Core EN/TL catalogs, and renders package-owned runtime files.

Generated runtime paths are:

```text
<mod>/common/media/translation/<LANG>/Conversation/Bundles/<domain>/<audience>/<bundle>.json
```

PNC and Dynamic Trading runtime consumers read those generated paths through
the `PNC_ConversationTextCatalog` boundary. The former `media/conversation`
trees and migration-only catalog utilities are removed; no runtime bridge
remains.

## Validation contract

The rendering gate requires deterministic catalog validation, JSON parity
against every package bundle, focused PNC and DT conversation smokes, Kahlua
validation, and a real build through the Core compiler. P5 additionally
requires composition validation for each dependency-closed mod selection.
