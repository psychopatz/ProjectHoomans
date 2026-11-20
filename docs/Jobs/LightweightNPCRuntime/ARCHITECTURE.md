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

Bulk `HydrateCoreActors()` is retired from startup and generated-view refresh (`RestoreActiveCoreActors` restores only active/persisted Hoomans extensions, and interest refresh promotes at most `CORE_PROMOTE_MAX_PER_REFRESH = 4` per pass). Do not replace it with another whole-registry Hoomans projection pass.

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

The single chosen extension authority is `PsychopatzCore` actor namespaced
extension storage at `actor.extensions["ProjectHoomans.ActorExtension"]`
(`schemaVersion = 1`, managed by `PNC_CoreActorExtension.lua`). Unmodified
bystanders encode to `nil` (`0` bytes), and Core-backed records never write
duplicate `PNC_NPC_<id>` ModData or re-serialize Core appearance envelopes.

The extension never duplicates identity/name/seed, Core appearance, Core
personal inventory, Core social/persona state, canonical
affiliation/world/journey, or provider lease. Each extension field has an
explicit owner, durability reason, bound, and save/reload test.

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

A phase optimization is not considered developer-verifiable if it can only be exercised by manually launching Project Zomboid. L1-L4 and L6 must extend the simulator whenever their runtime contract changes. Prefer operation/count assertions over machine-specific timing thresholds; headless elapsed timing is supporting evidence only.

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

## 12. Continuous follow-movement performance contract

`FollowOwner` responsiveness is a hot gameplay contract, but a moving owner must not force every follower to rebuild equivalent expensive route work at every decision.

Separate three concepts:

~~~text
owner trajectory / shared group pursuit direction
    -> per-follower formation/local steering target
    -> native route acquisition/replan only when route semantics require it
~~~

The exact implementation may remain fully per-follower if measurement proves it cheap. L6 does not mandate a shared path. It mandates that the distinction be measurable and that native route changes are not accidentally coupled one-for-one to high-frequency follow decisions.

Required properties:

- owner movement sampling remains responsive to real SP/MP travel direction
- formation sampling/cache rules remain deterministic
- `ShouldIssueFollowMove` suppresses semantically unchanged movement
- native path ownership/replanning remains the PathService/EnginePathPlanner responsibility
- obstacle/passage handling stays authoritative per physical follower
- one stalled follower must not reset an otherwise healthy follow group
- expensive replans may be deterministically staggered when safe, but urgent invalidation/recovery cannot be delayed behind cosmetic smoothing
- increasing native path request concurrency is not a default performance fix

The integrated simulator is the developer authority for operation-count regression. Native PZ remains the authority for Java pathfinder cost and frame-time feel.

## 13. Low-overhead stutter correlation

Normal gameplay must not require deep profiler wrapping to diagnose a hitch.

An explicitly enabled stutter trace may retain a small bounded ring of top-level per-frame counters already produced by runtime diagnostics, then dump a short window when a configurable server-update/frame threshold is crossed.

The trace must be off by default, bounded in memory and output, allocation-light while enabled, effectively absent from normal hot paths while disabled, observational only, and based on coarse counters rather than wrapping each follower helper.

Its purpose is correlation, not attribution by itself. A spike window should make it possible to compare follow/path requests, replans, traversal, combat hit/reaction fan-out, wound/social/faction work, census, persistence, and network activity around the hitch, after which focused instrumentation can be enabled only for the implicated lane.

## 14. Combat-impact performance contract

A combat decision, attack animation, and successful impact are separate performance stages. L6 must measure them separately.

The authoritative impact chain is conceptually:

~~~text
committed attack
  -> impact gate
  -> hit event
  -> immediate authoritative target mutation
  -> target-specific reaction / wound / stats sync
  -> social / faction / semantic consequences
  -> network delta/reaction
  -> deferred/coalesced persistence where permitted
~~~

For NPC -> zombie, NPC -> Hoomans NPC, and NPC -> player, the damage result must remain authoritative and immediate. Expensive **secondary** work may be indexed, deduplicated, coalesced, or deferred only when that does not change gameplay outcomes.

Required invariants:

- misses and accepted hits are measurable separately
- target-specific post-hit fan-out is measurable
- repeated hits must not trigger whole-population work unless a documented bounded query truly requires it
- one hit must not force unrelated full-record snapshots
- NPC wound/medical/faction/social hooks remain semantically correct
- player damage retains required body/stats synchronization
- zombie hit reaction/aggro remains correct
- kill/death transition work executes once per transition, not once per already-dead follow-up hit
- synchronized combatants may not create unbounded same-frame downstream work
- low-overhead diagnostics remain observational and off by default

The accepted optimization may differ by target type. Do not force one generalized batching mechanism across zombie, NPC, and player damage paths if their authority contracts differ.

## 15. Abstract travel and representation-handoff performance contract

Compact travel is a time-domain simulation problem, not a reason to run physical AI off-screen.

The canonical ownership chain is:

~~~text
PsychopatzCore group/actor journey
    -> deterministic elapsed-world-time projection
    -> player-interest test at projected position
    -> Hoomans promotion/materialization only when relevant
    -> live physical travel while safely observable
    -> capture live route progress on abstraction
    -> Core/compact elapsed-time projection resumes
~~~

Required invariants:

- one journey identity survives abstract/live/abstract representation changes;
- large world-time jumps advance mathematically through segments and waits rather than replaying server frames;
- distant mobile groups do not require full Hoomans records or bodies merely to travel;
- map/debug/discovery projection is observational and never permission to promote;
- materialization uses current projected position, not stale departure/staging coordinates;
- live progress may advance a journey but may never rewind canonical distance travelled;
- overlapping multiplayer interest deduplicates materialization and retains one authority/body;
- arrival actions and state transitions are idempotent across abstract/live/reload paths;
- Hoomans hot-path work scales with the nearby live subset while compact Core travel scales independently with abstract journeys.

The integrated simulator must compare fully abstract travel, one mid-route materialization, repeated materialization cycles, and save/reload at the same world-hour checkpoints. Equivalent canonical journeys must converge to equivalent progress/arrival outcomes.

## 16. Cross-system composition invariant

Performance fixes are accepted only if they compose across representation, combat, persistence, networking, observation, and lifecycle transitions.

A fast isolated path is insufficient if a compound event reintroduces a synchronous spike or duplicate authority. In particular:

- materialization followed immediately by combat must not multiply promotion, targeting, hit, social/faction, network, and persistence work without bounds;
- save/reload during mixed live pressure must restore one actor/body/journey authority graph;
- death during abstract/live handoff must permanently prevent later rematerialization while preserving valid survivor/group state;
- many simultaneous arrivals must keep transition side effects idempotent and bounded;
- observation must remain side-effect-free;
- fast player relocation must evaluate current projected positions under ordinary admission budgets;
- provider handoff must preserve Core canonical authority and Hoomans' temporary physical-only responsibility;
- multi-day simulation must not accumulate transient runtime state, dirty backlog, orphan leases, or duplicate tombstones monotonically.

The integrated simulator owns these developer-side composition guarantees; native PZ remains the final engine-cost/feel authority.

## 17. Inventory/ModData scale invariant

Player-native inventory scale and NPC durable inventory scale are separate costs and must remain separable.

NPC personal inventory authority is the compact PsychopatzCore actor inventory. Hoomans may hydrate a richer logical/native representation only while concrete gameplay requires it.

Required properties:

- unchanged deterministic NPC inventories remain representable as `SEED_ONLY`;
- ordinary durable changes use `BASELINE_DELTA` when exact semantics permit;
- `FULL` payloads are exceptional/justified rather than the default for every looted NPC;
- compact inventory size grows with actual durable item differences, not runtime/UI caches or historical mutation logs;
- distant actors carrying items remain bodyless and do not require Hoomans runtime/native item hydration;
- one actor's inventory mutation does not serialize unrelated actors;
- same-tick mutations may coalesce for persistence/networking while authoritative item ownership remains exact;
- large player inventories may require native scans for explicit operations, but stable UI/queries must reuse revision/event-driven caches rather than rescanning every frame;
- inventory replication remains inventory/domain-specific and does not rebuild unrelated NPC state;
- materialize/abstract and save/reload round trips preserve exact item IDs/state without duplication or delta growth.

Inventory optimization may remove redundancy, derived state, duplicate serialization, and unnecessary hydration. It may not replace exact durable items with count-only summaries or create a second inventory authority.
