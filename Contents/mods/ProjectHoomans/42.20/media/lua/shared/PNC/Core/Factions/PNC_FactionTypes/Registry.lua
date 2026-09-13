PNC = PNC or {}
PNC.FactionTypes = PNC.FactionTypes or {}
PNC.FactionTypes.Internal = PNC.FactionTypes.Internal or {}

local Types = PNC.FactionTypes
local Internal = Types.Internal
local Constants = PNC.FactionConstants

local function normalizeFactions(source, output)
    local faction
    local factionIDs = {}
    for id, raw in pairs(
        type(source.byID) == "table" and source.byID or {}
    ) do
        faction = Types.NormalizeFaction(raw, id)
        if faction and faction.id == id then
            output.byID[id] = faction
            factionIDs[#factionIDs + 1] = id
            output.byArchetype[faction.archetypeID] =
                output.byArchetype[faction.archetypeID] or {}
            output.byArchetype[faction.archetypeID][id] = true
        end
    end
    table.sort(factionIDs)
    return factionIDs
end

local function indexPlayerMemberships(output, factionIDs)
    local faction
    for _, id in ipairs(factionIDs) do
        faction = output.byID[id]
        for playerKey, _ in pairs(
            faction.playerMemberKeys or {}
        ) do
            if output.byPlayerKey[playerKey] == nil then
                output.byPlayerKey[playerKey] = id
            else
                faction.playerMemberKeys[playerKey] = nil
                if faction.ownerPlayerKey == playerKey then
                    faction.ownerPlayerKey = nil
                end
            end
        end
        if faction.ownerPlayerKey
            and faction.playerMemberKeys[
                faction.ownerPlayerKey
            ] ~= true
        then
            faction.ownerPlayerKey = nil
        end
    end
end

function Types.NormalizeFactionRegistry(value)
    local source = type(value) == "table" and value or {}
    local output = {
        schemaVersion = Constants.REGISTRY_SCHEMA_VERSION,
        revision = Internal.Revision(source.revision),
        byID = {},
        byArchetype = {},
        byPlayerKey = {},
    }
    local factionIDs = normalizeFactions(source, output)
    indexPlayerMemberships(output, factionIDs)
    return output
end

function Types.NewFactionRegistry(value)
    return Types.NormalizeFactionRegistry(value)
end
