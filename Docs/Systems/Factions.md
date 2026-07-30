# Persistent Factions

## Purpose and Compatibility Boundary

Phase 5A gave survivor organizations stable server-owned identity and NPC
membership. Phase 5B adds a narrow server-owned behavior bridge, player
factions, and pairwise faction war. The system still separates:

- a faction archetype classifies what kind of organization it is;
- a faction record identifies one persistent organization;
- `record.affiliation` identifies an NPC's organization, status, role, and rank;
- legacy `record.faction` remains a derived tactical compatibility field used
  by existing combat, targeting, jobs, recruitment, visuals, and commands.

`record.affiliation.factionID` is canonical. The centralized behavior bridge
derives legacy ownership/hostility fields after membership or diplomacy
changes. Migration still never groups old `colonist`, `neutral`, or `hostile`
records automatically.

## Registry and Records

The authority stores a separate `PNC_Factions` Global ModData registry:

```lua
{
    schemaVersion = 2,
    revision = 0,
    byID = {
        faction_123 = {
            id = "faction_123",
            name = "Riverside Cooperative",
            archetypeID = "settler",
            status = "active",
            createdAt = 182.5,
            archivedAt = 0,
            leaderNPCID = "npc_123",
            ownerPlayerKey = "player:Patrick:char_f8d31a",
            memberIDs = { npc_123 = true },
            playerMemberKeys = {
                ["player:Patrick:char_f8d31a"] = true,
            },
            tags = {},
            revision = 1,
        },
    },
    byArchetype = {
        settler = { faction_123 = true },
    },
    byPlayerKey = {
        ["player:Patrick:char_f8d31a"] = "faction_123",
    },
    diplomacy = {
        ["faction_123|faction_456"] = {
            factionAID = "faction_123",
            factionBID = "faction_456",
            state = "war",
            changedAt = 183.0,
            reason = "player_attacked_member",
            instigatorFactionID = "faction_123",
            revision = 1,
        },
    },
}
```

`byID` is canonical for faction identity. NPC affiliation is canonical for
NPC membership; `playerMemberKeys` is canonical for stable player-character
membership. `memberIDs`, `byArchetype`, and `byPlayerKey` are primitive-only
secondary indexes rebuilt deterministically.
Complete NPC records and engine objects are never copied into
the faction registry.

Faction statuses are `active`, `inactive`, `archived`, and `destroyed`.
Ordinary APIs preserve archived/destroyed records and never reuse their IDs.
Faction names are display data and need not be unique.

## Archetypes

The shared, copy-returning archetype registry contains exactly:

- `settler` — Settlement
- `looter` — Looter Gang
- `trader` — Trading Company
- `refugee` — Refugee Group

Definitions contain labels, descriptions, allowed/default roles, and a small
data-only tactical policy. A looter faction is hostile to outsiders. Settler,
trader, and refugee factions are neutral until war. Definitions contain no
engine callbacks, raid schedules, economy, territory, or autonomous strategy.

## Player Factions

`CreatePlayerFaction(player, spec)` resolves the existing stable
`player:<account>:<characterUUID>` identity and stores it as the owner/member.
One player character may belong to one faction. A new survivor UUID is a
different person and does not inherit the dead character's faction.

Player-owned NPC members derive companion ownership from the faction owner:
legacy `colonist`, recruited, follow order, and owner identity. Transferring
that NPC to an external faction removes those companion fields. If
authoritative aggression needs a player faction and none exists, the service
creates a personal settler faction for that specific character.

## Behavior and War

The server applies this compatibility policy:

- player-owned faction member: commandable companion;
- looter member: hostile-hunt behavior toward outsiders;
- settler/trader/refugee member at peace: neutral roaming behavior;
- any faction member at war: aggressive toward members of the opposing
  faction;
- unaffiliated NPC after faction removal: neutral and unowned.

War is one canonical, symmetric diplomacy record keyed by a sorted faction-ID
pair. Reads in either direction return the same state. The target resolver
checks faction IDs and player-character membership, preventing a war with one
player faction from making neutral organizations attack every player.

War begins when authoritative combat records a player or NPC attacking a
member of another faction, or when a member's directed relationship toward a
player reaches `enemy`. An attacking unaffiliated player first receives their
stable personal faction. Making peace restores non-looter factions to neutral;
looters remain hostile to outsiders by archetype.

## NPC Affiliation

Every V14 NPC record contains affiliation schema V1:

```lua
{
    schemaVersion = 1,
    factionID = nil,
    membershipStatus = "unaffiliated",
    role = "civilian",
    rank = "member",
    joinedAt = 0,
    leftAt = 0,
    originArchetypeID = nil,
    formerFactionIDs = {},
    revision = 0,
}
```

Supported membership statuses are `unaffiliated`, `applicant`, `guest`,
`refugee`, `member`, `probationary_member`, `prisoner`, `mercenary`,
`deserter`, and `exile`. Phase 5A behavior is limited to unaffiliated, guest,
refugee, and member.

Roles are `leader`, `lieutenant`, `guard`, `enforcer`, `raider`, `trader`,
`medic`, `farmer`, `builder`, `scavenger`, `cook`, `mechanic`, `laborer`,
`caregiver`, `civilian`, and `prisoner`. Archetypes validate the roles they
currently allow. Ranks are `member`, `senior`, `officer`, `second`, and
`leader`. Role and rank do not modify personality, conduct, or tactical AI.

Former-membership history contains faction ID, joined/left world-age hours,
and a normalized reason. It is deterministically limited to the newest eight
entries.

## Membership, Leadership, and Archival

All mutation uses `PNC.Factions`. Add rejects unintended dual membership;
transfer removes the old index, appends history, and commits the destination
in one synchronous authority operation. Remove resets affiliation and clears
leadership when necessary.

Leader assignment requires a living member unless `addIfMissing` is explicitly
requested. A new leader receives leader role/rank; the former leader is
demoted to member rank and the archetype's safe default role. Removing or
killing a leader clears `leaderNPCID`; no successor is selected and the faction
is not archived.

Archival preserves the faction ID and display record, clears leadership,
converts current memberships into former-membership history, and leaves
relationships, conduct, personality, and inventory unchanged. Removed NPCs are
reconciled to unaffiliated neutral behavior. Active wars involving the
archived faction become peace so surviving factions do not remain aggressive
toward a faction that can no longer field members.

## Authority, Revisions, and API

Mutation APIs are server-only:

- `Create`
- `CreatePlayerFaction`, `EnsurePlayerFaction`
- `AddNPC`, `RemoveNPC`, `TransferNPC`
- `SetNPCStatus`, `SetNPCRole`, `SetNPCRank`
- `SetLeader`
- `Archive`
- `DeclareWar`, `MakePeace`
- authoritative `OnPlayerAggression`, `OnNPCAggression`, and
  `OnRelationshipChanged` adapters

Copied read APIs are:

- `Get`, `List`, `GetByArchetype`, `GetMembers`, `GetLeader`
- `GetNPCFaction`, `GetNPCAffiliation`, `IsMember`
- `GetArchetype`, `GetAllowedRoles`
- `GetPlayerFaction`, `GetFactionForPlayerKey`
- `GetDiplomacy`, `AreAtWar`, `IsFactionAtWar`
- `GetOrganizationalFactionID`, `GetLegacyFactionClass`

Membership changes advance affiliation and owning NPC record revisions plus
the affected faction and faction-registry revisions. Derived behavior changes
use normal NPC dirty-record revision rules and never advance
`presenceRevision`. War/peace advances both faction revisions and the registry
once. Pure reads and already-current diplomacy advance nothing.

Faction IDs come from `PNC.Core.GenerateID("faction")`, are collision checked
with bounded retries, and cannot be supplied by ordinary clients.

## Persistence and Debugging

Phase 5A advanced NPC persistence from V13 to V14 solely so every existing
record is rewritten with neutral affiliation. Social remains V3, the
player-character registry remains V3, and conduct remains V1. Migration does
not infer membership from legacy faction, proximity, archetype, ownership, or
recruitment.

Phase 5B advances only the separate `PNC_Factions` registry from V1 to V2.
Normalization adds empty player and diplomacy indexes deterministically.
NPC persistence remains V14 and affiliation remains V1.

The admin/debug-only **PNC Faction Inspector** lists factions and NPCs, displays
details/members/diplomacy, and routes player-faction creation, war/peace,
create, assign, transfer, remove, leader, role, rank, and archive actions
through the real service. The Relationship Inspector
shows read-only organization summaries for observer/target NPCs and explicitly
shows no organizational faction for player targets.

## Non-Goals and Extensions

Phase 5B still adds no reputation/standing score, communities, settlement
simulation, territory, mobile parties, trade, economy, raids, tribute, goals,
role-specific AI, gossip, dialogue, romance, order refusal, or desertion
simulation. War is a tactical relationship and target filter, not autonomous
strategic faction simulation.
