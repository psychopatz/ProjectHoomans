# Unified Semantic Catalog Architecture

## Ownership

PsychopatzCore owns the semantic harness, schemas, compiler, validators,
manifest, and generated semantic contracts. Project Hoomans owns its dialogue
policy/content, while Dynamic Trading owns its provider pack. Physical source
hosting in Core does not change gameplay ownership: every shard and bundle
declares its package owner. External packs mount into the Core input graph and
do not create a second compiler or copied harness.

## Canonical source model

```text
tools/semantic_harness/codebuilder/sources/conversation/
├── manifest.json
├── content/
├── responses/
├── patterns/
├── flows/
├── behaviors/
├── beats/
├── realization/
├── ui/
└── conversation_bundles.json
```

Every semantic shard uses `psychopatz.semantic.shard.v3`. The manifest owns
filesystem ordering, package ownership, external mounts, and source profiles;
source records own their player-facing locale maps. Phrase IDs and runtime
translation keys are compiler products, not authoring fields. Array order is
the phrase slot identity and is append-only within a style.

## Compiler boundaries

`conversation_compiler.py` is the public orchestration API.
`conversation_manifest.py` owns filesystem boundaries,
`conversation_validation.py` owns typed shard validation,
`conversation_assembly.py` owns source assembly, and the rendering, discovery,
health, and registry modules own their respective outputs. There is no source
catalog hydrator or compatibility bridge.

The authoring service presents locale maps to the editor and writes the
owning source shard. It resolves provenance from manifest profiles in memory;
it never writes a repeated source envelope into a recipe.

## Translation model

Authoring recipes keep comparable locale maps next to each phrase, response,
choice, or UI suggestion. The compiler aggregates those maps into generated
package output under each mod's `common/media/translation/<LANG>` directory.
Runtime translation files are build artifacts, not authoring inputs.

The compiler emits phrase records using these derived identities:

```text
phrase.<semanticTemplateID>.<style>.<index02>
conversation.content.<semanticTemplateID>.<style>.<index02>
```

## Runtime bundle rendering

`conversation_bundle_catalog.py` validates the bundle manifest, resolves inline
recipe text, and renders package-owned runtime files:

```text
<mod>/common/media/translation/<LANG>/Conversation/Bundles/
  <domain>/<audience>/<bundle>.json
```

PNC and Dynamic Trading read those generated paths through their package
runtime boundaries. The former source catalog directory and migration-only
catalog modules are absent.

## Validation contract

The rendering gate requires deterministic source compilation, runtime EN/TL
parity, bounded shard/index sizes, focused PNC and DT tests, and a real build
through the Core compiler. Composition validation covers PNC, PNC + Dynamic
Trading, DTAbstract, and future provider manifests.
