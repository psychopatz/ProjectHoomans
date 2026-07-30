# Player-Character Identity

## Purpose

Phase 3A gives each specific player survivor a persistent,
server-authoritative UUID. Account identity answers who owns the connection;
character identity answers which survivor NPCs remember. They are deliberately
separate:

```text
player:<accountIdentity>:<characterUUID>
player:Patrick:char_169283719_12_4
```

A new survivor on the same account is a new social person. Old relationships
and memories continue to reference the old UUID.

## Persistent Registry

The server owns the separate Global ModData table `PNC_PlayerCharacters`:

```lua
{
    schemaVersion = 2,
    revision = 0,
    byUUID = {
        ["char_..."] = {
            uuid = "char_...",
            accountIdentity = "Patrick",
            status = "active", -- active, dead, or retired
            createdAt = 182.5,
            firstSeenAt = 182.5,
            lastSeenAt = 190.25,
            diedAt = 0,
            retiredAt = 0,
            socialProfile = {
                schemaVersion = 1,
                revision = 0,
                resolvedAt = 0,
                orientation = "straight",
                foodPreference = "neutral",
                romanceStyle = "neutral",
                jealousyStyle = "normal",
                socialStyle = "neutral",
                sourceTraits = {},
            },
            revision = 1,
        },
    },
    byAccount = {
        Patrick = { ["char_..."] = true },
    },
}
```

`byUUID` is canonical. Normalization rebuilds `byAccount`, discards invalid
UUID keys and records without valid accounts, repairs a record UUID to its
canonical map key, removes non-finite numbers, and never generates identities.
Invalid statuses normalize to `retired`, preventing malformed data from
reactivating a dead identity. Normalization is deterministic and idempotent.

Names, display name, and last coordinates are optional diagnostics only. They
never prove identity or ownership. The registry contains primitives and plain
tables only.

## Survivor Mirror

The server writes only these primitive fields to the survivor's persistent
`IsoPlayer` ModData:

```lua
PNC_CharacterUUID = "char_..."
PNC_CharacterIdentityVersion = 1
```

Build 42.20's `IsoPlayer` save chain serializes the inherited `IsoObject`
ModData table as part of the character blob. The mirror therefore travels with
the survivor through save/load. It is still only a claim: the server accepts it
only when the registry knows the UUID, the authoritative `getUsername()`
matches its account, the record is active, and no other live object owns the
runtime binding.

Unknown, malformed, cross-account, dead, retired, and duplicate-live claims
are rejected. The claimant receives a newly generated identity when it is
otherwise an eligible live survivor. Existing ownership and old memories are
never rewritten.

## UUID Generation

The authority reuses `PNC.Core.GenerateID("char")`, producing the repository's
existing millisecond-plus-`ZombRand` opaque format. Before insertion the result
must pass the `char_[A-Za-z0-9_-]+` validator and be absent from `byUUID`.
Generation retries at most 16 times and returns
`uuid_generation_exhausted` rather than reusing a collision.

Neither account name nor online ID is sufficient to generate or validate an
identity. Online ID appears only in opt-in runtime diagnostics.

## Lifecycle

All creation paths call `PNC.PlayerCharacters.EnsureIdentity()`:

- an unmarked survivor receives a new active registry record and mirror;
- a known active mirror is rebound and reused;
- repeated calls on the same live object are pure and do not increment
  revisions;
- disconnect clears only the runtime binding and leaves status active;
- reconnect reads the same survivor mirror and reuses the same UUID;
- death marks the current record dead once, stores `diedAt`, and unbinds it;
- a survivor carrying a dead UUID receives a new UUID, while the old record
  remains dead and addressable.

Corpse creation and reanimation do not create, reactivate, or retarget player
identities. They require no additional identity hook in this phase.

Runtime maps relate the live player object to its UUID in both directions.
They are module state, never part of `PNC_PlayerCharacters`, and are reset on
registry/server load. A throttled one-second authoritative player sweep
ensures visible players, detects `isDead()`, and clears bindings for player
objects no longer returned by the server player list.

Build 42.20 exposes `OnCreatePlayer` and `OnPlayerDeath`, so guarded,
idempotent adapters are registered. Static inspection shows
`IsoPlayer.OnPlayerDeath` is emitted only for a local player; it is not a
reliable dedicated-server death source. The authoritative sweep is therefore
the dedicated-server fallback. No dedicated server-shutdown Lua event exists
in the inspected event registry; runtime tables disappear with the Lua VM and
are explicitly empty again on the next server/registry load.

## Revisions and Persistence

- creating a record increments registry revision and starts character revision
  at 1;
- death or a meaningful persisted information/last-seen update increments the
  character and registry revisions once;
- mirror writes and runtime binding alone do not increment persistent
  revisions;
- pure reads and redundant ensure/death calls do not increment revisions;
- player identity operations do not touch NPC `recordRevision`,
  `presenceRevision`, or `social.revision`.

Phase 3B advances this Global ModData domain to schema V2 and adds the
UUID-owned `socialProfile`. Existing historical records receive neutral
profiles without guessed traits. Active loaded survivors resolve against
their authoritative Build 42 traits when their player object becomes
available. See `SocialProfiles.md`.

## Public Server API

- `PNC.PlayerCharacters.EnsureIdentity(player, context)`
- `PNC.PlayerCharacters.GetCharacterUUID(player)`
- `PNC.PlayerCharacters.GetEntityKey(player, context)`
- `PNC.PlayerCharacters.GetRegistryRecord(characterUUID)`
- `PNC.PlayerCharacters.ResolveEntityKey(entityKey)`
- `PNC.PlayerCharacters.IsCharacterActive(characterUUID)`
- `PNC.PlayerCharacters.IsCharacterDead(characterUUID)`
- `PNC.PlayerCharacters.MarkDead(player, worldAgeHours, reason)`
- `PNC.PlayerCharacters.Unbind(player, reason, worldAgeHours)`
- `PNC.PlayerCharacters.NormalizeRegistry([value])`
- `PNC.PlayerCharacters.ValidateClaim(player, claimedUUID)`

Registry reads return copies. There is no client command for identity mutation,
status changes, registry reads, or arbitrary actor keys.

## Relationship and Social-Event Integration

`PNC.SocialEventHooks.ResolvePlayerKey()` delegates to
`PNC.PlayerCharacters.GetEntityKey()`. Treatment and combat adapters no longer
read a UUID directly or require a caller to supply one. NPC-to-NPC events and
all Phase 2 balance, cooldown, saturation, and memory rules are unchanged.

Dead entity keys still resolve to their preserved registry record. No
relationship is moved to a later survivor.

## Diagnostics

Both flags default to `false`:

```lua
PNC.Config.Relationships.DebugPlayerIdentity = false
PNC.Config.Relationships.DebugCombatCallbacks = false
```

Identity diagnostics report callback, account, UUID, status, world-age hour,
runtime online ID, and result/reason. Combat diagnostics report weapon-hit and
zombie-death callback delivery, identity resolution, encounter join, threat
neutralization, and encounter end. They do not print the registry or add
gameplay events.

`PNC.PlayerCharacterDebug.FormatRecord(uuid)` is a read-only developer
formatter. Live validation steps are in
`Docs/Testing/PlayerCharacterIdentityValidation.md`.

## Non-Goals and Next Phase

This system does not implement player traits or profiles, romance, gossip,
dialogue, factions, account-wide reputation, relationship inheritance, AI
consequences, hostility changes, or UI.

The recommended next step is the still-required SP/hosted/dedicated identity
and social-profile live validation before adding further social behavior.
