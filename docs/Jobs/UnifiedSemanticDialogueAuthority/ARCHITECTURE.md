# Architecture — Unified Semantic Dialogue Authority

## Authority model

```text
world/input truth
    ↓
semantic frame + facts
    ↓
ResponseCatalog / flow / ResponsePlan
    ↓
Dialogue Content
    ↓
Speech Presentation
```

Player-facing navigation is separate:

```text
Conversation UI Registry
    ↓
registered semantic choice/provider/predicate
    ↓
existing semantic + gameplay authority
```

### Ownership

- **Semantics / ResponseCatalog:** meaning, semantic variants, plans.
- **Dialogue Content:** Project Hoomans first-party wording and phrase variants.
- **Semantic lifecycle/context:** conversational continuation/follow-up state.
- **Conversation UI Registry:** landing/hub/navigation/presentation structure.
- **Gameplay/domain systems:** factual truth, eligibility, permissions, effects.
- **Speech Presentation:** delivery only.
- **PBrainZ:** optional downstream consumer, never semantic truth authority.

## Canonical authoring architecture

```text
tools/semantic_harness/codebuilder/sources/conversation/
├─ manifest.json
├─ content/
├─ patterns/
├─ flows/
└─ ui/
        ↓
CodeBuilder
        ↓
merged validation + global ID checks + fingerprints
        ↓
bounded generated runtime shards
+ generated domain translations
+ generated audit snapshot
+ generated translation manifest
```

Physical shard paths are provenance, not identity.

Moving a record between shards must not change its canonical runtime identity.

Generated aggregate snapshots and compatibility snapshots are read-only outputs,
not canonical authoring sources.

## Generation rule

Mechanical information should be derived whenever safe:

- Lua data tables;
- runtime indexes/manifests;
- translation keys;
- generated module names;
- fingerprints;
- cross-reference indexes;
- translation bundles;
- audit snapshots.

Generated files must never become a second manual implementation surface.

Generated runtime shards are bounded by semantic/domain ownership rather than
arbitrary byte chunks where practical.

## Translation model

EN is the required fallback language.

All additional locales are ordinary data:

```text
canonical translations
    ↓
locale discovery
    ↓
generated domain bundles
    ↓
generated media/translation/manifests/Conversation.json
    ↓
runtime CustomTranslationManager
```

CodeBuilder must not contain normal control flow such as
`for language in ("EN", "TL")`.

The only permitted explicit TL knowledge is temporary backward-compatible
parsing of historical `tl` source fields in one centralized adapter. New
authoring uses generic `translations` maps.

Runtime language loading is owned by the generated Conversation translation
manifest. Semantic/automatic-flow manifests do not duplicate locale path lists.

## Naming model

Canonical Conversation identity describes meaning.

Bad steady-state identity:

```text
semantic.generated.parameterized_task.fetch.failed
```

Target:

```text
task.fetch.failed
```

Generator/workflow/source information belongs in metadata:

```text
origin = automatic_flow
workflowKind = parameterized_task
sourceShard = ...
generatedModule = ...
```

P11E owns the broad ID/key/file-name migration.

## Studio model

Target mental model:

```text
Simulation = what happens?
Explore → Conversation = what exists?
Developer Tools = edit selected Conversation item
Review = what changed?
Sources = read-only provenance
```

Interactions is not a separate everyday authoring authority. Useful route/
trigger/flow/condition information belongs in selected Conversation details.

## Persistence/performance invariants

- no rendered transcript persistence in NPC ModData;
- no per-NPC/per-tick semantic scans;
- bounded context/follow-up state;
- generated registries/shards remain within configured toolchain budgets;
- known game events enter semantics as typed events rather than string round
  trips;
- source/save state is not mutated by developer acceptance.

## Compatibility boundary

External mods may own facts/events and their own presentation.

Project Hoomans compatibility adapters may translate those facts into semantic
inputs, but external/legacy systems must not become PNC first-party wording or
meaning authority.
