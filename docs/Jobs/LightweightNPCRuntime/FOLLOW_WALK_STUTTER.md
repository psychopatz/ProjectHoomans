# Follow-Walk Stutter Harness and Root-Cause Plan

## Status

**ACTIVE L6 DEVELOPER WORK.**

User-owned native acceptance after L5 exposed a remaining gameplay defect: ordinary player walking with multiple live companions following can still produce severe visible stutter. This invalidates the prior assumption that L0-L5 developer acceptance was sufficient for ordinary follow movement.

The correction is to extend the existing deterministic Lightweight NPC Runtime simulator. Do **not** build a second follow benchmark or a disconnected fake AI.

## Verified coverage gap

Current source shows that the integrated simulator moves its fake first player only on the one-second boundary by changing X with `_setX(...)`. The fake player does not expose the complete moving-player contract used by live `FollowOwner`, including `isPlayerMoving()` and a continuously changing travel vector.

The existing follow smoke tests verify important isolated contracts such as MP movement-heading stability, formation caching, hold leases, move-mode selection, follow/combat interaction, and profiler marker availability. Those tests do not run a sustained integrated workload where one player continuously walks while 1/3/6/12 live companions execute the real follow decision, formation, move-intent, and path-service seams.

The integrated runtime simulator therefore currently measures **player interest movement around a mostly abstract world**, not the native symptom that triggered L6.

## Current code facts

At the audited revision:

- `FOLLOW_DECISION_INTERVAL_MS = 200`
- `FOLLOW_TICK_INTERVAL_MS = 100`
- `FOLLOW_RETARGET_OWNER_DISTANCE = 0.75`
- `FOLLOW_RETARGET_MAX_MS = 800`
- `FOLLOW_MOVE_INTENT_EPSILON = 0.35`
- `ENGINE_PATH_REQUEST_BUDGET_WINDOW_MS = 100`
- `ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW = 1`
- `ENGINE_PATH_REPLAN_MS = 1000`
- `ENGINE_PATH_TARGET_REPLAN_DISTANCE = 1.5`

These values are evidence for what the harness must observe; they are **not** permission to tune constants before the baseline identifies the dominant source of stutter.

## Native evidence and profiler caution

The native session that triggered this phase showed six live recruited followers active under one owner. During the audit, the profiler reached peaks of:

~~~text
Follow.Live        = 6
Follow.Orders      = 6
Follow.OwnerGroups = 1
Follow.OwnerMoving = 6
Follow.PathActive  = 6
~~~

The same captured session emitted repeated follow/path symptoms including native progress timeouts, a native stall recovery, window/fence traversal starts and completions, missing fence-transfer signals, and movement-state suppression while the owner was moving.

The latest profiler snapshot remains in `DETAILED` mode. Deep instrumentation materially changes the workload and therefore must not be used as the clean performance baseline. L6 timing comparisons use profiler `OFF`; bounded coarse/deep capture may only explain a spike after the profiler-OFF workload is reproducible.

The native evidence is enough to justify the test gap. It is **not** yet proof that native path replanning is the sole root cause.

## L6 deterministic workload

Extend `tests/support/lightweight_runtime_simulator.lua`, `tests/pnc_lightweight_runtime_simulation_smoke.lua`, and `tests/benchmarks/lightweight_npc_runtime.lua` rather than creating a parallel framework.

Add a deterministic moving-player contract that updates every simulation step, preferably at `stepMs = 50`, and implements the production-facing player methods used by follow logic:

~~~text
getX / getY / getZ
isPlayerMoving
isRunning
isSprinting
getForwardDirection
getOnlineID
getUsername
~~~

The fixture must drive the real production seams wherever engine-independent:

~~~text
Scheduler / SimulationLOD
  -> BehaviorCompanion.TickFollowOwner
  -> owner motion state
  -> formation slot sampling
  -> FollowOwner movement plan
  -> BehaviorMoveIntent
  -> PathService
  -> native-path adapter boundary
~~~

The fake native-path boundary must model request ownership, progress, completion, drift/replan, and injected stalls without reimplementing the production planner.

### Standard trajectory

Use a reproducible trajectory such as:

1. 0-10 s: continuous straight walk
2. 10-15 s: ninety-degree turn while walking
3. 15-18 s: stop and allow formation hold
4. 18-28 s: resume walking
5. 28-35 s: run/catch-up pressure
6. final settle/hold interval

The exact distances may be tuned to repository conventions, but all steps must be deterministic and long enough to cross the real follow/retarget/replan cadences.

### Follower scaling

Exercise at minimum 1, 3, 6, and 12 followers. The six-follower case is the primary reproduction target because it matches the observed native party size.

## Required scenarios

### `FOLLOW_WALK_OPEN`

Straight/turning movement in an unobstructed deterministic world. Isolate pure owner-motion, formation, move-intent, and moving-target route churn.

After initial route acquisition, require zero obstacle traversal events, zero healthy-provider progress timeouts, zero stall recoveries, move-intent suppression between meaningful target changes, and path requests/replans attributable to actual route acquisition or target drift rather than every follow tick.

### `FOLLOW_WALK_TURN_STOP`

Walk -> turn -> stop -> hold -> resume. Catch moving/idle oscillation, unnecessary route cancellation, formation rebuilding, and synchronized follower wakeups.

Verify stop grace prevents micro-jitter thrash, stable hold does not repeatedly cancel movement, resume does not create an unbounded same-frame burst, and formation cache behavior remains stable.

### `FOLLOW_WALK_OBSTACLE`

A deterministic corridor containing representative door/fence/window traversal boundaries. Reproduce the class of traversal churn seen in native logs while keeping the scenario deterministic.

Verify bounded traversal starts/completions, retries, recovery, path invalidation/replan, and passage handoff. The fixture must not pretend an obstacle is successfully traversed when the production handoff rejects it.

### `FOLLOW_WALK_STALL`

Inject one follower whose native route stops making progress. Prove one bad route does not cause group-wide follow/path churn.

Verify only the affected route enters timeout/backoff/recovery, unaffected followers continue, request budgets remain bounded, and no whole-party route reset occurs unless production policy explicitly requires it.

## Required counters

Expose counters from production diagnostics or narrow test adapters for follow decisions, owner-motion samples/transitions, formation group builds, formation resolves/cache hits, sampled-target refreshes, move-intent requests/no-op suppression, PathService move requests, engine path requests, moving-target replans, retries, native request-budget deferrals, active routes, timeouts/stall backoffs, traversal starts/completions/failures, path invalidations/cancellations, presence-delta sends, world-census refreshes, maximum path requests/replans in one simulated frame, and average/p95/max simulator tick CPU in profiler-OFF mode.

Do not invent expected counter values. First record the pre-fix baseline, then set regression bounds that reflect the accepted algorithm.

## Low-overhead stutter trace

Add a tiny **off-by-default** diagnostic suitable for native correlation without requiring deep profiling. When enabled explicitly, maintain a bounded ring buffer of recent per-frame/top-level samples such as:

~~~text
serverUpdateMs
ownerMovedDistance
movingFollowers
activeRoutes
followDecisions
moveIntents
enginePathRequests
replans
retries
timeouts
traversalStarts
censusRefreshes
presenceDeltas
~~~

On a configurable frame/update spike, emit a short pre-spike / spike / post-spike window.

Requirements:

- disabled path adds effectively no allocation-heavy per-NPC work
- ring size and output are bounded
- no persistent unbounded logs
- no deep wrappers are required
- diagnostics use existing counters where possible
- the trace is observational only and never changes scheduling/path behavior

## Root-cause gate

Do not optimize FollowOwner/pathing until the baseline can distinguish at least:

| Evidence | Likely area |
| --- | --- |
| open-field move intents/path requests scale with follow decisions | follow target/move-intent churn |
| move intents are bounded but engine requests/replans spike | native path planner/replan ownership |
| open field is healthy but obstacle scenario spikes | passage/traversal/recovery |
| pathing is bounded but census/presence spikes correlate | non-path shared runtime lane |
| only deep profiling shows the spike | instrumentation overhead, not normal-play proof |

Record one profiler-OFF baseline for 1/3/6/12 followers and preserve the operation counts before editing the hot path.

## Conditional optimization candidates

Only use candidates justified by the measured baseline.

**Shared owner-group pursuit corridor / trajectory cache.** If individual moving formation slots cause unnecessary native route churn, compute a shared owner travel corridor/trailing anchor per follow-owner group and let each follower apply cheap local slot steering around that shared pursuit direction. The shared route concept must not erase per-follower collision/passage correctness.

**Deterministically staggered replans.** If several followers become replan-eligible at the same moment, assign stable per-owner-group offsets so they cannot all attempt expensive native replanning on the same scheduler slice. Staggering must not delay urgent recovery, combat escape, level transitions, or clearly invalid routes.

**More stable route targets.** If the current target moves faster than native routing needs, separate high-frequency local formation steering from lower-frequency native route destination changes. Do not make followers visually unresponsive merely to reduce path calls.

**Request-budget changes.** Do **not** blindly increase `ENGINE_PATH_REQUEST_BUDGET_PER_WINDOW`. A larger synchronous engine budget may convert repeated small hitches into one larger frame spike. Change the budget only if the harness/native trace proves queue starvation rather than path-computation cost.

## L6 acceptance

L6 is developer-complete only when:

1. continuous moving-player + real FollowOwner workload exists in the integrated simulator
2. 1/3/6/12 follower cases are reproducible
3. open/turn-stop/obstacle/stall scenarios exist
4. pre-fix profiler-OFF operation baselines are recorded
5. the dominant developer-reproducible churn source(s) are identified before optimization
6. any optimization reduces the implicated operation counts/cost on the identical workload
7. open field has no healthy-provider stalls/timeouts/traversal noise
8. obstacle/stall recovery remains bounded and correct
9. follow responsiveness, formation spacing, combat preemption, and MP owner-heading behavior retain their existing focused tests
10. the low-overhead stutter trace can correlate a later native hitch without deep profiling
11. existing L0-L5 runtime, persistence, replication, and Core-authority suites remain green apart from documented unrelated baselines

Native Project Zomboid remains the final proof of Java pathfinder/frame-time feel. After L6 developer acceptance, return to user-owned SP/MP testing with profiler `OFF` first.

The parent L6 phase also requires the combat-hit gate in [COMBAT_HIT_STUTTER.md](COMBAT_HIT_STUTTER.md) and the abstract-travel/materialization gate in [ABSTRACT_TRAVEL_HANDOFF_STUTTER.md](ABSTRACT_TRAVEL_HANDOFF_STUTTER.md); fixing follow movement alone cannot close L6.
