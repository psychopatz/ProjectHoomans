# Audit — Pragmatic Dialogue Beat Director

**Audited ProjectHoomans checkpoint:** `6fa471dec0fc1caec2d3b4871f56d4b102ae0e6f` on existing `main`.

This audit is source/harness evidence. It is not native Project Zomboid live
acceptance.

## Verified foundation

### Production flow architecture

`PNC_SemanticDialogueFlowRegistry.lua` is a bounded data-only registry.
Its runtime owns validation-backed `Register`, generated replacement, lookup,
list, revision tracking, reset, and frame matching.

Current authored flows include bounded examples such as:

- `greeting`;
- `identity`;
- `wellbeing`.

They demonstrate triggers, accepted frames, response pools, branch offers,
terminal states, suspension, cancellation, and slot capture.

### Existing live authoring seam

`tools/semantic_harness/lua/worker/FlowEditor.lua` already:

- reads the production Flow Registry;
- exposes production policy, semantic, response-pool, fact/event/capability
  catalogs;
- calls the real `Registry.Validate`;
- worker-registers a valid draft through the real `Registry.Register`;
- keeps the registration disposable and worker-local.

Existing tests prove a new draft flow can be validated, registered, and then
selected by a real Lua-worker conversation turn.

The Semantic Lab README explicitly defines the Flow Editor as an authoring
surface over production Lua rather than a second Python flow engine.

### Existing observability

The Interaction Explorer is built from the live worker catalog and already
projects policy branches, triggers, flows, capabilities, generated definitions,
response pools, concepts, and speech acts.

Worker turn observations already include IR/candidates, response, active flow
state, translation, and side effects. This is the correct seam to extend with
beat/director evidence.

### Existing response composition

`PNC_SemanticDialogueResponsePlan.lua` already provides a bounded,
validated dialogue-act plan with:

- dialogue act;
- topic;
- grounded fact references;
- uncertainty;
- tone/personality style;
- bounded turns/segments/offers;
- composition and rendering support.

The beat/director system should produce or influence this existing plan rather
than own final prose.

### Existing compiler/translation authority

The current Unified Semantic Dialogue Authority job has established:

```text
tools/semantic_harness/codebuilder/sources/conversation/
    content/
    patterns/
    flows/
    ui/
    manifest.json
        ↓
Conversation CodeBuilder
        ↓
generated runtime shards
generated Conversation translation bundles
generated manifests/indexes/fingerprints
```

EN is the required fallback. Additional locales are data-driven. Generated
artifacts are downstream-only.

## Verified current product gap

The current runtime has no first-class production concept corresponding to a
social/dramatic **beat** that spans turns and biases reaction selection.

There is no verified production:

- `DialogueBeatRegistry`;
- `DialogueDirector` with beat arbitration;
- beat/behavior candidate explanation contract;
- active-beat timeline;
- Beat Studio draft editor;
- beat scenario matrix;
- beat draft preview/register protocol;
- canonical compiler source type for beats/behaviors.

Current flows model bounded conversational obligations well, but a flow such as
identity or wellbeing is not the same thing as an argument, reconciliation,
suspicious first contact, grief withdrawal, or other cross-turn social
situation.

## Important parity/regression signal

The repository contains tests asserting that recognized hostile language routes
to `HOSTILE_REMARK_RECEIVED` and must not use the generic clarification
response. The user-observed Semantic Lab trace classified a typoed hostile
utterance as `HOSTILE_REMARK` with high confidence but displayed generic
clarification.

P0 must reproduce and explain that path through the current real worker before
adding director intelligence. Recognized semantic meaning being discarded by a
later layer is a parity bug, not a vocabulary problem.

## Missing compiler/string contract

The new system must not introduce manually maintained Lua strings for beat
labels, behavior labels, NPC reactions, suggestions, or response text.

The existing modular Conversation compiler is the correct authority. This job
may extend the manifest/schema with cohesive `beats` and `behaviors` source
shards if that is the cleanest implementation, while keeping actual wording in
Dialogue Content records and generating translation keys/bundles mechanically.

Do not create a separate beat translation pipeline.

## Constraints

- reuse PsychopatzCore NLU/candidates and existing Project Hoomans semantic
  context/flows/ResponsePlan;
- no second Python decision engine;
- no arbitrary runtime JSON interpreter;
- no direct beat mutation of relationship/inventory/task/world state;
- no hardcoded EN/TL locale list;
- no generated-file hand edits;
- no per-NPC/per-tick global beat scans;
- no native PZ launch or Workshop publication for developer acceptance.
