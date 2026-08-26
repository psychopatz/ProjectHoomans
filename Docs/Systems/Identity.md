# Identity

Player-survivor UUID ownership and Phase 3B social-profile resolution are
documented separately in `PlayerCharacterIdentity.md` and
`SocialProfiles.md`. NPC personality generation reuses the identity seed but
does not alter names, appearance, gender, archetype selection, or body
materialization.

## Purpose
- `PNC_Archetypes` owns self-registering archetype definitions, looks, base skills, and loadout templates.
- `PNC_ArchetypeLoader` owns default archetype-module import, pending-bundle application, and bootstrap diagnostics, not individual archetype data.
- `PNC_Identity_Factory` resolves a new NPC from `SurvivorFactory`, then PNC persists the resolved result.
- `PNC_Identity_Profile` normalizes `identitySeed`, `archetypeID`, `displayName`, gender, and appearance from persisted identity fields.
- `PNC.PlayerCharacters` owns player-survivor UUIDs, registry persistence,
  server claim validation, and runtime binding.
- archetype definition modules themselves live in `common/media/lua/shared/PNC/ArchetypeDefinitions/...` so they are not duplicated per-version.
- common archetype files publish declarative bundles into `PNC.PendingArchetypeBundles` so PZ preload order cannot silently drop registrations before the registry API exists.

## Owned Data
- `identitySeed`
- `archetypeID`
- `archetypeLabel`
- `displayName`
- `identity.survivor.*`
- archetype skill-bias metadata
- archetype look and loadout metadata
- persisted resolved SurvivorFactory name and appearance fields

Seed-derived skills are resolved by `PNC_Skills`; progression stores signed deltas over that base.
Starting equipment is owned by `PNC.Inventory`, not archetypes. It uses the
persisted `identitySeed` with category-specific salts, making selections stable
across multiplayer peers, save/load, and inventory template rebases without
restricting an NPC type to a particular weapon family.

## Player-Character Social Identity

The relationship system does not treat a username or online ID as a complete
social person. Player targets use
`player:<accountIdentity>:<characterUUID>` through
`PNC.EntityRef.ForPlayerIdentity()`.

`PNC.PlayerCharacters` owns a server-authoritative Global ModData registry and
validates the lightweight UUID mirror persisted in each survivor's player
ModData. Reconnect and save/load preserve the UUID; death preserves and closes
the old identity; a new survivor receives a new UUID. `getUsername()` supplies
the authoritative account component. Display name, survivor name, and online
ID never establish ownership.

See `Docs/Systems/PlayerCharacterIdentity.md` for schema, lifecycle,
anti-spoofing, revisions, and callback limitations.

## Organizational NPC Identity

NPC organization membership is identified by
record.affiliation.factionID (also serialized as the top-level factionID
in network summaries). record.tacticalClass and the `colonist` value are tactical
presentation fields; they must not establish player ownership,
conversation membership, or death-marker eligibility.

PNC.Identity.Verifier is the shared, read-only contract used by gameplay,
network presentation, debug diagnostics, and future integrations:

- GetFactionID(value) reads canonical identity from a record, snapshot,
  wrapper, or payload.
- GetPlayerFactionID(player) resolves the requesting survivor's current
  faction without collapsing a multi-player faction to one username.
- BuildOwnershipSummary(value) is the compact hot-path view used by
  presence replication.
- IsOwnedByPlayer(value, player) resolves a character-scoped player key
  against the faction ownerPlayerKey and playerMemberKeys.
- IsColonyOwnedNPC(value) identifies NPCs eligible for player-colony
  presentation such as death markers.
- Verify(value, options) reports missing, malformed, or unknown identity
  fields.
- BuildView(value, options) returns a serialization-safe public identity
  view without exposing live records or engine objects.

The integration facade is PNC.API.Identity. Its Get, GetForSource, Verify,
VerifyPayload, GetPlayerFactionID, ResolveOwnership, IsOwnedByPlayer,
GetVersion, and GetCapabilities methods are intended to be
the stable boundary for the upcoming LLM conversation adapter. A faction
can contain multiple player characters; all members therefore resolve
through the same factionID rather than a single username or tactical class.

## Public Functions

- PNC.Identity.Verifier.GetFactionID(value)
- PNC.Identity.Verifier.GetPlayerFactionID(player)
- PNC.Identity.Verifier.BuildOwnershipSummary(value)
- PNC.Identity.Verifier.IsOwnedByPlayer(value, player)
- PNC.Identity.Verifier.IsColonyOwnedNPC(value)
- PNC.Identity.Verifier.Verify(value, options)
- PNC.Identity.Verifier.BuildView(value, options)
- PNC.API.Identity.Get(npcID, options)
- PNC.API.Identity.GetForSource(source, options)
- PNC.API.Identity.Verify(npcID, options)
- PNC.API.Identity.VerifyPayload(payload, options)
- PNC.API.Identity.GetPlayerFactionID(player)
- PNC.API.Identity.ResolveOwnership(npcID, player)
- PNC.API.Identity.IsOwnedByPlayer(npcID, player)
- `PNC.RegisterArchetypeModule(id, spec)`
- `PNC.RegisterArchetypeBundle(id, bundle)`
- `PNC.LoadArchetypes()`
- `PNC.RegisterArchetype(id, data)`
- `PNC.RegisterArchetypeLooks(id, data)`
- `PNC.RegisterArchetypeSkills(id, data)`
- `PNC.RegisterArchetypeLoadout(id, data)`
- `PNC.Identity.ResolveArchetypeID(source)`
- `PNC.Identity.GenerateResolvedIdentity(source)`
- `PNC.Identity.ApplyRecordIdentity(record, source)`
- `PNC.Identity.RollAppearance(record)`
- `PNC.Identity.GetCharacterSummary(record)`
- `PNC.PlayerCharacters.EnsureIdentity(player, context)`
- `PNC.PlayerCharacters.GetEntityKey(player, context)`
- `PNC.PlayerCharacters.GetRegistryRecord(characterUUID)`
- `PNC.PlayerCharacters.MarkDead(player, worldAgeHours, reason)`

## Forbidden Responsibilities
- NPC identity/profile modules do not save NPC records;
  `PNC.PlayerCharacters` saves only its separate player-character registry
- does not build network payloads
- does not draw nameplates or character UI
- does not own progression deltas
- does not rely on definition-file side effects happening in a specific PZ alphabetical order
