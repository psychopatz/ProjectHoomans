-- Rehydration configuration, diagnostics, and runtime projection refresh.

local function install(ProductionRehydration)
    local Internal = ProductionRehydration.Internal
    local Configuration = require "worker/ProductionRehydration_Configure"

function ProductionRehydration.configure(context)
    return Configuration.run(context, {
        sourceKind = Internal.SourceKind,
        fail = Internal.Fail,
        rawRecordFor = Internal.RawRecordFor,
        countItems = Internal.CountItems,
        resetOrganizationState = Internal.ResetOrganizationState,
        installEngineItemTypeFixture =
            ProductionRehydration.installEngineItemTypeFixture,
        loadProductionPlayerCharacters = Internal.LoadProductionPlayerCharacters,
        loadProductionKnowledge = Internal.LoadProductionKnowledge,
        loadProductionOrganizations = Internal.LoadProductionOrganizations,
        productionFactionContext = Internal.ProductionFactionContext,
        scenarioProjection = Internal.ScenarioProjection,
    })
end

function ProductionRehydration.refreshDiagnostics(context)
    local Runtime = context.Runtime
    local Values = context.Values
    if Internal.SourceKind(context) ~= "SAVE" then
        return false
    end

    local scenario = Runtime.scenario or {}
    local npc = scenario.npc or {}
    local npcID = tostring(npc.npcID or npc.id or "")
    if npcID == "" or not context.player then
        return false
    end

    local knowledge = PNC and PNC.NPCKnowledge or nil
    local dossier = nil
    local dossierReason = "production_knowledge_snapshot_unavailable"
    if knowledge
        and type(knowledge.BuildPlayerSnapshotForPlayer) == "function"
    then
        local ok, snapshot, reason = pcall(
            knowledge.BuildPlayerSnapshotForPlayer,
            context.player,
            npcID
        )
        if ok and type(snapshot) == "table" then
            dossier = snapshot
            dossierReason = nil
        elseif not ok then
            dossierReason = tostring(snapshot)
        else
            dossierReason = tostring(reason or dossierReason)
        end
    end
    Runtime.productionNpcDossier = {
        schema = "semantic.production_npc_dossier.v1",
        source = "PRODUCTION",
        status = dossier and "HYDRATED" or "UNAVAILABLE",
        npcID = npcID,
        playerUUID = (Runtime.sourceMetadata or {}).playerUUID,
        owner = "PNC.NPCKnowledge.BuildPlayerSnapshotForPlayer",
        rehydration = Values.copy(Runtime.productionKnowledgeRehydration),
        snapshot = Values.copy(dossier),
        reason = dossierReason,
    }

    local debug = PNC and PNC.RelationshipDebug or nil
    local history = nil
    local historyReason = "production_relationship_debug_unavailable"
    if debug and type(debug.BuildSnapshotForRequest) == "function" then
        local ok, snapshot, reason = pcall(
            debug.BuildSnapshotForRequest,
            context.player,
            {
                observerNPCID = npcID,
                targetKind = "current_player",
            },
            Runtime.lastSemanticActionResult
        )
        if ok and type(snapshot) == "table" then
            history = snapshot
            historyReason = nil
        elseif not ok then
            historyReason = tostring(snapshot)
        else
            historyReason = tostring(reason or historyReason)
        end
    end
    Runtime.productionRelationshipHistory = {
        schema = "semantic.production_relationship_history.v1",
        source = "PRODUCTION",
        status = history and "HYDRATED" or "UNAVAILABLE",
        npcID = npcID,
        playerKey = Runtime.relationshipTargetKey,
        owner = "PNC.RelationshipDebug.BuildSnapshotForRequest",
        snapshot = Values.copy(history),
        reason = historyReason,
    }
    return dossier ~= nil or history ~= nil
end

function ProductionRehydration.applyRuntimeRelationshipBaseline(
    context, payload
)
    local Runtime = context.Runtime
    local Values = context.Values
    if Internal.SourceKind(context) ~= "SAVE" then
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
        or Internal.PlayerEntityKey(context)
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
    if Internal.SourceKind(context) ~= "SAVE"
        or type(context.Runtime.hydratedNpcRecord) ~= "table"
    then
        return false
    end
    local Runtime = context.Runtime
    local scenario = Runtime.scenario or {}
    Runtime.productionFactionContext = Internal.ProductionFactionContext(
        context,
        Runtime.hydratedNpcRecord
    )
    scenario.npc = Internal.ScenarioProjection(
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
    Runtime.productionRehydration.inventoryItemCount = Internal.CountItems(
        Runtime.hydratedNpcRecord.inventory
    )
    Runtime.productionRehydration.recordRecruited =
        Runtime.hydratedNpcRecord.recruited == true
    return true
end

end

return install
