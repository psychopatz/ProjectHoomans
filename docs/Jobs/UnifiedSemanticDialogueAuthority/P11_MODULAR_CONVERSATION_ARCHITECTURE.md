# P11 — Modular Conversation Architecture & Contextual Authoring

**Status:** IN PROGRESS — P11A accepted; P11B recovery restart is active. The prior P11B–P11H attempt was rejected and reverted after regression audit.

P0–P10 remain accepted semantic-runtime foundation. P11 does not replace the
semantic engine. It removes the remaining authoring/content fragmentation and
turns Semantic Lab into a scalable Conversation browser + contextual editor.

## Parent result

The steady-state developer model must be:

```text
WORLD / PLAYER INPUT
        ↓
semantic frame + authoritative facts
        ↓
ResponseCatalog / flow / response plan
        ↓
Dialogue Content
        ↓
Speech Presentation
```

For player-facing navigation:

```text
Conversation UI Registry
        ↓
registered semantic choice / hub / capability reference
        ↓
existing semantic route + gameplay/domain authority
```

And for authoring:

```text
Explore = what exists?
Simulation = what happens?
Developer Tools = edit the selected Conversation item
Review = what changed?
```

The GUI and automated agents must use the same bounded authoring service. Do
not create separate human and agent content pipelines.

## Post-P10 audit baseline

Audit baseline: `7c9e91d096f52909c1470b12a7e08e747ddc0ab4`.

Verified:

- P10 removed the old first-party SocialFlavor/ToolReply/CompanionCommandFlavor
  prose authorities and first-party Flavor resolve/register paths.
- `semantic_dialogue_content.json` is still one ~105 KB source with 216 phrase
  families and 395 phrases.
- `Responses.json` contains 144 live keys referenced by production Lua.
- `Realizations.json` contains a second live realization-key family.
- LocalResponse still contains hard-coded English fallback wording and a
  `LEGACY_TEXT_FALLBACKS` registration seam.
- `common_interactions.json` mixes NLU patterns and response pools.
- `grounded_personal_dialogue.json` also mixes patterns and response pools.
- `semantic_definitions.json` mixes patterns, flows and wording.
- the runtime catalog exposes 193 pools, including 67
  `semantic.generated.*` pools whose IDs encode build provenance rather than
  conversational meaning.
- Studio currently exposes separate Responses, Interactions and Dialogue
  Content views.
- Interactions duplicates response pools while also containing useful route,
  trigger, flow, capability, speech-act and policy information.
- Developer Tools currently exposes Flow editor, Canonical source editor,
  Block contracts, Interaction composer and Legacy build workflow.
- Dialogue Content already provides useful fingerprint/stale guards, validation,
  preview, Review handoff, explicit writes and deterministic compilation.
- current Dialogue Content editing permits wording replacement but rejects
  adding/removing phrase variants as structural changes.
- `conversation.landing:whats_up` is canonical content, but its child buttons
  are distributed across Lua providers and group-presentation code, so adding
  a child requires Lua edits.
- dynamic choices such as relationship proposal, gossip eligibility, camp
  locations and gameplay capabilities depend on production authorities and
  must remain dynamically gated.

## Core invariant

P11 must reduce surfaces, not create new authorities.

> **Semantics owns meaning. Dialogue Content owns first-party wording.
> Conversation UI Registry owns presentation/navigation structure.
> Gameplay/domain services own permissions and effects.**

Conversation UI data may reference an existing semantic choice, capability,
provider or registered predicate. It must not copy the implementation of that
authority.

## P11A — steady-state hygiene

Finish the post-P10 cleanup before modularization.

Required:

- reconcile stale P10 status at the top/phase table of `PROGRESS.md`;
- remove `LEGACY_TEXT_FALLBACKS` by moving required wording to the canonical
  content path;
- remove dead `legacyRegistry`, `migrationPhase`, `legacyTrace` and similar
  migration-only vocabulary when no production consumer requires it;
- rename legitimate compatibility speech adapters whose `Flavor` filenames
  now falsely imply dialogue authority, while preserving external behavior;
- consolidate migration-era absence tests into durable architecture-contract
  tests instead of preserving one test per historical phase;
- keep domain behavior tests that still prove real runtime behavior.

**P11A gate:** production and durable tests describe the current architecture,
not the migration history used to reach it.

## P11B — one first-party wording path

Make Dialogue Content the literal first-party wording authority, but do it
incrementally. The rejected 2026-10-27 attempt proved that a repository-wide
wording rewrite can make focused new tests pass while breaking established
Conversation behavior.

### P11B-R0 — characterize before migration

Before deleting or redirecting any wording source:

- enumerate every production caller of `Responses.json`, `Realizations.json`,
  LocalResponse fallback prose, static translation-key maps, and hard-coded
  SpeechRealization family keys;
- record placeholder/argument conventions for each family;
- classify each key as fixed wording, parameterized wording, dynamic fact
  formatting, external/public compatibility, or dead;
- preserve the existing behavior tests as contract evidence;
- run the full native Lua suite and record the green baseline before the first
  wording change.

The verified recovery baseline is native Lua `897/897 PASS` at recovery commit
`18eacad50745e445c92639d1ce77d487d1da07fd`, whose tree matches P11A anchor
`08081ac8`.

### P11B-R1+ — migrate one bounded family at a time

For each coherent wording family:

1. add or reuse the Dialogue Content semantic template and EN/TL variants;
2. preserve exact parameter/placeholder semantics;
3. migrate the actual production caller(s) to the semantic template directly;
4. regenerate outputs through CodeBuilder rather than hand-editing generated
   Lua/translation files;
5. run focused caller/content tests;
6. run the **full native Lua suite** before accepting the slice;
7. run relevant Python/Kahlua/PBrainZ/compatibility checks;
8. only after all callers are migrated, remove that family's old translation
   key/table entry;
9. prove there is no production caller for the retired key before continuing.

Start with a low-risk family whose callers and formatting are fully enumerable.
Do **not** begin with identity exchange, gossip, backstory, PBrainZ integration,
or other parameterized cross-domain responses in the same slice.

### No alias-table shortcut

Do not introduce a broad `runtimeAliases`, translation-key alias shard, or
equivalent phase-wide compatibility registry merely to keep old callers working
while claiming one wording authority. That reproduces the split system under a
different name.

If a specific externally consumed public key truly must remain compatible,
document that exact boundary and stop for an explicit compatibility decision.
Internal Project Hoomans callers should be migrated directly.

Runtime semantic/question handlers should ultimately return stable semantic
template IDs plus bounded arguments/facts rather than authored English prose.

Parameterized time/date/weather/identity/location/etc. answers may use
localized templates and arguments; do not move volatile fact truth into
Dialogue Content.

After per-family parity is proven:

- remove first-party `Responses.json` and `Realizations.json` as independent
  wording authorities;
- remove obsolete text-fallback registration;
- retain generated translation artifacts only when they are outputs of the one
  canonical content compiler.

**P11B gate:** every Project Hoomans first-party NPC/player conversational phrase
is traceable to Dialogue Content or a clearly external provider-owned surface;
no broad compatibility alias registry masks unmigrated internal callers; and
the full pre-existing native Lua regression suite remains green.

## P11C — modular Conversation authoring sources

Replace giant/mixed authoring documents with domain shards and a deterministic
manifest/compiler.

Target conceptual domains include:

```text
Conversation/
  greeting
  social/
    compliment
    apology
    relationship
  questions/
    identity
    wellbeing
    needs
    health
    activity
    weather
    time_date
    knowledge
    backstory
  commands/
  tasks/
  gifts/
  events/
    combat
    medical
    leader_loss
    companion
  compatibility/
    bandits
    necroa
    companion_dogs
    project_alife
```

Requirements:

- split NLU/pattern authoring from response/content wording;
- do not keep response pools embedded in generic pattern datasets merely for
  convenience;
- load shards through one manifest or deterministic discovery contract that is
  Project Zomboid-safe at generation time;
- enforce global unique semantic IDs and content IDs;
- preserve stable canonical identities across physical file moves;
- generated/runtime artifacts remain deterministic/idempotent;
- agents and GUI use service APIs, not knowledge of physical shard paths.

**P11C gate:** adding variants to one conversation family does not require
editing a 100+ KB monolith or a mixed NLU/response document.

## P11D — canonical Conversation UI Registry

Create one canonical, declarative registry for player-facing Conversation
navigation/presentation.

It owns:

- landing choices;
- hub definitions;
- parent/child membership;
- ordering;
- labels and player utterance wording references;
- presentation grouping;
- registered eligibility/predicate references;
- semantic route references;
- static child membership.

It does **not** own:

- relationship eligibility logic;
- recruitment authority;
- inventory/task/gameplay effects;
- faction policy;
- world mutation;
- dynamic camp-site discovery;
- gossip truth/privacy;
- semantic response selection.

Dynamic providers remain production authorities. The registry may provide their
presentation slot/order/wording and reference their provider ID.

Migrate hard-coded presentation/navigation for surfaces such as:

- `conversation.landing:whats_up`;
- What's Up child membership/order;
- group labels;
- static question entries;
- companion-orders/camp navigation where declarative structure is safe;
- other static Conversation UI structure discovered by caller audit.

Example target:

```text
Conversation UI
├─ Landing
│  └─ What's up
└─ Hub: What's up
   ├─ Wellbeing
   ├─ Needs
   ├─ Health
   ├─ Activity
   ├─ Gossip          [dynamic eligibility]
   ├─ Weather
   └─ Relationship    [dynamic provider/eligibility]
```

**P11D gate:** adding/reordering an existing semantic choice beneath What's Up
does not require editing production Lua.

## P11E — remove generated taxonomy pollution

`generated` describes provenance, not conversational meaning.

Migrate `semantic.generated.*` IDs to domain identities, e.g.:

```text
semantic.task.consume.active
semantic.task.consume.completed
semantic.command.follow.queued
semantic.command.camp.failed
semantic.gift.pending
semantic.gift.completed
```

Keep build origin separately:

```text
origin = automatic_flow
workflowKind = parameterized_task
templateVersion = ...
```

Do not create a visible Generated domain in Studio merely because CodeBuilder
generated the registration.

**P11E gate:** canonical semantic IDs describe conversation/domain meaning; build
provenance remains inspectable metadata.

## P11F — Studio consolidation

Replace redundant browsing surfaces with one primary Conversation explorer.

Target:

```text
Studio
├─ Explore
│  ├─ Conversation
│  └─ Sources
└─ Review

[ Developer Tools… ]
```

The Conversation tree combines response/content/navigation identity without
duplicating authority. Selecting a leaf exposes bounded detail tabs such as:

```text
Overview
Wording
Route
Conditions
Follow-ups
Sources
```

Requirements:

- fold useful Interactions execution-route information into selected
  Conversation detail;
- remove duplicated response-pool rows from a separate Interactions browser;
- raw trigger/concept/speech-act/generation diagnostics may move under a narrow
  diagnostic/developer inspection surface when still useful;
- full canonical IDs and source provenance remain visible;
- search and hierarchy remain bounded/lazy;
- branch counts must be unambiguous, e.g. pools vs variants vs phrases.

**P11F gate:** ordinary inspection has one obvious Conversation browser; no
separate Responses/Interactions/Dialogue Content maze is required.

## P11G — contextual Developer Tools editor

Repurpose Developer Tools from structural semantic construction into a
contextual editor for the selected Conversation item.

Retire/demote the current user-facing:

- Flow editor;
- Canonical source editor;
- Block contracts;
- Interaction composer;
- Legacy build workflow;

unless a specific low-level diagnostic remains justified under an explicit
advanced/diagnostic surface.

### Dialogue/translation editing

For a selected phrase family, support structured:

- EN/TL editing;
- style selection;
- add phrase variant;
- duplicate variant;
- delete variant;
- reorder variant;
- add/remove style when allowed by the content schema;
- generated phrase IDs/translation keys;
- validation;
- preview in Simulation;
- Review;
- explicit canonical write;
- explicit compile.

Do not require raw JSON for normal edits.

### Conversation UI editing

For a selected landing/hub/choice node, support:

- EN/TL label;
- EN/TL player utterance;
- parent hub;
- child membership;
- order;
- add existing registered semantic choice;
- remove/reorder child;
- select registered eligibility/predicate/provider reference;
- preview the actual Conversation UI;
- Review;
- explicit canonical write/compile.

Semantic destination, gameplay authority and dynamic predicate implementation
remain locked and visibly sourced.

### Dynamic provider presentation

Dynamic choices may be shown in the editor with fields such as:

```text
Source: Relationship Provider
Eligibility: production-owned / locked
Presentation/order: editable
Wording: editable when Project Hoomans-owned
```

Do not convert dynamic gameplay authority into editable static JSON merely to
make the GUI convenient.

**P11G gate:** a human can select a dialogue family and add a new EN/TL variant,
or select What's Up and add/reorder an existing semantic child, without editing
Lua or giant JSON manually.

## P11H — agent-friendly authoring API

The GUI and agents must call the same authoring service.

Provide bounded operations conceptually equivalent to:

```text
conversation inspect <id>
conversation variants <id>
conversation variant add|duplicate|delete|move ...
conversation ui inspect <node>
conversation ui add-child|remove-child|move-child ...
conversation validate ...
conversation preview ...
conversation write ...
conversation compile ...
```

Exact CLI naming is implementation-defined. Required properties:

- stable IDs;
- bounded reads;
- stale/fingerprint guards;
- schema validation;
- no generated-file direct editing;
- no hidden auto-write;
- deterministic outputs;
- machine-readable diagnostics;
- human GUI uses the same service methods.

**P11H gate:** an agent can add/edit response variants and Conversation UI
membership without patching arbitrary Lua/JSON files directly.

## P11I — final modular acceptance

Final developer acceptance must prove:

### Architecture

- one semantic meaning authority;
- one first-party wording authority;
- one Conversation UI/navigation registry;
- gameplay/domain authority remains external to UI authoring;
- no `semantic.generated.*` canonical taxonomy;
- no live migration-era wording/fallback shim;
- no separate human-vs-agent authoring path.

### Authoring

- content is domain-sharded and deterministically compiled;
- add/duplicate/delete/reorder phrase variants works;
- EN/TL parity and placeholders are validated;
- What's Up children can be added/reordered/removed declaratively;
- dynamic provider eligibility remains locked/authoritative;
- stale source edits are rejected;
- Review and preview remain effect-free until explicit write.

### Studio

- one Conversation explorer;
- Interactions is removed as a redundant everyday browser;
- Route/Conditions/Follow-ups/Sources remain inspectable;
- Developer Tools edits the currently selected item;
- normal editing does not require raw JSON.

### Runtime/regression

- typed/clicked semantic parity remains;
- command/task/gift generated flows preserve behavior under renamed IDs;
- event follow-up remains grounded;
- PBrainZ compatibility remains;
- Bandits/Necroa/Companion Dogs/Project ALife behavior remains;
- no save mutation;
- no native PZ launch / Workshop publication by the agent;
- resource-aware Python, focused Xvfb, native Lua, Kahlua and CodeBuilder
  idempotence remain green;
- no material unexplained worker/runtime regression.

## Completion boundary

Only after P11A–P11I pass may the parent goal return to
`READY FOR USER LIVE TEST`.

The final handoff must describe the system in steady-state Conversation terms,
not as a collection of Responses/Interactions/Generated/migration-era tools.
