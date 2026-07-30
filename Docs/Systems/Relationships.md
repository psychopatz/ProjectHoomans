# Relationships

## Purpose

Phase 1 provides persistent, server-authoritative personal relationship data
and pure relationship logic. Phase 2 adds a centralized event pipeline that
turns five verified health/combat milestones into memories. Phase 3A supplies
the player-character UUID lifecycle used by those events. Phase 3B adds
persistent player/NPC profiles and applies the observer NPC's personality only
while constructing new event memories. These relationship phases do not make
NPCs talk, join factions, refuse orders, or act autonomously.

Phase 5B keeps the directed relationship data model but adds one explicit
integration: an affiliated leader/officer/second whose relationship toward a
stable player reaches `enemy` may submit a faction grievance report. Personal
hostility does not immediately force symmetric war by default.

## Directed Model

Relationships belong to the observing NPC and are keyed by the target entity:

```lua
alice.social.relationships["npc:bob"]
bob.social.relationships["npc:alice"]
```

These are independent records. No relationship stores a pointer to another NPC
record or a live `IsoPlayer`/`IsoZombie`.

## Entity Keys

- NPC: `npc:<npcID>`
- player character:
  `player:<accountIdentity>:<characterUUID>`

`PNC.EntityRef` constructs, parses, and validates these keys without throwing
on malformed input. Colons and control characters are rejected inside key
components so parsing stays unambiguous.

A username or online ID alone is not a persistent player-character identity.
Phase 3A's server-authoritative `PNC.PlayerCharacters` service validates the
survivor UUID mirror against its persistent registry and constructs the entity
key centrally. Phase 2 adapters never trust the mirror directly and never fall
back to username or online ID.

## Persistent Schema

Every NPC record owns:

```lua
record.social = {
    schemaVersion = 3,
    revision = 0,
    morale = 0,
    moraleBaseline = 0,
    relationships = {},
    recentEventIDs = {},
    lastEvaluatedAt = 0,
    personality = { ... },
    personalityOverrides = {},
    conduct = { ... },
}
```

Each relationship stores target kind and stable primitive ID, baseline and
cached scores, familiarity, current and previous states, memories,
event-specific saturation/cooldown maps, timestamps, and its own revision.

Approval and respect range from -100 to 100. Familiarity ranges from 0 to 100.
Morale and morale baseline range from -100 to 100. Phase 2 events change
morale, but morale still has no AI or gameplay effect.

The memory list and baseline values are authoritative. Cached approval and
respect are recalculated from them and are re-derived during persistence
sanitization.

## Memories and Decay

A memory contains a required unique ID, type, valid `aboutKey`, world-age-hour
timestamps, approval/respect/morale effects, strength, decay, permanence,
sharing metadata, a knowledge source, an optional source entity key, and
map-style boolean tags.

Supported knowledge sources are:

- `experienced`
- `witnessed`
- `told_by_trusted_person`
- `told_by_stranger`
- `community_rumor`
- `inferred`

Gossip is not implemented; these values only make the save schema ready for
later work.

Temporary memory strength is calculated without mutating the stored strength:

```text
elapsedDays = max(0, (worldAgeHours - createdAt) / 24)
effectiveStrength = max(0, strength - decayPerDay * elapsedDays)
```

Permanent memories always use their stored strength. Approval and respect are:

```text
baseline + sum(memory effect * effective strength)
```

The result is clamped to its valid range.

Each directed relationship keeps at most 20 active memories. Addition and
explicit pruning discard invalid entries and expired temporary entries first,
then remove the weakest temporary entry. Ties use `createdAt` and memory ID.
Permanent entries are never pruned; an addition that cannot satisfy the limit
without deleting a permanent entry is rejected. Future consolidation may turn
weak repeated memories into baseline traits, but Phase 1 does not.

## States and Hysteresis

Familiarity below 5 always resolves to `unknown`. At familiarity 5 or above,
entry rules are:

| State | Entry rule |
|---|---|
| `friend` | approval >= 35 and respect >= 15 |
| `rival` | approval <= -25 and respect >= 25 |
| `enemy` | approval <= -60 and respect < 10 |
| `neutral` | none of the above |

Existing states remain until these exit rules are crossed:

- friend exits when approval < 25 or respect < 5
- rival exits when approval > -15 or respect < 15
- enemy exits when approval > -45

When a state changes, the old value is copied to `previousState`. Friend and
rival do not change faction or hostility. Phase 5B may turn an authorized
NPC's player-directed `enemy` state into a faction grievance report; it does
not rewrite the personal relationship or affiliation.

## Normalization

Normalizers are deterministic and idempotent. They:

- create missing tables and defaults
- reject malformed entity keys
- discard memories missing ID, type, or a valid `aboutKey`
- deterministically deduplicate memory IDs
- repair invalid optional numbers and knowledge sources to safe defaults
- clamp all bounded values
- discard unsupported fields rather than copying unknown values or engine
  objects into persistence

Ordinary normalization never generates a random ID. Memory producers must
supply their own deterministic or event-owned ID.

## Persistence and Revisions

NPC persistence schema V14 stores social schema V3 personality and conduct
data plus the separate affiliation schema V1. V13 and
older records deserialize through `NormalizeSocialState`, deterministically
generating a profile from the existing identity seed while preserving
relationships and event state and adding neutral conduct without reconstructing
history. The existing registry migration pipeline marks old records for
rewrite; no separate migration path duplicates this logic.

A relationship mutation increments that relationship's revision. A committed
social change increments `record.social.revision` and calls
`PNC.Registry.MarkDirty(record, "social")`, which advances `recordRevision`
according to the registry's existing dirty-batch convention.
`presenceRevision` is never changed by the social service. Reads and no-op
recalculations do not advance revisions.

## Server Authority and API

Mutation functions are defined by the server-only relationship service and
reject non-authority calls, invalid observer IDs, malformed keys, malformed
memories, and duplicate memory IDs. Arguments are stable primitives and plain
tables only.

Read APIs return canonical copies so callers cannot mutate the authoritative
record through a getter:

- `PNC.Relationships.Get(observerNPCID, targetKey)`
- `GetApproval`, `GetRespect`, `GetFamiliarity`, `GetState`

Mutation APIs are:

- `GetOrCreate`
- `AddMemory`
- `RemoveMemory`
- `Recalculate`
- `PruneMemories`
- `ApplyEventMutation` (atomic boundary used by the server social-event
  service)

Mutators return a success boolean followed by a stable reason string and,
where useful, a canonical result. There are no client commands for changing
relationship scores.

## Social-Event Pipeline

Gameplay systems report completed milestones through
`PNC.SocialEvents.Emit(eventSpec)`. They never edit scores or choose arbitrary
effects. The authority pipeline:

1. validates safe primitive/table data, stable entity keys, event type,
   source system, and world-age timestamp;
2. resolves NPC observers from the directed actor/target roles;
3. reads the observer NPC's persistent personality and purely modifies the new
   event effects;
4. checks the bounded recent-event cache, relationship cooldown, and
   per-event contribution saturation;
5. builds a deterministic memory from the shared definition and modified
   effects;
6. atomically applies memory, familiarity, morale, cooldown, saturation,
   recalculation, dedupe ID, and revisions through
   `PNC.Relationships.ApplyEventMutation`.

The transient event shape is:

```lua
{
    id = "social:<authoritative milestone id>",
    type = "treated_wound",
    actorKey = "player:Patrick:char_01",
    targetKey = "npc:npc_123",
    occurredAt = 182.5,
    sourceSystem = "wounds",
    x = 10520, y = 9240, z = 0,
    context = { bodyPart = "Torso_Upper" },
}
```

Events and encounter runtime state contain only primitives and plain tables.
Clients cannot submit relationship effects or arbitrary social events.
Existing memories are never modified retroactively. See `SocialProfiles.md`
for the exact modifiers and generation rules.

Public event APIs return structured results:

- `PNC.SocialEvents.Emit(eventSpec)`
- `PNC.SocialEvents.Process(eventSpec)`
- `PNC.SocialEvents.Validate(eventSpec)`
- `PNC.SocialEvents.GetDefinition(eventType)`

## Initial Event Balance

| Event | Approval | Respect | Morale | Familiarity | Decay/day | Cooldown | Approval cap | Respect cap | Shareable |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---|
| `treated_wound` | +4 | +2 | +2 | +2 | 0.05 | 12 h | +20 | +15 | no |
| `saved_from_incapacitation` | +18 | +25 | +12 | +8 | 0.008 | episode dedupe | +70 | +80 | yes |
| `protected_from_attacker` | +8 | +14 | +5 | +4 | 0.02 | encounter dedupe | +50 | +70 | yes |
| `survived_combat_together` | +3 | +6 | +3 | +4 | 0.035 | encounter dedupe | +30 | +50 | no |
| `abandoned_in_combat` | -20 | -18 | -10 | +5 | 0.006 | encounter dedupe | -80 | -80 | yes |

Saturation records nominal contributions rather than current decayed score.
Decay therefore does not reopen a farming cap. If one axis has less room than
the definition value, that memory axis is deterministically clipped. When
neither approval nor respect has room, the event is rejected and familiarity,
morale, dedupe, and revisions remain unchanged.

`recentEventIDs` retains the last 64 successfully applied IDs in insertion
order. Oldest IDs are evicted first. Memory IDs are deterministic from event
ID, observer NPC ID, and event role.

## Attribution and Gameplay Hooks

- `PNC_Treatment.TryBandage` emits `treated_wound` only after
  `NPCWounds.Bandage` succeeds. Opening UI, failed treatment, healing ticks,
  and clean-bandage reapplication do not emit.
- Successful player treatment while the NPC is incapacitated registers a
  runtime contribution against the target's `npcID + downedAt` episode.
  `Health.ResumeFromIncapacitated` credits only the most recent verified
  contributor. It never selects a nearby player.
- NPC hits on ordinary zombies and authoritative player weapon/death events
  feed the runtime encounter tracker. Protection requires the neutralized
  threat to have targeted or damaged the protected NPC.
- `Presence.Abstract` marks a possible departure. Abandonment requires prior
  shared encounter participation, an active threat, an injured/incapacitated
  or multiply threatened target, a capable actor, and a 10-world-second grace
  period. Returning cancels the candidate.

## Encounter Aggregation

`PNC.SocialEncounterTracker` is server-runtime only. It stores stable entity
keys, threat IDs, numeric positions/times, participant flags, and pair maps;
it stores no live characters and is not saved.

Encounters qualify for shared-combat memories when both participants survive
and at least one condition holds: five world seconds elapsed, at least two
threats participated, or a participant took damage. An encounter ends after
15 world seconds without qualifying threat activity. Protection and
abandonment are limited to one event per actor/target/encounter. Shared combat
uses one event: the event service creates reciprocal memories for two NPCs,
or the single NPC-owned memory for an NPC/player pair.

The tracker runs at most once per world second and iterates active encounters
only; it performs no world-wide scan. NPC distance-based abandonment checks
use authoritative record positions.
Player distance departure is not inferred from a stale online ID and requires
a future explicit authoritative departure adapter.

## Feature Flag

`PNC.Config.Relationships.EnableSocialEvents` defaults to `true`.
`SandboxVars.ProjectHoomans.EnableSocialEvents`, when present, overrides that
default through the existing sandbox accessor. When disabled, hooks are no-ops
and no social or presence revisions change.

## Debugging

`PNC.RelationshipDebug.Inspect(observerNPCID, targetKey, worldAgeHours)` returns
read-only formatted diagnostics with cached values, states, baselines, active
memories, current strengths, and knowledge sources.

The admin/debug-only **PNC Relationship Inspector** is available from the
PsychopatzCore Debug Hub and from the selected NPC's **Relationships** button
in the PNC NPC Monitor. It displays one directed relationship at a time:
observer and target keys, cached and baseline values, states, morale,
personality dimensions, relationship/social/record/presence revisions,
cooldowns, saturation, current memory strengths, and the independently stored
reverse direction for NPC targets. It also shows observer and target conduct
scores/evidence. Merely opening, selecting, or refreshing
the inspector does not create a relationship or advance revisions.

The inspector can submit only these named test milestones:

- `treated_wound`
- `saved_from_incapacitation`
- `protected_from_attacker`
- `survived_combat_together`
- `abandoned_in_combat`

The server derives the requesting player's stable character key, validates NPC
IDs and debug authorization, assigns the authoritative world-age timestamp and
event ID, and sends the milestone through `PNC.SocialEvents.Process`. The
client cannot provide scores, memory effects, entity keys, or timestamps.
Cooldown, saturation, dedupe, personality modification, memory limits, and
revision rules therefore remain active during a debug trigger. Multiplayer
access requires admin status; single-player access requires debug mode. The
network response is a dedicated, read-only snapshot containing only the
selected pair's social data.

`PNC.SocialEventDebug.FormatProcessed(result, definition)` formats the event,
definition effects, observer, memory ID, saturation, and before/after
relationship values. Detailed automatic logs require
`PNC.Config.Relationships.DebugSocialEvents = true`; normal cooldown and
non-qualifying encounter paths do not spam production logs.

Player identity and combat callback delivery have separate opt-in flags:
`DebugPlayerIdentity` and `DebugCombatCallbacks`. Both default to `false`.

## Current Non-Goals

The relationship system still does not implement romance, dialogue, gossip,
autonomous social AI, faction simulation, community
reputation, diplomacy, hostility changes, order refusal, desertion, rescue
willingness, trading effects, normal-player relationship UI, or continuous
relationship updates. The developer inspector is intentionally unavailable to
ordinary players.

Current attribution limitations are deliberate:

- player-versus-zombie attribution depends on authoritative
  `OnWeaponHitCharacter`/`OnZombieDead` delivery in the active game mode;
- player distance/disconnect abandonment is not guessed;
- no new abstract combat social events are fabricated;
- encounter runtime state is lost on restart, while already-created memories
  remain persistent.

Future work should first complete the documented in-game SP, hosted, and
dedicated callback validation. Memory consolidation, gossip, factions, AI
decisions, and presentation remain later consumers of this foundation.
