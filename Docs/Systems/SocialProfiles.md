# Social Profiles

## Purpose

Phase 3B adds persistent character description data without confusing it with
behavior or relationship history:

- a **profile** describes a player character or NPC;
- **reputation** will describe observed behavior, but is not implemented;
- a directed **relationship** records how one NPC feels about one stable
  target as a result of memories.

Profiles do not initiate romance, dialogue, factions, hostility, order refusal,
desertion, food reactions, or autonomous social behavior.

## Player Profile

Every `PNC_PlayerCharacters.byUUID` record owns:

```lua
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
}
```

The profile belongs to the survivor UUID, not the account index. A new
survivor resolves a new profile from that survivor's authoritative character
traits. Historical dead records that predate Phase 3B receive a neutral
profile; their old traits are never guessed.

`sourceTraits` is a map of canonical PNC string IDs to `true`. Runtime
`CharacterTrait`, `IsoPlayer`, descriptor, or Java collection objects are
never persisted.

## Build 42 Character Traits

Build 42.20 exposes `CharacterTrait.register`,
`CharacterTraitDefinition.addCharacterTraitDefinition`, and
`CharacterTraitDefinition.setMutualExclusive`. The shared
`PNC_SocialTraits` bootstrap uses these registries directly before the
standard character-creation screen is built. Registration is guarded and
idempotent, does not require UI modules on a dedicated server, and uses the
engine's generic trait texture fallback because this phase adds no media.

Build 42.20's vanilla `populateTraitList` and `populateBadTraitList` omit
definitions whose cost is exactly zero. The client-only
`PNC_SocialTraitCharacterCreationPatch` wraps the normal positive-list
population and appends only PNC's registered zero-point definitions. It does
not create a custom screen or replace vanilla point, selection, sorting,
removal, or mutual-exclusion behavior.

| Canonical ID | Name | Build 42 `Cost` | Player result |
|---|---|---:|---|
| `PNC_Gay` | Gay | 0 | orientation `gay` |
| `PNC_Bisexual` | Bisexual | 0 | orientation `bisexual` |
| `PNC_BlandPalate` | Bland Palate | 0 | food `bland` |
| `PNC_SpiceLover` | Spice Lover | 0 | food `spicy` |
| `PNC_Flirty` | Flirty | 0 | romance `flirty` |
| `PNC_Reserved` | Reserved | 0 | romance `reserved` |
| `PNC_Jealous` | Jealous | 0 | jealousy `jealous` |
| `PNC_Unpossessive` | Unpossessive | 0 | jealousy `unpossessive` |
| `PNC_Friendly` | Friendly | 2 | social `friendly`; costs 2 points |
| `PNC_Withdrawn` | Withdrawn | -2 | social `withdrawn`; grants 2 points |

Build 42's cost sign is confirmed by its trait UI: positive cost is displayed
and deducted as points spent; negative cost is displayed as points granted.

Engine exclusions and server resolver exclusions both cover:

- Gay / Bisexual
- Bland Palate / Spice Lover
- Flirty / Reserved
- Jealous / Unpossessive
- Friendly / Withdrawn

Malformed combinations resolve deterministically: Bisexual, Spice Lover,
Reserved, Jealous, and Friendly take precedence in their respective groups.
Only the retained primitive trait IDs enter `sourceTraits`.

No selected orientation means explicit `straight`; all other unselected groups
use their neutral/default value. Orientation has no approval, respect, morale,
health, combat, panic, skill, or event modifier.

## Player Resolution Lifecycle

`PNC.PlayerCharacterLifecycle` calls the profile service after a successful
Phase 3A identity ensure. The first authoritative player object is inspected,
its ten recognized PNC traits are canonicalized and fingerprinted, and the
resolved profile is committed to that UUID.

A weak runtime cache avoids resolving the same bound player every one-second
identity sweep. A replaced/reconnected player object is verified once.
Unchanged traits do not update `resolvedAt` or revisions. The explicit
`RefreshPlayerProfile` API supports admin/debug or other-mod trait changes
without accepting a client-supplied profile table.

## NPC Personality

Every NPC owns `record.social.personality`:

```lua
{
    schemaVersion = 1,
    orientation = "straight",
    foodPreference = "neutral",
    romanceStyle = "neutral",
    jealousyStyle = "normal",
    socialStyle = "neutral",
    compassion = 0.50,
    sociability = 0.50,
    forgiveness = 0.50,
    bravery = 0.50,
    materialism = 0.50,
    aggression = 0.50,
    loyalty = 0.50,
    generatedFromSeed = true,
    generationVersion = 1,
}
```

Numeric values clamp to `[0, 1]`. Generation uses only
`record.identitySeed`, independent salted `PNC.Identity.Float` calls,
`generationVersion`, and mild archetype modifiers. It never consumes
`ZombRand`, `math.random`, a clock, or a live object.

Numeric dimensions start in `[0.25, 0.75]`, then apply:

| Archetype | Modifiers |
|---|---|
| `Doctor` | compassion +0.10, aggression -0.05, materialism -0.05 |
| `Foreman` | loyalty +0.05, sociability +0.05 |
| `Mechanic` | materialism +0.05, sociability -0.02 |
| `General` | none |

`Farmer` and `Scavenger` currently use the general distribution. Archetype
never determines orientation.

Orientation generation defaults to gameplay weights 80 straight / 10 gay /
10 bisexual. Servers may replace
`PNC.Config.Relationships.NPCOrientationWeights`. These are generation balance
values, not demographic claims. Food, romance, jealousy, and social categories
are independently generated at 60% neutral/default and 20% for either
non-neutral value.

Stored valid profiles are normalized in place and never rerolled. Future
generator changes must use a new `generationVersion`; they must not silently
rewrite version 1 profiles.

## Authored Overrides

Scenario definitions may provide:

```lua
social = {
    personalityOverrides = {
        orientation = "gay",
        compassion = 0.85,
        foodPreference = "bland",
    },
}
```

Valid overrides replace the initially generated fields. Invalid enums are
ignored, numbers are clamped, and the normalized override map persists beside
the resulting profile. Normalization of an existing valid profile does not
reapply or reroll it, so removing an override does not silently change the
stored personality. A future editor can add an explicit regeneration command.

## Orientation Compatibility

`IsGenderCompatible` is a pure eligibility helper for the current binary
identity representation (`isFemale` boolean or `male`/`female`):

- straight: other gender;
- gay: same gender;
- bisexual: either current gender.

`AreMutuallyOrientationCompatible` requires both profiles to be compatible.
Compatibility is not attraction, approval, relationship state, consent, or a
successful romantic action. Invalid genders fail closed. The helper can be
extended when Project Hoomans supports additional gender identities.

## Existing Event Interpretation

Only new instances of the five Phase 2 events are modified. Existing memories
are never rewritten. The observer is always the NPC whose directed
relationship changes; the actor's profile is not applied.

Effects are rounded deterministically to two decimals and clamped to approval,
respect, and morale `[-100, 100]`, and familiarity `[0, 100]`.

- `treated_wound` and `saved_from_incapacitation`: compassion scales positive
  approval and morale from 0.85x to 1.15x.
- `protected_from_attacker` and `survived_combat_together`: low bravery scales
  positive approval/morale up to 1.15x while high bravery scales them down to
  0.85x; combat respect uses the inverse 0.85x to 1.15x range.
- `survived_combat_together`: loyalty adds a 0.90x to 1.10x positive scale.
- `abandoned_in_combat`: loyalty scales negative effects 0.80x to 1.25x;
  forgiveness scales negative approval/respect from 1.25x down to 0.75x.
- friendly observers multiply positive approval and familiarity by 1.10;
  withdrawn observers multiply positive approval by 0.90 and familiarity by
  0.80.

Materialism and aggression are deliberately unused until events such as gifts,
theft, trading, threats, or violence have a clear meaning.

Modifier calculation does not mutate the profile, event definition, event
specification, or registry. Saturation and cooldown checks use the modified
new contribution, and the existing atomic event mutation still owns the one
relationship/social/record revision commit.

## Persistence and Revisions

Phase 3B advances:

- NPC record schema V11 to V12;
- NPC social schema V1 to V2;
- player-character registry schema V1 to V2.

Phase 4 later advances these domains to NPC V13, social V3, and player
registry V3 solely to add behavioral conduct. Profile generation and values
remain unchanged.

Phase 5A advances only the containing NPC record to V14 for organizational
affiliation. Social profiles remain unchanged, and faction archetypes never
generate or modify personality.

The top-level NPC schema advances because the existing registry marks old
records for rewrite from that marker. V11 records deterministically generate a
personality from their persisted seed while preserving relationships,
memories, cooldowns, saturation, event IDs, morale, and revisions.

Player registry normalization gives every record a profile without guessing
historical traits. Migration normalization follows existing conventions and
does not fabricate revision activity. A later meaningful player profile
change increments profile, character-record, and registry revision once. An
NPC profile repair increments `social.revision` and uses the existing
record-dirty convention. No profile operation increments `presenceRevision`.

## Public API

- `PNC.SocialProfiles.GetPlayerProfile(characterUUID)`
- `PNC.SocialProfiles.GetPlayerProfileForPlayer(player)`
- `PNC.SocialProfiles.ResolvePlayerProfile(player, worldAgeHours)`
- `PNC.SocialProfiles.RefreshPlayerProfile(player, worldAgeHours)`
- `PNC.SocialProfiles.NormalizePlayerProfile(value)`
- `PNC.SocialProfiles.ResolveTraits(traitSet)`
- `PNC.SocialProfiles.GetNPCProfile(npcID)`
- `PNC.SocialProfiles.GenerateNPCProfile(seed, archetypeID, overrides)`
- `PNC.SocialProfiles.EnsureNPCProfile(record)`
- `PNC.SocialProfiles.IsGenderCompatible(...)`
- `PNC.SocialProfiles.AreMutuallyOrientationCompatible(...)`
- `PNC.SocialProfiles.ModifySocialEvent(...)`

Read APIs return copies. Mutation and live-trait inspection live in server-only
Lua; no client profile mutation command exists.

## Debugging

`PNC.Config.Relationships.DebugSocialProfiles` defaults to `false`.
`PNC.SocialProfileDebug.FormatPlayer(uuid)` and `FormatNPC(npcID)` are
read-only formatters. Existing `DebugSocialEvents` output includes the
profile-modified effects and sorted multiplier breakdown when enabled.

## Non-Goals and Next Phase

Phase 3B does not implement romance, flirting, partners, jealousy events, food
classification, gifts, dialogue, gossip, reputation, factions, diplomacy,
order compliance, desertion, hostility changes, loneliness, or player-owned
relationships.

The recommended next step is to complete the Phase 3A and Phase 3B live
validation matrices before adding any new social event category. After that,
a small behavior-derived reputation layer is safer than immediately building
romance or factions.
