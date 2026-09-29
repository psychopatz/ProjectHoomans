# Audit: Return-home travel across the live/abstract boundary

Status: **audit + plan, no code changed yet.**
Scope: `PNC.Travel.Service` (durable journey), `PNC.Presence` (live/abstract body),
`PNC.PathService` + `PNC.FakeLocomotion` (live movement), `PNC.OrderSystem`
(order/lane terminal states), `PNC.HomeDutyService` (return-home intent).

Evidence used: `~/Zomboid/console.txt` (current session, frames 7705-16920),
live profiler bridge (`pid 1062227`), and a static read of the cited Lua.

---

## 1. Observed failure

Two live colonists, both on a durable `colony_home` journey, are pinned ~842
tiles from their destination and never arrive:

| item | value |
| --- | --- |
| NPCs | `npcLutherPacker_Z1IS` (Luther Packer), `npcOrvilleSilas_3MTR` (Orville Silas) |
| behaviour | `job=Travel behavior=Travel:en_route order=travel` for every line in the window |
| goal | `10622,10336,0` - the only published goal in the whole window |
| position | `~11400.0,10656` (Luther starts at y `10675.16`, walks 19 tiles, then stalls) |
| presence | `live` for both, confirmed on the live profiler during this audit |
| journeys | `journey_1790637976145_478484`, `journey_1790637976167_369040` (stable, never replaced) |

Log shape over ~1 in-game hour (frame 7705 -> 16920, ~2.6 real minutes):

- 2257 lines: 2040 `DEBUG`, **311 `WARN`**, 5 `INFO`, zero `ERROR`/exception.
  The "errors" are the PNC movement-lane warning loop, not Lua errors.
- `move=` histogram per NPC: `suppress_state` 610, `progress` 416, `blocked` 101,
  `step_blocked` 65, `interact_rejected` 65, `request_issued`/`requested`/`active`
  60 each, `progress_timeout` 60, `native_progress_timeout` 59, `route_failed` 54,
  `complete` 54.
- `reason=` histogram: `progress_timeout` 98, `native_no_goal_progress` 71,
  `fake_locomotion_blocked` 67.
- 83 terminal `route_failed` events (35 + 48) and 17 `live_travel_recovery`
  warnings - i.e. ~83 failed movement-order cycles inside one in-game hour.
- Fake-step labels: `direct` 490 but rejected often; the accepted steps are
  `axis_y` 168, `axis_x` 98, `slide_preferred` 79, `hard_other` 75, all with
  `dist` 0.03-0.25 tiles. Position oscillates inside a ~1.7 tile box, `x` pinned
  at `11400.00-11403.84`, `y` pinned at a floor of `10656.00`.

The failure cycle, exactly as the log prints it:

```text
move=step_blocked  reason=stalled          (all 7 fake candidates rejected)
move=interact_rejected reason=stalled      (no goal-advancing door/window/fence edge)
move=progress_timeout reason=fake_locomotion_blocked
move=native_progress_timeout reason=native_no_goal_progress   (engine_path also fails)
move=progress_timeout reason=fake_locomotion_blocked
move=blocked reason=progress_timeout
move=route_failed reason=progress_timeout
move=complete phase=blocked ... action=idle lastAction=walktoward owner=blocked
-> next tick: order=travel re-issued, revision++, same goal, same journey, repeat
```

Net effect: five `WARN` lines per cycle, ~83 cycles/hour, the journey stays
`en_route` with `distanceTravelled` near 0, and the NPC makes no net progress
toward home - forever.

---

## 2. Root cause

**There is no handoff between the live controller and the abstract controller of
a journey.** The lane that advances a journey is derived purely from
`presenceState`, and `presenceState` is derived purely from player distance.

```text
journey.controller = live     <- record.presenceState == live   (Travel_Model.lua:126)
journey.controller = abstract <- presence flip only             (Travel_Service_Live.lua:268,279)

presence live -> abstract  <=> nearest player distSq >= ABSTRACT_DISTANCE^2 = 40^2
                               (PNC_Presence_Decisions.lua:38-52, SchedulingPresence.lua:29)
```

Consequences that combine into the observed deadlock:

1. `HomeDutyService.SendHome` never consults presence or player distance; it
   starts a `routeProvider = "direct"` (straight line), `speedProfile = "walk"`
   journey to a home point that can be hundreds of tiles away
   (`PNC_HomeDutyService_Commands.lua:41-58`).
2. The record is `live` (a player is within 40 tiles), so the journey is owned
   by the live lane: `BehaviorTravel.Tick` -> `Common.MoveRecord` ->
   `PathService` -> engine path / fake locomotion, one segment target at a time
   (`PNC_Behavior_Travel.lua:85-106`).
3. The live lane cannot serve a multi-hundred-tile route. The engine pather
   needs loaded ground around both ends; fake locomotion refuses any candidate
   square whose occupancy reason is `unloaded`, `solid`, `solid_trans` or
   `occupied` (`TraversalQuery_Squares.lua:23-41`, used by
   `FakeLocomotion_Candidate.lua:10-24`). Whatever the local blocker is (a
   stretched unloaded boundary or a geometry pocket), there is no replan, no
   reroute and no escape.
4. The abstract lane - the only lane designed for long hauls, advancing at
   `ABSTRACT_TRAVEL_SPEED = 1.667` tiles/s and ignoring collisions
   (`PNC_Travel_Projection.lua` `AdvanceMutable`, pumped by
   `PNC_Server_SubsystemPumps.lua:109-112`) - is only ever entered through a
   presence flip, and `RefreshAbstractPositions` explicitly skips live records.
5. Nothing else can end the journey. The movement lane's terminal state is
   local to `PathService` (`completeMove`, `MotionLifecycle.lua:144-220`): it
   logs, sets `phase = "blocked"`, and returns nothing to the caller
   (`MotionScripted.lua:105-126`). `Travel.Service` therefore never learns that
   its live lane is dead, and never calls `SetState("cancelled"/"blocked")`.
   `Cancel` is the only path to a terminal state and only
   `HomeDutyService.Recover` calls it (`PNC_HomeDutyService_Commands.lua:134-138`).

This is the gap the pathing research note already flagged as *recommended and
unimplemented*: "the recommended abstract-route handoff"
(`Docs/Research/VanillaAndAnimalPathing.md:212-231`,
`Docs/Systems/Pathing.md:105-106`).

The mobile-group director already has the intended pattern - it abstracts every
member before a long settlement departure
(`PNC_MobileGroupDirector_Departures.lua:149-157`). Colonist travel never got
the equivalent.

---

## 3. Defect register

Ranked by how directly each one breaks "NPC reliably returns home".
`P` = priority.

### P0 - journey can never terminate

| # | defect | evidence |
| --- | --- | --- |
| P0-1 | Movement terminal state is not reported to the journey owner; `Travel` never sees `blocked`/`route_failed`. No replan, no cancel, no abstract handoff. | `MotionLifecycle.lua:144-220`, `MotionScripted.lua:105-126` |
| P0-2 | No watchdog for an active journey. A `LIVE` journey is advanced only from `BehaviorTravel.Tick`, and only while `orderSpec.kind == "travel"`. If any other order/job takes over (facility activity, `guard` fallback, roam-on-arrival), the journey freezes `en_route` forever with no owner. | `PNC_Behavior_Travel.lua:29-53,85-89`; `PNC_Travel_Service_Progression.lua`; `RefreshAbstractPositions` skips live records (`PNC_Server_SubsystemPumps.lua:109-112`) |
| P0-3 | `Travel.Service.Start` writes `record.orderSpec` directly instead of `OrderSystem.SetOrder`, so an existing facility/AtHome lease is not revoked and can starve the travel job: journey created at 0 %, `Travel.Tick` never runs. | `PNC_Travel_Service_Control.lua:57` vs `PNC_OrderSystem.lua:255-269`; `PNC_JobSystem.lua:71-80` |
| P0-4 | `OrderSystem` silently replaces a failed travel order with `guard`/`hostile_hunt` after `MAX_RECOVERY_ATTEMPTS`, while `record.travel` stays `en_route`. Caller (HomeDuty/Work) is never notified. | `PNC_OrderSystem.lua:557-628`, `MAX_RECOVERY_ATTEMPTS = 2` (`:21`) |
| P0-5 | `Cancel` leaves `record.travel` attached in a terminal state; the next materialization advances it again and `AdvanceMutable` re-projects `record.x/y/z` from the stale route *before* the spawn position is read - teleporting the NPC back to the old site. | `PNC_Travel_Service_Control.lua:151-158`; `PNC_Travel_Service_Progression.lua:11-19`; `PNC_Presence_Materialize.lua:86-93` vs `:295` |

### P1 - live/abstract crossing corrupts the journey

| # | defect | evidence |
| --- | --- | --- |
| P1-1 | Flip asymmetry: `OnAbstracted` re-derives `distanceTravelled`/`segmentIndex` from the body, `OnMaterialized` does not. After any `live -> abstract -> live` cycle the live lane resumes from a segment target the body never reached. | `PNC_Travel_Service_Live.lua:264-271` vs `:273-282` |
| P1-2 | Live stall counters (`liveLastX/Y/Z`, `liveStallCount`, `liveLastProgressAt`, `liveRecoveryCount`) are reset by neither flip handler and are absent from `BuildSummary`/`Normalize`: stale in-session (spurious stall recovery on the first live tick) and lost on reload. | `PNC_Travel_Service_Live.lua:13-43,264-282`; `PNC_Travel_Model.lua:220-270,144-218` |
| P1-3 | `journey.controller` is never corrected for the reachable `ABSTRACT + body exists` state (`Abstract` early-returns when `presenceState ~= live`), so the abstract lane advances a journey still marked `live`. | `PNC_Presence_Abstract.lua:136-140`; `PNC_Travel_Service_Progression.lua:81`; `PNC_Server_RecordProcessing.lua:55-62` |
| P1-4 | Arrival can fire more than once: a failing primary handler is immediately followed by the default handler in the same dispatch; a total failure resets `arrivalHandled` and re-dispatches on **every** `Advance` (~4/s) with a `LogWarn` per attempt. `Retarget` keeps `journeyId` while `Model.New` resets `arrivalHandled`. | `PNC_Travel_Arrivals.lua:156-247`; `PNC_Travel_Service_Control.lua:182`; `PNC_Travel_Model.lua:132` |
| P1-5 | `colony_home` failure degrades silently to `roam`, installing a roam order at the destination while `runtime.homeState` stays `RETURNING_HOME`. `AtHome.Tick` no longer runs, so there is no retry home. | `PNC_Travel_Arrivals.lua:175-216`; `PNC_HomeDutyService_Commands.lua:61` |
| P1-6 | Arrival predicate disagrees with the journey radius: live arrival is granted by the whole base zone (`IsAtHome` -> `GridRegion.containsXY`, z-blind), while `arrivalRadius = 3`. Result: "arrived" at the zone boundary, possibly tens of tiles short, with `distanceTravelled` frozen below `distanceTotal`. | `PNC_Travel_Service_Live.lua:109-118,173-175`; `PNC_HomeDutyService_Queries.lua:25-39`; `PC_GridRegion.lua:133-140` |
| P1-7 | A live journey's monotone distance ratchet is unrecoverable: `ProjectWorldPosition` floors on the stored value and the write is `math.max`, so once the abstract lane credits distance the body never walked, no later `SyncLivePosition` can undo it. | `PNC_Travel_Service_Progression.lua:60-79`; `PNC_Travel_Route.lua:190-241` |

### P2 - live movement quality / noise

| # | defect | evidence |
| --- | --- | --- |
| P2-1 | Fake-locomotion oscillation guard is ineffective: `bestGoalDistance` is a monotone ratchet that is never relaxed when the body drifts away, and the 24-consecutive-step limit resets on a `0.001` improvement re-cross. A body circling its own recorded minimum loops indefinitely. | `PNC_FakeLocomotion_Candidate.lua:89-130,229-239`; `PNC_FakeLocomotion_Step.lua:24-27`; `PNC_FakeLocomotion_Profiles.lua:12-14` |
| P2-2 | Progress semantics disagree by 10x: fake `MIN_GOAL_PROGRESS = 0.001` vs native `goalProgress >= 0.01`. | `PNC_FakeLocomotion_Profiles.lua:14`; `PNC_PathService_MotionNativeProgress.lua:158` |
| P2-3 | Router ping-pong: `Resolve` computes `nativeSafe` and discards it (provider stays `engine_path` until a timeout), and clears its own fallback window right after arming it. `fallbackCount` is zeroed on every new goal, so there is no fallback budget or escalation. | `PNC_NavigationRouter.lua:156-221,317-328`; `PNC_PathService_Lane_GoalState.lua:33` |
| P2-4 | Warning volume is unbounded and duplicated per cycle (5 `WARN` lines + ~25 `DEBUG` lines per blocked attempt, 311 `WARN` in one in-game hour for two NPCs). `{ blocked, route_failed, complete }` are three lines for one transition. | console histogram, section 1 |
| P2-5 | `PathService.Commands.Reset` rebuilds the same lane against the same `GetCurrentTarget` segment; the 12 s travel stall recovery therefore performs the same failing attempt with a fresh counter. | `PNC_Travel_Service_Live.lua:45-107,120-154` |

### P3 - home semantics (independent of the deadlock, still wrong)

| # | defect | evidence |
| --- | --- | --- |
| P3-1 | `IsWithinHome` ignores `z`, so an NPC on another floor counts as home. | `PNC_HomeDutyService_Queries.lua:30-39`; `PC_GridRegion.lua:133-140` |
| P3-2 | Unguarded last-resort home anchor can sit outside the zone -> `AtHome.Tick` calls `SendHome(forceDestination)` every tick, creating a journey that is instantly `arrived`, rewriting the same bad anchor. | `PNC_HomeDutyService_Core.lua:216-228,231-263`; `PNC_Behavior_AtHome.lua:36-44` |
| P3-3 | `WorkService_WorkerReconciliation` home re-order branch is unreachable; on `SendHome` failure `orderSpec` becomes `nil` -> `GuardAnchor`, so the colonist guards in the field instead of going home. | `PNC_WorkService_WorkerReconciliation.lua:63-82`; `PNC_JobSystem.lua:95` |
| P3-4 | `runtime.homeState` / `homeJourneyId` are write-only: no consumer reads them, so `RETURNING_HOME` is unobservable and cannot be used to drive a retry or a UI state. | `PNC_HomeDutyService_Commands.lua:61-63`; `PNC_HomeDutyService_Core.lua:267-288` |

### P4 - presence subsystem (found while auditing, not the current symptom)

| # | defect | evidence |
| --- | --- | --- |
| P4-1 | `presenceState` is set to `live` before `RegisterLiveZombie`; if registration is skipped the record is `live` with no body, and `ShouldMaterialize` does not check `presenceState`, so it is unrecoverable until the player leaves 40 tiles. | `PNC_Presence_Materialize.lua:256-257`; `PNC_Presence_Reconcile.lua:15-19` |
| P4-2 | Per-tick materialization budget is compared against a fresh `Core.Now()` instead of the stored tick timestamp, so `MATERIALIZE_MAX_PER_TICK = 2` is per-millisecond. | `PNC_Presence_Budget.lua:19-40`; `PNC_Server_Tick.lua:10-27` |
| P4-3 | `runtime.forceAbstract` is sticky: only the `WORLD_POPULATION` director init and a manual debug command clear it; other setters never do, pinning the record abstract for the save's life. | `PNC_PopulationDirector_Context.lua:34-36`; `PNC_CommunityDirector_NPCSpawner.lua:185`; `PNC_API/DebugCommands.lua:24` |
| P4-4 | `Materialize` has no failure containment between body spawn and registration; an error leaves a live, untagged body and permits a duplicate on the next retry. | `PNC_Presence_Materialize.lua:306-309,217-278` |

---

## 4. Fix plan

Design rule for every phase: **a journey must always have exactly one lane that
advances it, and must reach a terminal state (arrived / cancelled+reason) within
a bounded time.** No phase may leave a journey `en_route` without an owner.

### Phase 0 - baseline and instrumentation (no behaviour change)

1. Focused baseline already recorded:
   `python3 tests/run_tests.py pnc_travel pnc_presence pnc_home_duty
   pnc_native_path pnc_path_service pnc_engine_path pnc_simulation_lod
   pnc_live_travel` -> **2 of 18 fail, both pre-existing and unrelated**:
   - `pnc_home_duty_smoke.lua:295`: follow journey state expected
     `TRAVELING_TO_PLAYER`, actual `FOLLOWING_PLAYER`;
   - `pnc_travel_conversation_hold_smoke.lua:283` ->
     `PNC_BehaviorThreatGuard_Transitions.lua:376`: `SetCombatDebug` is nil in
     the test stub.
   Treat these as baseline, not as permission to weaken assertions.
2. Behind the existing per-record debug flag plus a travel diagnostics toggle,
   emit **one** line per stall, not per tick: journey id, state, controller,
   `segmentIndex`, remaining distance, player distance, the occupancy reason of
   each rejected candidate, the loaded state of the current segment target, and
   the escalation counter.
3. Add a counter pair the plan can be judged by: `journeys_blocked`,
   `warnings_per_journey`, `live_recoveries_per_journey`.
4. Use (2) to settle the one open question: is the blocker unloaded terrain
   (`unloaded` occupancy reason at the segment target) or a geometry pocket
   (`solid`/`solid_trans`/`occupied` with all passage probes rejected)? Both
   outcomes are covered by Phase 1, but the choice inside Phase 2 changes.

Deliverable: a diagnostic that makes one failing journey explainable in one
line, and a measured baseline.

### Phase 1 - journey integrity (P0)

1. **Terminal contract.** Add a bounded failure notification from the movement
   lane to its owner (`PathService` publishes reason + goal on `completeMove`;
   `BehaviorCommon.MoveRecord` returns it; `BehaviorTravel.Tick` forwards it to
   `Travel.Service.OnLiveBlocked(record, reason)`). No new tick, scan or
   allocation loop - it is a state-transition event.
2. **Escalation ladder in `Travel.Service`**, counters stored on the journey
   (and added to `BuildSummary`/`Normalize` so they survive a flip and a
   reload):
   - attempt 1: bounded replan of the current segment (engine path request to
     the same destination, `ENGINE_PATH_REPLAN_MS`-style cooldown);
   - attempt 2: mark `journey.blockedReason` and apply the handoff policy
     (Phase 2);
   - attempt 3+: force a terminal state - `cancelled` with an explicit reason,
     and notify the owner (`HomeDutyService` re-queues, `WorkService` releases
     the worker). The journey must not stay active.
   New constants in `PNC_Constants/TravelPathing.lua`:
   `TRAVEL_LIVE_MAX_REPLANS`, `TRAVEL_LIVE_MAX_RECOVERIES`,
   `TRAVEL_LIVE_ESCALATION_COOLDOWN_MS`, `TRAVEL_LIVE_HANDOFF_*`.
3. **Journey watchdog.** A bounded server sweep (existing
   `PNC_Server_SubsystemPumps` seam, one pass per `TRAVEL_POSITION_REFRESH_MS`
   window over active journeys only) that finds `en_route`/`waiting` journeys
   with no lane progress and no owning order, and applies step 2. This closes
   P0-2 and P0-4 without depending on any single behaviour.
4. **Ownership hygiene.** `Travel.Service.Start` publishes its order through
   `OrderSystem.SetOrder` (P0-3); `Cancel` detaches or terminal-flags the
   journey so it can never re-project a record afterwards (P0-5).

### Phase 2 - the live/abstract handoff (the actual "traversal" fix)

Two complementary rules; both go through the single `Presence.Abstract` /
`Presence.Materialize` boundary - no second body owner, no hidden body.

1. **Handoff out (live -> abstract).** `Presence.ShouldAbstract` gains a
   travel-aware branch: a record whose active journey is stalled past the
   Phase 1 ladder hands off to the abstract lane, with reason
   `travel_unreachable`. Guard rails:
   - never for `runtime.forceLive`, vehicle passengers, incapacitated, or an
     active follow/combat target (existing precedence kept);
   - only when the record is outside the player's visible radius
     (`>= MATERIALIZE_DISTANCE`) so nothing pops out in front of the player;
     otherwise defer with a bounded retry and keep walking live;
   - `Abstract` already calls `Travel.Service.OnAbstracted`, which syncs the
     body position and switches `controller` - the abstract lane then advances
     the journey at `ABSTRACT_TRAVEL_SPEED` and the 250 ms pump finishes it.
2. **Handoff in (abstract -> live).** `ShouldMaterialize` gains a
   destination-approach branch: materialize when an abstract journey is within
   `MATERIALIZE_DISTANCE` of its destination, so the arrival action runs with a
   body (chunk-readiness and settle gates unchanged, admission budget
   unchanged). Keep the existing player-near rule.
3. Optional distance policy (only if Phase 0 shows the stall is
   distance-driven rather than geometry-driven): refuse to start a *live* long
   haul at all - `Travel.Service.Start` requests
   `Presence.Abstract(record, "travel_long_haul")` when
   `route.totalDistance > TRAVEL_LIVE_MAX_DISTANCE` (new constant, default
   aligned with the abstract-follow long-range value of 64), subject to the same
   visibility guard.

### Phase 3 - flip symmetry and arrival correctness (P1)

1. `OnMaterialized` resyncs from the fresh body exactly like `OnAbstracted`
   (shared helper) and resets the live stall counters in both directions;
   `controller` is written on every edge.
2. Make lost distance impossible: `ProjectWorldPosition` must be able to move
   `distanceTravelled` **both** ways (drop the `math.max` floor, or floor only
   per live stint with an explicit `liveDistanceFloor`).
3. Arrival: dispatch at most once per `(journeyId, revision)`; do not
   substitute the default handler for a failed `colony_home` - record
   `RETURN_HOME_FAILED` and let the home duty retry with a bounded counter;
   stop the per-`Advance` re-dispatch loop.
4. Align the arrival predicate with the arrival radius: live arrival inside the
   anchor radius, and `IsWithinHome` becomes z-aware.
5. `Cancel`/`arrived` journeys are neutralized (see Phase 1.4) so
   `prepareRecord` cannot re-project the record.

### Phase 4 - live movement quality (P2, bounded)

1. Relax `bestGoalDistance` when the lane goal changes **and** when the body
   drifts beyond a small hysteresis past it; replace the 24-consecutive-step
   limit with a time+distance budget; add a bounded lateral-exploration
   escalation that hands control back to the journey ladder instead of looping.
2. Align fake/native progress thresholds, honour `nativeSafe` in the router,
   keep the fallback window, and bound fallback/recovery counts per goal.
3. Logging: one `WARN` per blocked transition, periodic detail at `DEBUG`,
   hard cap per journey.

### Phase 5 - home semantics (P3)

1. Zone-correct last-resort anchor, reachable worker reconciliation branch,
   consistent use of `homeState` (drive a bounded retry, or delete the field).

### Test matrix

- unit/behaviour (extend existing suites): `pnc_travel_service_smoke`,
  `pnc_travel_service_presence_boundary_smoke`, `pnc_presence_*`,
  `pnc_home_duty_smoke`, `pnc_native_path_stall_smoke`,
  `pnc_path_service_recovery_smoke`, `pnc_engine_path_planner_smoke`,
  `pnc_simulation_lod_smoke`, `pnc_live_travel_threat_smoke`,
  `pnc_travel_conversation_hold_smoke`.
- new assertions: `/arrived` after a long journey in one of three ways
  (live arrival, handoff + abstract completion, explicit cancel+reason);
  `/not/en_route` after the escalation ladder; `controller` correct on both
  edges; `distanceTravelled` monotone in the direction of travel across a flip;
  arrival action invoked exactly once; warning count per journey bounded;
  `presenceState` and body existence agree after every transition.
- runtime verification: one home-bound colonist, long distance, watch
  `console.txt` for `journeys_blocked`, the warning histogram, and that the NPC
  reaches `IsAtHome`.

---

## 5. Decisions taken

1. **Handoff trigger**: **distance policy**. A live journey with more than
   `TRAVEL_LIVE_MAX_DISTANCE` (64) tiles left hands off as soon as the nearest
   player is outside `MATERIALIZE_DISTANCE` (28). The escalation ladder remains
   as the safety net for a journey that is stuck for any other reason.
2. **End of the ladder**: **cancel + notify the owner**. The journey reaches
   `cancelled` with an explicit reason, the travel order is released, and the
   owner (`colony_return_home` -> `HomeDutyService.OnTravelFailed`) restores the
   durable home order with a bounded retry cooldown.
3. **Scope**: Phases 0-3.

## 6. Implementation status (Phases 0-3)

Implemented and test-covered:

| change | file |
| --- | --- |
| handoff constants (distance, ladder, watchdog, arrival, home retry) | `PNC_Constants/TravelPathing.lua` |
| `Model.LiveHandoffRequired`, persisted ladder/arrival/failure bookkeeping, `createdAtMs` grace stamp | `Travel/PNC_Travel_Model.lua` |
| travel-aware `ShouldAbstract`, handoff-aware `ShouldMaterialize` anti-thrash guard | `Presence/PNC_Presence/PNC_Presence_Decisions.lua` |
| `Service.FailJourney`, `Service.NotifyOwner`, `Service.AuditActiveLiveJourneys` watchdog, bounded arrival redispatch | `Travel/PNC_Travel_Service/PNC_Travel_Service_Core.lua` |
| escalation ladder, `handoffForced` request, flip symmetry + stall-state reset, home-zone distance clamp | `Travel/PNC_Travel_Service/PNC_Travel_Service_Live.lua` |
| terminal journeys never re-project their record | `Travel/PNC_Travel_Service/PNC_Travel_Service_Progression.lua` |
| travel order published through `OrderSystem.SetOrder` when the normalizer is registered | `Travel/PNC_Travel_Service/PNC_Travel_Service_Control.lua` |
| `Arrivals.StrictActionTypes`, bounded arrival attempts + retry stamp | `Travel/PNC_Travel_Arrivals.lua` |
| watchdog wired into the server prepare phase | `server/PNC/Server/Server/PNC_Server_SubsystemPumps.lua` |
| home arrival is a strict action type | `server/.../HomeDutyService/PNC_HomeDutyService_Arrivals.lua` |
| `Service.OnTravelFailed`, bounded `homeRetryAt` cooldown in `EnsureHomeAnchor` | `server/.../HomeDutyService/PNC_HomeDutyService_{Commands,Core}.lua` |
| new regression test | `tests/pnc_travel_live_handoff_smoke.lua` |

Deliberately **not** implemented:

- **Materialize-on-approach (abstract -> live at the destination).** With no
  player near the destination, a materialized body would be abstracted again by
  the `range_exit` rule on the next presence pass, so it would only add body
  churn. Arrival already completes in the abstract lane, and the existing
  player-near rule still materializes the NPC when a player is there.
- **Phases 4 and 5** (live movement quality, home semantics). The remaining
  register entries stay as documented follow-ups: fake-locomotion ratchet
  relaxation, router `nativeSafe`/fallback budget, log volume, z-aware
  `IsWithinHome`, unreachable worker reconciliation branch, `homeState`
  consumers.

Verification:

- focused suite
  (`pnc_travel pnc_presence pnc_home_duty pnc_native_path pnc_path_service
  pnc_engine_path pnc_simulation_lod pnc_live_travel`): 19 tests, the same 2
  pre-existing failures as the recorded baseline, and the new
  `pnc_travel_live_handoff_smoke` passes.
- full suite: 752 tests, 36 failures - **every one of them also fails at
  `HEAD`** (a clean `git worktree` baseline run gave 38 failures, a superset).
  No new failures. Two `HEAD` failures are fixed by the unrelated uncommitted
  work already in the tree.
- all changed files pass `luac -p` and the Kahlua ERROR scan.
- no staging directories were created under `media/`; every runtime file was
  rewritten in place while the game was running.

Runtime note: the changed files must be picked up by a full game restart. Do not
hot-reload a partially written set of interdependent modules mid-session.

Watch item for the first playtest: the handoff floor reuses
`MATERIALIZE_DISTANCE` (28 tiles), so an NPC hands a long journey off once the
nearest player is 28+ tiles away. On a zoomed-out client that is close to the
edge of view. Raise the floor or `TRAVEL_LIVE_MAX_DISTANCE` if a colonist is
seen disappearing.

---

# 7. Follow-up audit: a colonist at home does not follow the player

Reported after the Phase 0-3 work: return-home now works, but a colonist that
reached the base and is then ordered to follow stays `abstract` and never moves
toward the player, with no error. NPC Monitor shows AI `Follow Owner` and the
`abstract` presence badge.

## 7.1 Verified state

- Live profiler during the report: `npcLutherPacker_Z1IS` and
  `npcOrvilleSilas_3MTR` are both `presence: abstract`.
- Fresh `console.txt` contains **no** error and only two new markers, both mine:
  `travel_watchdog_stall ... remaining=594/511 target=10622,10336
  targetOccupancy=unloaded` - i.e. the *old* return-home journey was still
  walking and had already closed 83 tiles. The home fix works.
- NPC Monitor renders presence as a badge and the AI row as
  `item.activeBehavior or item.activeJob` (`PNC_NPCMonitorSupport.lua:103`,
  `:88`). So "Follow Owner + Abstract" means the *abstract follow tick did run*
  and set `activeJob = "FollowOwner"` (`PNC_BehaviorCompanion_FollowOwner.lua:68`).

## 7.2 The abstract follow lane, end to end

```text
ProcessRecord (PNC_Server_RecordProcessing.lua:112-118)
  -> BehaviorSystem.Tick
       early returns before the follow branch:  tickPendingSleepWake (:49-67)
                                                PuppetOpera lease (:69)
                                                OrderSystem.RecoverStalled (:262)
       -> isAbstractFollowRecord(record)            PNC_BehaviorSystem.lua:154-168,289
            requires presenceState == abstract and orderSpec.kind == follow
       -> Internal.TickAbstractFollowOwner          FollowOwner.lua:23
            owner = Common.GetOwner(record)         PNC_Behavior_Common.lua:146-159
              -> owner resolved:  target = player, MoveRecord(record, nil, ...)
              -> owner nil:       target = record.anchorX/Y/Z, mode = "returning_to_anchor"
                                  FollowOwner.lua:86-91
            MoveRecord abstract branch              PNC_Behavior_Common.lua:~400
              -> PathService.AdvanceAbstract        MotionApi.lua:153-202 (straight step)
```

Two independent ways this lane produces **zero movement with no error**, and both
require the record to be holding a facility lease:

**H1 - the move is refused before it starts.** `MoveRecord` resolves a stationary
presentation first and halts:

```lua
presentationKind = liveBodyControl.ResolveStationaryPresentation(record, now)   -- :233
if presentationKind then ... Common.HaltMovement(record, zombie, "sleep_hold")
    return false, presentationHoldReason end                                    -- :250-288
```

`ResolveStationaryPresentation` (`PNC_LiveBodyControl_State.lua:262-277`) returns
`sleep`/`sleep_wake`/`seat` whenever
`record.runtime.facilityActivity` is a live sleep or seat lease
(`IsSleeping` `:238-248`, `IsSleepWakeActive` `:250-257`, `IsSeated`). A colonist
that reached the base is exactly where the home/needs route assigns sleep and
seat activities, so an abstract follower there can be permanently halted. The
guard is silent unless the seating diagnostics are enabled, and
`TickAbstractFollowOwner` ignores `MoveRecord`'s return value and sets
`moved = true` unconditionally (`FollowOwner.lua:160-172`) - so even the existing
audit would claim movement.

**H2 - the owner cannot be resolved, so the follower walks to its anchor.**
`FollowOwner.lua:86-91` falls back to `record.anchorX/Y/Z` with
`mode = "returning_to_anchor"`. For a colonist spawned by the community director
the anchor is *the base* - where the NPC already stands. `dist <= stopDistance`
=> `arrived = true` => `MoveRecord` is never called => provably zero movement.
The owner comes from `Common.GetOwner` using `record.ownerUsername` /
`record.ownerOnlineID`, which `OrderSystem.SetOrder` copies from the order
(`PNC_OrderSystem.lua:304-306`); `followOrder` only fills them from
`player:getUsername()` / `player:getOnlineID()`
(`PNC_CompanionCommandDefinitions.lua:55-61`). The abstract lane has a repair
path for a missing record field (`FollowOwner.lua:30-44`) but it depends on the
order having a usable identity in the first place.

Ruled out: the `tickPendingSleepWake` early return (H3) cannot be the cause here
because the AI row proves the follow tick ran. It remains a latent freeze risk
for the other order kinds and is worth bounding.

## 7.3 Root defect shared by H1 and H2

**A player order does not revoke the facility lease that owns the NPC.** The
only revocation is in `OrderSystem.SetOrder`:

```lua
if previousKind == "facility_activity" and requestedKind ~= "facility_activity"
   and activeFacility and PNC.FacilityJobs.AbortForOrderChange then ... -- :255-269
```

The condition tests the *previous durable order kind*, but the lease lives in
`record.runtime.facilityActivity` independently of it. A colonist whose durable
order is `colony_home` (or `travel`) while a sleep/seat activity is live -
precisely the "went home, then was ordered to follow" case - keeps the lease, so
`MoveRecord` keeps halting every movement request with `sleep_hold`/`seated_hold`
while `orderSpec.kind` already says `follow`. This is the same class as P0-3 in
section 3 (`Start` bypassing `SetOrder`): the lease/order precedence is wrong,
not the movement code.

Note this is **not** a regression from the Phase 0-3 work: the handoff predicate
requires `Model.IsActive(record.travel)`, and `prepareFollowOrder`
(`PNC_CompanionCommandRegistry.lua:687-698`) cancels the journey when the follow
order is applied, so no journey is active afterwards and
`travelHandoffRequired` is false. The watchdog only inspects records with an
active journey. The previous work simply let colonists reach the base, which is
where the lease is taken.

## 7.4 Plan

### Phase 0 - confirm which hypothesis (one toggle, one minute)

Enable `ProjectHoomans.FollowerPresenceAudit` ("Follower presence audit",
`PNC_PerformanceScalingDiagnostics.lua:134-143`, runtime-mutable, free when
disabled), reproduce, and read one `abstract_follow_tick` line
(`FollowOwner.lua:174-201`):

- `ownerResolved=false` and `target` = the base -> **H2**;
- `ownerResolved=true`, `distanceBefore == distanceAfter`, `moved=true` -> **H1**
  (the move was refused; the log currently lies about `moved`).

### Phase 1 - revoke the owning lease on a movement order (H1, the root defect)

1. `OrderSystem.SetOrder`: abort the active facility lease when
   `runtime.facilityActivity` exists and the requested order is a movement order
   (`follow`, `travel`, `guard`, `patrol`, `roam`), independent of
   `previousKind`. Keep the camp reason/`camp_entered` behaviour and the
   `requestedKind ~= facility_activity` guard.
2. `prepareFollowOrder`: explicit second line of defence - if the live activity
   is a stationary presentation (sleep/seat/relax), stop it through the existing
   facility command before installing the follow order, and fail the command
   with a reason instead of installing a follow order that cannot move.
3. Make the refusal observable: `TickAbstractFollowOwner` must use
   `MoveRecord`'s return value, log one gated `abstract_follow_move_held` line
   with the reason, and set `moved` from the real distance delta.

### Phase 2 - owner identity (H2)

1. `prepareFollowOrder(record, player)`: resolve and write
   `record.ownerUsername` / `record.ownerOnlineID` at command time through
   `Core.ResolvePlayerBy*`, with a single-player fallback to the local player,
   instead of relying on the abstract lane's self-repair.
2. `TickAbstractFollowOwner`: when the owner is unresolved, do not silently walk
   to the anchor. Retry resolution for a bounded number of ticks
   (`runtime.followOwnerRetry`), wake presence (`forcePresenceCheck`), and emit
   one gated warning; only fall back to the anchor after the retry, and treat
   "I am already at my anchor" as a reported failure rather than success.

### Phase 3 - bound the sleep wake transaction (latent H3)

`tickPendingSleepWake` returns before the follow branch for as long as
`activity.sleepWakePending` is set. Add a bounded escape: when the pending flag
outlives `sleepWakeDeadlineAt` plus slack, force-clear it, log once, and let the
behavior tick resume. Verify the abstract-record case can always complete the
transaction.

### Phase 4 - tests

Extend the follower suites (`pnc_abstract_follow_smoke`,
`pnc_abstract_follow_catchup_smoke`) or add
`pnc_abstract_follow_lease_smoke`:

- a follow order aborts a live sleep/seat facility activity even when the
  previous durable order was `colony_home` or `travel`;
- an abstract follower holding a stationary presentation either moves or reports
  `abstract_follow_move_held` - it must never be silently frozen;
- `moved` reflects the real position delta;
- an unresolved owner does not anchor-walk while a local player exists, warns
  once, and does not spin;
- after a follow order, `JobSystem.Select` does not return `FacilityActivity`
  for the record.

Immediate workaround for the reported case: bring the player within
`MATERIALIZE_DISTANCE` (28) of the colonist so the body is re-created, which lets
the sleep/seat lease release normally, or issue a non-follow order (stay/guard)
and then follow again after they wake.
