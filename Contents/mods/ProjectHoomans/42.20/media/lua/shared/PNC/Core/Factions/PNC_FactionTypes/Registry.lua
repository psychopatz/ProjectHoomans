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

local function migrateRelation(diplomacy, sourceFaction, targetFaction)
    local atWar
    if sourceFaction.relations[targetFaction.id] then return end
    atWar = diplomacy.state == Constants.DIPLOMACY_WAR
    sourceFaction.relations[targetFaction.id] = Types.NormalizeRelation({
        atWar = atWar,
        state = atWar and "war" or "neutral",
        previousState = "unknown",
        warStartedAt = atWar and diplomacy.changedAt or 0,
        warEndedAt = atWar and 0 or diplomacy.changedAt,
        warReason = atWar and "unknown" or nil,
        initiatingFactionID = diplomacy.instigatorFactionID,
        lastEvaluatedAt = diplomacy.changedAt,
        revision = diplomacy.revision,
    }, sourceFaction.id, targetFaction.id)
end

local function migrateLegacyDiplomacy(source, output)
    -- V2 stored one symmetric pair record. V3 migrates it into two directed
    -- relations while preserving the official war/peace state.
    for pairKey, raw in pairs(
        type(source.diplomacy) == "table"
            and source.diplomacy or {}
    ) do
            local diplomacy = Types.NormalizeDiplomacy(raw, pairKey)
        if diplomacy
            and output.byID[diplomacy.factionAID]
            and output.byID[diplomacy.factionBID]
        then
            local first = output.byID[diplomacy.factionAID]
            local second = output.byID[diplomacy.factionBID]
            migrateRelation(diplomacy, first, second)
            migrateRelation(diplomacy, second, first)
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
    migrateLegacyDiplomacy(source, output)
    return output
end

function Types.NewFactionRegistry(value)
    return Types.NormalizeFactionRegistry(value)
end
