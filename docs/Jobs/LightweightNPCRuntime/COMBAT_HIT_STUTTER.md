# Combat-Hit Stutter Harness and Root-Cause Plan

## Status

**ACTIVE L6 DEVELOPER WORK.**

Native user testing reports massive lag spikes when a live Hoomans NPC actually lands a hit. L6 therefore covers both sustained FollowOwner walking and combat-contact spikes.

Required attacker/target combinations:

- NPC -> zombie
- NPC -> Hoomans NPC
- NPC -> player

The goal is not merely to prove combat correctness. The deterministic harness must identify and reduce the synchronous work triggered at the impact boundary while preserving authoritative damage, wounds, faction/social consequences, reactions, replication, and death handling.

## Code-verified impact fan-out

The current combat path routes committed impact through `CombatResolution.ApplyTargetDamage` and then dispatches by target kind.

### NPC -> zombie

`PNC_CombatResolution_Zombie.lua` can perform, on or after one accepted hit:

- target lookup and threat/protected-target context
- `SocialEncounterTracker.RecordActivity`
- fake-zombie acquisition for engine hit semantics
- `CombatZombieReaction.ApplyWeaponHit` or native `victim:Hit(...)` fallback
- `ZombieAggro.OnZombieProvoked`
- `Network.BroadcastZombieReaction`
- on kill, `SocialEventHooks.OnThreatNeutralized`
- on kill, `engine:zombie_killed` semantic event publication
- on kill, `SemanticCombatReactionService.OnNPCKill`

This means a zombie hit is not just arithmetic. The harness must separate engine-hit/reaction cost from social, semantic, aggro, and network fan-out.

### NPC -> Hoomans NPC

`PNC_CombatResolution_NPC.lua` and `PNC_NPCWounds_Mutation.lua` can perform, on one accepted hit:

- hostility/owner-defense authorization
- group-alert publication
- `NPCWounds.ApplyCombatDamage`
- `Health.ApplyDamage` and dirty marking
- wound construction/recalculation
- wound event emission
- `MedicalCareService.RequestNPC`
- social damage recording
- faction aggression/incident handling
- on human kill, semantic combat reaction
- combat-damage delta scheduling or removal broadcast

This path must be tested for repeated nonlethal hits as well as the kill transition. Per-hit social/faction/medical work must not accidentally become a broad scan or synchronous persistence/network storm.

### NPC -> player

`PNC_CombatResolution_Player.lua` and `PNC_CombatResolution_Target.lua` can perform, on one accepted hit:

- body-part damage/wound mutation
- `BodyDamage:Update()`
- `sendPlayerStatsChange(player)`
- faction attack-player handling
- social damage recording

`RecordNPCDamagedPlayer` can then reach `RecordPlayerHurtWitnesses`, which may scan live NPCs through `Registry.ForEachLive` when its cooldown admits the event.

That witness scan is already cooldown-bounded in source, but L6 must measure its actual cost and verify repeated NPC hits cannot create synchronized live-NPC scans or relationship-event fan-out spikes.

## Harness principle

Extend the existing `tests/support/lightweight_runtime_simulator.lua` and its benchmark/smoke consumers. Do not create a second fake combat implementation.

Drive the real engine-independent production chain as far as possible:

~~~text
combat decision / committed action
    -> attack timing / impact gate
    -> CombatResolution.BuildHitEvent
    -> ApplyTargetDamage
    -> target-specific damage/reaction
    -> wounds / aggro / faction / social / semantic hooks
    -> network delta/reaction
    -> persistence dirty marking
~~~

Fake only narrow native boundaries such as body-part objects, engine zombie `Hit`/reaction, `BodyDamage:Update`, `sendPlayerStatsChange`, socket sends, and other engine callbacks.

Every fake boundary must count invocations and allow deterministic injected cost/failure where useful.

## Required control and impact scenarios

For each target type, include a **pre-impact control** so a successful hit can be compared with the same attacker/target workload without impact fan-out.

### `COMBAT_NPC_ZOMBIE_MISS`

Committed attacks resolve as misses/no impact.

Purpose: baseline attack decision, animation/action pump, targeting, movement, and attack timing without zombie damage fan-out.

### `COMBAT_NPC_ZOMBIE_HIT`

Repeated deterministic accepted hits against live zombies.

Measure:

- hit-resolution calls
- engine/fake `Hit` or reaction calls
- zombie reaction starts
- aggro provokes
- zombie-reaction network sends
- social encounter activity
- semantic events
- kill hooks
- census/spatial work caused by the impact

Include nonlethal repeated hits and a deterministic kill transition.

### `COMBAT_NPC_NPC_MISS`

Same NPC hostility/targeting/attack setup, but no accepted impact.

Purpose: isolate attack orchestration from damage/wound/faction/social work.

### `COMBAT_NPC_NPC_HIT`

Repeated accepted hits against another live Hoomans NPC.

Measure:

- damage authorization
- health mutations
- wound add/recalculate operations
- wound events
- medical work requests
- registry dirty marks
- social damage events
- faction aggression/incidents
- network combat-damage deltas/removals
- semantic kill hooks
- persistence enqueue/pump work caused by combat

Include repeated nonlethal hits, severe-hit escalation, and a deterministic kill/incapacitation transition.

### `COMBAT_NPC_PLAYER_MISS`

Committed NPC attacks resolve without damaging the player.

Purpose: isolate attack orchestration and target validation from player body/social/faction fan-out.

### `COMBAT_NPC_PLAYER_HIT`

Repeated accepted hits against a player.

Measure:

- body-part mutation
- `BodyDamage:Update` calls
- `sendPlayerStatsChange` calls
- faction attack-player operations
- social damage operations
- live-witness scan count and candidates
- relationship-event emissions
- network sends caused by impact

Test both a single NPC attacker and multiple attackers landing impacts near the same time.

## Melee and ranged

At minimum, the baseline must include melee for all three target types because it best matches the reported visible contact hitch.

Also include representative ranged impact cases where the production path materially differs, especially:

- firearm effects/audio
- ammo consumption
- ranged hit resolution
- player/zombie reaction differences
- firearm network events

Do not multiply the matrix unnecessarily if operation counts prove the post-hit target-specific path is shared.

## Burst and same-frame pressure

The native symptom is a lag **spike**, so average throughput alone is insufficient.

For each hit scenario record:

- total accepted hits
- maximum accepted hits in one simulated frame/tick
- maximum hit-resolution calls in one frame
- maximum wound/health mutations in one frame
- maximum social/faction events in one frame
- maximum witness scans in one frame
- maximum network sends/delta builds in one frame
- maximum persistence dirty marks/enqueues in one frame
- profiler-OFF average/p95/max simulator tick CPU

Include deterministic cases where 1, 3, 6, and 12 NPC attackers land hits with controlled spacing, plus one synchronized-contact stress case.

The accepted design should avoid pathological synchronous fan-out without artificially delaying authoritative damage or making combat feel unresponsive.

## Required counters

Expose or add bounded diagnostics for at least:

### Attack pipeline
- attack actions started
- attack pump calls
- hit gates reached
- misses
- accepted hits
- rejected hits
- hit-resolution calls
- weapon wear/stamina/XP commits

### Zombie target
- engine/fake hit calls
- reaction applications
- aggro provokes
- zombie reaction broadcasts
- social encounter activity
- threat-neutralized hooks
- zombie kill semantic events/reactions

### NPC target
- health damage calls
- wound recalculations
- wound event emissions
- medical requests
- registry dirty marks
- faction aggression/incident operations
- social damage operations
- combat-damage delta builds/sends
- removal broadcasts
- kill semantic reactions

### Player target
- body-part damage operations
- `BodyDamage:Update` calls
- `sendPlayerStatsChange` calls
- faction attack-player operations
- player-hurt witness scans
- witness candidates
- emitted witness/relationship events

### Shared
- full snapshots vs narrow deltas
- persistence logical commits/pump work attributable to hits
- census/spatial refreshes
- allocation-heavy diagnostic/audit calls when enabled
- maximum same-frame values for all expensive fan-out counters

Counters must come from real exercised production seams or narrow adapters. Do not hard-code expected success counts into the simulator.

## Root-cause decision gate

No combat optimization may be selected until miss-vs-hit and target-type comparisons identify the dominant synchronous fan-out.

Examples:

| Evidence | Likely area |
| --- | --- |
| miss is cheap; all hit types spike before target-specific work | common impact/hit-resolution path |
| only NPC -> zombie spikes | engine zombie hit/reaction, aggro, or zombie network path |
| only NPC -> NPC spikes | wounds/health/medical/faction/social/delta path |
| only NPC -> player spikes | BodyDamage update/stats sync/faction or witness scan path |
| repeated hits worsen with live NPC count | witness/social/faction membership scan |
| kill transition alone spikes | death/removal/semantic/social cleanup |
| synchronized attackers spike but staggered attackers do not | same-frame fan-out/coalescing problem |
| deep profiler alone creates the spike | instrumentation contamination |

Record profiler-OFF pre-fix operation baselines before changing runtime combat behavior.

## Optimization rules

Fix the measured cause, not a guessed one.

Potential evidence-backed solutions may include:

- coalescing presentation/social work that does not need to execute once per same-frame hit
- owner/target scoped cooldowns for non-authoritative flavor work
- indexed nearby-witness queries instead of broad live scans, when current measurement proves the scan material
- deferring/coalescing persistence and noncritical semantic work while keeping damage authoritative immediately
- one bounded combat-damage delta per target/domain revision rather than repeated full/same-domain rebuilds
- caching immutable weapon/hit descriptors during an attack action
- batching or deduplicating same-frame reaction/network work when gameplay semantics allow it
- moving expensive kill-only work strictly behind the kill transition

Never:

- skip authoritative damage to improve performance
- delay damage enough to change combat outcomes
- remove wounds/faction/relationship consequences
- suppress legitimate player stats synchronization without a proven safe replacement
- globally disable social/semantic combat hooks
- lower supported combatant counts as the fix
- hide the problem behind a longer combat tick interval
- turn profiler/deep diagnostics on in normal play

## L6 combat acceptance

Combat-hit work is developer-complete only when:

1. NPC -> zombie, NPC -> NPC, and NPC -> player miss/hit scenarios run deterministically through real production seams
2. repeated nonlethal hits and kill/incapacitation transitions are covered
3. single-attacker and synchronized multi-attacker pressure are covered
4. profiler-OFF pre-fix operation counts exist
5. the dominant hit-boundary fan-out is identified before optimization
6. the accepted fix reduces the implicated same-frame work on the identical workload
7. authoritative damage/wounds/death remain immediate and correct
8. network behavior remains narrow and convergent
9. social/faction/semantic consequences remain correct but bounded
10. no target type reintroduces broad per-hit persistence or whole-population work
11. focused combat/wound/player-damage/social/faction tests and the existing L0-L5 matrices remain accepted
12. native SP/MP can be retested with profiler OFF and the same low-overhead stutter trace used for follow movement

The parent L6 phase is not complete until follow-walk, combat-hit, and abstract-travel/materialization acceptance gates all pass. See [ABSTRACT_TRAVEL_HANDOFF_STUTTER.md](ABSTRACT_TRAVEL_HANDOFF_STUTTER.md).
