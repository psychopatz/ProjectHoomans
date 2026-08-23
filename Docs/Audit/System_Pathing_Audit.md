# Pathing System Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans at `d8cf0fd`  
**Priority:** `P2`  
**Coverage target:** one report for every production subsystem emitted by the architecture analyzer.

## Baseline

| Metric | Value |
|---|---:|
| Analyzer health | 69.1 |
| Architecture pressure | 36.1 |
| Graph coverage score | 78.5 |
| Evidence confidence | 63.7 |
| Production files | 18 |
| Production LOC | 8362 |
| Rule findings | 15 (0 high, 15 medium, 0 low) |
| Fan-in / fan-out | 1 / 0 |

## Next-phase disposition

Main NPC traversal hotspot. The companion NPC_Traversal_Refactor_Audit.md has deeper findings. Split query/planning, motion execution, door/window interaction, native body control, and debug visualization while preserving the action/fence state machine and load order.

This is refactor triage, not a claim that behavior is broken. Preserve load order, save/network contracts, engine API boundaries, and test expectations while extracting seams.

## Architecture findings

| ID | Rule | Severity | Confidence | Evidence |
|---|---|---|---|---|
| `ARC-B02C57D6F6` | `UNBOUNDED_LOOP` | MEDIUM | HIGH (92%) | Potential unbounded loop in Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_VehicleAvoidance.lua. |
| `ARC-0CC8E7E74C` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua has 1090 code lines; review responsibility density. |
| `ARC-C77890DC7D` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua has 881 code lines; review responsibility density. |
| `ARC-D9CAB72F7F` | `LARGE_MODULE` | MEDIUM | HIGH (92%) | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua has 1130 code lines; review responsibility density. |
| `ARC-235E33C8F5` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | PathService.Pump spans 478 lines. |
| `ARC-291C2A4C7A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.updateTraversalAction spans 173 lines. |
| `ARC-3B2802244A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | FakeLocomotion.StepTowardGoal spans 279 lines. |
| `ARC-492A940991` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.consumeMoveIntent spans 140 lines. |
| `ARC-6709B9C271` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.ensureMoveLane spans 136 lines. |
| `ARC-7175C54441` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.repairInvalidBodyPosition spans 134 lines. |
| `ARC-A19719929D` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.updateActiveMove spans 357 lines. |
| `ARC-AC61D87996` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.tryDoorOrWindowInteraction spans 480 lines. |
| `ARC-B3EEEE5E3F` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Planner.Pump spans 277 lines. |
| `ARC-D14A09349C` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Internal.beginTraversalAction spans 146 lines. |
| `ARC-FEC418A93A` | `LARGE_FUNCTION` | MEDIUM | HIGH (90%) | Planner.GetSteeringTarget spans 133 lines. |

### Large modules and functions

| Kind | ID | Tokens | File | Symbol |
|---|---|---:|---|---|
| Large module | `ARC-D9CAB72F7F` | 1130 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua | — |
| Large module | `ARC-0CC8E7E74C` | 1090 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua | — |
| Large module | `ARC-C77890DC7D` | 881 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua | — |
| Large function | `ARC-AC61D87996` | 480 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua:279 | Internal.tryDoorOrWindowInteraction |
| Large function | `ARC-235E33C8F5` | 478 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua:650 | PathService.Pump |
| Large function | `ARC-A19719929D` | 357 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua:214 | Internal.updateActiveMove |
| Large function | `ARC-3B2802244A` | 279 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_FakeLocomotion.lua:271 | FakeLocomotion.StepTowardGoal |
| Large function | `ARC-B3EEEE5E3F` | 277 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua:292 | Planner.Pump |

## Context-size inventory

The persistent local tokenizer is `tiktoken 0.14.0` using `o200k_base`. The full scan covered 676 production Lua files and found 214 above the 2,000-token threshold. The paths below are heuristic matches; the complete inventory is in `Token_Bloat_Index.md`.

| Tokens | Lines | Candidate file |
|---:|---:|---|
| 10302 | 1248 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua |
| 9333 | 1157 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua |
| 7249 | 941 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_TraversalQuery.lua |
| 7139 | 770 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua |
| 5839 | 682 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context.lua |
| 5820 | 598 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane.lua |
| 5080 | 676 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua |
| 4077 | 551 | Contents/mods/ProjectHoomans/42.20/media/lua/shared/PNC/Core/Pathing/PNC_EnginePathPlanner_Context.lua |

## Verification notes

- Inventory and findings came from the architecture-audit scan at the repository commit above.
- Structural evidence was checked against the `project-hoomans` codebase-memory graph.
- Coverage was checked for the production Lua tree, shared animation assets, tests, and tools; the known excluded area is the graph cache directory.
- Static analysis cannot prove runtime behavior, save migration safety, or multiplayer authority correctness; P1/P2 work needs focused characterization tests.
- Companion deep report: `NPC_Traversal_Refactor_Audit.md`.

## Completed work — shared traversal-action contract

**Completion date:** 2026-08-23

This pass completed the first recommended traversal slice: the duplicated
low-fence `up -> cross_pending -> cross` phase and timing policy now lives in
the pure shared `PNC.TraversalAction` contract. The scripted PathService and
client-native controller remain separate side-effecting executors.

### Files changed

Production:

- `shared/PNC/Core/Pathing/PNC_TraversalAction.lua` — new pure action creation
  and phase/timing evaluation contract.
- `shared/PNC/Core/Pathing/PNC_PathService.lua` — loads the contract before
  PathService consumers.
- `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua`
  — delegates action creation and phase evaluation while retaining scripted
  body movement, animation, interaction, and lane mutation.
- `client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController.lua`
  — loads the contract before native-controller consumers.
- `client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage.lua`
  — delegates fence phase evaluation while retaining multiplayer ownership,
  native body control, cooldowns, and retry state.

Tests:

- `tests/pnc_traversal_action_contract_smoke.lua` — native/scripted phase and
  progress parity plus evaluator purity.
- `tests/pnc_client_native_fence_passage_smoke.lua` — contract loading and a
  characterization of stable same-side/server-correction behavior.
- `tests/pnc_split_fence_traversal_smoke.lua` — missing transfer/finish event
  deadline behavior.
- `tests/pnc_window_break_traversal_smoke.lua` — explicit contract loading for
  the isolated runtime test.
- `tests/pnc_pathing_presence_boundary_smoke.lua` — provider-first PathService
  load-order contract.

Paths above are relative to `Contents/mods/ProjectHoomans/42.20/media/lua`
unless they begin with `tests/`.

### Behavior and compatibility preserved

- Public functions remain unchanged: `Internal.beginTraversalAction`,
  `Internal.updateTraversalAction`, `Controller.UpdateWindowSmash`, and
  `Controller.TryNativePassage` are compatibility executors/wrappers.
- Existing action phases, state keys, animation variables, profile timings,
  50 ms transition settle, lane fields, finish reasons, SP/MP ownership split,
  engine invalidation, body control, cooldowns, and retry fields are retained.
- No save format, network payload, engine API call, or unrelated production
  file changed.

### Before/after architecture metrics

The current architecture-audit CLI groups this repository as one `PNC`
subsystem, so its whole-project baseline/diff is reported alongside direct
Pathing function measurements rather than compared with the older 92-system
health score above.

| Metric | Before | After |
|---|---:|---:|
| Whole-project production findings | 131 | 128 |
| Targeted large-function findings | 3 | 0 |
| `beginTraversalAction` span | 146 lines | 100 lines |
| `updateTraversalAction` span | 173 lines | 110 lines |
| native `updateWindowSmash` span | 125 lines | 100 lines |
| Pathing call cycles | 2 | 2 |
| Graph coverage gaps in changed files | 0 recorded | 0 recorded |

The three targeted `LARGE_FUNCTION` findings resolved with no introduced
architecture findings. Existing Pathing cycles in `NavigationRouter` and
`EnginePathPlanner` were outside this slice and remain unchanged.

### Before/after token metrics

Measured with local `tiktoken 0.14.0` and `o200k_base`:

| Scope | Before | After | Delta |
|---|---:|---:|---:|
| scripted traversal runtime | 3,933 | 3,132 | -801 (-20.4%) |
| client-native passage executor | 4,402 | 4,086 | -316 (-7.2%) |
| new shared action contract | 0 | 1,056 | +1,056 |
| full shared Pathing + native-controller scope | 84,062 | 84,031 | -31 |

The total scoped code is slightly smaller, while the duplicated executor
logic dropped by 1,117 tokens and the extracted contract fits independently
in a 1,056-token context.

### Tests and validation

```text
python3 tests/run_tests.py pnc_traversal_action_contract_smoke \
  pnc_client_native_fence_passage_smoke \
  pnc_split_fence_traversal_smoke \
  pnc_traversal_route_edges_smoke pnc_door_interaction_smoke \
  pnc_native_path_stall_smoke pnc_fake_locomotion_stall_smoke
PASS 7/7

python3 tests/run_tests.py
PASS 240/240

pz_verify --kahlua (19 shared Pathing files + 9 native-controller files)
0 errors, 0 warnings

pz_verify --i18n (19 shared Pathing files)
0 hardcoded UI strings
```

The refreshed `project-hoomans` graph generation is
`2026-08-23T11:11:23Z`; all changed production/test files report no recorded
coverage issue. This remains best-effort static evidence and does not replace
an in-game SP/MP traversal session.

### Remaining risks and recommended next refactor

- Characterization exposed a pre-existing discrepancy: when a stable server
  correction keeps the native body on the approach side, the executor keeps
  returning `native_fence_climb` after `finishAt`; it does not reach the
  advertised same-side retry branch. This behavior was preserved rather than
  silently fixed during the architecture pass. Add an explicit desired-
  behavior test and fix it as a separate runtime change.
- The highest-value next architecture slice is T-02: split geometry/probing
  and suppression/progression policy from the 480-line
  `tryDoorOrWindowInteraction()` compatibility wrapper. Keep door, window,
  and fence execution adapters separate and retain all current return reasons.
- `TraversalQuery`, `PathService_Motion`, `LiveBodyControl`, and the two
  existing Pathing call cycles remain follow-up work. No in-game SP/MP smoke
  session was available in this pass.

## Completed work — passage interaction boundaries

**Completion date:** 2026-08-23

This pass completed T-02. The stable
`Internal.tryDoorOrWindowInteraction()` entry point now coordinates small
door, window, breach, fence, object-adapter, and policy providers instead of
containing all passage behavior in one 480-line function.

### Files changed

Production files under
`shared/PNC/Core/Pathing/PNC_PathService/`:

- `PNC_PathService_Interactions.lua` — stable public entry point, context and
  candidate construction, and provider load order.
- `Interactions/PNC_PathService_PassagePolicy.lua` — suppression, direction, collision,
  distance, and rejection policy.
- `Interactions/PNC_PathService_PassageObjects.lua` — door/window engine object adapters.
- `Interactions/PNC_PathService_PassageDoors.lua` — blocked-door and candidate-door flows.
- `Interactions/PNC_PathService_PassageWindowBreach.lua` — open/smash decisions.
- `Interactions/PNC_PathService_PassageWindows.lua` — candidate-window and climb flows.
- `Interactions/PNC_PathService_PassageFences.lua` — fence resolution, rejection, action
  construction, and action tracking.

Tests:

- `tests/pnc_fence_interaction_smoke.lua` — characterizes blocked low-fence
  action construction, tracking, and the exact 500 ms suppression boundary.
- `tests/pnc_door_interaction_smoke.lua` — loads provider modules through the
  normal shared package path while retaining its existing door assertions.

### Behavior and compatibility preserved

- `Internal.tryDoorOrWindowInteraction`, `Internal.rememberSpecialAction`,
  `Internal.shouldSuppressSpecialAction`, `Internal.isDoorCollision`, and the
  existing object adapters retain their names and contracts.
- The PathService hub still loads only `PNC_PathService_Interactions`; that
  entry file owns the provider order, so external load order is unchanged.
- Interaction providers live in the dedicated `Interactions/` directory;
  the engine-visible entry file remains at its original flat path.
- Door opening and hold state, window open/smash/climb behavior, low-fence
  action specs, rejection reasons, logging, timestamps, and suppression
  boundaries are preserved by focused and full-suite tests.
- No save format, network payload, or unrelated production subsystem changed.

### Before/after architecture metrics

| Metric | Before | After |
|---|---:|---:|
| Whole-project production findings | 128 | 127 |
| Targeted `LARGE_FUNCTION` findings | 1 | 0 |
| `tryDoorOrWindowInteraction` span | 480 lines | 41 lines |
| `tryDoorOrWindowInteraction` cyclomatic complexity | 50 | 9 |
| `tryDoorOrWindowInteraction` cognitive complexity | 233 | 23 |
| Introduced architecture findings | 0 | 0 |
| Pathing call cycles | 2 | 2 |
| Graph coverage gaps in changed files | 0 recorded | 0 recorded |

The existing `NavigationRouter` and `EnginePathPlanner` cycles were outside
this slice and remain unchanged.

### Before/after token metrics

Measured with local `tiktoken 0.14.0` and `o200k_base`:

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Largest interaction-family file | 7,139 | 1,770 | -5,369 (-75.2%) |
| Interaction-family files above 2,000 tokens | 1 | 0 | -1 |
| Stable interaction entry file | 7,139 | 1,406 | -5,733 (-80.3%) |
| Total interaction-family code | 7,139 | 8,836 | +1,697 (+23.8%) |

The total grew because the providers now have explicit interfaces, module
guards, and locally named dependencies. That is an intentional context-size
tradeoff rather than a claim of less total code: every interaction provider
now fits independently below the 2,000-token limit.

### Tests and validation

```text
python3 tests/run_tests.py pnc_fence_interaction_smoke \
  pnc_door_interaction_smoke pnc_native_path_stall_smoke \
  pnc_traversal_route_edges_smoke pnc_window_break_traversal_smoke \
  pnc_split_fence_traversal_smoke
PASS 6/6

python3 tests/run_tests.py
PASS 241/241

pz_verify --dir shared/PNC/Core/Pathing/PNC_PathService \
  --kahlua --severity ERROR --no-snippets
13 files, 0 errors, 0 warnings
```

The refreshed `project-hoomans` graph generation is
`2026-08-23T11:35:39Z`. It records the wrapper's production and test callers,
35 reachable callees within two hops, and no coverage issue in any changed
production/test file. This is best-effort static evidence and does not replace
an in-game SP/MP traversal session.

### Remaining risks and recommended next refactor

- Passage interactions no longer exceed the 2,000-token limit. The remaining
  oversized PathService files are `PNC_PathService_Motion.lua` (9,333),
  `PNC_PathService_Context.lua` (5,839), `PNC_PathService_Lane.lua` (5,820),
  and `PNC_PathService_TraversalRuntime.lua` (3,132).
- `PNC_PathService_Motion.lua` is the next recommended Pathing slice because
  it contains both the 357-line `updateActiveMove` flow and the 478-line
  `PathService.Pump` orchestration entry point. Characterize scheduler and
  stalled-move outcomes before splitting its movement progression from pump
  orchestration.
- No in-game SP/MP smoke session was available in this pass.

## Completed work — PathService motion ownership

**Completion date:** 2026-08-23

This pass completed T-04 for `PNC_PathService_Motion.lua`. The existing module
path is now a compatibility entry point that loads explicit lifecycle,
scripted-motion, native-motion, pump, and public-API providers. Public
`PathService` and `Internal` function names remain available to existing
callers.

### Files changed

Production files under
`shared/PNC/Core/Pathing/PNC_PathService/`:

- `PNC_PathService_Motion.lua` — stable ordered provider entry point.
- `Motion/PNC_PathService_MotionLifecycle.lua` — request startup, cancellation,
  completion, refresh, and restart transitions.
- `Motion/PNC_PathService_MotionPassage.lua` — scripted passage acquisition,
  traversal adoption, and special-action cooldown ownership.
- `Motion/PNC_PathService_MotionRecovery.lua` — suppressed/non-locomotion body-state
  recovery.
- `Motion/PNC_PathService_MotionScripted.lua` — thin active-move coordinator and
  fake-locomotion progress/watchdog handling.
- `Motion/PNC_PathService_MotionNativePassage.lua` — adjacent and stalled native
  passage recovery.
- `Motion/PNC_PathService_MotionNativeProgress.lua` — native physical/goal progress,
  failure, timeout, and retry accounting.
- `Motion/PNC_PathService_MotionNative.lua` — native engine execution adapter.
- `Motion/PNC_PathService_MotionPump.lua` — hot orchestration boundary and dedicated
  scripted-passage handoff.
- `Motion/PNC_PathService_MotionApi.lua` — `Reset`, `MoveToward`, and
  `AdvanceAbstract` commands.

Other Pathing production:

- `shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua` — routes staged and
  collision-triggered scripted passages through
  `PathService.AdvanceScriptedPassage` instead of recursively calling the
  general `PathService.Pump`.

Tests:

- `tests/pnc_path_service_motion_ownership_smoke.lua` — new characterization
  of attack, scripted traversal, native waiting, and fake-locomotion ownership
  precedence.
- `tests/pnc_engine_path_planner_smoke.lua` — follows the explicit scripted
  handoff and provider source boundaries.
- `tests/pnc_attack_animation_pipeline_smoke.lua` — checks the extracted pump
  provider while retaining attack-before-intent ordering coverage.
- `tests/pnc_simulation_lod_smoke.lua` — loads the provider-backed entry point
  through the shared package path.

### Behavior and compatibility preserved

- `PathService.Pump`, `Reset`, `MoveToward`, `AdvanceAbstract`, and
  `Internal.updateActiveMove` retain their signatures and return states.
- Attack leases still precede intent mutation; scripted passage ownership
  precedes native movement; an inactive native lane remains stationary instead
  of falling through to fake locomotion.
- Existing lane keys, diagnostic names, owner modes, passage reasons,
  animation/body calls, native progress thresholds, motion hints, retries,
  completion reasons, and abstract-travel calculations remain intact.
- The PathService hub still requires only the stable Motion entry path.
- Motion providers live in the dedicated `Motion/` directory; the
  engine-visible entry file remains at its original flat path and explicitly
  requires providers in dependency order.

### Before/after architecture metrics

| Metric | Before | After |
|---|---:|---:|
| Whole-project production findings | 127 | 124 |
| Targeted architecture findings | 3 | 0 |
| `PathService.Pump` span | 478 lines | 31 lines |
| `PathService.Pump` cyclomatic complexity | 44 | 6 |
| `PathService.Pump` cognitive complexity | 141 | 6 |
| `Internal.updateActiveMove` span | 357 lines | 51 lines |
| `Internal.updateActiveMove` cyclomatic complexity | 43 | 8 |
| `Internal.updateActiveMove` cognitive complexity | 74 | 8 |
| Pathing call cycles | 2 | 1 |
| Whole-graph call cycles | 16 | 15 |
| Introduced architecture findings | 0 | 0 |

The resolved findings are the large Motion module plus both large functions.
The removed cycle was the re-entrant
`PathService.Pump -> EnginePathPlanner.Pump -> PathService.Pump` passage
handoff. `PNC_NavigationRouter.clearProvider <-> Router.Clear` remains the one
recorded Pathing cycle.

### Before/after context-size metrics

Measured with local `tiktoken 0.14.0` and `o200k_base`:

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Largest Motion-family file | 9,333 | 1,810 | -7,523 (-80.6%) |
| Stable Motion entry file | 9,333 | 256 | -9,077 (-97.3%) |
| Motion-family files above 2,000 tokens | 1 | 0 | -1 |
| Total Motion-family tokens | 9,333 | 10,502 | +1,169 (+12.5%) |
| Total Motion-family lines | 1,157 | 1,495 | +338 (+29.2%) |

Total source grew because the split makes dependencies, provider guards,
handoff contracts, and role names explicit. The improvement is context
locality rather than a claim of less aggregate code: all ten Motion files now
fit independently below the 2,000-token limit.

### Tests and validation

```text
python3 tests/run_tests.py pnc_path_service_motion_ownership_smoke \
  pnc_native_path_stall_smoke pnc_engine_path_planner_smoke \
  pnc_simulation_lod_smoke pnc_attack_animation_pipeline_smoke \
  pnc_pathing_presence_boundary_smoke pnc_split_fence_traversal_smoke \
  pnc_door_interaction_smoke pnc_fence_interaction_smoke
PASS 9/9

python3 tests/run_tests.py
PASS 242/242

pz_verify --dir shared/PNC/Core/Pathing/PNC_PathService \
  --kahlua --severity ERROR --no-snippets
22 files, 0 errors, 0 warnings
```

The final `project-hoomans` graph has no recorded skipped or parse-partial
files in the changed Pathing/test scope. Coverage remains best-effort static
evidence and does not replace an in-game SP/MP traversal session.

### Remaining risks and recommended next refactor

- The remaining oversized PathService providers are
  `PNC_PathService_Context.lua` (5,839 tokens),
  `PNC_PathService_Lane.lua` (5,820), and
  `PNC_PathService_TraversalRuntime.lua` (3,132).
- `PNC_PathService_Context.lua` is the next recommended slice. Separate body
  state/animation access from movement policy and recovery bookkeeping before
  changing `Lane`, because Motion providers currently consume those context
  helpers through a stable `Internal` contract.
- At the conclusion of the Motion slice, `PNC_TraversalQuery.lua`,
  `PNC_LiveBodyControl.lua`, and the remaining NavigationRouter cycle were
  still follow-up Pathing work; the next section records the completed query
  extraction.
- No in-game SP/MP smoke session was available in this pass.

## Completed work — traversal query ownership

**Completion date:** 2026-08-23

This pass completed T-03 for `PNC_TraversalQuery.lua`. Its original path now
remains a stable engine-visible entry file, while seven read-only providers
under `shared/PNC/Core/Pathing/TraversalQuery/` own compatibility helpers,
square safety, object policy, fence geometry, passage discovery, route
planning, and live fence search.

### Files changed

- `PNC_TraversalQuery.lua` — stable ordered provider entry point.
- `TraversalQuery/PNC_TraversalQuery_Internal.lua` — PZ API compatibility,
  cardinal-edge geometry, materialization-object checks, and nearest-safe
  search support.
- `TraversalQuery/PNC_TraversalQuery_Squares.lua` — square lookup, occupancy,
  vehicle-clearance, traversal landing, and materialization queries.
- `TraversalQuery/PNC_TraversalQuery_Objects.lua` — door, window, and fence
  classification plus passage usability policy.
- `TraversalQuery/PNC_TraversalQuery_Fences.lua` — cardinal fence lookup,
  approach readiness, and crossing geometry.
- `TraversalQuery/PNC_TraversalQuery_Passages.lua` — edge passage lookup and
  goal-directed passage discovery.
- `TraversalQuery/PNC_TraversalQuery_Planning.lua` — `CanStep` and planner-only
  action/cost classification.
- `TraversalQuery/PNC_TraversalQuery_FenceSearch.lua` — live forward-fence
  discovery.
- Three legacy direct-load tests now register the shared Lua package path.
- `pnc_pathing_presence_boundary_smoke.lua` now fixes the provider load order
  as an explicit compatibility contract.

### Behavior and compatibility preserved

- All 24 public `PNC.TraversalQuery` function names and signatures remain at
  the original namespace.
- `PNC_SharedComposition` still requires only the original flat entry path.
- Vehicle safety still takes precedence over window/fence traversal; door,
  window, fence, diagonal-edge, approach-distance, materialization, and route
  cost semantics retain their focused test coverage.
- Providers are explicitly required in dependency order instead of relying on
  Project Zomboid's alphabetical discovery order.

### Before/after metrics

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Whole-project production findings | 124 | 123 | -1 |
| Targeted `LARGE_MODULE` findings | 1 | 0 | -1 |
| Stable entry tokens | 7,249 | 206 | -7,043 (-97.2%) |
| Largest TraversalQuery-family file | 7,249 | 1,378 | -5,871 (-81.0%) |
| Files above 2,000 tokens | 1 | 0 | -1 |
| Total family tokens | 7,249 | 7,877 | +628 (+8.7%) |
| Total family lines | 941 | 1,007 | +66 (+7.0%) |
| Public functions | 24 | 24 | 0 |
| Introduced architecture findings | 0 | 0 | 0 |

The aggregate increase is provider bootstrap and explicit dependency wiring;
every independently edited file now fits under the exact 2,000-token budget.

### Tests and validation

```text
python3 tests/run_tests.py traversal_route_edges vehicle_pathing \
  client_native_fence_passage fence_interaction mp_replica_transport \
  pathing_presence_boundary door_interaction presence_position_recovery \
  combat_tactical_decisions fake_locomotion_stall
PASS 10/10

python3 tests/run_tests.py
PASS 242/242

pz_verify --kahlua (entry + 7 providers)
8 files, 0 errors, 0 warnings

file-token-bloat-detector --threshold 2000
0 / 8 files over threshold
```

No in-game SP/MP traversal session was available in this pass. At this point,
the next Pathing slice was `PNC_PathService_Context.lua`; the following
section records its completion.

## Completed work — PathService context ownership

**Completion date:** 2026-08-23

The original `PNC_PathService_Context.lua` path remains the stable entry point.
Seven providers under `PNC_PathService/Context/` now own configuration, world
state access, invalid-position recovery, traversal memory, body ownership,
goal/profile policy, and animation presentation.

### Files changed

- `PNC_PathService_Context.lua` — stable ordered provider entry point.
- `Context/PNC_PathService_Context_Config.lua` — dependency bindings and
  shared tuning constants.
- `Context/PNC_PathService_Context_WorldState.lua` — square/body/path state
  accessors, attack ownership, and record-position synchronization.
- `Context/PNC_PathService_Context_PositionRecovery.lua` — invalid-position
  repair, vehicle-goal quarantine, persistence dirtiness, and throttled
  recovery diagnostics.
- `Context/PNC_PathService_Context_TraversalMemory.lua` — repeated-passage
  suppression and progress-based memory release.
- `Context/PNC_PathService_Context_BodyOwnership.lua` — non-locomotion
  recovery and native path/body reset.
- `Context/PNC_PathService_Context_Goals.lua` — goal equality, tolerance,
  resolved movement mode, and locomotion profile state.
- `Context/PNC_PathService_Context_Animation.lua` — moving and stationary
  presentation boundaries.
- Direct-load smoke tests now register the shared package path, and the
  multiplayer source-boundary assertion follows the Animation provider.
- `pnc_pathing_presence_boundary_smoke.lua` fixes Context provider order as an
  explicit load contract.

### Behavior and compatibility preserved

- All 27 existing `PathService.Internal` functions retain their names and
  signatures.
- The PathService hub still requires only the original flat Context entry.
- Existing timing constants and injected dependency fields remain on
  `PathService.Internal` before later PathService modules load.
- Position recovery keeps the same safe-square search, authoritative body
  placement, lane resets, vehicle cancellation, runtime metadata, dirty mark,
  diagnostic text, and log-throttling rules.
- Motion, Lane, TraversalRuntime, Logging, and external square-walkability
  consumers continue using the same internal contracts.

### Before/after metrics

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Whole-project production findings | 123 | 122 | -1 |
| `repairInvalidBodyPosition` span | 134 lines | 65 lines | -69 (-51.5%) |
| Stable entry tokens | 5,839 | 226 | -5,613 (-96.1%) |
| Largest Context-family file | 5,839 | 1,616 | -4,223 (-72.3%) |
| Files above 2,000 tokens | 1 | 0 | -1 |
| Total family tokens | 5,839 | 6,516 | +677 (+11.6%) |
| Total family lines | 682 | 794 | +112 (+16.4%) |
| Existing internal functions | 27 | 27 | 0 |
| Introduced architecture findings | 0 | 0 | 0 |

The family grows through explicit bootstraps and two coherent recovery
helpers. Every file remains independently below the exact 2,000-token budget.

### Tests and validation

```text
focused Context/PathService suite
PASS 14/14

python3 tests/run_tests.py
PASS 242/242

pz_verify --kahlua (entry + 7 providers)
8 files, 0 errors, 0 warnings

file-token-bloat-detector --threshold 2000
0 / 8 files over threshold
```

No in-game SP/MP traversal session was available. The next PathService slice
is `PNC_PathService_Lane.lua`, followed by TraversalRuntime ownership and then
`PNC_LiveBodyControl.lua`.
