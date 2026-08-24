if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

local Factions = PNC.Factions
local Internal = Factions.Internal
local Core = PNC.Core
local Constants = PNC.FactionConstants
local Types = PNC.FactionTypes
local Archetypes = PNC.FactionArchetypes
local EntityRef = PNC.EntityRef
function Factions.Create(spec)
    local id
    local faction
    local leader
    local leaderAffiliation
    local createdAt
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    spec = type(spec) == "table" and spec or {}
    if not Archetypes.Exists(spec.archetypeID) then
        return false, "unknown_archetype"
    end
    id = Factions.GenerateID()
    if not id then return false, "id_generation_failed" end
    createdAt = Internal.finiteTimestamp(spec.createdAt, 0)
    faction = Types.NewFaction({
        id = id,
        name = spec.name,
        archetypeID = spec.archetypeID,
        status = "active",
        createdAt = createdAt,
        archivedAt = 0,
        tags = Types.NormalizeTags(spec.tags),
        ownerPlayerKey = spec.ownerPlayerKey,
        playerMemberKeys = spec.playerMemberKeys,
        policy = spec.policy,
        emblem = spec.emblem,
        revision = 1,
    })
    if not faction then return false, "invalid_name" end
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        if Factions.Registry.byPlayerKey[playerKey] then
            return false, "player_already_affiliated"
        end
    end
    if spec.ownerPlayerKey ~= nil then
        if not EntityRef.IsPlayer(spec.ownerPlayerKey) then
            return false, "invalid_player_key"
        end
        faction.ownerPlayerKey = spec.ownerPlayerKey
        faction.playerMemberKeys[spec.ownerPlayerKey] = true
    end
    if spec.leaderNPCID ~= nil then
        leader = Internal.npcRecord(spec.leaderNPCID, false)
        if not leader then return false, "leader_not_found" end
        leaderAffiliation = Types.NormalizeAffiliation(
            leader.affiliation
        )
        if leaderAffiliation.factionID then
            return false, "npc_already_affiliated"
        end
        leaderAffiliation = Types.NormalizeAffiliation({
            factionID = id,
            membershipStatus = "member",
            role = "leader",
            rank = "leader",
            joinedAt = createdAt,
            originArchetypeID = faction.archetypeID,
            formerFactionIDs =
                leaderAffiliation.formerFactionIDs,
            revision = leaderAffiliation.revision,
        }, faction)
        faction.leaderNPCID = leader.id
        faction.memberIDs[leader.id] = true
    end
    Factions.Registry.byID[id] = faction
    Factions.Registry.byArchetype[faction.archetypeID] =
        Factions.Registry.byArchetype[faction.archetypeID] or {}
    Factions.Registry.byArchetype[faction.archetypeID][id] = true
    for playerKey, _ in pairs(
        faction.playerMemberKeys or {}
    ) do
        Factions.Registry.byPlayerKey[playerKey] = id
    end
    if leader then Internal.commitAffiliation(leader, leaderAffiliation) end
    Internal.touchRegistry()
    if PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetPrimary
    then
        PNC.ColonyStorageRepository.GetPrimary(id)
    end
    if leader and PNC.FactionBehavior
        and PNC.FactionBehavior.ApplyNPC
    then
        PNC.FactionBehavior.ApplyNPC(
            leader,
            "faction_created"
        )
    end
    return true, "created", Internal.copy(faction)
end

function Factions.SetName(factionID, value)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    local name = type(value) == "string"
        and string.match(value, "^%s*(.-)%s*$") or nil
    if not name or name == "" or #name > Constants.NAME_MAX_LENGTH then
        return false, "invalid_name"
    end
    if faction.name == name then return false, "unchanged", Internal.copy(faction) end
    faction.name = name
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "renamed", Internal.copy(faction)
end

function Factions.MergeTags(factionID, values)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    local merged = Internal.copy(faction.tags or {})
    for key, value in pairs(type(values) == "table" and values or {}) do
        merged[key] = value
    end
    merged = Types.NormalizeTags(merged)
    if Types.AreEqual(faction.tags, merged) then
        return false, "unchanged", Internal.copy(faction)
    end
    faction.tags = merged
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "tags_merged", Internal.copy(faction)
end

function Factions.SetProvisionPolicy(factionID, value)
    if not Internal.authority() then return false, "not_authority" end
    Factions.EnsureLoaded()
    local faction = Internal.registryRecord(factionID)
    if not faction then return false, "faction_not_found" end
    local normalized = PNC.ProvisionPolicy.Normalize(value)
    if Types.AreEqual(faction.provision, normalized) then
        return false, "unchanged", Internal.copy(faction.provision)
    end
    faction.provision = normalized
    Internal.touchFaction(faction)
    Internal.touchRegistry()
    return true, "updated", Internal.copy(faction.provision)
end

return Factions
