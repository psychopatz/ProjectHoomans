# Unified Semantic Catalog Architecture

## Ownership

PsychopatzCore owns the harness, schemas, compiler, validators, and shared
semantic catalogs. Project Hoomans owns Hoomans-specific dialogue policy and
content. Dynamic Trading owns trading content and provider packs. Physical
source hosting in Core does not imply Core gameplay ownership; each shard must
declare its package owner explicitly.

External packs are mounted into the Core CodeBuilder input graph. They are not
copied into adopter repositories and they do not create a second compiler.

## Canonical source model

```text
sources/conversation/
├── manifest.json
├── content/ patterns/ flows/ behaviors/ beats/ realization/ ui/
└── translations/
    ├── EN.json
    ├── TL.json
    └── <locale>.json
```

Each shard uses a common envelope while retaining a typed payload:

```json
{
  "schema": "psychopatz.semantic.shard.v2",
  "shardId": "conversation.content.social.reactions",
  "kind": "content",
  "domain": "social.reactions",
  "owner": "PsychopatzCore",
  "records": []
}
```

The manifest owns registry metadata, order, source roots, and package mounts.
Repeated generator and license metadata is not copied into every record.

## Translation model

Semantic records carry stable `translationKey` values. Locale catalogs contain
the complete language-specific wording and optional authoring context:

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

CodeBuilder may emit flat runtime maps from these catalogs, but the authoring
source remains one self-contained file per locale. Runtime translation
directories remain package-specific generated artifacts.

## Stability rules

- Record IDs and translation keys are semantic identities, not file paths.
- Moving a record between shards must not change its identity.
- Locale names are normalized and discovered from files; `EN` is mandatory.
- Missing non-English wording falls back to `EN` according to the runtime
  contract.
- No runtime compatibility shim is part of the final architecture. A one-shot
  offline converter may read the old shape during migration and is deleted
  after conversion.
