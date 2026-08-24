-- Authoritative faction secondary-index reconstruction.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionValidation = PNC.FactionValidation or {}
local Validation = PNC.FactionValidation
local Factions = PNC.Factions
local Types = PNC.FactionTypes

function Validation.RepairSecondaryIndexes()
    if PNC.Core and PNC.Core.IsAuthority
        and PNC.Core.IsAuthority() ~= true
    then
        return false, "not_authority"
    end
    Factions.EnsureLoaded()
    local registry = Factions.Registry
    local byArchetype = {}
    local byPlayerKey = {}
    local memberIDs = {}
    local factionIDs = {}
    local changed = false
    for factionID, _ in pairs(registry.byID or {}) do
        factionIDs[#factionIDs + 1] = factionID
        memberIDs[factionID] = {}
    end
    table.sort(factionIDs)
    for _, factionID in ipairs(factionIDs) do
        local faction = registry.byID[factionID]
        byArchetype[faction.archetypeID] =
            byArchetype[faction.archetypeID] or {}
        byArchetype[faction.archetypeID][factionID] = true
        for playerKey, enabled in pairs(
            faction.playerMemberKeys or {}
        ) do
            if enabled == true and not byPlayerKey[playerKey] then
                byPlayerKey[playerKey] = factionID
            end
        end
    end
    for npcID, record in pairs(PNC.Registry.Data or {}) do
        local factionID = record.affiliation
            and record.affiliation.factionID or nil
        local faction = factionID and registry.byID[factionID]
        if faction and faction.status == "active" then
            memberIDs[factionID][npcID] = true
        end
    end
    for _, factionID in ipairs(factionIDs) do
        local faction = registry.byID[factionID]
        if not Types.AreEqual(
            faction.memberIDs,
            memberIDs[factionID]
        ) then
            faction.memberIDs = memberIDs[factionID]
            faction.revision =
                (tonumber(faction.revision) or 0) + 1
            changed = true
        end
    end
    if not Types.AreEqual(registry.byArchetype, byArchetype) then
        registry.byArchetype = byArchetype
        changed = true
    end
    if not Types.AreEqual(registry.byPlayerKey, byPlayerKey) then
        registry.byPlayerKey = byPlayerKey
        changed = true
    end
    if not changed then return false, "unchanged" end
    registry.revision = (tonumber(registry.revision) or 0) + 1
    return true, "secondary_indexes_repaired"
end

return Validation
