# Progress — Pragmatic Interaction Director Recovery

**Status:** READY FOR USER LIVE TEST.
**Current branch:** `main`.
**Documentation baseline commit:** `62597936a3a17932dd44bddb3f975064f386b626`.
**Current phase:** R9 — DEVELOPER ACCEPTED; native Project Zomboid live test is user-owned.

## Recovery baseline

The original dialogue-director prototype was never accepted or committed as the
foundation. Its useful behavioral evidence was preserved while rejected
ownership boundaries were replaced by the Pragmatic Interaction Director.

Do not restore the superseded prototype architecture merely to satisfy an old
test expectation.

## R0 — recovery matrix

### KEEP

The following outcomes/evidence are protected:

- typoed `fuck ypuuuu` remains recognized as `HOSTILE_REMARK`;
- generic unresolved trailing text does not erase a high-confidence,
  entity-independent social act;
- same hostile semantic meaning can yield grounded reactions:
  - warning;
  - verbal retaliation;
  - de-escalation;
- argument → apology → reconciliation transition;
- low-forgiveness exit/refusal variant;
- suspicious-first-contact multi-turn persistence;
- bounded per-conversation situation state;
- worker candidate/predicate/modifier evidence;
- bounded turn timeline concept;
- non-mutating draft preview and disposable worker-registration concepts.

### REWORK

These concepts remain useful but their prototype ownership/API is not frozen:

- situation/beat structural schema;
- reusable behavior structural schema;
- bounded situation state;
- scoring/modifier logic;
- structural worker draft overlay;
- structural authoring UI;
- predicate evaluation;
- director composition/module boundaries;
- generated registry access;
- structural canonical edit service.

### REMOVE / REPLACED

The following prototype architecture is rejected:

- `DialogueDirector.ResolveResponse`;
- director-owned response pools;
- `responses/director.json`;
- `semantic.director.*` response content;
- `flow → director response → LocalResponse` response precedence;
- dialogue wording in `Conversation/Director.json`;
- mandatory localized beat/behavior labels;
- catch-all `beats/social.json`;
- catch-all `behaviors/social.json`;
- manual manifest entry per interaction definition;
- partially implemented old `DIRECTOR_OVERRIDE` / FORCE_ACTIVE /
  FORCE_ELIGIBLE plumbing.

The active old override plumbing has been removed.

## R1 — ACCEPTED: restore one speech authority

The interaction layer now emits a bounded semantic `InteractionPlan`:

```text
behaviorID
dialogueAct
beatID
topic
source intent/speech act
subject
groundedFactRefs
```

The director no longer resolves a response or chooses a response pool.

Normal policy flow is:

```text
Flow response (when flow owns the turn)
        OR
LocalResponse
        ↓
ResponsePlan.Attach
        ↑
InteractionPlan may supply semantic dialogueAct/content identity
```

Verified real-worker examples for the same typoed hostile input:

- normal NPC → `BOUNDARY_WARNING`;
- aggressive/confident NPC → `RETALIATE_VERBALLY`;
- panicked NPC → `DEESCALATE`;

while all three still use the ordinary `semantic.hostile_remark` response
authority.

## R2 — ACCEPTED: ordinary Dialogue Content owns wording

Behavior definitions now reference `contentTemplateID`, not `responsePool`.

Current examples:

- `behavior.warn`
  → `semantic.social.hostile_boundary`;
- `behavior.retaliate_verbally`
  → `semantic.interaction.argument.retaliate`;
- `behavior.deescalate`
  → `semantic.interaction.argument.deescalate`;
- `behavior.end_conversation`
  → `semantic.social.hostile_withdrawn`;
- `behavior.reconcile`
  → `semantic.social.apology.friendly`;
- `behavior.challenge`
  → `semantic.interaction.first_contact.challenge`.

New missing wording families live under:

`content/social/interaction/`

and compile through the existing Dialogue Content system.

Real-worker proof:

- retaliation uses ordinary response pool `semantic.hostile_remark`;
- ResponsePlan dialogue act is `RETALIATE_VERBALLY`;
- visible wording is realized from
  `semantic.interaction.argument.retaliate`;
- de-escalation and first-contact challenge follow the same authority model.

The existing `SemanticLabAuthoringService` Dialogue Content edit path was
verified against the new retaliation family in a temporary repository:

- EN edit;
- TL edit;
- effect-free preview;
- canonical source write;
- generated locale update.

No director-specific string service is required.

Generated director response modules are gone. Structural beat/behavior records
no longer generate a `Conversation/Director.json` translation bucket.

## R3 — ACCEPTED: modular sources + deterministic discovery

Canonical interaction source is now modular.

Examples:

```text
content/social/interaction/
  argument_deescalate.json
  argument_retaliate.json
  first_contact_challenge.json

behaviors/social/
  challenge.json
  deescalate.json
  end_conversation.json
  reconcile.json
  retaliate_verbally.json
  warn.json

beats/social/
  argument_escalation.json
  reconciliation.json
  suspicious_first_contact.json
```

The root manifest now approves deterministic `sourceRoots`:

- `content/social/interaction`;
- `behaviors/social`;
- `beats/social`.

CodeBuilder recursively discovers sorted JSON shards below those roots while
still validating every file's expected kind/domain/schema.

Adding a new behavior file under `behaviors/social/` was proven to compile
without modifying `manifest.json`.

Unregistered JSON outside approved explicit shards/source roots remains an
error.

Generated runtime remains explicit and deterministic:

- `Generated/Conversation/Behaviors/Social.lua`;
- `Generated/Conversation/Beats/Social.lua`;
- canonical Registry/Manifest modules.

No Project Zomboid runtime directory discovery was introduced.

### R3 validation

Latest focused recovery pass:

- Python: **24 tests passed**;
- Lua: **3/3 focused tests passed**;
- two-pass generated output: **byte-identical**;
- `git diff --check`: clean.

## R4 — ACCEPTED: one registry + shared predicate + modular runtime

Production beat/behavior identity now comes directly from the generated
Conversation Registry.

`PNC_SemanticInteractionCatalog.lua` adds only:

- derived lookup indexes;
- structural validation;
- a disposable worker-local draft overlay.

The old duplicate production files were removed:

- `PNC_SemanticDialogueBehaviorRegistry.lua`;
- `PNC_SemanticDialogueBeatRegistry.lua`;
- `PNC_SemanticDialogueDirectorCatalog.lua`.

The catalog returns the exact canonical generated behavior objects. Worker draft
registration never mutates those canonical objects.

One shared `PNC_SemanticPredicate.lua` now owns typed predicate semantics for
both suggestions and interactions. Existing suggestion availability/privacy
tests pass through the same implementation.

The director was split into focused concerns:

- `PNC_SemanticInteractionContext.lua`;
- `PNC_SemanticInteractionArbitration.lua`;
- `PNC_SemanticInteractionPlan.lua`.

`PNC_SemanticInteractionDirector.lua` is now the lifecycle/orchestration root rather than a
second parser/predicate/context/response subsystem. The rejected
`PNC_SemanticDialogueDirector.lua` / `PNC.Semantics.DialogueDirector` identity
has been removed rather than retained as a compatibility shim.

## R5 — ACCEPTED: typed stimuli + normalized providers/adapters

Added bounded typed stimuli in
`PNC_SemanticInteractionStimulus.lua`, including HUMAN_UTTERANCE,
NPC_SEMANTIC_ACT, EMOTE, AMBIENT_SOCIAL_OPPORTUNITY, WORLD_EVENT,
FACTION_EVENT, TASK_EVENT, DANGER_CHANGED, actor join/leave, and witnessed
death.

Added `PNC_SemanticInteractionProviders.lua` with normalized ActorSnapshot,
RelationshipSnapshot, WorldSnapshot, KnowledgeSnapshot and provider provenance.

Current authored predicates use generic semantic paths:

- `stimulus.semantic.*`;
- `actor.disposition.*`;
- `actor.condition.*`;
- `relationship.*`;
- `world.*`;
- `scene.*`;
- `history.*`;
- `beat.*`.

They no longer depend on Project-Hoomans-specific `npcPersonality`,
`dialogueSituation`, raw `ir.*`, or prototype `director.*` paths.

A synthetic third-party adapter with unrelated backing fields was verified to
project capabilities/disposition/condition, relationship, and grounded
knowledge into the same contract. Explicit false remains false; missing fields
remain unknown.

## R6 — ACCEPTED: pragmatic resolver + one-shot behaviors + generic stimulus entry

Added `PNC_SemanticPragmaticResolver.lua`.

It resolves an already-semantic stimulus against bounded interaction state:

- active/suspended flows;
- pending follow-up/agenda;
- current topic;
- bounded recent semantic acts;
- grounded fact IDs.

It never parses text and never includes raw transcript text in its recent-act
projection.

Real-worker proof: `hello` opens the greeting flow; subsequent `yes` parses
as generic `ACCEPT`, while the pragmatic frame resolves topic/subject to
`greeting` and `replyTo` to flow `greeting`, node `await_thanks`.

Behavior schema is now output-agnostic:

```text
act
mode = beat | one_shot
stimuli[]
requiredCapabilities[]
outputs:
  speech?
  emote?
  gameplayIntent?
when
baseRelevance
modifiers[]
```

Speech dialogue/content identity exists only under `outputs.speech`.

Added canonical one-shot `behavior.acknowledge_thanks`. Direct `thanks`
selects it without entering a beat while the ordinary `semantic.thanks`
response authority remains intact.

The director now exposes `PreviewStimulus`; human-text `Preview(ir,...)` is
only a HUMAN_UTTERANCE adapter.

Harness `INTERACTION_PREVIEW` proves an `NPC_SEMANTIC_ACT` can trigger the
same one-shot behavior directly with no NLU, no recorded turn, and no gameplay
mutation.

### R4–R6 validation

Latest full recovery pass:

- Python: **28 tests passed**;
- Lua: **6/6 focused suites passed**;
- two-pass Conversation generation: **byte-identical**;
- no `Conversation/Director.json`;
- no generated Director response module;
- `git diff --check`: clean.

## R7 — ACCEPTED: event-driven indexing, bounded scenes, and LOD

Beat definitions now carry explicit stimulus bindings. The canonical
Conversation Registry plus disposable draft overlay builds deterministic indexes
for:

- inactive beat entry by stimulus;
- one-shot behavior candidates by stimulus.

`PreviewStimulus` evaluates only the indexed inactive beat set for the current
stimulus. An already-active beat may still evaluate its own maintain/exit rules.

Bounded decision metrics expose:

- total/effective catalog sizes;
- indexed beat/one-shot candidate IDs;
- candidates actually evaluated;
- behavior candidates evaluated;
- predicate trace rows;
- whether an active beat was already present.

Added `PNC_SemanticInteractionScheduler.lua` with explicit scene limits and
simulation LOD:

- player/full;
- nearby/perceived;
- nearby/unperceived semantic-only;
- distant suppression for flavor-only opportunities.

A synthetic load test registered twenty unrelated WORLD_EVENT beats and ten
WORLD_EVENT one-shot behaviors, then proved a HUMAN_UTTERANCE still considers
only its human-stimulus index. Five hundred distant flavor opportunities caused
zero director evaluations.

## R8 — ACCEPTED: NPC scenes, multi-participant interaction, and shared outputs

Added bounded semantic scene orchestration in
`PNC_SemanticInteractionScene.lua`.

Verified:

- 2-NPC semantic interaction without reparsing generated text;
- semantic memory disclosure with grounded fact IDs;
- different responder state selecting different behaviors;
- speech-disabled actor participation through non-speech outputs;
- the same selected behavior driving speech + emote + ambient flavor;
- grounded news/event knowledge gates;
- rejection of fabricated/unknown facts and world events;
- 3-participant targeted turns without pairwise sub-scene creation;
- active argument interruption by a grounded danger event;
- nearby/unperceived semantic-only processing with no speech/emote/flavor
  realization;
- bounded semantic history with no rendered transcript persistence.

### R0–R8 validation

Latest combined pass:

- Python: **28 tests passed**;
- Lua: **6/6 focused suites passed**;
- scheduler/provider/scene smoke tests: green;
- Conversation generation: **90 artifacts byte-identical across two passes**;
- `git diff --check`: clean.

## R9 — ACCEPTED: integrated Semantic Lab workbench

The old standalone Beat Studio identity has been removed.

Developer Tools now exposes **Interaction Modules** for stateful situations, typed stimuli, predicates, reusable behaviors, capability requirements, output references, disposable worker overlays, and effect-free structural promotion.

Wording is not editable there. Speech/flavor outputs link directly to their canonical `contentTemplateID` in the ordinary Dialogue Content editor. Selecting a situation candidate can jump to its behavior structure, then into referenced Dialogue Content.

The workbench uses the recovered interaction schema, including `stimuli[]` and generic `stimulus.* / scene.* / beat.*` predicates. Its Python implementation is split into a small layout root plus catalog, draft, behavior, and pure-model providers rather than one large pane.

Simulation now exposes an **Interactions** trace showing typed stimulus/source, pragmatic topic/subject/reply-to, provider provenance, behavior source, selected situation/behavior, InteractionPlan outputs/content identity, response lineage, and bounded candidate/predicate metrics.

Prototype compatibility aliases were removed rather than shipped: no `PNC.Semantics.DialogueDirector`, no `PNC_SemanticDialogueDirector.lua`, no `BeatEditor` worker module, no `beat_editor` UI package/app alias, and no `director_definition_*` authoring-service wrappers.

### Final R0–R9 developer acceptance

Latest exact-tree validation:

- pragmatic/recovery Python tests: **32/32 passed**;
- focused Lua suites: **6/6 passed**;
- real Tk organization/consolidation tests: **7/7 passed** using system Python;
- canonical Conversation source unchanged across compiler runs;
- generated Conversation artifacts: **90 byte-identical artifacts** across two consecutive builds;
- new/modified Lua syntax: clean;
- Python compilation: clean (apart from an unrelated vendored-pip warning);
- rejected prototype runtime/name scan: clean;
- `git diff --check`: clean.

Developer-side R0–R9 is complete. The remaining acceptance gate is the user-owned native Project Zomboid live test. Do not publish to Workshop and do not launch native PZ on the user's behalf unless explicitly reassigned.

## Stop conditions

Under autonomous implementation, stop early only for:

- unsafe concurrent worktree ownership;
- irreconcilable external dependency;
- an architecture choice that genuinely requires user direction;
- completion of all R9 developer gates.

Do not stop merely because one recovery phase or example interaction works.

## Safety

- no new branch;
- no push without explicit authorization;
- no Workshop publication;
- no native PZ launch for ordinary developer acceptance;
- no source-save mutation;
- no root `AGENTS.md` goal-state edits;
- no hand-editing generated artifacts.
