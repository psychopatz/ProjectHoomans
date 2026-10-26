-- Raw save payload access and bounded persistence-summary helpers.

local function install(ProductionRehydration)
    local Internal = ProductionRehydration.Internal

local function sourceKind(context)
    local metadata = context.Runtime.sourceMetadata or {}
    return tostring(metadata.sourceKind or "FIXTURE")
end

local function fail(context, reason)
    local Runtime = context.Runtime
    Runtime.productionRehydration = {
        schema = "semantic.production_rehydration.v1",
        source = "SAVE",
        status = "REHYDRATION_FAILURE",
        reason = tostring(reason or "unknown"),
    }
    return false, tostring(reason or "unknown")
end

local function rawRecordFor(context, npcID)
    local payloads = context.Runtime.sourceProviderPayloads or {}
    local hoomans = payloads.ProjectHoomans
    if type(hoomans) ~= "table" then return nil end
    local rawRecords = hoomans.rawRecords
    if type(rawRecords) == "table" and type(rawRecords.npc) == "table" then
        return rawRecords.npc
    end
    return hoomans["PNC_" .. tostring(npcID)]
end

local function rawRegistriesFor(context)
    local payloads = context.Runtime.sourceProviderPayloads or {}
    local hoomans = payloads.ProjectHoomans
    local registries = type(hoomans) == "table"
        and hoomans.rawRegistries or nil
    registries = type(registries) == "table" and registries
        or context.Runtime.productionRawRegistries
    return type(registries) == "table" and registries or {}
end

local function rawPlayerRegistryFor(context)
    local registries = rawRegistriesFor(context)
    return registries.playerCharacters
end

local function rawKnowledgeRegistryFor(context)
    local registries = rawRegistriesFor(context)
    return registries.npcKnowledge
end

local function playerEntityKey(context)
    local player = context.Runtime.scenario
        and context.Runtime.scenario.player or {}
    return tostring(player.entityKey or "")
end

local function nameParts(record)
    local identity = type(record.identity) == "table"
        and record.identity or {}
    local survivor = type(identity.survivor) == "table"
        and identity.survivor or {}
    local displayName = tostring(
        identity.displayName or record.displayName or record.name or "Saved NPC"
    )
    local forename = tostring(survivor.forename or "")
    local surname = tostring(survivor.surname or "")
    if forename == "" then
        local first, rest = string.match(displayName, "^(%S+)%s*(.*)$")
        forename = first or displayName
        surname = surname ~= "" and surname or (rest or "")
    end
    return forename, surname, displayName
end

local function countItems(inventory)
    local count = 0
    for _ in pairs(type(inventory) == "table" and inventory.items or {}) do
        count = count + 1
        if count >= 200000 then return count end
    end
    return count
end

local function hasEntries(value)
    if type(value) ~= "table" then return false end
    for _ in pairs(value) do
        return true
    end
    return false
end

local function countKeys(value)
    local count = 0
    for _ in pairs(type(value) == "table" and value or {}) do
        count = count + 1
    end
    return count
end

local function factionSummary(faction)
    if type(faction) ~= "table" then return nil end
    return {
        id = faction.id,
        name = faction.name,
        archetypeID = faction.archetypeID,
        status = faction.status,
        leaderNPCID = faction.leaderNPCID,
        ownerPlayerKey = faction.ownerPlayerKey,
        provisionalPlayerFaction = PNC.Factions
            and type(PNC.Factions.IsProvisionalPlayerFaction) == "function"
            and PNC.Factions.IsProvisionalPlayerFaction(faction) or false,
        memberCount = countKeys(faction.memberIDs),
        playerMemberCount = countKeys(faction.playerMemberKeys),
        tags = faction.tags,
        mobile = faction.mobile,
    }
end

local function communitySummary(community)
    if type(community) ~= "table" then return nil end
    return {
        id = community.id,
        name = community.name,
        factionID = community.factionID,
        status = community.status,
        leaderNPCID = community.leaderNPCID,
        memberCount = countKeys(community.memberIDs),
    }
end

local function resetOrganizationState()
    if PNC and PNC.Factions and PNC.FactionTypes
        and type(PNC.FactionTypes.NewFactionRegistry) == "function"
    then
        PNC.Factions.Registry = PNC.FactionTypes.NewFactionRegistry()
        PNC.Factions.Loaded = true
        PNC.Factions.Dirty = false
    end
    if PNC and PNC.Communities and PNC.CommunityTypes
        and type(PNC.CommunityTypes.NewRegistry) == "function"
    then
        PNC.Communities.Registry = PNC.CommunityTypes.NewRegistry()
        PNC.Communities.Loaded = true
        PNC.Communities.Dirty = false
    end
end

    Internal.SourceKind = sourceKind
    Internal.Fail = fail
    Internal.RawRecordFor = rawRecordFor
    Internal.RawRegistriesFor = rawRegistriesFor
    Internal.RawPlayerRegistryFor = rawPlayerRegistryFor
    Internal.RawKnowledgeRegistryFor = rawKnowledgeRegistryFor
    Internal.PlayerEntityKey = playerEntityKey
    Internal.NameParts = nameParts
    Internal.CountItems = countItems
    Internal.HasEntries = hasEntries
    Internal.CountKeys = countKeys
    Internal.FactionSummary = factionSummary
    Internal.CommunitySummary = communitySummary
    Internal.ResetOrganizationState = resetOrganizationState
end

return install
