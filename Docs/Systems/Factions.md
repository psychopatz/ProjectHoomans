# Persistent Factions

## Purpose and Compatibility Boundary

Phase 5A gives survivor organizations stable server-owned identity and NPC
membership. It deliberately separates four concepts:

- a faction archetype classifies what kind of organization it is;
- a faction record identifies one persistent organization;
- `record.affiliation` identifies an NPC's organization, status, role, and rank;
- legacy `record.faction` remains the tactical compatibility classification
  used by existing combat, targeting, jobs, recruitment, visuals, and commands.

`record.faction` is deprecated for new organizational identity, but Phase 5A
does not rename, reinterpret, or replace it. A `looter` organization does not
become hostile automatically, and `colonist`, `neutral`, or `hostile` NPCs are
not grouped into organizations during migration.

## Registry and Records

The authority stores a separate `PNC_Factions` Global ModData registry:

```lua
{
    schemaVersion = 1,
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
            memberIDs = { npc_123 = true },
            tags = {},
            revision = 1,
        },
    },
    byArchetype = {
        settler = { faction_123 = true },
    },
}
```

`byID` is canonical for faction identity. NPC affiliation is canonical for
current membership. `memberIDs` and `byArchetype` are primitive-only secondary
indexes rebuilt deterministically from faction records and NPC affiliations.
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

Definitions contain labels, descriptions, allowed roles, and default roles
only. They contain no hostility, diplomacy, economy, recruitment, or AI
callbacks.

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
`leader`. Role and rank do not modify personality, conduct, relationships,
hostility, or AI.

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
relationships, conduct, personality, inventory, recruitment, and hostility
unchanged.

## Authority, Revisions, and API

Mutation APIs are server-only:

- `Create`
- `AddNPC`, `RemoveNPC`, `TransferNPC`
- `SetNPCStatus`, `SetNPCRole`, `SetNPCRank`
- `SetLeader`
- `Archive`

Copied read APIs are:

- `Get`, `List`, `GetByArchetype`, `GetMembers`, `GetLeader`
- `GetNPCFaction`, `GetNPCAffiliation`, `IsMember`
- `GetArchetype`, `GetAllowedRoles`
- `GetOrganizationalFactionID`, `GetLegacyFactionClass`

Membership changes advance affiliation and owning NPC record revisions plus
the affected faction and faction-registry revisions. They never advance
presence, social, relationship, or conduct revisions. Pure reads and already
correct index rebuilds advance nothing.

Faction IDs come from `PNC.Core.GenerateID("faction")`, are collision checked
with bounded retries, and cannot be supplied by ordinary clients.

## Persistence and Debugging

Phase 5A advances NPC persistence from V13 to V14 solely so every existing
record is rewritten with neutral affiliation. Social remains V3, the
player-character registry remains V3, and conduct remains V1. Migration does
not infer membership from legacy faction, proximity, archetype, ownership, or
recruitment.

The admin/debug-only **PNC Faction Inspector** lists factions and NPCs, displays
details/members, and routes create, assign, transfer, remove, leader, role,
rank, and archive actions through the real service. The Relationship Inspector
shows read-only organization summaries for observer/target NPCs and explicitly
shows no organizational faction for player targets.

## Non-Goals and Extensions

Phase 5A adds no diplomacy, reputation, standing, communities, settlements,
territory, mobile parties, trade, economy, raids, tribute, goals, recruitment
policy, role-based AI, player faction, gossip, dialogue, romance, order
refusal, desertion behavior, or hostility changes. Those systems may later
reference stable faction IDs without changing this identity foundation.
