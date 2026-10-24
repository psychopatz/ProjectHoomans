-- Configuration paths for fixture and SAVE-backed production rehydration.

local Configuration = {}

local function configureDeveloperRuntime(context, helpers, source)
    local Runtime = context.Runtime
    Runtime.hydratedNpcRecord = nil
    Runtime.productionPlayerRehydration = nil
    Runtime.productionKnowledgeRehydration = nil
    Runtime.modData = Runtime.modData or {}
    Runtime.modData.PNC_NPCKnowledge = nil
    if PNC and PNC.NPCKnowledge then
        PNC.NPCKnowledge.Registry = nil
        PNC.NPCKnowledge.Loaded = false
        PNC.NPCKnowledge.Dirty = false
    end
    Runtime.productionNpcDossier = {
        schema = "semantic.production_npc_dossier.v1",
        source = source,
        status = "NOT_APPLICABLE",
        mode = "developer_test",
    }
    Runtime.productionRelationshipHistory = {
        schema = "semantic.production_relationship_history.v1",
        source = source,
        status = "NOT_APPLICABLE",
        mode = "developer_test",
    }
    Runtime.productionFactionContext = nil
    Runtime.productionFactionRehydration = {
        schema = "semantic.production_faction_rehydration.v1",
        source = source,
        status = "NOT_APPLICABLE",
        mode = "developer_test",
    }
    helpers.resetOrganizationState()
    Runtime.productionRehydration = {
        schema = "semantic.production_rehydration.v1",
        source = source,
        status = "NOT_APPLICABLE",
        mode = "developer_test",
    }
    return true
end

local function configureSaveRuntime(context, helpers)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local original = scenario.npc or {}
    local npcID = tostring(original.npcID or original.id
        or (Runtime.sourceMetadata or {}).npcID or "")
    if npcID == "" then return helpers.fail(context, "npc_id_missing") end
    local raw = helpers.rawRecordFor(context, npcID)
    if type(raw) ~= "table" then
        return helpers.fail(context, "raw_npc_record_missing")
    end
    local itemTypeFixtureCount = helpers.installEngineItemTypeFixture(context)
    if not PNC or not PNC.Persistence
        or type(PNC.Persistence.DeserializeRecord) ~= "function"
    then
        return helpers.fail(context, "production_deserializer_unavailable")
    end
    if not PNC.Inventory
        or type(PNC.Inventory.EnsureRecordInventory) ~= "function"
    then
        return helpers.fail(context, "production_inventory_hydrator_unavailable")
    end

    local ok, record = pcall(
        PNC.Persistence.DeserializeRecord,
        Values.productionCopy(raw),
        npcID
    )
    if not ok or type(record) ~= "table"
        or tostring(record.id or "") ~= npcID
    then
        return helpers.fail(context,
            ok and "production_deserializer_rejected_record"
                or "production_deserializer_error:" .. tostring(record))
    end

    local hydratedOK, inventory = pcall(
        PNC.Inventory.EnsureRecordInventory,
        record
    )
    if not hydratedOK or type(inventory) ~= "table" then
        return helpers.fail(context,
            hydratedOK and "production_inventory_hydration_failed"
                or "production_inventory_hydration_error")
    end

    PNC.Registry = PNC.Registry or {}
    PNC.Registry.Data = PNC.Registry.Data or {}
    -- Organization production loaders query the isolated registry while they
    -- normalize persisted faction/community references. The semantic adapter
    -- later adds its conversation-specific lease seam on top.
    PNC.Registry.Get = function(id)
        return PNC.Registry.Data[tostring(id)]
            or PNC.Registry.Data[id]
    end
    PNC.Registry.Data[npcID] = record
    PNC.Registry.Loaded = true
    Runtime.hydratedNpcRecord = record

    local playerStatus, playerReason =
        helpers.loadProductionPlayerCharacters(context)
    if not playerStatus then
        return helpers.fail(context, "production_player_rehydration:"
            .. tostring(playerReason))
    end
    Runtime.productionPlayerRehydration = playerStatus

    local knowledgeStatus, knowledgeReason =
        helpers.loadProductionKnowledge(context)
    if not knowledgeStatus then
        return helpers.fail(context, "production_knowledge_rehydration:"
            .. tostring(knowledgeReason))
    end
    Runtime.productionKnowledgeRehydration = knowledgeStatus

    local organizationStatus, organizationReason =
        helpers.loadProductionOrganizations(context)
    if not organizationStatus then
        return helpers.fail(context, "production_faction_rehydration:"
            .. tostring(organizationReason))
    end
    Runtime.productionFactionRehydration = organizationStatus
    Runtime.productionFactionContext = helpers.productionFactionContext(
        context,
        record
    )
    scenario.npc = helpers.scenarioProjection(context, record, original)
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
        inventoryItemCount = helpers.countItems(inventory),
        inventoryRuntimeType = type(record.inventory),
        registry = "isolated PNC.Registry",
        sourceRecord = "ProjectHoomans.rawRecords.npc",
        playerRegistry = Values.copy(Runtime.productionPlayerRehydration),
        knowledgeRegistry = Values.copy(Runtime.productionKnowledgeRehydration),
        engineItemTypeFixtureCount = itemTypeFixtureCount > 0
            and itemTypeFixtureCount or nil,
    }
    return true
end

function Configuration.run(context, helpers)
    local source = helpers.sourceKind(context)
    if source ~= "SAVE" then
        return configureDeveloperRuntime(context, helpers, source)
    end
    return configureSaveRuntime(context, helpers)
end

return Configuration
