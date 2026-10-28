# Roadmap — Pragmatic Interaction Director Recovery

**Parent status:** RECOVERY / RE-ARCHITECTURE REQUIRED.

The old P0–P8 dialogue-director roadmap is superseded.

Do not continue from the prototype's partially implemented P7.

The mandatory developer objective is R0–R9.

## R0 — freeze, classify, and protect useful evidence

Audit the entire current uncommitted prototype.

For every modified/new implementation file or coherent hunk classify:

- `KEEP` — behavior/test/observability worth retaining;
- `REWORK` — useful concept with wrong ownership/API;
- `REMOVE` — parallel authority or dead-end implementation.

Mandatory protected acceptance:

- typoed recognized hostility does not become generic clarification;
- context can change behavior while semantic meaning remains stable;
- argument → apology → reconciliation transition;
- bounded session state;
- explainable worker trace.

Do not commit the prototype as-is.

**Gate:** a written recovery matrix exists and no old-P7 work continues.

## R1 — restore single response/content authority

Remove prototype ownership that lets the director directly select its own
response pools.

Required:

- no `DialogueDirector.ResolveResponse` response authority;
- no `flow → director response → local response` competing realization path;
- behavior output becomes semantic intent/InteractionPlan;
- existing ResponsePlan/Dialogue Content becomes the only speech path;
- preserve prototype behavioral acceptance through the unified path.

**Gate:** a selected behavior can alter ResponsePlan semantics without creating
a second response catalog.

## R2 — migrate director wording into ordinary modular Dialogue Content

Remove the architectural idea of director-owned response strings.

Required:

- migrate warning/retaliation/de-escalation/reconciliation/first-contact wording
  into modular Dialogue Content records;
- existing Dialogue Content harness editing works for those strings;
- compiler generates locales normally;
- no catch-all `responses/director.json`;
- no catch-all `Conversation/Director.json` for dialogue wording;
- labels/descriptions only exist when an actual player-facing UI needs them.

**Gate:** change one interaction phrase through the normal Dialogue Content
authoring workflow and prove generated EN + additional-locale output.

## R3 — modular canonical situation/behavior source model

Replace catch-all beat/behavior shards with small modular source records.

Required:

- one bounded situation/beat record per file or tiny coherent family;
- one reusable behavior record per file or tiny coherent family;
- stable canonical IDs;
- behavior references semantic content identity, not a director-specific response
  pool;
- deterministic compiler-side discovery of approved source roots;
- no ever-growing manual manifest entry per file;
- deterministic generated indexes/modules.

**Gate:** adding one new beat/behavior source file requires no root compiler code
or manifest list edit beyond approved source-root configuration.

## R4 — one registry, one predicate contract, modular runtime

### Registry

Use one canonical Conversation Registry/index view.

Harness drafts use a worker-local overlay.

Remove duplicate production beat/behavior registries if they no longer add
unique authority.

### Predicates

Audit existing flow/suggestion/context predicate engines.

Converge on one typed/bounded predicate evaluator where practical.

### Runtime

Split the large prototype director into focused providers/reused modules.

**Gate:** production has one canonical registry identity and no giant
dialogue-director composition module owns unrelated concerns.

## R5 — typed stimuli and provider/adaptor projections

Implement the generic interaction input contract.

Required:

- typed stimuli for human semantic input, engine/world events, NPC semantic acts,
  emotes/tasks/social events;
- bounded ActorSnapshot;
- RelationshipSnapshot;
- WorldSnapshot;
- KnowledgeSnapshot;
- SceneContext;
- explicit unknown handling;
- provider capability/provenance visibility;
- third-party adapter contract.

No beat may read arbitrary subsystem internals directly.

**Gate:** Project Hoomans and a synthetic third-party actor adapter can project
into the same interaction contract.

## R6 — pragmatic resolver and behavior arbitration

Implement the missing original intelligence layer.

Required pragmatic inputs:

- semantic candidates/IR;
- pending questions/offers/requests;
- current/recent topic;
- referenced actors/entities;
- active/suspended flows;
- recent semantic acts;
- relevant grounded world/social events.

Behavior arbitration must:

- support one-shot reactions without beats;
- support optional stateful beats;
- use normalized disposition/relationship/world factors;
- produce a grounded InteractionPlan;
- remain deterministic/explainable under the harness.

**Gate:** underspecified/context-sensitive turns resolve against prior
interaction state without hardcoded phrase-specific branches.

## R7 — event-driven beat/scene engine and performance LOD

Implement the scalable runtime scheduling model.

Required:

- stimulus → candidate index;
- no whole-catalog scans on every NPC tick;
- no global social simulation every frame;
- bounded candidate counts;
- bounded active scenes;
- bounded turns;
- cooldowns;
- nearby/perceived vs distant LOD;
- no transcript persistence;
- compact semantic outcomes only when needed.

**Gate:** instrumentation proves candidate evaluation is event-driven and
bounded under synthetic high-NPC scenarios.

## R8 — NPC-to-NPC, multi-NPC, emote, flavor, and world-event reuse

Prove the generic interaction layer outside direct player dialogue.

Required:

- 2-NPC ambient scene;
- 3+ participant bounded scene;
- NPC-generated semantic acts delivered directly, without reparsing generated
  English;
- emote reaction using the same semantic behavior;
- ambient/flavor presentation using the same semantic behavior;
- grounded world-event reaction;
- grounded gossip/news topic;
- interruption by danger/world stimulus;
- optional speech skipped where actor capability or LOD says not to realize it.

**Gate:** the same underlying behavior/beat machinery works across direct
dialogue, ambient NPC scenes, emotes, and flavor presentation.

## R9 — integrated Semantic Lab workbench and final acceptance

Replace the standalone Beat Studio concept with an integrated interaction module
workflow.

Structural authoring:

- situations/beats;
- behaviors;
- stimuli;
- predicates;
- capability requirements;
- contextual modifiers.

Wording:

- linked ordinary Dialogue Content records;
- existing Dialogue Content editor remains canonical wording editor.

Simulation:

- actor/world/context projections;
- pragmatic resolution;
- behavior candidates;
- active beat;
- multi-participant scene timeline;
- flow coexistence;
- output adapters;
- natural vs harness override clearly distinguished.

Final acceptance must prove:

- one NLU authority;
- one context/conversation authority;
- one semantic interaction decision pipeline;
- one ResponsePlan/Dialogue Content speech path;
- one gameplay authority;
- modular compiler-owned source;
- data-driven locales;
- deterministic two-pass generation;
- no generated-file hand editing;
- no transcript/save bloat;
- event-driven bounded performance;
- Project Hoomans + synthetic third-party adapter compatibility;
- direct dialogue + NPC scene + emote/flavor reuse;
- no required PBrainZ dependency.

Only then mark **READY FOR USER LIVE TEST**.

## Non-goals

- do not recreate Façade scripts/content;
- do not use an LLM as authoritative offline interaction logic;
- do not simulate irrelevant distant conversations turn-by-turn;
- do not make every reaction a beat;
- do not make beats response pools;
- do not make the director a parser;
- do not let interaction definitions mutate gameplay state directly.
