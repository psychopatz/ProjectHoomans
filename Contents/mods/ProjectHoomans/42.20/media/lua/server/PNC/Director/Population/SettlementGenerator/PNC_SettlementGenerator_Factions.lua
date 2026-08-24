if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Generator = PNC.SettlementGenerator
local Config = PNC.DirectorConfig.Population
local Sectors = PNC.PopulationSectors
local Candidates = PNC.SettlementCandidates
local Locations = PNC.AbstractLocations
local Store = PNC.AbstractWorldStore
local Identity = PNC.PopulationIdentity

local function factionScore(faction)
    local weight = Config.SETTLEMENT_FACTION_WEIGHTS[faction.archetypeID]
    if not weight or faction.status ~= "active" or faction.ownerPlayerKey
        or PNC.Factions.IsMobileGroup(faction) then return nil end
    local communities = PNC.Communities.GetForFaction(faction.id) or {}
    local active = 0
    for _, community in ipairs(communities) do
        if community.status == "active" then active = active + 1 end
    end
    return weight / (1 + active)
end

function Generator.ChooseFaction(seed)
    local factionWeights = {}
    for _, faction in ipairs(PNC.Factions.List()) do
        local score = factionScore(faction)
        if score then
            factionWeights[faction.id] = score
        end
    end
    local factionID = Sectors.WeightedChoice(factionWeights,
        tostring(seed) .. ":EXISTING_FACTION")
    if factionID then
        local faction = PNC.Factions.Get(factionID)
        return factionID, faction and faction.archetypeID or "settler"
    end
    local archetype = Sectors.WeightedChoice(Config.SETTLEMENT_FACTION_WEIGHTS,
        tostring(seed) .. ":NEW_FACTION")
    return nil, archetype or "settler"
end

return Generator

