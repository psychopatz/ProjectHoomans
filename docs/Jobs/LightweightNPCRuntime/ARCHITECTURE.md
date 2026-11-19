# Architecture — Lightweight NPC Runtime

## 1. Ownership model

### PsychopatzCore owns canonical durable actor/world state

For Core-backed SurvivorWorld actors, Core remains authoritative for reusable provider-neutral domains, including actor identity/seed, deterministic or authored appearance, canonical personal inventory, portable social/persona state, world/group/affiliation state, provider lease/lifecycle, and shared map/portrait projections.

Project Hoomans must not serialize a second copy of those domains merely because it temporarily owns a physical provider representation.

### Project Hoomans owns physical gameplay/runtime and sparse durable extension state

Hoomans owns live body lifecycle/binding, combat, local perception/pathing, physical animation, Hoomans-specific jobs/facilities/medical/gameplay policy, physical inventory/body synchronization, interaction state, and only Hoomans-specific durable deltas that cannot be reconstructed from Core canonical state.

## 2. Representation levels

Use one canonical actor with progressively richer Hoomans representation:

| Level | Owner | Cost rule |
| --- | --- | --- |
| compact abstract actor | Core | always allowed; no full Hoomans record required |
| provider-neutral projection | Core/shared projection | map/portrait/hover/discovery without Hoomans AI |
| Hoomans runtime record | Hoomans | created only for a concrete Hoomans gameplay responsibility |
| live physical body | Hoomans provider | materialized only inside bounded live-presence policy |

A compact actor remaining far away must never be promoted merely because it exists in the Core registry.

## 3. Lazy promotion

Remove bulk `HydrateCoreActors()` from normal startup/generated-view refresh. Do not replace it with another whole-registry Hoomans projection pass.

Promote one actor on demand when at least one Hoomans responsibility requires a rich runtime record, for example entering Hoomans materialization/interaction interest, becoming/reloading a recruited companion, explicit Hoomans provider handoff, Hoomans job/facility/medical/combat state that cannot execute abstractly, or authorized debug force-live.

Map, roster, portrait, discovery and abstract-world queries should consume Core projection directly when no Hoomans runtime responsibility exists. Promotion must be idempotent by canonical actor ID.

## 4. Demotion

A promoted Core-backed actor may be demoted after it has no live body and no active Hoomans responsibility that needs rich runtime state.

Before demotion:

1. capture final durable Core-owned deltas through Core APIs;
2. capture only Hoomans-owned durable extension state;
3. compact inventory through the existing Core/Hoomans bridge;
4. release scheduler/spatial/live-body/presence runtime references;
5. discard Hoomans-only transient state.

Demotion never deletes or replaces the canonical Core actor. Do not introduce a second tombstone/GC database; reuse Core actor lifecycle/GC contracts.

## 5. Hoomans durable extension storage

Prefer the existing bounded Core actor namespaced-extension seam if it can hold required Hoomans-owned durable data without violating Core ownership or size contracts. If exact source proves that seam unsuitable, use one sparse Hoomans extension repository keyed by canonical actor ID.

There must be **one chosen extension authority**, never both.

The extension must not duplicate identity/name/seed, Core appearance, Core personal inventory, Core social/persona state, canonical affiliation/world/journey, or provider lease. Each extension field requires an owner, durability reason, bound, and save/reload test.

## 6. Persistence transaction model

Separate logical mutation from physical persistence:

```text
gameplay mutation
  -> validate/mutate authority
  -> increment revision / mark specific domain dirty
  -> enqueue/coalesce persistence work
  -> return to gameplay

bounded persistence pump / OnSave / shutdown
  -> serialize only dirty owners/domains
  -> write ModData
  -> perform required global flush
```

Ordinary gameplay commits must not call `GlobalModData.save()` synchronously unless a documented critical checkpoint requires it.

Do not scan every actor to discover normal dirty state. Mutating authorities must mark their own domains. Position/stamina capture for promoted physical actors may use bounded checkpoint sampling rather than a global scan on every logical commit.

Serialization outcomes must distinguish success/written, terminal/not-applicable (clear local retry state), and retryable failure (retain dirty state with bounded backoff/diagnostics). A schema/ownership mismatch must not become an infinite retry loop.

## 7. Network domain revisions

Keep independent revisions/deltas for meaningful domains. At minimum audit presence/motion, combat action/state, health/damage, wounds/treatment/medical, equipment/visible appearance, inventory summary/detail, replicated needs/job state, and full detail/inspection.

Full NPC snapshot is reserved for initial full-detail hydration, explicit inspection where required, reconnect/repair or protocol fallback. A one-domain mutation must not rebuild unrelated domains.

Preserve the accepted NPCReplicationScaling portrait/incarnation/revision protocol and its fallback behavior.

## 8. Profiler contract

Profiler default normal-play cost must be effectively zero.

- `OFF` installs no deep wrappers.
- cheap coarse sampling may observe top-level server/persistence/network lanes without wrapping dozens of per-NPC helpers;
- deep instrumentation is explicit and time-bounded;
- stopping/expiry restores original functions/events deterministically;
- persisted debug configuration must not silently force deep capture forever;
- diagnostics clearly label instrumented timing as such.

Implement shared profiler behavior in PsychopatzCore; Project Hoomans owns only its feature registration/metrics.

## 9. Headless runtime simulation contract

The developer feedback loop uses one deterministic integrated simulator described in [RUNTIME_SIMULATOR.md](RUNTIME_SIMULATOR.md). It drives real production seams behind narrow fake Project Zomboid boundaries and must cover Core actor population, Hoomans promotion/demotion, scheduler membership, persistence, domain networking, materialization, zombie/census budgeting and profiler modes.

A phase optimization is not considered developer-verifiable if it can only be exercised by manually launching Project Zomboid. L1-L4 must extend the simulator whenever their runtime contract changes. Prefer operation/count assertions over machine-specific timing thresholds; headless elapsed timing is supporting evidence only.

The simulator does not replace native acceptance for body creation, Java pathfinding, rendering/chunk costs, real sockets, asset rendering or actual SP/MP engine event behavior.

## 10. Activity-sensitive budgets

After authority/persistence/network work lands and a clean baseline identifies remaining cost, tune global simulation budgets without reducing correctness.

Candidate policy: combat/urgent danger uses fastest cadence; ordinary moving/following uses medium cadence; idle/hold uses slower cadence; no live Hoomans bodies uses the slowest cadence; threat/damage/materialization/interaction events wake relevant lanes early.

Materialization remains bounded and prioritized. Do not synchronously promote or spawn an unbounded crowd when the player enters a populated area.

## 11. Complexity target

For `N` canonical Core actors and `L` actors with current Hoomans runtime responsibility, ordinary Hoomans hot-path work should trend with `L`, not `N`.

Desired shape:

- Core abstract storage: O(N), compact;
- Hoomans rich runtime state: O(L);
- full-body AI/path/combat: O(live/active subset of L);
- mutation persistence: O(actual dirty domains), not O(N) per logical commit;
- recipient replication: O(interested recipients x changed domain), bounded by existing interest/capability contracts.
