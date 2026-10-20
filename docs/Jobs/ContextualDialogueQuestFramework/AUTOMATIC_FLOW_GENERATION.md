# Automatic Production Flow Generation — current mandatory phase contract

**Status:** NEW / NOT IMPLEMENTED at branch-source baseline `f0b6e41b90b0`. Central user requirement: **generate all supported registered Project Hoomans semantic NLP flows THROUGH Semantic Lab**, including production-action lifecycle, rather than hand authoring one definition per action or attaching a recognition-only trigger.

## Inventory before generation

A discoverer aggregates **public registered** data, NOT parses private Lua files for guessed callables:
- Core registered intent/action/subject/pattern frames and safe reviewed synonym/example sources.
- `PNC.Semantics.CapabilityCatalog`, companion command definitions, semantic TaskAdapter and gift workflow descriptors; source owner, transport, binding ID, normalized request and recognized vs actually dispatchable.
- Dialogue response/flow catalogs including weather/greeting/wellbeing, typed Conversation Blocks facts/gates, registered engine observations/events.
- Available authoring specs, overlays, translations, source manifest and legacy handwritten definitions.
- Future registered quests and memory/social providers when their contracts are real.

Build a stable **coverage manifest** with one row per unique capability/flow: `id, kind, owner, frame(s), template, outputFlowID, supportStatus, missingFields[], source, existingFlow?, generated?, compileErrors[], lastWorkerResult`. Status must distinguish `GENERATED`, `ELIGIBLE`, `METADATA_INCOMPLETE`, `RECOGNITION_ONLY`, `MANUAL_LEGACY`, `UNSUPPORTED_WORKFLOW`, `CONFLICT`. Display counts and denominators; `generated/supported` must not hide unsupported ones. No silent omission. Engine events are NOT assumed to be executable capabilities.

## Reusable workflow templates (not per-action special cases)

1. **simple_command**: semantic trigger → resolve exact NPC/group target → preflight permission/gates → single allowed dispatch request through existing companion command adapter → `rejected`, `queued/admitted`, `failed`, `completed` where observable → localized response/optional wait for result. Ex: FOLLOW, STAY, GO HOME, CAMP if descriptor compatible.
2. **parameterized_task**: trigger → typed location/item/target slot resolution → clarification if missing → approved task adapter → admission/active/progress/failure results → response. Ex: WAIT_AT, FETCH, give/consume when supported.
3. **multi_stage_transaction**: trigger → pending offer/selection → disambiguate item+recipient → consent lease → existing gift/inventory transfer → authoritative inventory/relationship result → response; idempotency/reconnect. Ex: GIFT. Never send an inventory transaction straight from parsing alone.
4. **response_only / context_gate**: trigger/topic → pure weather/time/need/social/personality/memory/quest facts → PASS/FAIL/UNKNOWN → response and topic transition, no gameplay side effects. Existing legacy flows may remain manual until safe canonical import.
5. **quest_command** (later): request/offer/accept/query via server-owned Quest service; no fabricated quest instance. Only eligible once quest contract exists.

Templates are generic schema-driven compositions, never one hard-coded `if action=="FOLLOW"` source writer per capability. A specialization may be required for genuinely different workflows (gift vs companion order), but remains encapsulated in a reusable *registered workflow type*, not duplicated per action.

## Typed metadata the generator must require

`capabilityId`, `owner`, `workflowKind/templateVersion`, `triggerFrames` and/or registered pattern references, `requiredSlots`, `optionalSlots`, `targetScope`, `allowlistedDispatcherRoute`, `permission/gate IDs`, `outcomeMapping` (`rejected/queued/admitted/completed/failed`), `responsePoolKeys` or reviewed fallback, `translationOwner`, `contractVersion`.

If public registry lacks a field, *extend the owning published descriptor* conservatively or classify `METADATA_INCOMPLETE`. Do not infer consent, translations, personality, item types, unknown success text, or imperative aliases from arbitrary string names. Generated action node refers to **registered binding ID only**, never raw executable Lua/Python code.

## Production action-flow state machine

Introduce a **versioned** flow node/phase contract (e.g. `condition`, `resolve_slots`, `capability_request`, `await_result`, `response`; actual names designed after registry audit). Validate schema/edge reachability, target/ref scope, permission, bounded concurrency and allowed outcomes. Define effects once in the existing dispatcher; flow commit/response arbitration must not dispatch twice.

Positive result belongs to the correct stage: queued != completed. Async request IDs/correlations must select the correct NPC/player/flow pending node; retries and duplicate results are idempotent. Disabled/unsupported metadata cannot generate executable action nodes. Existing legacy routes continue safely until migrated with measured parity.

**Suggested generated simple-command graph:**
```text
recognized trigger
   → resolve actor/addressee
   → permission/condition gate
   ├─ NO / UNKNOWN → deny or clarify
   └─ YES → capability_request(<registered binding ID>)
             ├─ rejected → denied response
             ├─ admitted/queued → queued response
             ├─ failed → failure response
             └─ completed (if observable) → completion response
```

## Source round-trip and UX

A source-of-truth **typed authoring spec** is canonically edited in Semantic Lab via graph and supported code view; user changes update the spec, not arbitrary generated Lua. `Generate Missing Flows`, `Regenerate Selected`, `Validate All`, and `Show Coverage` should use the same generator core. Preview no writes; approve source diff before generation; only generate into correct existing Build 42.20/common paths and explicit Lua/EN/TL manifests; re-run worker after generating. Stable IDs/layout metadata, preserved custom authoring overlays, regeneration conflict handling, no overwriting handwritten flow modules without explicit migration.

## ONE next implementation chunk G0A

**Build one generic `simple_command` generator whose input is discovered/validated registered metadata**, not an enumerated list of FOLLOW-specific cases; discover all compatible simple companion-command capabilities (at minimum independently prove FOLLOW and STAY), output a capability coverage report and complete typed production flow(s) for the eligible set. Integrate the minimum versioned action-flow schema + worker observation needed so actual real-Lua dispatch/denial/result transitions are represented by generated production flows, without double-dispatch and without moving game authority.

Tests: generated FOLLOW+STAY are both loaded after fresh worker restart, share template logic, expose real bound handler/flow state and queued/denied reply, no `flow_response_eligible` suppression, preview side-effect free, legacy commands unaffected, negated/question/unauthorized/unknown safe. Non-simple capabilities (WAIT_AT and GIFT) should be inventoried with explicit deferred reason rather than falsely generated. Check EN/TL, determinism, manifest/load path, Kahlua and runtime flow-count constraints. Only after G0A accepted start G0B parameterized task template, then G0C gift template.

This is a small but real product slice: **two independently generated production action flows from one generic template + complete runtime behavior**, not just a catalog display. No silent "done" if only a new diagram or cloned handwritten flow is produced.

## Risks / limits

Registry currently defaults to 32 flows/32 nodes per flow; bulk population may hit limits. Measure/plan safe indexing/sharding/registry capacity *without* blanket increasing limits and runtime CPU. Language generation must be reviewed, precise and collision-checked; no guarantee of arbitrary natural language. The harness is the developer validation environment, not a native game simulator. Native PZ/Workshop remain user-owned.
