-- Production organization context and bounded NPC projection.

local function install(ProductionRehydration)
    local Internal = ProductionRehydration.Internal

local function productionFactionContext(context, record)
    local Values = context.Values
    local affiliation = type(record and record.affiliation) == "table"
        and record.affiliation or {}
    local npcFactionID = affiliation.factionID
    local playerKey = Internal.PlayerEntityKey(context)
    local npcFaction
    local playerFaction
    local directedRelation
    local factionReason
    local playerReason
    if PNC.Factions and type(PNC.Factions.Get) == "function"
        and npcFactionID
    then
        npcFaction, factionReason = PNC.Factions.Get(npcFactionID)
    end
    if PNC.Factions
        and type(PNC.Factions.GetDiplomacyFactionForPlayerKey)
            == "function"
    then
        playerFaction, playerReason =
            PNC.Factions.GetDiplomacyFactionForPlayerKey(playerKey)
    end
    if npcFaction and playerFaction
        and npcFaction.id ~= playerFaction.id
        and type(PNC.Factions.GetRelation) == "function"
    then
        directedRelation = PNC.Factions.GetRelation(
            npcFaction.id,
            playerFaction.id
        )
    end

    local community
    local communityReason
    if PNC.Communities
        and type(PNC.Communities.Get) == "function"
        and affiliation.communityID
    then
        community, communityReason = PNC.Communities.Get(
            affiliation.communityID
        )
    end

    local effective = directedRelation and {
        state = directedRelation.state,
        standing = directedRelation.standing,
        trust = directedRelation.trust,
        fear = directedRelation.fear,
        grievance = directedRelation.grievance,
        source = "PNC.Factions.GetRelation",
    } or npcFaction and playerFaction
        and npcFaction.id == playerFaction.id and {
            state = "same_faction",
            source = "PNC.Factions.GetDiplomacyFactionForPlayerKey",
        } or {
            state = "unknown",
            source = "PNC.Factions.GetRelation",
        }

    return {
        schema = "semantic.production_faction_context.v1",
        source = "PRODUCTION",
        playerKey = playerKey,
        npcFaction = Internal.FactionSummary(npcFaction),
        npcFactionReason = factionReason,
        playerDiplomacyFaction = Internal.FactionSummary(playerFaction),
        playerDiplomacyFactionReason = playerReason,
        directedRelation = Values.copy(directedRelation),
        effective = effective,
        community = Internal.CommunitySummary(community),
        communityReason = communityReason,
        affiliation = Values.copy(affiliation),
    }
end

function ProductionRehydration.installEngineItemTypeFixture(context, fixture)
    local existingCount = tonumber(
        context.Runtime.engineItemTypeFixtureCount
    ) or 0
    fixture = type(fixture) == "table" and fixture or nil
    if type(fixture) ~= "table" then
        local payloads = context.Runtime.sourceProviderPayloads or {}
        local projectZomboid = payloads.ProjectZomboid
        fixture = type(projectZomboid) == "table"
            and projectZomboid.itemTypeRegistry or nil
    end
    local chunkCount = fixture and tonumber(fixture.chunkCount) or nil
    local chunkIndex = fixture and tonumber(fixture.chunkIndex) or nil
    if chunkCount and chunkIndex then
        if chunkCount < 1 or chunkIndex < 1 or chunkIndex > chunkCount
            or type(fixture.types) ~= "table"
        then
            return existingCount
        end
        local chunks = context.Runtime.engineItemTypeFixtureChunks
        if not chunks or chunks.expected ~= chunkCount then
            chunks = { expected = chunkCount, values = {}, received = 0 }
            context.Runtime.engineItemTypeFixtureChunks = chunks
        end
        if not chunks.values[chunkIndex] then
            chunks.received = chunks.received + 1
        end
        chunks.values[chunkIndex] = fixture.types
        if chunks.received < chunks.expected then
            return existingCount
        end
        local assembled = {}
        for index = 1, chunks.expected do
            local chunk = chunks.values[index]
            if type(chunk) ~= "table" then
                return existingCount
            end
            for _, value in ipairs(chunk) do
                assembled[#assembled + 1] = value
            end
        end
        context.Runtime.engineItemTypeFixtureChunks = nil
        fixture = { types = assembled }
    end
    local types = fixture and fixture.types or nil
    local coreInventory = PsychopatzCore and PsychopatzCore.Inventory or nil
    local registry = coreInventory and coreInventory.ItemTypeRegistry or nil
    if type(types) ~= "table" or not registry
        or type(registry.load) ~= "function"
    then
        return existingCount
    end
    local persistedTypes = {}
    for index = 1, #types do
        persistedTypes[index] = types[index]
    end
    registry.load({
        schemaVersion = 1,
        revision = #persistedTypes,
        nextId = #persistedTypes + 1,
        types = persistedTypes,
    })
    context.Runtime.engineItemTypeFixtureCount = #persistedTypes
    return #persistedTypes
end

local function scenarioProjection(context, record, original)
    local Values = context.Values
    -- Keep the public scenario/UI view bounded. The complete hydrated record
    -- remains in Runtime.hydratedNpcRecord and the isolated production
    -- registry; copying it here would duplicate large persisted social and
    -- knowledge payloads into every Talk response.
    local projection = Values.copy(original or {})
    local identity = type(record.identity) == "table"
        and record.identity or {}
    local affiliation = type(record.affiliation) == "table"
        and record.affiliation or {}
    local hostility = type(record.hostility) == "table"
        and record.hostility or {}
    local orderSpec = type(record.orderSpec) == "table"
        and record.orderSpec or {}
    local playerKey = Internal.PlayerEntityKey(context)
    local forename, surname, displayName = Internal.NameParts(record)
    local owned = record.recruited == true
        or tostring(record.ownerPlayerKey or "") == playerKey
    local following = tostring(orderSpec.kind or "") == "follow"
        or tostring(hostility.mode or "") == "defend_owner"
    local hostile = hostility.attackPlayers == true
        or tostring(hostility.mode or "") == "hostile"
        or tostring(hostility.mode or "") == "aggressive"
        or tostring(hostility.mode or "") == "attack"
    local relationship = type(record.social) == "table"
        and type(record.social.relationships) == "table"
        and record.social.relationships[playerKey] or nil

    projection.npcID = tostring(record.id)
    projection.forename = forename
    projection.surname = surname
    projection.displayName = displayName
    projection.gender = identity.isFemale == true and "female"
        or identity.isFemale == false and "male" or "unknown"
    projection.identityState = displayName ~= "" and "known" or "unknown"
    projection.identitySeed = record.identitySeed
    projection.archetype = record.archetypeID
    projection.archetypeID = record.archetypeID
    projection.factionID = affiliation.factionID
    projection.communityID = affiliation.communityID
    projection.factionRole = affiliation.role
    projection.recruited = record.recruited == true
    projection.companion = owned
    projection.ownedByPlayer = owned
    projection.actorAuthority = {
        eligible = owned,
        companion = owned,
        owned = owned,
        status = owned and "eligible" or "not_owned",
        source = "PRODUCTION_RECORD",
    }
    projection.followState = {
        mode = following and "following" or "idle",
        source = "PRODUCTION_RECORD",
    }
    projection.activeBehavior = following and "following"
        or hostile and "hostile" or "idle"
    projection.hostility = Values.copy(hostility)
    projection.orderSpec = Values.copy(orderSpec)
    projection.affiliation = Values.copy(record.affiliation or {})
    projection.generation = Values.copy(record.generation or {})
    projection.isTrader = tostring(record.generation
        and record.generation.source or ""):lower() == "dynamic_trading"
        or tostring(affiliation.originArchetypeID or ""):lower() == "trader"
    projection.role = projection.isTrader and "trader" or nil
    projection.factionContext = Values.copy(
        context.Runtime.productionFactionContext
    )
    projection.traits = Values.copy(record.npcTraits or {})
    projection.social = nil
    projection.personality = Values.copy(
        record.social and record.social.personality or {}
    )
    projection.personalityOverride = type(projection.personality) == "table"
        and Internal.HasEntries(projection.personality) or false
    projection.personalityMode = projection.personalityOverride and "saved" or ""
    projection.relationship = Values.copy(relationship or {})
    projection.inventory = Values.copy(record.inventory or {})
    -- The production record's runtime table is mutable service state. The
    -- worker projection keeps only its existing engine/lease view so a
    -- refresh cannot leak service runtime into the immutable source baseline.
    projection.runtime = Values.copy(
        type(original) == "table" and original.runtime or {}
    )

    -- Needs/world values are engine fixtures. Preserve only that boundary
    -- from the pre-transport scenario; persistence-owned fields above come
    -- from the hydrated production record.
    if type(original) == "table" then
        projection.needs = Values.copy(original.needs)
    end
    return projection
end

    Internal.ProductionFactionContext = productionFactionContext
    Internal.ScenarioProjection = scenarioProjection
end

return install
