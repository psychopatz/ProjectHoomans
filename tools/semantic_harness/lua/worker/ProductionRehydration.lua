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
        Values.copy(raw),
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
    PNC.Registry.Data[npcID] = record
    PNC.Registry.Loaded = true
    Runtime.hydratedNpcRecord = record
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
    }
    return true
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
