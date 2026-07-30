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

## Public Functions
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
