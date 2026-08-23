# NPC Traversal Refactor Audit

**Audit date:** 2026-08-23  
**Repository:** ProjectHoomans  
**HEAD audited:** `d8cf0fd` (`Refactor test suite to use new testing framework`)  
**Scope:** the three traversal commits `72d85eb`, `3739f66`, and `1dab9b8`

## Executive summary

The traversal code is functioning, but the current shape is expensive to change safely. The most important issue is that the split-fence state machine exists twice:

- the client/native passage controller stores `state.passageAction` and implements `up -> cross_pending -> cross` in `updateWindowSmash()`;
- the shared scripted runtime stores `lane.traversalAction` and implements the same phases in `updateTraversalAction()`.

Both paths duplicate timing, animation handoff, interpolation, completion, and failure handling. A bug fix or timing adjustment can therefore correct one execution path while leaving the other inconsistent.

The next refactoring phase should extract a shared, side-effect-free traversal-action contract/reducer first. The native client and scripted runtime should remain separate executors because their ownership and multiplayer rules differ.

No production behavior was changed during this audit.

## Baseline measurements

The architecture audit scanned 946 files, including 699 production files and 243 tests:

| Area | Result |
|---|---:|
| Overall production health | 82.7 / 100 |
| Overall coverage | 70.6% |
| Pathing health | 69.1 / 100 |
| Pathing refactor pressure | 36.1 / 100 |
| Pathing coverage | 78.5% |
| Production findings | 148 |

The local ChatGPT 5.4-compatible token scan found 214 of 676 Lua files above the 2,000-token threshold. This is a triage signal, not a requirement to split every large file.

The graph was refreshed on 2026-08-23. The audited paths had no recorded skipped or partial coverage. Coverage is still best-effort and does not prove that every dynamic Lua reference was resolved.

## Files changed by the traversal commits

These are the direct files to keep together when planning the migration.

| File | Current evidence | Disposition |
|---|---|---|
| `client/PNC/PresenceSync/ClientNativePathController/PNC_ClientNativePathController_Passage.lua` | 543 lines / 4,402 tokens. Owns native passage probing, fence/window action state, movement leases, and client-side cooldowns. | **P1 — split execution from state-machine policy.** |
| `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Interactions.lua` | 770 lines / 7,139 tokens. `tryDoorOrWindowInteraction()` spans 480 lines and combines detection, geometry, goal-progress policy, cooldowns, profile resolution, and action creation. | **P1 — split by responsibility.** |
| `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_TraversalRuntime.lua` | 475 lines / 3,933 tokens. `beginTraversalAction()` spans 146 lines; `updateTraversalAction()` spans 173 lines. Mutates the lane, body, animation state, path state, and engine ownership. | **P1 — consume the shared action contract.** |
| `shared/PNC/Core/Pathing/PNC_TraversalQuery.lua` | 941 lines / 7,249 tokens; 881 code lines. The architecture audit flagged it as a large module. `TraversalQuery.CanStep()` has 29 inbound callers in the refreshed graph. | **P1 — separate geometry/occupancy from route/action policy.** |
| `shared/PNC/Core/Pathing/PNC_TraversalProfiles.lua` | 85 lines / 593 tokens. Small data registry for window, low-fence, and tall-fence timing/animation profiles. | **Keep as a seam.** Do not split further until the action contract is stable. |
| `client/PNC/Debug/PNC_AnimationDebugCatalog.lua` | 11,251 lines / 111,314 tokens. Header identifies it as generated from 544 XML nodes; it contains data rather than a large hand-written behavior module. | **P3 — generator/artifact hygiene only. Do not hand-refactor.** |
| `common/media/AnimSets/zombie/bumped/PNC_Anim_ClimbFenceStart.xml` | Emits `PNCTraversalPhase=transfer` and transitions to `Idle`. | **Behavior contract; preserve while migrating.** |
| `common/media/AnimSets/zombie/bumped/PNC_Anim_ClimbFenceEnd.xml` | Emits finish variables at 70%/end and transitions to `Idle`. | **Behavior contract; preserve while migrating.** |
| `tests/pnc_client_native_fence_passage_smoke.lua` | Covers native raise, transition settle, landing, movement lease, and cooldown. | **Keep as native executor regression coverage.** |
| `tests/pnc_split_fence_traversal_smoke.lua` | Covers scripted raise, transfer event, settle delay, crossing, landing, and bump release. | **Keep as scripted executor regression coverage.** |
| `tests/pnc_traversal_route_edges_smoke.lua` | Covers window classification, generic/tall fence classification, diagonal rejection, and approach readiness. | **Keep as route-policy regression coverage.** |
| `tests/pnc_animation_debug_catalog_smoke.lua` | Covers the generated catalog contract. | **Keep with the generator/artifact.** |
| `Docs/FakeLocomotion.md` | Documents the related movement behavior. | **Update when ownership boundaries change.** |

The `client/...` and `shared/...` Lua paths above are relative to `Contents/mods/ProjectHoomans/42.20/media/lua`; the `common/...`, `tests/...`, and `Docs/...` paths are repository-relative.

## Indirect files in the refactor blast radius

These files were not all changed by the three traversal commits, but the graph and architecture scan show that they are part of the same ownership chain.

| File | Evidence | Priority |
|---|---|---|
| `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Motion.lua` | 1,157 lines / 9,333 tokens. `PathService.Pump()` spans 478 lines; `Internal.updateActiveMove()` spans 357 lines. It invokes traversal updates and passage interaction from multiple movement branches. | **P1** |
| `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Context.lua` | 682 lines / 5,839 tokens. Owns traversal memory, repeat-attempt tracking, body/path state, and lane context used by the new cooldown logic. | **P1** |
| `shared/PNC/Core/Pathing/PNC_PathService/PNC_PathService_Lane.lua` | 598 lines / 5,820 tokens. Stores the mutable movement-lane state that both traversal implementations mutate. | **P1** |
| `shared/PNC/Core/Pathing/PNC_EnginePathPlanner.lua` | 676 lines / 5,080 tokens. `Planner.Pump()` spans 277 lines and participates in native-versus-scripted ownership handoff. | **P1** |
| `shared/PNC/Core/Pathing/PNC_EnginePathPlanner_Context.lua` | 551 lines / 4,077 tokens. Stages upcoming passages and exposes native traversal state. | **P2** |
| `shared/PNC/Core/Pathing/PNC_FakeLocomotion.lua` | 550 lines / 3,954 tokens. `FakeLocomotion.StepTowardGoal()` spans 279 lines and depends on traversal queries. | **P2** |
| `shared/PNC/Core/Pathing/PNC_LiveBodyControl.lua` | 1,248 lines / 10,302 tokens. Architecture audit flagged it as a large module; it owns multiplayer checks, authoritative position, body suppression, and animation leases. | **P1 boundary; P2 split** |
| `shared/PNC/Core/Visuals/PNC_Animation.lua` | 1,050 lines / 9,100 tokens. Provides `PlayBump`, `FinishBump`, and body lease behavior consumed by both traversal paths. | **P2 contract owner** |
| `shared/PNC/Core/Visuals/PNC_AnimationScenes.lua` | 919 lines / 6,234 tokens. Related animation-scene/event contract. | **P2 contract owner** |

The refreshed graph shows these high-impact relationships:

- `Internal.updateTraversalAction()` has 7 inbound callers, including `updateActiveMove()`, `PathService.Pump()`, the server record loop, and traversal/stall tests.
- `Internal.beginTraversalAction()` has 7 inbound callers, including `tryDoorOrWindowInteraction()`, `updateActiveMove()`, and `PathService.Pump()`.
- `tryNativePassage()` has 2 inbound callers: the native path-controller update and lifecycle path.
- `TraversalQuery.CanStep()` has 29 inbound callers spanning pathing, combat, zombie aggro, companion following, and tests.
- `PathService.Pump()` is reached by the server record loop and server tick path, making it a hot orchestration boundary.

## Refactor findings

### T-01 — Duplicate traversal state machines

**Priority: P1 / highest value**

`PNC_ClientNativePathController_Passage.lua:119-243` and `PNC_PathService_TraversalRuntime.lua:302-474` both implement the split-fence phases `up`, `cross_pending`, and `cross`. They both:

- wait for an animation variable or a duration deadline;
- hold the body at the fence contact point;
- wait 50 ms for the `Idle` transition to settle;
- switch to the landing animation;
- interpolate toward the destination;
- apply a hard completion/failure boundary; and
- release the animation/movement lease.

The state is stored under different shapes (`passageAction` versus `traversalAction`), which makes parity difficult to guarantee. The two implementations should share pure phase/timing logic while retaining separate adapters for native body control, scripted coordinates, animation calls, and multiplayer ownership.

### T-02 — Obstacle detection and action execution are fused

`PNC_PathService_Interactions.lua:279-758` puts door opening, window opening/smashing/climbing, fence discovery, approach checks, destination selection, repeated-attempt suppression, cooldown checks, profile lookup, logging, and `beginTraversalAction()` calls in one function.

This is the clearest “spaghetti” point in the current traversal slice. Suggested future ownership:

1. `TraversalGeometry` — edge/object lookup and landing/approach geometry;
2. `PassagePolicy` — whether an action is progressive, repeated, blocked, or suppressed;
3. `PassageExecutor` — open, smash, climb, or hand off to the action runtime; and
4. a thin compatibility wrapper retaining `Internal.tryDoorOrWindowInteraction()` during migration.

### T-03 — `TraversalQuery` mixes read-only queries with route policy

**Completed 2026-08-23.** The original flat entry path now explicitly loads
seven providers under `shared/PNC/Core/Pathing/TraversalQuery/`; all 24 public
query functions remain on `PNC.TraversalQuery`, and every family file is below
2,000 exact `o200k_base` tokens.

`PNC_TraversalQuery.lua` contains object classification, passage/fence lookup, occupancy checks, step validation, door/window usability, fence approach readiness, fence discovery, and action-kind selection. The high fan-in of `CanStep()` makes it a shared contract: changing its return semantics has impact outside traversal.

Split by stable responsibility, not by arbitrary line count. Preserve the existing exported methods first, then delegate them to smaller internal modules. This keeps combat, following, zombie aggro, and fake locomotion from breaking during the migration.

### T-04 — PathService movement orchestration is the next monolith

`PNC_PathService_Motion.lua` is both a large module and a hot-path coordinator. `PathService.Pump()` handles diagnostics, body repair, attack leases, intent phases, engine-path ownership, native passage recovery, scripted traversal, and fake locomotion. `Internal.updateActiveMove()` repeats several of those decisions at a lower level.

Do not split this file before T-01. First establish one traversal-action contract; then extract movement stages around that contract. Otherwise the same state transition will move between files while remaining duplicated.

### T-05 — Mutable ownership crosses too many boundaries

**Context ownership update, 2026-08-23.** The stable
`PNC_PathService_Context.lua` entry now loads seven providers under
`PNC_PathService/Context/`. Position recovery, traversal memory, body reset,
goal policy, and animation presentation are explicit boundaries; all existing
`PathService.Internal` contracts remain compatible.

`beginTraversalAction()` invalidates the engine planner, writes lane state, clears target/path state, changes body control flags, resets engine traversal variables, applies facing, starts animation, and records motion hints. This is valid behaviorally, but it makes ownership implicit and makes partial failure hard to reason about.

The migration should make the owner explicit at each point: `engine_path`, `native_passage`, `scripted_traversal`, or `fake_locomotion`. Keep the current state fields and public calls until the new contract is proven by tests.

### T-06 — Generated animation catalog is a separate maintenance problem

`PNC_AnimationDebugCatalog.lua` is enormous, but its header says it is generated from 544 XML nodes and the file is effectively one data literal. It should not be treated like a hand-written monolith. Track its generator, generation validation, and runtime loading cost separately from the traversal refactor.

## Architecture finding IDs to carry forward

These IDs come from the baseline architecture scan and can be queried again after each migration step.

| ID | Finding |
|---|---|
| `ARC-C77890DC7D` | Large `PNC_TraversalQuery.lua` module (881 code lines). |
| `ARC-AC61D87996` | `Internal.tryDoorOrWindowInteraction()` spans 480 lines. |
| `ARC-D14A09349C` | `Internal.beginTraversalAction()` spans 146 lines. |
| `ARC-291C2A4C7A` | `Internal.updateTraversalAction()` spans 173 lines. |
| `ARC-235E33C8F5` | `PathService.Pump()` spans 478 lines. |
| `ARC-A19719929D` | `Internal.updateActiveMove()` spans 357 lines. |
| `ARC-0CC8E7E74C` | Large `PNC_PathService_Motion.lua` module (1,090 code lines). |
| `ARC-3B2802244A` | `FakeLocomotion.StepTowardGoal()` spans 279 lines. |

## Test and verification status

Focused tests passed on 2026-08-23:

```text
PASS 6/6 in 0.02s (4 workers)
```

The run covered:

- `pnc_client_native_fence_passage_smoke`
- `pnc_split_fence_traversal_smoke`
- `pnc_traversal_route_edges_smoke`
- `pnc_door_interaction_smoke`
- `pnc_native_path_stall_smoke`
- `pnc_fake_locomotion_stall_smoke`

The existing tests give good coverage of the happy-path phase transitions, route classification, cooldown, native stall recovery, and the multiplayer fake-locomotion gate. Before extracting shared state logic, add these regression cases:

- one parity test that drives the same fence scenario through native and scripted executors;
- a missing-animation-event/hard-timeout case;
- a same-side landing or server-correction case for both executors;
- blocked landing and repeated-attempt suppression for low and tall fences; and
- explicit SP/MP ownership assertions around the handoff boundary.

The architecture tool’s automatic affected-test selector returned no mapped tests for the supplied historical file set; that was not treated as evidence of no impact. The test set above was selected from the direct commit changes and refreshed graph callers.

## Recommended next-phase order

### Phase 0 — Freeze behavior

- Add the parity and timeout tests above.
- Document the current action states, state variables, lease ownership, and completion reasons.
- Treat `PNC_TraversalProfiles.lua` as the source of timing/profile data.

### Phase 1 — Extract the shared action contract

- Introduce a small shared traversal-action model/reducer for phase transitions and timing decisions.
- Keep native client and scripted runtime execution separate.
- Preserve `Controller.TryNativePassage`, `Controller.UpdateWindowSmash`, `Internal.beginTraversalAction`, and `Internal.updateTraversalAction` as compatibility wrappers.

### Phase 2 — Separate passage policy from execution

- Split geometry/probing from suppression/progression policy.
- Split door/window/fence executors behind the existing interaction wrapper.
- Keep all existing action keys, cooldown fields, and return reasons until the focused suite is green.

### Phase 3 — Reduce PathService orchestration

- Extract explicit movement stages from `updateActiveMove()` and `PathService.Pump()`.
- Make the traversal owner a visible stage result instead of an implicit collection of lane flags.
- Only then consider splitting `PathService_Context`, `PathService_Lane`, and `LiveBodyControl`.

### Phase 4 — Clean supporting artifacts

- Move animation-catalog generation/validation into its own maintenance path.
- Update `Docs/FakeLocomotion.md` and add a short traversal ownership document.
- Remove duplicate test-finalization calls while touching the focused tests.

## Audit limitations

- This is a static audit plus focused smoke-test run; it does not replace an in-game SP/MP traversal session.
- Lua dynamic loading and engine userdata calls are only partially visible to static analysis.
- The architecture analyzer reports unknown/low-coverage categories as `UNKNOWN`; those are inspection prompts, not quality scores.
- The token threshold identifies large files, not necessarily bad design. Generated data and stable registries are intentionally treated differently from behavior modules.
