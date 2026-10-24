-- SAVE-backed boundary into the real Project Hoomans persistence owners.
--
-- This module does not deserialize or interpret Hoomans state itself.  It
-- only selects the already-transported raw record, calls the production
-- deserializer/hydrator, and installs the resulting record in the worker's
-- isolated registry.

local ProductionRehydration = {}

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

local function loadProductionOrganizations(context)
    local Values = context.Values
    local registries = rawRegistriesFor(context)
    local factions = registries.factions
    local communities = registries.communities
    local status = {
        schema = "semantic.production_faction_rehydration.v1",
        source = "ProjectHoomans.rawRegistries",
        status = "NO_REGISTRIES",
        factionRegistry = "MISSING",
        communityRegistry = "MISSING",
    }

    resetOrganizationState()
    if type(factions) == "table"
        and PNC.Factions
        and type(PNC.Factions.LoadRaw) == "function"
    then
        local ok, loaded, reason = pcall(
            PNC.Factions.LoadRaw,
            Values.productionCopy(factions)
        )
        if not ok or loaded ~= true then
            return nil, "faction_load_failed:" .. tostring(
                ok and reason or loaded
            )
        end
        status.factionRegistry = "HYDRATED"
        status.factionLoadOwner = "PNC.Factions.LoadRaw"
    elseif type(factions) == "table" then
        return nil, "production_faction_loader_unavailable"
    end

    if type(communities) == "table"
        and PNC.Communities
        and type(PNC.Communities.LoadRaw) == "function"
    then
        local ok, loaded, reason = pcall(
            PNC.Communities.LoadRaw,
            Values.productionCopy(communities)
        )
        if not ok or loaded ~= true then
            return nil, "community_load_failed:" .. tostring(
                ok and reason or loaded
            )
        end
        status.communityRegistry = "HYDRATED"
        status.communityLoadOwner = "PNC.Communities.LoadRaw"
    elseif type(communities) == "table" then
        return nil, "production_community_loader_unavailable"
    end

    if status.factionRegistry == "HYDRATED"
        or status.communityRegistry == "HYDRATED"
    then
        status.status = "HYDRATED"
    end
    return status
end

local function loadProductionPlayerCharacters(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local raw = rawPlayerRegistryFor(context)
    local status = {
        schema = "semantic.production_player_rehydration.v1",
        source = "ProjectHoomans.rawRegistries.playerCharacters",
        status = "MISSING",
        loadOwner = "PNC.PlayerCharacters.Load",
    }
    if not PNC or not PNC.PlayerCharacters
        or type(PNC.PlayerCharacters.Load) ~= "function"
    then
        return nil, "production_player_loader_unavailable"
    end

    -- ModData is the production persistence boundary.  This table belongs to
    -- the isolated worker runtime; it is never connected to the source save.
    Runtime.playerModData = {}
    local key = PNC.PlayerCharacterConstants
        and PNC.PlayerCharacterConstants.REGISTRY_MODDATA_KEY
        or "PNC_PlayerCharacters"
    Runtime.modData[key] = type(raw) == "table"
        and Values.productionCopy(raw) or nil
    PNC.PlayerCharacters.Loaded = false
    PNC.PlayerCharacters.Dirty = false
    if type(PNC.PlayerCharacters.ResetRuntimeBindings) == "function" then
        PNC.PlayerCharacters.ResetRuntimeBindings("harness_rehydration")
    end

    local ok = pcall(PNC.PlayerCharacters.Load)
    if not ok then
        return nil, "production_player_load_failed"
    end

    -- Older/compact saved registries may omit derived indexes.  Let the
    -- production normalizer repair that persisted shape after the real Load
    -- owner has inspected the raw ModData; Python never builds these indexes.
    local registry = PNC.PlayerCharacters.Registry
    local needsProductionNormalization = type(raw) == "table"
        and type(raw.byUUID) == "table"
        and (type(registry) ~= "table"
            or type(registry.byUUID) ~= "table"
            or not hasEntries(registry.byUUID))
    if needsProductionNormalization
        and type(PNC.PlayerCharacters.NormalizeRegistry) == "function"
    then
        local normalized = PNC.PlayerCharacters.NormalizeRegistry(
            Values.productionCopy(raw)
        )
        if type(normalized) ~= "table"
            or type(normalized.byUUID) ~= "table"
        then
            return nil, "production_player_normalization_failed"
        end
        PNC.PlayerCharacters.Registry = normalized
        PNC.PlayerCharacters.Loaded = true
        PNC.PlayerCharacters.Dirty = false
        if type(PNC.PlayerCharacters.ResetRuntimeBindings) == "function" then
            PNC.PlayerCharacters.ResetRuntimeBindings(
                "harness_rehydration_normalized"
            )
        end
        status.normalizer = "PNC.PlayerCharacters.NormalizeRegistry"
    end
    if type(raw) == "table" and type(raw.byUUID) == "table"
        and type(PNC.PlayerCharacters.Registry) == "table"
        and type(PNC.PlayerCharacters.Registry.byUUID) == "table"
        and hasEntries(PNC.PlayerCharacters.Registry.byUUID)
    then
        status.status = "HYDRATED"
        status.recordCount = countKeys(PNC.PlayerCharacters.Registry.byUUID)
    elseif type(raw) ~= "table" then
        status.status = "MISSING"
        status.missingClass = "LEGITIMATE_ABSENCE"
    else
        return nil, "production_player_registry_empty"
    end
    local productionPlayers = Runtime.productionPlayerCharactersService
    if context.player and productionPlayers
        and type(productionPlayers.GetEntityKey) == "function"
    then
        local entityKey, identityReason = productionPlayers.GetEntityKey(
            context.player,
            { callback = "semantic_lab_rehydration", worldAgeHours = Runtime.now }
        )
        status.entityKey = entityKey
        status.identityReason = identityReason
    end
    return status
end

local function productionFactionContext(context, record)
    local Values = context.Values
    local affiliation = type(record and record.affiliation) == "table"
        and record.affiliation or {}
    local npcFactionID = affiliation.factionID
    local playerKey = playerEntityKey(context)
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
        npcFaction = factionSummary(npcFaction),
        npcFactionReason = factionReason,
        playerDiplomacyFaction = factionSummary(playerFaction),
        playerDiplomacyFactionReason = playerReason,
        directedRelation = Values.copy(directedRelation),
        effective = effective,
        community = communitySummary(community),
        communityReason = communityReason,
        affiliation = Values.copy(affiliation),
    }
end

function ProductionRehydration.installEngineItemTypeFixture(context, fixture)
    local existingCount = tonumber(
        context.Runtime.engineItemTypeFixtureCount
    ) or 0
    if type(fixture) ~= "table" then
        local payloads = context.Runtime.sourceProviderPayloads or {}
        local projectZomboid = payloads.ProjectZomboid
        fixture = type(projectZomboid) == "table"
            and projectZomboid.itemTypeRegistry or nil
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
    local playerKey = playerEntityKey(context)
    local forename, surname, displayName = nameParts(record)
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
        and hasEntries(projection.personality) or false
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

function ProductionRehydration.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    if sourceKind(context) ~= "SAVE" then
        Runtime.hydratedNpcRecord = nil
        Runtime.productionPlayerRehydration = nil
        Runtime.productionFactionContext = nil
        Runtime.productionFactionRehydration = {
            schema = "semantic.production_faction_rehydration.v1",
            source = sourceKind(context),
            status = "NOT_APPLICABLE",
            mode = "developer_test",
        }
        resetOrganizationState()
        Runtime.productionRehydration = {
            schema = "semantic.production_rehydration.v1",
            source = sourceKind(context),
            status = "NOT_APPLICABLE",
            mode = "developer_test",
        }
        return true
    end

    local scenario = Runtime.scenario or {}
    local original = scenario.npc or {}
    local npcID = tostring(original.npcID or original.id
        or (Runtime.sourceMetadata or {}).npcID or "")
    if npcID == "" then return fail(context, "npc_id_missing") end
    local raw = rawRecordFor(context, npcID)
    if type(raw) ~= "table" then
        return fail(context, "raw_npc_record_missing")
    end
    local itemTypeFixtureCount = ProductionRehydration
        .installEngineItemTypeFixture(context)
    if not PNC or not PNC.Persistence
        or type(PNC.Persistence.DeserializeRecord) ~= "function"
    then
        return fail(context, "production_deserializer_unavailable")
    end
    if not PNC.Inventory
        or type(PNC.Inventory.EnsureRecordInventory) ~= "function"
    then
        return fail(context, "production_inventory_hydrator_unavailable")
    end

    local ok, record = pcall(
        PNC.Persistence.DeserializeRecord,
        Values.productionCopy(raw),
        npcID
    )
    if not ok or type(record) ~= "table"
        or tostring(record.id or "") ~= npcID
    then
        return fail(context, ok and "production_deserializer_rejected_record"
            or "production_deserializer_error:" .. tostring(record))
    end

    local hydratedOK, inventory = pcall(
        PNC.Inventory.EnsureRecordInventory,
        record
    )
    if not hydratedOK or type(inventory) ~= "table" then
        return fail(context, hydratedOK and "production_inventory_hydration_failed"
            or "production_inventory_hydration_error")
    end

    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Data = PNC.Registry.Data or {}
    -- Organization production loaders query the isolated registry while they
    -- normalize persisted faction/community references.  The semantic
    -- adapter later adds its conversation-specific lease seam on top.
    PNC.Registry.Get = function(id)
        return PNC.Registry.Data[tostring(id)]
            or PNC.Registry.Data[id]
    end
    PNC.Registry.Data[npcID] = record
    PNC.Registry.Loaded = true
    Runtime.hydratedNpcRecord = record
    local playerStatus, playerReason = loadProductionPlayerCharacters(context)
    if not playerStatus then
        return fail(context, "production_player_rehydration:" .. tostring(
            playerReason
        ))
    end
    Runtime.productionPlayerRehydration = playerStatus
    local organizationStatus, organizationReason =
        loadProductionOrganizations(context)
    if not organizationStatus then
        return fail(context, "production_faction_rehydration:" .. tostring(
            organizationReason
        ))
    end
    Runtime.productionFactionRehydration = organizationStatus
    Runtime.productionFactionContext = productionFactionContext(
        context,
        record
    )
    scenario.npc = scenarioProjection(context, record, original)
    Runtime.scenario = scenario
    Runtime.productionRehydration = {
        schema = "semantic.production_rehydration.v1",
        source = "SAVE",
        status = "HYDRATED",
        recordID = npcID,
        deserializer = "PNC.Persistence.DeserializeRecord",
        inventoryHydrator = "PNC.Inventory.EnsureRecordInventory",
        inventoryMode = record.inventoryPersistenceMode
            or inventory.persistenceMode or "SEED_ONLY",
        inventoryItemCount = countItems(inventory),
        inventoryRuntimeType = type(record.inventory),
        registry = "isolated PNC.Registry",
        sourceRecord = "ProjectHoomans.rawRecords.npc",
        playerRegistry = Values.copy(Runtime.productionPlayerRehydration),
        engineItemTypeFixtureCount = itemTypeFixtureCount > 0
            and itemTypeFixtureCount or nil,
    }
    return true
end

function ProductionRehydration.applyRuntimeRelationshipBaseline(
    context, payload
)
    local Runtime = context.Runtime
    local Values = context.Values
    if sourceKind(context) ~= "SAVE" then
        return nil, "runtime_relationship_override_requires_save"
    end
    payload = type(payload) == "table" and payload or {}
    local relationship = type(payload.relationship) == "table"
        and payload.relationship or payload
    local npcID = tostring(payload.npcID
        or context.npcData and (context.npcData.npcID or context.npcData.id)
        or "")
    if npcID == "" then return nil, "npc_id_missing" end
    local targetKey = Runtime.relationshipTargetKey
        or playerEntityKey(context)
    local setter = Runtime.productionRelationshipService
        and Runtime.productionRelationshipService.SetDebugBaseline
    if type(setter) ~= "function" then
        return nil, "production_relationship_baseline_unavailable"
    end
    local standing = {
        approval = Values.number(relationship.approval, 0),
        respect = Values.number(relationship.respect, 0),
        familiarity = Values.number(relationship.familiarity, 0),
    }
    local ok, result, reason = pcall(
        setter,
        npcID,
        targetKey,
        standing,
        tonumber(Runtime.now) or 0
    )
    if not ok or type(result) ~= "table" then
        return nil, ok and tostring(reason or "baseline_rejected")
            or "baseline_error:" .. tostring(result)
    end
    Runtime.runtimeRelationshipOverrides =
        Runtime.runtimeRelationshipOverrides or {}
    Runtime.runtimeRelationshipOverrides[npcID] = {
        source = "HARNESS_RUNTIME_OVERRIDE",
        owner = "PNC.Relationships.SetDebugBaseline",
        resettable = true,
        relationship = Values.copy(result),
    }
    ProductionRehydration.refreshProjection(context)
    if context.Conversation
        and type(context.Conversation.refreshViewContext) == "function"
    then
        context.Conversation.refreshViewContext(context)
    end
    local snapshot = context.ScenarioSession.snapshot(context)
    snapshot.runtimeRelationshipOverride = Values.copy(
        Runtime.runtimeRelationshipOverrides[npcID]
    )
    return snapshot
end

function ProductionRehydration.refreshProjection(context)
    if sourceKind(context) ~= "SAVE"
        or type(context.Runtime.hydratedNpcRecord) ~= "table"
    then
        return false
    end
    local Runtime = context.Runtime
    local scenario = Runtime.scenario or {}
    scenario.npc = scenarioProjection(
        context,
        Runtime.hydratedNpcRecord,
        scenario.npc or {}
    )
    Runtime.scenario = scenario
    context.npcData = scenario.npc
    Runtime.productionRehydration.inventoryRevision = type(
        Runtime.hydratedNpcRecord.inventory
    ) == "table" and Runtime.hydratedNpcRecord.inventory.revision or nil
    Runtime.productionRehydration.inventoryRuntimeType = type(
        Runtime.hydratedNpcRecord.inventory
    )
    Runtime.productionRehydration.inventoryItemCount = countItems(
        Runtime.hydratedNpcRecord.inventory
    )
    Runtime.productionRehydration.recordRecruited =
        Runtime.hydratedNpcRecord.recruited == true
    return true
end

return ProductionRehydration
