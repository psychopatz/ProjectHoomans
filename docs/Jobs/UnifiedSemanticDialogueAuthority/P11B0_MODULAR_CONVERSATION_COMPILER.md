# P11B0 — Modular Conversation Source & Generation Foundation

**Status:** MANDATORY / NEXT.

P11A remains accepted. The parked P11B wording migration must not resume until
this foundation is accepted.

## Why this phase exists

The current clean baseline is deterministic but monolithic:

- `semantic_dialogue_content.json`: ~105 KB, 216 phrase families / 395 phrases;
- `common_interactions.json`: ~38 KB, mixing 47 NLU patterns + 13 response pools;
- `grounded_personal_dialogue.json`: ~10 KB, mixing patterns + response pools;
- `semantic_definitions.json`: mixes patterns, flow declarations and response content;
- Dialogue Content compiles into one `Generated/DialogueContent/Registry.lua`;
- the parked P11B attempt grew that registry beyond the verifier's 256 KiB
  single-file ceiling before the wording migration was even complete.

This is the wrong scaling direction for humans and agents.

The repository already has a better pattern in other CodeBuilder paths:
manifest-driven compilation into bounded generated Lua shards plus a small hub.

P11B0 generalizes that pattern to Conversation authoring.

## Core result

```text
small canonical Conversation shards
            ↓
deterministic manifest-driven compiler
            ↓
merged validated whole-model in memory
            ↓
generated audit snapshot / fingerprints
            ↓
bounded generated runtime shards
            ↓
small generated registry / manifest
```

Canonical sources are modular and human/agent-editable.
Mechanical/runtime structure is generated.

## P11B0A — canonical Conversation source tree

Create one canonical source root, conceptually:

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ content/
│  ├─ greeting/
│  ├─ social/
│  ├─ question/
│  ├─ command/
│  ├─ task/
│  ├─ gift/
│  ├─ event/
│  └─ compatibility/
├─ patterns/
├─ flows/
└─ ui/
```

Exact shard boundaries may evolve, but each file must represent one cohesive
Conversation domain rather than compiler history.

Requirements:

- source files remain intentionally small enough for targeted human/LLM edits;
- physical shard paths do not become semantic identity;
- canonical IDs remain stable when content moves between shards;
- no shard may duplicate semantic/content/UI ownership from another shard;
- NLU patterns, flow declarations, wording and UI navigation are separate
  responsibilities even when compiled together.

## P11B0B — explicit deterministic manifest

Use one small manifest as the canonical source inventory.

The manifest must:

- list or deterministically reference all canonical Conversation shards;
- define stable category/order metadata where required;
- reject duplicate paths and duplicate canonical IDs;
- use canonical ordering independent of filesystem enumeration;
- allow the compiler to report missing/unregistered shards;
- remain small and readable.

Do not make runtime Project Zomboid depend on filesystem discovery. Discovery
and manifest expansion happen at generation time.

## P11B0C — modular loaders and compiler

Refactor CodeBuilder so it can:

1. load the Conversation manifest;
2. validate each shard independently;
3. merge shards into one in-memory canonical model;
4. enforce global uniqueness across all shard types;
5. validate cross-references between content, patterns, flows and UI;
6. canonical-sort the merged model;
7. compute deterministic whole-model and per-shard fingerprints;
8. compile existing runtime contracts without changing gameplay meaning.

The compiler is the authority for joins and mechanical derivation.

Normal agents/editors must not concatenate JSON manually.

## P11B0D — generated runtime shards

Dialogue Content must stop emitting one giant `Registry.lua`.

Generate bounded runtime modules, conceptually:

```text
Generated/Conversation/
├─ Registry.lua
├─ Manifest.lua
├─ Content/
│  ├─ Greeting.lua
│  ├─ Social.lua
│  ├─ Question/
│  ├─ Command/
│  ├─ Task/
│  ├─ Gift/
│  ├─ Event/
│  └─ Compatibility/
├─ Patterns/
├─ Flows/
└─ UI/
```

Requirements:

- `Registry.lua` is a small lookup/hub, not a whole-content dump;
- generated shards are data-only where practical;
- shard loading is static/deterministic and Project Zomboid-safe;
- runtime APIs such as `FamilyFor(...)` remain stable or are migrated through
  one narrow implementation seam;
- enforce generated shard size/count bounds in CodeBuilder;
- no generated shard may silently exceed the verifier/toolchain size guard.

Prefer one semantic/domain shard over arbitrary byte slicing. If a domain itself
outgrows a bound, split it deterministically without changing canonical IDs.

## P11B0E — generated translations by Conversation domain

Replace implementation-history translation buckets with generated domain
artifacts.

Target direction:

```text
Conversation/
├─ Greeting.json
├─ Social.json
├─ Question/
│  ├─ Identity.json
│  ├─ Wellbeing.json
│  └─ ...
├─ Command.json
├─ Task/
├─ Gift.json
├─ Event/
└─ Compatibility/
```

Translation filenames are generated presentation artifacts, not canonical
semantic identity.

Do not preserve `Generated*.json`, `Responses.json`, `Realizations.json`
or `Semantic/` as permanent naming merely because current code emits them.
Their later removal still occurs only after caller/runtime parity is proven.

## P11B0F — generated whole-model snapshot

Generate one deterministic aggregate snapshot for auditing/tests only, e.g.:

```text
tools/semantic_harness/.generated/ConversationSnapshot.json
```

or an equivalent ignored/generated artifact location.

It may contain the merged canonical model, source shard addresses,
fingerprints, cross-reference resolution and generated artifact addresses.

It is:

- generated;
- read-only;
- suitable for CI/diff/audit/agent inspection;
- never a canonical authoring source.

Normal edits must target small canonical shards.

## P11B0G — source/editor/agent APIs become shard-agnostic

Update Dataset/Dialogue Content authoring services so callers operate on stable
Conversation IDs, not monolithic filenames.

Required capabilities:

- locate an item by canonical ID;
- report owning shard;
- inspect one bounded item/family;
- validate edits against the merged model;
- write only the owning shard;
- use stale/fingerprint guards at shard and whole-model level;
- compile/generate through the same service used by GUI and agents.

The GUI/agent must not need to know that an item physically lives in
`content/question/wellbeing.json`.

## P11B0H — naming/provenance foundation

Canonical Conversation identity describes meaning, not generation method.

This phase establishes the compiler support needed for later P11E cleanup:

- build provenance lives in metadata;
- shard path lives in provenance;
- generated module path lives in provenance;
- canonical ID does not need `generated` or physical-file information.

Do not perform a giant semantic-ID rename in P11B0 unless required by the
modular compiler itself. P11E remains the canonical taxonomy migration phase.

## Acceptance

P11B0 is accepted only when:

- canonical Conversation data is loaded from modular manifest-backed shards;
- existing monolithic authoring files are retired or reduced to generated
  compatibility snapshots with no canonical-write authority;
- Dialogue Content runtime output is sharded and the registry hub stays below
  the verifier/toolchain size guard;
- global ID uniqueness and cross-reference validation work across shards;
- generation is byte-for-byte deterministic across two consecutive runs;
- moving a canonical record between source shards without changing its ID does
  not change runtime semantic identity;
- one targeted Conversation edit reads/writes only its owning source shard;
- generated aggregate snapshots are never canonical inputs;
- current runtime behavior remains unchanged;
- full native Lua remains `897/897` or better with no previously-green
  regression;
- relevant Python/Kahlua/CodeBuilder idempotence tests pass;
- source saves remain untouched;
- native PZ / Workshop publication remain user-owned.

## Relationship to the rest of P11

After P11B0 passes:

1. resume P11B one-wording-authority migration **by coherent domain shard**, not
   one sentence at a time;
2. P11C becomes refinement/expansion of the modular source model rather than a
   future prerequisite;
3. P11D Conversation UI Registry is implemented under `conversation/ui/`;
4. P11E removes `semantic.generated.*` and other implementation-history
   taxonomy using the new modular compiler;
5. P11F–P11I build Studio/editor/agent workflows on stable bounded services.

The parked branch
`wip/p11b-wording-paused-20261028` is evidence only. Do not merge/cherry-pick it
wholesale into this foundation.
