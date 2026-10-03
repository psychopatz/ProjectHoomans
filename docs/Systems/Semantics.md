# Semantics System: Architecture and Incremental Plan

Status: paused at the Conversation relationship boundary on 2026-09-20. This
worktree's current refactor plan is cut here; remaining slices are deferred to
a separately scoped task. The whole Semantics subsystem and live Project
Zomboid acceptance checks are not complete.

## Current architecture

The client conversation input enters through
`PNC_SemanticDialogueInput.Input.Submit` and the lifecycle spoke's
`Internal.SubmitSingle`. It trims and bounds text, builds a client context, and
asks the `PsychopatzCore.Semantics.DialogueRouter` for a preview. The shared
semantic parser produces validated IR; the policy chooses a deterministic
branch or an optional LLM fallback; the local response resolver formats a
response from that IR and read-only context.

Client Conversation receives these services through the
`PNC_ConversationSemantics` registration adapter. The root client composition
loads the semantic Conversation runtime before PBrainZ's UI and bridge
integrations, keeping the Conversation package independent of those adapters.

The LLM is only submitted for a preview routed to `llm_fallback`. A missing or
rejected provider request becomes a deterministic clarification. An accepted
request keeps a session-scoped pending record until the provider result is
applied. The input UI is disabled during that interval, and the lifecycle also
rejects direct duplicate submissions.

On a completed local turn, the client presentation adapter appends the player
input and the action adapter handles response-only, inventory, gift, command,
and task paths. Task requests cross the client/server boundary through
`Client.RequestSemanticTask`. The server task service checks server authority,
normalizes the request, validates the conversation lease or companion command
permission, validates it with the action handler, then submits it. Semantic
action plans are normalized and started by the server plan service; live
runtime context is kept outside the persisted plan.

## Proposed module boundaries and contracts

| Boundary | Owns | Stable contract |
| --- | --- | --- |
| Core parsing and catalog | Normalized text, concepts, patterns, IR validation | Keep the current IR schema at version 1; keep vocabulary registration order and pattern IDs stable. |
| Policy | Confidence, unresolved-reference, safety, and branch decisions | A validated IR and bounded context produce a decision and optional action intent; policy never executes gameplay. |
| Local response | Templates and deterministic response data | `{ templateID, fallback, args }`; read-only access to the world snapshot. |
| Client input lifecycle | Input validation, preview, optional provider handoff, local completion | Preserve `Input.Submit`, router preview/process behavior, and the pending-result lifecycle. |
| Client adapters | Presentation, command/task transport, inventory and gift requests | Send bounded request contracts; client observations are hints, not authority. |
| Server task and plan services | Authority, authorization, validation, plan lifecycle, effects | Normalize requests, validate leases and handler constraints, and own plan/effect state. |
| Diagnostics | Optional trace and console output | Keep `ProjectHoomans.SemanticDialogueAudit` disabled by default, bounded, sanitized, and free of retained live game objects. |

MarketSense remains the item-classification authority. Parser and orchestration
code must not grow a second item taxonomy. The LLM remains an optional fallback;
known deterministic paths must not wait for it.

## State, authority, and resource constraints

- Dialogue history and identity obligations stay compact and bounded. Pending
  provider state is temporary session state and is retired after delivery or
  rejection; it does not belong in persisted semantic identity data.
- The client can parse, preview, present, and attach bounded observations. The
  server decides whether a task request is authorized and owns gameplay plans
  and effects.
- Keep parser, policy, and response formatting deterministic and free of game
  side effects. Keep world lookups in context or adapter modules.
- Avoid additional world scans, repeated entity scans, or provider/network
  calls on known deterministic input. Add caching only with measured need and
  explicit invalidation.
- Diagnostics currently return before inspecting the payload when disabled;
  when enabled they sanitize values and cap string length, recursion depth,
  keys, and console output.

## Migration order

Completed in this worktree:

1. Split semantic catalog registrations into role modules while keeping the
   catalog root as the compatibility entry point.
2. Separate gift selection and transfer stages in client input dispatch.
3. Move subject-specific question responses into a pure local-response spoke.
4. Move successful intent-to-branch selection into a pure policy spoke.
5. Extract the optional provider fallback path from input lifecycle and reject
   duplicate submissions while a provider turn is pending.
6. Move client integrations out of the Conversation runtime root and load them
   through the top-level client composition after the runtime is ready. Load
   the voice adapter first so authored and resolved messages can use Core's
   optional voice stream.
7. Move PNC UI module loading out of the Conversation package and into the
   top-level client composition. Keep the palette, faction presentation, and
   relationship graph ahead of Conversation; register its context provider
   after Conversation has been composed.
8. Separate semantic task-result correlation and pending state from reply
   formatting and conversation message delivery. Keep the result payload and
   message metadata unchanged.
9. Move client context projection and bounded cognition/identity request
   shaping out of the dialogue-input context/router module while preserving
   its `Input.Internal` contracts and original dependency load order.
10. Separate client world-target matching, local origin lookup, and optional
    hint diagnostics from the resolver coordinator. Keep observation scanning
    bounded and preserve the primitive client-hint contract and server checks.
11. Move semantic task dispatch correlation into its own spoke and isolate
    active-view selection plus bounded unmatched-result caching. Preserve
    provisional registration before transport and the existing task-result
    contract.
12. Split inventory result formatting, context projection, unmatched-result
    routing, and conversation delivery from the inventory response coordinator.
    Preserve `Input.ReceiveInventoryQueryResult`, response fields, bounded item
    mentions, and group delivery metadata.
13. Extract room and campfire primitive-hint projection from the camp-site
    resolver coordinator. Preserve cache timing, distance scoring, fallback
    reasons, and the server-validated client hint schema.
14. Separate deterministic reply and camp-acknowledgment payload formatting
    from conversation queue delivery. Preserve the `Input.Internal` presentation
    contracts and response keys.
15. Move gift selector UI handoff, selector context flags, and gift response
    payload construction into a client presentation adapter. Keep matching,
    request lifecycle, and inventory transfer in the gift coordinator.
16. Move camp task site projection, location wording, and camp-specific failure
    responses into a pure response spoke. Preserve the existing
    `TaskResponses` and `Input.Internal` entry points.
17. Separate identity-checked semantic entity candidate construction from
    general context projection. Preserve explicit-first de-duplication,
    known-identity gates, and the ambient snapshot candidate cap.
18. Separate authoritative gift-transfer mention projection from
    conversation-context state writes. Preserve MarketSense classification,
    item bounds, and the public `GiftContext.RecordTransfer` contract.
19. Separate conversation-local state and router lifecycle from the read-only
    context coordinator. Preserve `Input.Internal.RouterFor`, bounded state,
    and authored topic initialization for fresh or partially initialized
    sessions.
20. Separate server-authoritative semantic identity admission, relationship
    policy and mutation, response presentation, and result delivery. Preserve
    lease validation, event IDs, effect values, and the result payload schema;
    fail closed when authority or mutation services are unavailable.
21. Split the shared camp-site geometry implementation into runtime access,
    room records, room projection, enumeration, selection, and site-membership
    spokes. Keep `PNC.Semantics.CampSiteGeometry`, the established `_Internal`
    hooks, and the old require path as compatibility contracts.
22. Move inventory-query registration, result correlation, and cleanup into a
    shared pending-query lifecycle owner. Bound pending requests and preserve
    registration before transport so synchronous results remain correlatable.
23. Separate relationship-presentation receipt from active conversation
    rebuilding with a registered refresh callback. Preserve the public
    `Conversation.ReceiveIdentityPresentation` entry point and panel fallback.
24. Split conversation definition context projection, menu construction,
    extension-part assembly, and lifecycle handling into focused modules.
    Preserve the original definition require path and public Conversation API.
25. Move the conversation relationship adapter under its normalized
    `ConversationRelationship` entry, with separate resolution, snapshot,
    receipt, panel-control, and debug-action roles. Preserve the
    `PNC.Conversation.Relationship` table and server-authored presentation flow.

Deferred work (outside the current scope):

1. Re-scan the remaining Conversation, UI, and integration dependency cycles;
   take the next slice only where it reduces semantic coupling.
2. Continue decomposing client action dispatch only where command, task,
   inventory, gift, or presentation ownership is actually mixed.
3. Split remaining large catalog registrars only when their data belongs to
   distinct cohesive pattern families; preserve registration order and
   precedence.
4. Profile the deterministic and world-context paths before adding caches or
   other performance changes.

## Compatibility, testing, risks, and rollback

Keep Project Zomboid Kahlua/Lua 5.1 syntax and existing `require` load order.
Do not change the IR, request, response, action-plan, save, or network schemas
as part of these structural slices. Use real production contracts in compact
smoke tests for normal behavior, invalid input, fallback/rejection, pending
state, duplicate requests, server authorization, and module integration.
After each slice, run focused tests, the semantic suite, the full suite where
practical, PZ compatibility checks, architecture scan/diff, and diff
whitespace validation.

The main risks are Lua module load order, pattern precedence changes, duplicate
or late provider results, and mistakenly treating client context as
authoritative. Keep rollback source-only at each extracted module boundary:
restore the previous dispatch block or catalog registration body without
migrating saved or network data.

Acceptance requires no new architecture findings, passing semantic and
affected smoke tests, Kahlua-clean production code, unchanged IR and network
contracts, deterministic operation with the LLM disabled, and single-player
plus multiplayer verification that only server-authorized requests create
gameplay plans or effects.

## Verification checkpoint: 2026-09-19

- Architecture audit: Project Semantics health 57.5/100; overall production
  health 76.0/100. These are heuristic scores with incomplete coverage, not
  correctness proofs. The current Semantics scan reports six large-function
  findings and nine subsystem dependency cycles.
- Semantic tests: 61/61 pass. The full suite executes 721 tests and currently
  has the same three baseline failures: two inventory command-registration
  harness errors at `PNC_ClientInventoryCommands.lua:434`, and a constants
  count expectation of 563 versus 565 actual. No new suite failures appeared.
- PZ Kahlua checks on changed production files report zero warnings and errors.
- The live console currently has no references to the changed semantic input
  or policy modules and no semantic-audit events. Live single-player and
  multiplayer dialogue verification is still required.

## Verification checkpoint: 2026-09-19 (Conversation integration boundary)

- Moved PBrainZ and voice integration loading to the top-level client
  Conversation composition. The voice adapter loads before Conversation;
  PBrainZ bridge and input adapters load after Conversation and its semantic
  adapter.
- The prior `Conversation -> Integrations -> Conversation` finding
  (`ARC-3C1261F03D`) is resolved. The current audit still reports
  `Conversation -> UI -> Conversation`,
  `Conversation -> UI -> Networking -> Conversation`, and a composition/UI
  cycle. These need separate ownership traces.
- The architecture scan now reports production health 79.5/100, 74.1% coverage,
  59.8% confidence, and 221 production findings. The audit diff against the
  previous worktree scan records 19 resolved and 11 introduced findings across
  the whole worktree. Other files changed during the same interval, so the
  overall score and finding counts are not attributed to this slice.
- Focused bootstrap, PBrainZ inline, semantic input, and Conversation semantics
  adapter tests pass (4/4). The full suite remains at the recorded 3/722
  failures: the constants count expectation (563 vs 565) and two inventory
  command-registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- Kahlua checks on the four changed runtime Lua files report zero warnings and
  errors. `git diff --check` is clean.
- The Project Zomboid game is not running in this workspace, so live dialogue
  and multiplayer authority checks remain open. For a live deterministic-path
  check, open a conversation with one nearby NPC, enter `hello there`, and
  confirm the player line and local NPC reply appear with the LLM provider
  unavailable. With `ProjectHoomans.SemanticDialogueAudit` enabled, expect
  `semantic_audit event=semantic.input.received` followed by
  `semantic_audit event=semantic_input_local`; the latter should include the
  `GREET` intent, `pnc.social.greet` pattern, and `providerUsed=false`. With
  diagnostics disabled, no semantic audit line is expected.

## Verification checkpoint: 2026-09-19 (Conversation UI composition boundary)

- Moved Conversation's four direct `PNC/UI` requires to the top-level client
  Conversation composition. Presentation dependencies load before Conversation;
  the Conversation context provider registers after it. The Conversation
  package no longer statically loads PNC UI modules.
- The bootstrap smoke test now asserts both the package boundary and the
  runtime dependency order. The scoped import search found zero direct
  `require "PNC/UI/"` references under the Conversation package. The graph
  scope had no recorded coverage gaps; this remains a best-effort signal.
- The architecture scan reports Conversation health 81.0/100 and no current
  Conversation dependency-cycle finding. The full scan reports production
  health 80.4/100 and 216 findings; its stored diff includes changes elsewhere
  in the worktree. A remaining client Composition/Integrations/UI cycle points
  through the general client composition and nameplate/inventory modules, not
  the Conversation composition changed here.
- Focused Conversation/UI and bootstrap tests pass (6/6). The full suite remains
  at the same 3/722 baseline failures: the constants count expectation (563 vs
  565) and two inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- Kahlua checks on the five changed runtime Lua files report zero warnings and
  errors. `git diff --check` is clean. The Project Zomboid game is not running,
  so live single-player and multiplayer dialogue checks remain open.

## Verification checkpoint: 2026-09-19 (Task-result presentation boundary)

- Split the 3,777-token task-result module into request/result lifecycle,
  deterministic reply formatting, and conversation message delivery modules.
  Their measured sizes are 1,423, 1,937, and 683 tokens. The existing
  `Input.Internal` camp-formatting seam remains available to immediate
  acknowledgments; IR, request, response, action-plan, and network contracts are
  unchanged.
- The task-result smoke test confirms accepted requests remain pending until
  completion, server camp details override client hints, and grouped results
  route through the primary session with speaker and turn metadata.
- Focused task, gift, group, world-hint, local-route, and input tests pass
  (6/6). The full suite reports the same three failures in 723 tests: the
  constants count expectation (563 vs 565) and two inventory command
  registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- Kahlua checks on all three extracted task modules report zero warnings and
  errors. Architecture totals are unchanged from the previous scan. Live PZ
  single-player and multiplayer verification remains open because no game
  process is running.

## Verification checkpoint: 2026-09-19 (Dialogue context and request boundaries)

- Split context projection and semantic request preparation/dispatch from the
  dialogue-input router module. `Input.Internal.ShallowContext`, provider
  status, cognition requests, and identity request methods remain available
  with their existing signatures.
- Preserved service initialization order: world context, reference resolver,
  entity resolver, facts, situation, then fact-source registration. The
  context projection receives those services after they load.
- The affected client files are 1,813, 1,695, and 1,096 tokens. Five focused
  dialogue, local-route, identity, world-context, and group tests pass; Kahlua
  reports no warnings or errors for the three runtime modules.
- The full suite remains at the same 3/723 baseline failures: the constants
  count expectation (563 vs 565) and two inventory command registration
  harness errors at `PNC_ClientInventoryCommands.lua:434`.
- The current whole-PNC architecture scan reports health 64.8/100 with 63.4%
  coverage and 53.1% confidence, aggregating Semantics with all PNC modules.
  Concurrent worktree changes and the scan's coarse subsystem grouping prevent
  attribution of its finding-count change to this slice. The code graph still
  reflects generation `2026-09-19T15:22:09Z`; this slice's changed files were
  read directly after coverage marked their metadata stale. A full graph
  refresh attempt failed in the index pipeline and needs a retry.
- Live PZ single-player and multiplayer checks remain open because no game
  process is running.

## Verification checkpoint: 2026-09-19 (World-target hint boundaries)

- Split the client world-target hint module into a resolver coordinator, pure
  target/object matcher, client origin adapter, and optional diagnostics
  adapter. The resolver still delegates loaded-cell observation to the shared
  observation cache and returns the same primitive-only hint contract.
- The three world-target smoke tests pass, covering exact and misspelled target
  matching, cache reuse, unknown vocabulary, and server-side validation of
  client hints. Kahlua reports no warnings or errors in the four runtime
  modules.
- The matcher, resolver, origin adapter, and diagnostics adapter measure
  1,780, 1,460, 752, and 451 tokens. The full suite still reports the same
  three baseline failures in 723 tests.
- The current whole-PNC architecture scan remains at 64.8/100 health, 63.4%
  coverage, 53.1% confidence, and 193 production findings. This scan groups
  Semantics with the broader PNC subsystem, so the totals do not isolate this
  change. The graph index predates these files; coverage marked the changed
  source metadata stale and the full refresh attempt failed in the indexing
  pipeline. The affected source was read directly.
- Live single-player and multiplayer verification remains open because no PZ
  game process is running.

## Verification checkpoint: 2026-09-20 (Dialogue action context and hint boundaries)

- Split client action-context construction and client target-hint enrichment
  out of the dialogue action dispatcher. `Input.Internal.ActionContext` keeps
  the same function contract; action dispatch still enriches camp-site targets
  before world targets and reuses the bounded camp-site hint in command context.
- The action dispatcher, context builder, and target-hint module measure
  1,727, 722, and 1,097 tokens. The six affected dialogue, gift, task-result,
  group, world-target, and camp-site smoke tests pass.
- The full suite reports the same three baseline failures in 723 tests: the
  constants count expectation (563 vs 565) and two inventory command
  registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
  Kahlua checks report zero warnings or errors across the ten affected
  semantic runtime modules, and all ten are under the 2,000-token threshold.
- The code graph remains at generation `2026-09-19T15:22:09Z`; coverage marks
  changed modules stale or untracked, so their sources were read directly. The
  test files have no recorded coverage issues; `tests/__pycache__` remains an
  excluded scope. A full graph refresh attempt failed in the index pipeline.
  `git diff --check` is clean.
- Live single-player and multiplayer verification remains open because no PZ
  game process is running.

## Verification checkpoint: 2026-09-20 (Dialogue input trace boundary)

- Moved semantic event auditing and turn-trace payload construction into a
  dialogue-input trace adapter. The input composition explicitly loads it
  before the lifecycle spoke; isolated test loaders now load the adapter before
  the lifecycle module as well.
- The lifecycle module is 1,924 tokens and the trace adapter is 599 tokens.
  Seven focused dialogue input, local route, inventory, identity, group,
  context, and provider delivery tests pass. Kahlua reports zero warnings and
  errors for the root, lifecycle, and trace runtime modules.
- The full suite remains at the same three failures in 723 tests: the
  constants count expectation (563 vs 565) and two inventory command
  registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
  Both extracted modules are under the 2,000-token threshold, and
  `git diff --check` is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`. Coverage marks the
  edited lifecycle/root and new trace adapter stale or untracked; those sources
  were read directly. The three isolated tests now load the new module in their
  explicit setup. `tests/__pycache__` is the only excluded test scope.
- Live single-player and multiplayer verification remains open because no PZ
  game process is running.

## Verification checkpoint: 2026-09-20 (World time and weather provider)

- Moved calendar/time projection and climate projection into a dedicated
  environment provider. WorldContext still owns player selection, the shared
  snapshot schema, cache timing, and the injected time-band resolver; the
  existing safe readers are passed through unchanged.
- The semantic suite passes 59/59. The full suite reports the same 3/723
  baseline failures: the constants count expectation (563 vs 565) and two
  inventory command registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`. `pz_verify` reports no hardcoded UI
  strings, Kahlua issues, or token-threshold warnings for the root and provider.
- A directory-wide `pz_verify` token scan flags 11 files above 2,000 estimated
  tokens; the extracted WorldContext root and new provider are both below that
  threshold. This scanner estimates bytes divided by four, so its counts differ
  from the tokenizer used in earlier checkpoints.
- The graph remains at generation `2026-09-19T15:22:09Z`. Coverage marks the
  edited root metadata changed and the provider untracked; both sources were
  read directly. `git diff --check` is clean. Live single-player and
  multiplayer verification remains open because no PZ game process is running.

## Verification checkpoint: 2026-09-20 (World observation cache boundaries)

- Split the shared loaded-cell observer into a cache facade, bounded grid
  scanner, and object-to-primitive projection module. The facade preserves
  `Observe`, `ObserveDetailed`, `Invalidate`, cache keys and TTL, limits,
  primitive observation fields, and the detailed-observation cache tag.
- The semantic suite passes 59/59. The perception-debug, profiler-ModData,
  network-scale, and animation-scene tests pass. The full suite reports the
  same 3/723 baseline failures: constants expected 563 vs 565 and the two
  inventory command registration harness failures at
  `PNC_ClientInventoryCommands.lua:434`. `pz_verify` reports zero UI-string,
  Kahlua, or token-threshold findings for the three modules.
- The architecture scan reports project health 80.4/100, coverage 74.1%, and
  confidence 59.8%; Semantics is 89.2/100 with refactor pressure 23.6. The
  before/after diff has no overall health, coverage, or finding-count change;
  its only finding changes are in the unrelated PresenceSync subsystem. The
  affected-test selector found no tests within its configured dependency
  depth, so selection used the graph trace to the direct semantic, perception,
  profiler, network-scale, and animation consumers.
- The graph remains at generation `2026-09-19T15:22:09Z`. Coverage marks the
  edited facade stale and the scanner/projection modules untracked; those
  sources were read directly. The traced test files have no recorded coverage
  issues. `git diff --check` is clean. Live single-player and multiplayer
  verification remains open because no PZ game process is running.

## Verification checkpoint: 2026-09-20 (Task request/result correlation)

- Moved task dispatch and provisional-to-canonical request correlation into
  `TaskDispatch`. `TaskResultRouting` owns active-conversation selection and
  the bounded cache for unmatched results; `Tasks` handles admission and
  completion results. Dispatch registers the provisional request before the
  adapter call, preserving same-tick response handling.
- The task dispatch/result, local route, and group tests pass (4/4), and the
  semantic suite passes 60/60. The full suite has the same three baseline
  failures in 724 tests: constants expected 563 vs 565 and two inventory
  command-registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded UI strings, Kahlua issues, or files above
  the 2,000-token threshold for Actions, Tasks, TaskDispatch, or
  TaskResultRouting. `git diff --check` is clean. The architecture affected
  selector found no tests within its configured dependency depth; the semantic
  suite and focused task/group tests provide direct coverage.
- The post-slice architecture scan reports PNC health 64.8/100 and 63.4%
  coverage. Whole-project totals are 65.0/100 health and 61.9% coverage; the
  diff against the stored scan reports 219 resolved and 191 introduced
  findings across the worktree. Those aggregate changes span 2,977 parsed
  files and do not isolate this task slice.
- The graph remains at generation `2026-09-19T15:22:09Z`; it does not include
  the new dispatch/routing nodes. Coverage reports no recorded source gaps,
  but marks changed modules stale and new modules untracked, so those files
  were read directly. The graph is a best-effort signal, not completeness
  evidence.
- The Project Zomboid game process is not running. Live single-player and
  multiplayer checks remain open. For the multiplayer check, submit “Can you
  bring me some water?” with a nearby NPC, confirm that server admission and
  the action plan remain authoritative, and verify that an invalid lease is
  rejected with reason `invalid_lease`.

## Verification checkpoint: 2026-09-20 (Inventory response boundaries)

- Kept `Input.ReceiveInventoryQueryResult` as the public result coordinator
  and moved deterministic response formatting, bounded context projection,
  active-view/unmatched-result routing, and group-aware message delivery into
  four focused modules. The unmatched-result cache remains capped at 16; the
  smoke test also confirms returned item mentions remain in dialogue focus.
- Focused inventory, group, task-result, and local-route tests pass (4/4), and
  the semantic suite passes 60/60. The full suite retains the same three
  baseline failures in 724 tests: constants expected 563 vs 565 and two
  inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no Kahlua or token-threshold issues in the five inventory
  modules. It flags one existing fallback literal (`"I have "`) moved
  unchanged into the formatter; translation remains outside this refactor.
  `git diff --check` is clean.
- The affected-test selector found no tests within its configured dependency
  depth. The semantic and focused suites provide direct coverage. The graph
  remains at generation `2026-09-19T15:22:09Z`; it still shows the old
  inventory functions and does not include the new modules. Coverage reports
  no recorded source gaps but marks changed source/test metadata stale or new
  modules untracked, so the edited files were read directly.
- The post-slice scan reports PNC at 64.8/100 health and 63.4% coverage, with
  unchanged whole-project totals from the task checkpoint. Live SP/MP checks
  remain open because no Project Zomboid game process is running. The next
  static hotspot is `PNC_SemanticDialogueInput_Presentation.lua` at about
  2,356 estimated tokens; the documented Conversation/UI cycle review also
  remains open.

## Verification checkpoint: 2026-09-20 (Camp-site hint projection)

- Moved room and campfire hint construction into a projection module. The
  coordinator still normalizes requests, scopes and bounds local lookups,
  caches results, records reasons, and selects fallbacks. Primitive fields,
  distance scoring, 750 ms cache timing, and server validation remain intact.
- Focused client hint, shared camp-site, world-target, companion authority,
  and camp-task tests pass (5/5); the semantic suite passes 61/61. The full
  suite has the same three baseline failures in 725 tests: constants expected
  563 vs 565 and two inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded UI strings, Kahlua issues, or token-threshold
  warnings for the coordinator and projection module. The affected-test
  selector found no tests within its configured dependency depth; focused
  tests exercise both room and campfire projection paths. `git diff --check`
  is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`; it has no projection
  node. Coverage reports no recorded gaps but marks the coordinator changed
  and the projection/test files untracked, so those sources were read directly.
  The post-slice scan keeps PNC at 64.8/100 health and 63.4% coverage; its
  whole-project totals remain 65.0/100 health and 61.9% coverage.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid game process is running. The next file-size hotspot is
  `PNC_SemanticDialogueInput_Lifecycle.lua` at about 2,272 estimated tokens.

## Verification checkpoint: 2026-09-20 (Deterministic response formatting)

- Moved semantic translation-key selection, deterministic response payload
  creation, and camp acknowledgments into a response adapter. The presentation
  spoke still appends player input and queues the response through the existing
  conversation session. `Input.Internal.AppendPlayerInput` and
  `Input.Internal.QueueDeterministicResponse` remain unchanged.
- Focused dialogue-input, task-result, group, and local-route tests pass (4/4);
  the semantic suite passes 61/61. The full suite retains the same three
  baseline failures in 725 tests: constants expected 563 vs 565 and two
  inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded UI strings, Kahlua issues, or token-threshold
  warnings for the presentation coordinator or response adapter. The affected
  selector found no tests within its configured dependency depth; the semantic
  and focused suites cover the response and camp acknowledgment paths.
- The graph remains at generation `2026-09-19T15:22:09Z`; it still shows the
  old local response helpers and has no response-adapter node. Coverage marks
  the changed coordinator stale and the new adapter untracked, so their source
  was read directly. The post-slice architecture diff reports zero score or
  finding changes against the preceding scan; PNC remains at 64.8/100 health
  and 63.4% coverage.
- Live SP/MP checks remain open because no Project Zomboid game process is
  running. The next remaining file-size hotspot is
  `PNC_SemanticDialogueInput_Lifecycle.lua` at about 2,272 estimated tokens.

## Verification checkpoint: 2026-09-20 (Gift selector presentation)

- Moved gift response payload construction, semantic conversation context
  flags, inventory selector opening, and selector audit into
  `PNC_SemanticDialogueInput_GiftPresentation.lua`. The gift coordinator still
  owns local candidate matching, pending request lifecycle, request IDs, and
  the existing inventory transfer contract. The composition loads the adapter
  after action auditing is installed.
- The gift smoke test now checks both selector context flags and the missing
  inventory UI response. The focused gift test passes (1/1) and the semantic
  suite passes 61/61. The full suite retains the same three baseline failures
  in 725 tests: constants expected 563 vs 565 and two inventory command
  registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded strings or Kahlua issues for the changed
  gift modules. The size scan moved `PNC_SemanticDialogueInput_Gifts.lua`
  below 2,000 estimated tokens. `git diff --check` is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`. Coverage marks the
  gift coordinator and test metadata changed and the new adapter untracked, so
  those sources were read directly. The architecture scan remains at 65.0/100
  project health and 61.9% coverage; PNC remains at 64.8/100 and 63.4%.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid game process is running.

## Verification checkpoint: 2026-09-20 (Camp task response projection)

- Moved camp-site detail projection, location phrasing, completed/admitted
  camp responses, and camp-specific failure wording into
  `PNC_SemanticDialogueInput_TaskResponses_Camp.lua`. The `TaskResponses`
  module re-exports its existing methods, and the same functions remain on
  `Input.Internal`. Authoritative result fields still take precedence over
  bounded client hints.
- The task-result smoke test checks completed camp wording, server label
  precedence, and missing-site, missing-room, and missing-campfire responses.
  The focused test passes (1/1) and the semantic suite passes 61/61. The full
  suite retains the same three baseline failures in 725 tests.
- `pz_verify` reports no Kahlua issues for either task response module. The
  Semantics directory has one existing untranslated fallback warning
  (`"I have "` in `PNC_SemanticDialogueInput_InventoryResponses.lua`) and
  three files over the 2,000-token estimate: ContextProjection (2,083),
  Context (2,060), and GiftContext (2,001). `git diff --check` is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`; edited source and
  test metadata is stale and both new modules are untracked, so the touched
  files were read directly. The architecture scan remains at 65.0/100 project
  health, 61.9% coverage, and 192 findings; PNC remains at 64.8/100 and 63.4%.
  The whole-worktree diff against its saved baseline reports one resolved and
  zero introduced findings, with no Semantics files in either set; attribution
  is limited by the other active worktree changes.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid game process is running. The next size hotspots are the semantic
  input context projection and context coordinator.

## Verification checkpoint: 2026-09-20 (Semantic entity candidate projection)

- Moved explicit candidate de-duplication, known conversation NPC/player
  candidates, and identity-verified snapshot candidates into
  `PNC_SemanticDialogueInput_EntityCandidates.lua`. ContextProjection still
  assembles the read-only turn context and passes the candidate list to the
  existing entity resolver index builder. The 64 ambient snapshot candidate
  cap and identity gateway checks are unchanged.
- Added a focused smoke test for duplicate IDs, explicit-candidate precedence,
  verified versus unknown snapshot names, identity callback failure, and the
  64-candidate bound. It passes (1/1); the existing dialogue-input smoke test
  passes (1/1), and the semantic suite passes 62/62. The full suite has the
  same three baseline failures in 726 tests: constants expected 563 vs 565 and
  two inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded strings or Kahlua issues in the new
  candidate module or ContextProjection. The directory token scan now flags
  only Context (2,060) and GiftContext (2,001). `git diff --check` is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`; the current
  ContextProjection, candidate module, and focused test are untracked in that
  index, while Context metadata changed. Those current sources were read
  directly. The architecture scan remains at 65.0/100 project health and
  61.9% coverage, with PNC at 64.8/100 and 63.4%. The whole-worktree diff
  reports one resolved and zero introduced findings; no Semantics files appear
  in either set, and concurrent worktree changes limit attribution.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid process is running. The remaining token hotspots are Context and
  GiftContext; inspect their state and call boundaries before choosing the next
  extraction.

## Verification checkpoint: 2026-09-20 (Gift transfer context projection)

- Moved authoritative gift item-to-mention projection into
  `PNC_SemanticGiftContext_TransferProjection.lua`. `GiftContext.RecordTransfer`
  still validates context availability, writes the bounded turn, and records
  diagnostics. It uses the existing MarketSense adapter for item facts and
  retains the 12-item cap and `RecordTransfer` contract.
- Extended the gift-context smoke test to cover the 12-item limit, pending
  selection fallback, empty-transfer rejection, and direct context recording
  when the DialogueInput adapter is absent. Gift-context and gift-follow-up
  tests pass (2/2); the semantic suite passes 62/62. The full suite has the
  same three baseline failures in 726 tests: constants expected 563 vs 565 and
  two inventory command-registration harness errors at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded strings or Kahlua issues in the coordinator
  or projection module. The Semantics token scan now flags only Context
  (2,060). `git diff --check` is clean.
- The graph remains at generation `2026-09-19T15:22:09Z`; GiftContext and its
  test metadata changed, and the new projection module is untracked, so those
  current sources were read directly. The architecture scan remains at
  65.0/100 project health and 61.9% coverage, with PNC at 64.8/100 and 63.4%.
  The whole-worktree diff reports one resolved and zero introduced findings;
  no Semantics files appear in either set, and other active worktree changes
  limit attribution.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid process is running. The only remaining file over the 2,000-token
  estimate in Semantics is `PNC_SemanticDialogueInput_Context.lua`.

## Verification checkpoint: 2026-09-20 (Dialogue router lifecycle)

- Moved conversation state creation and router synchronization into
  `PNC_SemanticDialogueInput_RouterLifecycle.lua`. The context coordinator
  retains `Input.Internal.RouterFor` as a compatibility entry point and injects
  the existing state, policy, parser, resolver, and context dependencies.
- Hoisted authored-topic projection so a session with an existing semantic
  dialogue state still seeds a newly created context state with the authored
  topic. Smoke coverage checks missing-session rejection plus fresh and
  partially initialized sessions.
- The local-route smoke test passes (1/1) and the semantic suite passes 62/62.
  The full suite reports the same three baseline failures in 726 tests:
  constants expected 563 vs 565 and two inventory command-registration
  harness errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no hardcoded UI strings or Kahlua issues in the context
  coordinator or lifecycle module. The 50-file Semantics token scan reports no
  files above 2,000 tokens. `git diff --check` and
  `git diff --cached --check` are clean.
- The architecture scan remains at 65.0/100 project health and 61.9% coverage;
  PNC remains at 64.8/100 and 63.4%. Findings decreased from 193 to 192 with
  one large-function finding resolved and none introduced. The affected-file
  selector recommended no tests; the focused and semantic suites were run
  directly.
- The graph remains at generation `2026-09-19T15:22:09Z`; changed source and
  test metadata are stale and the lifecycle module is untracked, so current
  source was read directly. Live single-player and multiplayer verification
  remains open because no Project Zomboid process is running.

## Verification checkpoint: 2026-09-20 (Server semantic identity boundary)

- Split semantic identity request admission, relationship effect policy,
  canonical name and response projection, relationship mutation, and result
  construction/delivery into server-only modules. The command handler still
  owns the authoritative sequence and retains the existing request/result
  fields, event ID, effect values, and relationship mutation call.
- Admission now rejects with `conversation_authority_unavailable` when the
  conversation lease validator is absent. The mutation adapter rejects with
  `relationship_service_unavailable` when the relationship service is absent.
  Smoke coverage confirms both failures leave relationship effects unchanged;
  it also covers a stale lease, all three effect policies, and invalid policy
  input.
- Added a server runtime-role guard to each new server module and updated the
  multiplayer loader-gate inventory from 746 to 751 files. The identity smoke
  and server-file guard both pass (1/1 each); the semantic suite passes 62/62.
  The full suite has the same three baseline failures in 726 tests: the
  constants count mismatch and two inventory command-registration harness
  errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` scanned all 10 PlayerKnowledgeCommands files with no
  untranslated UI strings, Kahlua issues, or files above 2,000 estimated
  tokens. The architecture scan remains at 65.0/100 project health and 61.9%
  coverage; PNC remains at 64.8/100 and 63.4%. Two large-function findings
  resolved, none introduced; other active worktree changes limit attribution.
- Graph coverage marks the edited command and test metadata changed and the
  new modules untracked, so current sources were read directly. The separate
ConversationDefinition/Relationship presentation-refresh cycle remains
under audit; those Conversation UI files already contain active worktree
changes and were not changed in this slice. Live single-player and
multiplayer verification remains open because no Project Zomboid process is
running.

## Verification checkpoint: 2026-09-20 (Camp-site geometry boundary)

- Moved the room adapter behind a nested `CampSiteGeometry` entry module with
  role modules for runtime access, room identity records, room projection,
  room enumeration, nearby-room selection, and site membership. The prior
  `PNC_SemanticCampSiteGeometry` require path delegates to the new entry;
  `PNC.Semantics.CampSiteGeometry` and its five `_Internal` hooks are preserved.
- Split `FindNearestRoom` candidate scoring from its local tile scan. The
  nearby scan now stops querying tiles as soon as its configured unique-room
  candidate cap is reached. The smoke test confirms the same nearby room and
  exactly eight tile lookups at radius 8 with a one-room cap.
- The camp-site, camp-task, client-hint, companion-hint, camp-zone, and
  perception-debug smoke tests pass. The semantic suite passes 62/62. The
  full suite reports 3 failures in 728 tests: the existing constants count
  expectation of 563 versus 565 actual, and two inventory command-registration
  harness errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports zero UI-string findings and zero Kahlua errors or
  warnings across the seven geometry modules. Its size estimate leaves one
  cohesive module, `RoomSelection`, just above the 2,000-token threshold at
  2,035 estimated tokens. The architecture scan remains 65.0/100 overall and
  64.8/100 for PNC, with 61.9% and 63.4% coverage respectively; its diff shows
  three large-function findings resolved and none introduced across the
  worktree. Other concurrent work limits attribution of aggregate scores.
- The refreshed graph is at generation `2026-09-19T18:57:55Z`, with no
  recorded coverage gaps for the changed geometry modules and their key
  resolver, hint, and smoke-test callers. `git diff --check` and
  `git diff --cached --check` are clean.
- The six gift patterns in `RegisterGiftOffers` were reviewed and kept together:
  they share the same OFFER/GIFT result contract and precedence order. The
  gift-offer smoke passes; splitting that registrar would not create a useful
  module boundary.
- Live single-player and multiplayer verification remains open because no
  Project Zomboid process is running. Use the existing deterministic dialogue
  and server-authority procedures above before treating the overall Semantics
  migration as complete.

## Verification checkpoint: 2026-09-20 (Inventory-query pending lifecycle)

- Added `InventoryPending` as the shared owner for inventory-query request
  registration and result consumption. Requests are registered before adapter
  transport, preserving correlation if a result arrives synchronously. The
  pending map is capped at 16 entries; missing sessions or IDs, duplicate IDs,
  and a full map return explicit failures. Immediate transport rejection or
  unavailable status removes the pending entry. Result receipt consumes the
  entry through the same lifecycle module.
- Audited `DispatchAction`: it remains a small router to the existing gift,
  inventory, command, and task adapters, so no additional split was warranted.
- `pnc_semantic_inventory_dialogue` passes 1/1 and the semantic suite passes
  62/62. The full suite reports the same three baseline failures in 728 tests:
  the constants expectation of 563 versus 565 actual and two inventory
  command-registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no localization, Kahlua, or size findings in the three
  changed client modules. The broader 51-file client Semantics scan has one
  existing localization finding at
  `PNC_SemanticDialogueInput_InventoryResponses.lua:78` (`I have `);
  localization is outside this slice. Architecture `affected` maps the changed
  files to PNC and selects no tests; the focused inventory smoke and semantic
  suite were run directly. The current aggregate scan is 65.0/100 overall and
  64.8/100 for PNC, with 190 findings versus the stored baseline of 193 (three
  large-function findings resolved, none introduced). Concurrent worktree
  changes limit attribution of aggregate measures.
- The refreshed graph is at generation `2026-09-19T19:14:23Z`. The pending
  lifecycle module, its dispatch/result callers, and the inventory dialogue
  smoke test have no recorded coverage gaps; this is a best-effort signal.
  `git diff --check` and `git diff --cached --check` are clean.
- Live single-player and multiplayer verification remains open because no
  Project Zomboid process is running. Follow the deterministic dialogue and
  server-authority procedures above before treating the overall Semantics
  migration as complete.

## Verification checkpoint: 2026-09-20 (Conversation relationship refresh boundary)

- Relationship presentation receipt now calls a registered active-conversation
  refresh handler only when settlement or ambient-visit state changes. The
  Conversation definition registers `refreshForNPC`; receipt no longer calls
  back through `PNC.Conversation.ReceiveIdentityPresentation`. That public
  entry point remains for network result consumers. If no handler is available
  or the active view rejects a rebuild, the relationship panel still receives
  the presentation directly. Invalid handler input fails with
  `invalid_refresh_handler`.
- The conversation smoke covers callback registration, a relationship-driven
  rebuild, an invalid handler, and fallback after a rejected rebuild; the
  nameplate smoke covers fallback when no handler is registered. The
  conversation, conversation-safety, relationship-preview, and nameplate
  relationship-feedback smoke tests pass (1/1 each); the semantic suite passes
  62/62. The full suite has the same three baseline failures in 728 tests: the
  constants expectation of 563 versus 565 actual and two inventory
  command-registration harness errors at `PNC_ClientInventoryCommands.lua:434`.
- The refreshed call graph no longer contains the previous eight-function
  presentation-refresh cycle. It still reports a three-function component
  containing `BuildDefinition`, `Conversation.Open`, and `Relationship.OpenDossier`.
  Source inspection confirms the dossier bridge opens
  `CharacterWindow.OpenDossier`, which calls `CharacterWindow.Toggle`; that path
  does not call `Conversation.Open`. Treat this remaining graph component as a
  heuristic false positive, pending runtime confirmation.
- `pz_verify` found no UI-string or Kahlua issues in the two changed
  Conversation modules. Its size heuristic still flags the existing
  `PNC_ConversationDefinition.lua` (5,484 estimated tokens) and
  `PNC_ConversationRelationship.lua` (5,911 estimated tokens); responsibility
  splits in these two files remain useful future work. The architecture scan
  remains 65.0/100 with 61.9% coverage; its worktree diff is 193 findings to
  190, three large-function findings resolved and none introduced. Concurrent
  changes limit attribution of aggregate results.
- The refreshed graph is at generation `2026-09-19T19:31:53Z`; both Conversation
  modules, the dossier and Character Window adapters, and the smoke test have
  no recorded coverage gaps. `git diff --check` and `git diff --cached --check`
  are clean.
- Live single-player and multiplayer verification remains open because no
  Project Zomboid process is running. Continue with the deterministic dialogue
  and server-authority procedures above before treating the overall Semantics
  migration as complete.

## Verification checkpoint: 2026-09-20 (Conversation definition roles)

- Kept `PNC/Conversation/PNC_ConversationDefinition` as the compatibility
  require entry. It loads separate context projection, builder, extension-part,
  and lifecycle roles; the existing `Conversation.BuildDefinition`, `Open`,
  and ceasefire APIs remain on the public Conversation table. The builder now
  delegates presentation-context projection, menu construction, and extension
  spec assembly to focused helpers/modules.
- The five focused definition, semantic-adapter, faction-emblem, authority-
  presence, and PBrainZ highlight smoke tests pass (5/5). The semantic suite
  passes 65/65. The full suite reports the same three baseline failures in 728
  tests: the constants count expectation is 563 versus 565 actual, and two
  inventory command-registration harness errors occur at
  `PNC_ClientInventoryCommands.lua:434`.
- `pz_verify` reports no localization, Kahlua, or size findings across the four
  new Definition role modules. The compatibility entry also has no findings.
  The architecture audit remains 65.0/100 overall with 61.9% coverage and
  64.8/100 for PNC with 63.4% coverage. Its worktree diff is 193 findings to
  189, four large-function findings resolved and none introduced; affected-file
  selection found no tests. Concurrent worktree changes limit attribution of
  aggregate measures.
- The refreshed full graph is generation `2026-09-19T19:51:21Z` with 67,492
  nodes and 258,891 edges. The compatibility entry, four role modules, key
  callers, and focused smoke tests have no recorded coverage gaps; this remains
  a best-effort signal. `git diff --check` and `git diff --cached --check` are
  clean. Existing staged and unstaged changes were preserved, and no files were
  staged by this slice.
- Live single-player and multiplayer checks remain open because no Project
  Zomboid game process is available. For SP, disable the optional LLM provider,
  open a nearby NPC conversation, and enter “hello there”; verify a local reply.
  With `ProjectHoomans.SemanticDialogueAudit` enabled, expect
  `semantic_audit event=semantic.input.received` and
  `semantic_audit event=semantic_input_local` with `GREET`,
  `pnc.social.greet`, and `providerUsed=false`; with auditing disabled, expect
  no audit lines. For MP, ask a nearby NPC “Can you bring me some water?” and
  verify server-authoritative admission and action planning; an invalid lease
  should be rejected as `invalid_lease`.

## Verification checkpoint: 2026-09-20 (Conversation relationship roles)

- The current filename was accurate for this client conversation adapter. Moved
  its entry to `PNC/Conversation/ConversationRelationship/` and updated the
  single runtime require in `PNC_Conversation.lua` plus three direct test
  loaders. The entry returns the same `PNC.Conversation.Relationship` table and
  explicitly loads resolution, preview payloads, snapshot projection, result
  receipt, panel controls, and debug actions. The shared
  `PNC_RelationshipPresentation`, conversation panel widget, bounded diary,
  nameplate feedback, identity verifier, and network routers remain separate
  dependencies with their existing responsibilities.
- Receipt still rejects malformed summaries, hydrates the diary through its
  revision and entry limits, skips stale/equivalent presentations, stores the
  compact snapshot used for change detection, forwards the authoritative
  summary to client state and diagnostics, reports feedback to nameplates, and
  refreshes the matching active view with the relationship-panel fallback.
  `ReceiveAfter`, debug snapshot handling, preview controls, and debug actions
  remain on the same public Relationship table.
- The five conversation, nameplate-feedback, panel-edit, preview-UI, and
  PBrainZ-highlight smoke tests pass (5/5); the semantic suite passes 65/65.
  Final verification passes the full suite 729/729. This final pass also
  corrected the stale constants count and inventory command fixtures behind
  the three earlier baseline failures; production behavior was unchanged.
- `pz_verify` reports no localization, Kahlua, or size findings across the
  seven relationship role modules. The architecture scan remains 65.0/100
  overall with 61.9% coverage and 64.8/100 for PNC with 63.4% coverage. Its
  worktree diff is 193 findings to 189, four large-function findings resolved
  and none introduced. Affected-file selection found no recommended tests;
  direct smoke suites were run. Concurrent worktree changes limit attribution
  of aggregate measures.
- The refreshed full graph is generation `2026-09-19T20:13:04Z` with 67,521
  nodes and 258,984 edges. The entry, six role modules, runtime loader, direct
  callers, and focused tests have no recorded coverage gaps; this remains a
  best-effort signal. No stale require to the moved entry remains in Lua source.
  Both staged and worktree diff checks are clean. Existing staged changes were
  preserved, and no files were staged by this slice.
- Live single-player and multiplayer verification remains open; no live
  scenario was exercised. A `ProjectZomboid64 -debug` process was present at
  the final check, but it was not used for testing. For SP, disable
  the optional LLM provider, open a nearby NPC conversation, and enter “hello
  there”; verify a local reply. With `ProjectHoomans.SemanticDialogueAudit`
  enabled, expect `semantic_audit event=semantic.input.received` and
  `semantic_audit event=semantic_input_local` with `GREET`,
  `pnc.social.greet`, and `providerUsed=false`; with auditing disabled, expect
  no audit lines. For MP, ask a nearby NPC “Can you bring me some water?” and
  verify server-authoritative admission and action planning; an invalid lease
  should be rejected as `invalid_lease`.
