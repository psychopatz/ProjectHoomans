# Unified Semantic Catalog Architecture

## Ownership

PsychopatzCore owns the semantic harness, schemas, compiler, validators,
manifest, and generated semantic contracts. Project Hoomans owns its dialogue
policy/content, while Dynamic Trading owns its provider content. Physical
source hosting in Core does not change gameplay ownership: every shard and
bundle declares its package owner.

## Canonical source model

```text
tools/semantic_harness/codebuilder/sources/conversation/
├── manifest.json
├── content/
│   ├── social/
│   │   ├── interaction/<scene-or-behavior>/<topic>.json
│   │   └── reactions/<topic>.json
│   ├── event/<domain>/<topic>.json
│   ├── health/<topic>.json
│   ├── knowledge/<topic>.json
│   └── wellbeing/<topic>.json
├── responses/
├── patterns/
├── flows/
├── behaviors/
├── beats/
├── realization/
├── ui/
└── bundles/
    ├── manifest.json
    └── <domain>.json
```

Normal semantic records use `psychopatz.semantic.shard.v3`. The root manifest
owns filesystem ordering, package ownership, external mounts, source profiles,
and recursive `sourceRoots`. Bundle files use a separate indexed auxiliary
contract so they cannot accidentally be assembled as normal phrase shards.

## Authoring and identity

Recipes keep comparable `EN` and `TL` maps beside each authored record. The
compiler derives runtime phrase IDs and translation keys from the semantic
template ID, style, and append-only phrase order:

```text
phrase.<semanticTemplateID>.<style>.<index02>
conversation.content.<semanticTemplateID>.<style>.<index02>
```

No authoring `phraseID`, `translationKey`, locale-split source file, or
separate monolithic translation catalog is part of the contract.

## Compiler boundaries

- `conversation_manifest.py` validates explicit shards, recursive source roots,
  auxiliary roots, external mounts, ownership, and canonical ordering.
- `conversation_compiler.py` orchestrates assembly, validation, rendering,
  discovery, health, registry, and package routing.
- `conversation_bundle_catalog.py` validates the bundle index and domain
  shards, aggregates them by owner, and renders package-owned runtime files.
- Generated Lua and runtime translation files are build artifacts; source JSON
  remains the authoring authority.

## Runtime bundle rendering

```text
<mod>/common/media/translation/<LANG>/Conversation/Text/
└── <domain>/<audience>/<bundle>.json
```

Project Hoomans receives its 44 owned bundles. Dynamic Trading receives its
two DTCommon bundles only when its provider is enabled. A PNC-only build
contains no Dynamic Trading UI or trader-question output.

## Validation contract

Every source change must preserve semantic-template inventory, owner routing,
EN/TL parity, generated runtime paths, and direct/all-enabled composition
behavior. Core tests, Dynamic Trading tests, affected PNC tests, source audit,
and the real compiler build are required gates; native live-game acceptance and
Workshop publication remain user-owned boundaries.
