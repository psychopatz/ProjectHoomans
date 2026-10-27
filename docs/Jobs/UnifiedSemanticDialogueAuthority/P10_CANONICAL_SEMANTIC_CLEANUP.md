# P10 — Canonical Semantic Cleanup & Legacy Purge

**Status:** MANDATORY / NEXT.

P0–P9 established the semantic-first runtime and remain accepted foundation.
P10 is a cleanup/consolidation phase opened after a post-P9 source/UI audit
showed that migration-era files, names, metadata and a second wording registry
still remain even though they are no longer supposed to own semantic meaning.

P10 does **not** redesign semantic behavior. It makes the accepted architecture
literal in the repository:

> **ResponseCatalog chooses meaning. Dialogue Content owns wording.
> Semantic lifecycle owns conversational context. Speech Presentation only
> delivers already-selected speech.**

Git history is the archive. Production source must not keep obsolete executable
registries merely as migration history.

## Post-P9 audit baseline

Audit baseline: `fa1d9f9f1332e5d2a870a02e6abcfd885d7a7f0f`.

Verified findings:

- P0–P9 developer acceptance is complete and remains evidence.
- `PNC_SocialFlavorDefinitions_*` still exists under production `media/lua`
  and contains 13 first-party `Flavor.Register(...)` registrations.
- first-party Bandits/Necroa/Project ALife Flavor-definition files remain in the
  production tree even though semantic compatibility pools now own their PNC
  dialogue realization;
- `PNC_ConversationToolReplyCatalog.lua` remains a full literal wording table;
- the production Semantic Harness worker still explicitly loads that old
  ToolReply catalog as `tool_catalog`, despite `PNC_ConversationToolReplies.lua`
  stating that it no longer reads the table;
- `PNC_CompanionCommandFlavor*` remains loaded by shared composition and still
  chooses authored wording for some command/emote/greeting paths through
  `Flavor.Resolve(...)`;
- `PNC_FlavorTextResolver*` now behaves as semantic context classification but
  still exposes the old `PNC.FlavorText` / `PNC.FlavorTextConst` namespace;
- `PNC_FlavorAddress*` remains a legacy-named identity/addressing subsystem next
  to `PNC.Semantics.AddressResolver`;
- the canonical Dialogue Content source contains 168 phrase families / 179
  phrases and is about 242 KB;
- 167/168 phrase-family IDs contain `.migrated.`;
- 167/168 families carry `MIGRATED_*` concepts;
- 167/168 families carry `legacySource`;
- the canonical source contains roughly 1,674 repeated `locked` metadata fields;
- about 126 KB of the source is attributable to repeated
  `canonicalConcept + locked` metadata;
- Responses is a flat list of 191 pools;
- Dialogue Content is a flat list of 168 families.

These are cleanup defects, not proof that the semantic runtime migration failed.

## P10A — Hard legacy-file purge

Delete first-party executable/source-only dialogue registries once parity is
reconfirmed from current semantic/content sources.

Mandatory deletion candidates include:

- `PNC_SocialFlavorDefinitions.lua`;
- every `PNC_SocialFlavorDefinitions_*` shard;
- `PNC_ConversationToolReplyCatalog.lua`;
- Project Hoomans-owned Bandits/Necroa/Project ALife Flavor-definition files
  whose wording is already represented in semantic Dialogue Content;
- legacy-definition tests whose only purpose is to prove the deleted registry
  can still resolve prose.

Before deletion, prove the canonical semantic/content system contains the
required EN/TL wording and behavioral variants.

After deletion:

- remove worker/bootstrap/composition loads;
- replace legacy-definition tests with **negative absence tests** plus semantic
  parity tests;
- no production module may recreate the old tables as a hidden fallback.

**P10A gate:** no first-party PNC legacy prose definition/catalog file remains in
the production mod tree, and no worker/composition path loads one.

## P10B — Retire the remaining CompanionCommandFlavor wording registry

`PNC_CompanionCommandFlavor*` is still a parallel authored wording registry.
Migrate its Project Hoomans-owned command, player-emote, NPC-emote, greeting,
rejection and Companion Dogs wording into the same:

```text
ResponseCatalog
    → ResponsePlan / RealizationAuthority
    → SpeechRealization
    → Dialogue Content
    → Speech Presentation
```

pipeline already used by migrated semantic dialogue.

Requirements:

- player command/emote speech must receive semantic realization before wording;
- NPC acknowledgements/replies must use semantic realization before wording;
- Dialogue Content becomes the only first-party content registry;
- remove `PNC_CompanionCommandFlavor*` and its definitions when callers are
  migrated;
- remove `compatibilityFlavorID` / `flavorID` from first-party semantic packets
  when no external transport contract requires them;
- compatibility providers may supply event facts, but may not own PNC wording.

**P10B gate:** no Project Hoomans command/emote/greeting wording is selected by
`Flavor.Resolve` or another parallel content registry.

## P10C — Normalize legacy semantic helper names and namespaces

Useful behavior must survive under names that describe its current authority.

### Social context

Replace/merge the legacy `PNC_FlavorTextResolver*` naming with a semantic context
module, e.g. `PNC_SemanticSocialContext*` or an equivalent narrow provider.

Final-state requirements:

- no `PNC.FlavorText`;
- no `PNC.FlavorTextConst`;
- no source/test filename that calls the semantic context classifier a
  "FlavorTextResolver";
- threat/audience/need/grief classification remains pure, bounded and
  deterministic.

### Addressing

Reconcile `PNC_FlavorAddress*` with the existing semantic addressing model.

Final-state requirements:

- one clearly named semantic addressing namespace for player/NPC conversational
  address projection;
- no `PNC.FlavorAddress` compatibility alias inside Project Hoomans;
- identity/knowledge authority remains unchanged;
- existing stranger/mate/pal/bro/mister/miss variation and disclosure behavior
  remain intact.

### Presentation

Rename Project Hoomans presentation modules/functions/variables whose remaining
`SocialFlavor`/`Flavor` names now mean generic semantic speech delivery.

Prefer clear terms such as `SpeechPresentation`, `SemanticSpeech`,
`presentationID`, or `speechEventID`.

Do not rename generic PsychopatzCore public APIs unless the current caller audit
shows that doing so is required and safe; Project Hoomans must simply stop
depending on legacy prose-selection semantics.

**P10C gate:** Project Hoomans production source contains no first-party legacy
"Flavor" namespace that can be mistaken for a dialogue/content authority.

## P10D — Dialogue Content schema v2: compact canonical source

The current source repeats semantic topology and migration history inside every
phrase family. Replace it with a compact steady-state schema.

### Canonical identity

Use the existing semantic template/realization identity as the canonical join
key. Do not maintain multiple equivalent identities such as:

```text
semantic.tool_reply.admire.1
phrase.migrated.tool_reply_admire_1
MIGRATED_TOOL_REPLY_ADMIRE_1
semanticVariantID = semantic.tool_reply.admire.1
```

unless a distinct stable ID has a demonstrated runtime requirement.

### Remove migration archaeology from canonical content

The steady-state authoring source must contain no:

- `.migrated.` family IDs;
- `MIGRATED_*` concepts;
- `legacySource`;
- repeated prose such as `semanticAuthority`,
  `conditions = ResponseCatalog-owned`, `priority = ResponseCatalog-owned`,
  `contentVariation`, `authority`, or duplicated `followUpEligibility`;
- duplicated `responsePoolID` / `semanticVariantID` when they can be joined from
  ResponseCatalog by the semantic template identity.

Migration provenance belongs in this job's history / Git history, not every
runtime content record.

### Derive mechanical fields

Prefer CodeBuilder derivation for:

- phrase IDs where deterministic derivation is safe;
- translation key prefixes;
- style/index suffixes;
- content fingerprints;
- repeated owner namespace.

Keep an explicit field only when it has a real external/stability requirement.

### Group shared metadata once

Allow group-level ownership such as:

```text
tool_replies
medical
social
compatibility
commands_emotes
```

instead of repeating long content-owner strings in every phrase family.

### No compatibility reader

Perform a one-time source migration and update tests/callers. Do not keep a
permanent v1/v2 dual reader merely to preserve the discarded schema.

**P10D gate:** canonical Dialogue Content contains only content identity,
authoring structure and wording information that has a real owner; migration
metadata is absent; generation remains deterministic and EN/TL parity remains
green.

## P10E — Hierarchical Semantic Lab organization

Both current flat lists must become semantic trees derived from canonical IDs.

### Responses

Group response pools from the semantic namespace, for example:

```text
Combat
└─ Reaction

Compatibility
├─ Bandits
├─ Companion Dogs
├─ Necroa
└─ Project ALife

Tool Replies
├─ Ask Name
├─ Order
└─ Social

Generated
├─ Parameterized Task
└─ Simple Command
```

### Dialogue Content

Use the same semantic branch model and attach content families at leaves, e.g.:

```text
Medical
└─ Distress
   ├─ Call
   ├─ Update
   └─ Repeat

Tool Replies
└─ Social
   ├─ Admire
   ├─ Compliment
   └─ Flirt
```

Requirements:

- derive hierarchy from `semantic.*` IDs / canonical content joins;
- do **not** store a second hierarchy database;
- use humanized short labels in the tree;
- show full canonical IDs in the detail pane;
- parent nodes show useful descendant counts;
- search filters tree nodes and auto-expands matching branches;
- selection remains traceable to exact ResponseCatalog/Dialogue Content source;
- preserve lazy/bounded loading where needed.

**P10E gate:** the Studio no longer presents a 191-pool or 168-family flat wall;
family branches are obvious and exact source identity remains inspectable.

## P10F — No-legacy final acceptance

Final developer acceptance must prove all of the following.

### Source absence

- zero first-party `PNC_SocialFlavorDefinitions*`;
- zero first-party `PNC_ConversationToolReplyCatalog`;
- zero Project Hoomans `CompanionCommandFlavor` wording registry;
- zero `PNC.FlavorText*`;
- zero `.migrated.` phrase-family IDs;
- zero `MIGRATED_*` canonical concepts;
- zero `legacySource` fields in canonical Dialogue Content;
- zero worker/composition loads for deleted registries.

### Architecture

- one semantic response authority;
- one Dialogue Content wording authority;
- one semantic lifecycle/context authority;
- presentation only delivers selected speech;
- external compatibility systems own facts, not PNC wording.

### Regression

- semantic pool/variant/plan behavior unchanged unless a deliberate cleanup
  mapping is documented;
- EN/TL wording parity preserved;
- follow-up behavior preserved;
- command/emote/greeting behavior preserved;
- PBrainZ still consumes canonical semantic context/realizations;
- source saves unchanged;
- no native PZ launch / Workshop publication by the agent.

### Tooling

- Responses and Dialogue Content use the same derived semantic grouping model;
- full IDs and provenance remain inspectable;
- canonical source is smaller and easier to author;
- CodeBuilder remains deterministic/idempotent.

### Performance

Use the resource-aware Python runner from P9. Do not fall back to the old serial
full-suite topology.

Record before/after:

- canonical Dialogue Content bytes;
- generated runtime registry bytes;
- worker startup;
- full headless Python wall time;
- focused Xvfb wall time;
- native Lua wall time.

Cleanup is rejected if it introduces a material unexplained runtime/test
regression.

## Completion boundary

Only after P10A–P10F pass may this parent goal return to
`READY FOR USER LIVE TEST`.

The final live-test handoff must describe the steady-state architecture without
using migration-era terms such as FlavorText, SocialFlavorDefinitions,
ToolReplyCatalog, CompanionCommandFlavor, `.migrated`, `MIGRATED_*` or
`legacySource` as Project Hoomans production concepts.
