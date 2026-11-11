# Unified Semantic Catalog Architecture

## Ownership

PsychopatzCore owns the harness, schemas, compiler, validators, and shared
semantic catalogs. Project Hoomans owns Hoomans-specific dialogue policy and
content. Dynamic Trading owns trading provider packs. Physical source hosting
in Core does not imply gameplay ownership; every shard declares its package
owner.

External packs are mounted into the Core CodeBuilder input graph. They are not
copied into adopter repositories and do not create a second compiler.

## Canonical source model

```text
tools/semantic_harness/codebuilder/sources/conversation/
├── manifest.json
├── content/ responses/ patterns/ flows/ behaviors/ beats/ realization/ ui/
└── translations/
    ├── EN.json
    ├── TL.json
    └── <locale>.json
```

Each semantic shard has a common envelope and a typed payload. The envelope is
identity and ownership; the payload is selected by `kind`.

```json
{
  "schema": "psychopatz.semantic.shard.v2",
  "shardId": "conversation.content.social.reactions",
  "kind": "content",
  "domain": "social",
  "owner": "ProjectHoomans",
  "sourceProfile": "conversation.source.project.hoomans.dialogue.1234567890",
  "phraseFamilies": [],
  "playerChoices": []
}
```

Supported typed payloads are `phraseFamilies`/`playerChoices` for content,
`patterns`, `responsePools`, `definitions`, `behaviors`, `beats`,
`realizations`, `packs`, and `suggestions` for their respective kinds.

The manifest owns ordering, source roots, external mounts, and the
`sourceProfiles` provenance index. Profiles hold repeated generator/license
metadata once; they are not embedded in every shard or record. Source roots
declare their owner, while each file carries its own shard/profile identity.

Record IDs and translation keys are semantic identities, not file paths.
Moving a record between shards must not change either identity.
Catalog `sourceShard` fields use the stable shard ID; physical source-path
renames therefore do not invalidate locale metadata.

## Compiler module boundaries

`conversation_compiler.py` remains the stable orchestration and public API hub.
Its filesystem boundary is `conversation_manifest.py`, shard-local contracts
and merge rules are in `conversation_validation.py`, locale-key hydration is
in `conversation_catalog.py`, and source assembly is in
`conversation_assembly.py`. Runtime chunking/rendering, discovery/indexing,
health evidence, and registry serialization are owned by
`conversation_rendering.py`, `conversation_discovery.py`,
`conversation_health.py`, and `conversation_registry.py` respectively.
These modules are direct imports, not legacy bridges; there is one loader and
one validation path.

## Translation model

CodeBuilder authoring uses one complete, self-contained JSON catalog per
locale. Runtime translation directories remain package-specific generated
artifacts and are not the authoring source.

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

Locale validation requires EN, exact key parity, valid placeholders, stable
source-shard references, and deterministic duplicate-key rejection. Missing
non-English wording falls back to EN according to the runtime contract.

## Migration boundary

`conversation_shard_migration.py` is an offline, one-shot converter for the
legacy envelope. It is dry-run safe and is not loaded by runtime code. After
all source and external mounts are converted, the old envelope and inline
provenance shape have no supported runtime reader.
