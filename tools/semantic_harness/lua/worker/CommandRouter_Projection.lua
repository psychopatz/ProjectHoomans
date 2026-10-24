-- Bounded actor and production-fixture projections for the semantic worker router.

local Projection = {}

local function productionInventoryFixture(context, payload)
    local Runtime = context.Runtime
    local Values = context.Values
    local sourceKind = tostring(
        Runtime.sourceMetadata and Runtime.sourceMetadata.sourceKind or "FIXTURE"
    )
    if sourceKind ~= "FIXTURE" then
        return nil, "production_inventory_fixture_requires_fixture_mode"
    end
    payload = type(payload) == "table" and payload or {}
    local mode = tostring(payload.mode or "")
    if mode ~= "SEED_ONLY"
        and mode ~= "BASELINE_DELTA"
        and mode ~= "FULL"
    then
        return nil, "production_inventory_fixture_mode_invalid"
    end
    if not PNC.Persistence
        or type(PNC.Persistence.DeserializeRecord) ~= "function"
        or not PNC.Inventory
        or type(PNC.Inventory.EnsureRecordInventory) ~= "function"
        or type(PNC.Persistence.SerializeRecord) ~= "function"
    then
        return nil, "production_inventory_fixture_owner_unavailable"
    end
    -- The normal developer fixture path intentionally installs its explicit
    -- fixture inventory owner.  This test command switches back to the
    -- captured production owner before generating a persisted record.
    if context.InventoryFixtures
        and type(context.InventoryFixtures.restoreProduction) == "function"
    then
        local metadata = Runtime.sourceMetadata or {}
        local previousSourceKind = metadata.sourceKind
        metadata.sourceKind = "SAVE"
        Runtime.sourceMetadata = metadata
        context.InventoryFixtures.restoreProduction(context)
        metadata.sourceKind = previousSourceKind
    end

    local ok, result = pcall(function()
        local npcID = "npcP14B_" .. string.lower(mode)
        local raw = {
            schemaVersion = PNC.Const and PNC.Const.PERSISTENCE_VERSION or 16,
            recordRevision = 1,
            id = npcID,
            tacticalClass = "neutral",
            persist = true,
            identity = {
                displayName = "P14B " .. mode,
                isFemale = false,
                archetypeID = "General",
                seed = 1402,
                survivor = {
                    forename = "P14B",
                    surname = mode,
                },
            },
            hostility = { mode = "neutral", attackPlayers = false },
        }
        local record = PNC.Persistence.DeserializeRecord(raw, npcID)
        if type(record) ~= "table" then
            error("production_deserializer_rejected_fixture")
        end
        local inventory = PNC.Inventory.EnsureRecordInventory(record)
        if type(inventory) ~= "table" then
            error("production_inventory_hydrator_rejected_fixture")
        end
        local markerType
        local markerID
        if mode == "BASELINE_DELTA" then
            markerType = "Base.Bandage"
            markerID = "p14b_baseline_delta_item"
        elseif mode == "FULL" then
            markerType = "Base.HuntingKnife"
            markerID = "p14b_full_item"
        end
        if markerType then
            local added = PNC.Inventory.AddItems(
                record,
                {{
                    id = markerID,
                    type = markerType,
                    stack = mode == "BASELINE_DELTA" and 3 or 1,
                }},
                "root",
                "p14b_production_fixture"
            )
            if added ~= true then error("production_inventory_fixture_add_failed") end
        end
        if mode == "FULL" then
            record.inventoryPersistenceMode = "FULL"
        end
        local serialized = PNC.Persistence.SerializeRecord(record)
        if type(serialized) ~= "table"
            or type(serialized.inventory) ~= "table"
        then
            error("production_inventory_fixture_not_serialized:" .. tostring(
                type(serialized)
            ) .. ":" .. tostring(serialized and serialized.id))
        end
        local roundTrip = PNC.Persistence.DeserializeRecord(serialized, npcID)
        local roundTripInventory = roundTrip
            and PNC.Inventory.EnsureRecordInventory(roundTrip) or nil
        return {
            ok = true,
            type = "production_inventory_fixture",
            mode = serialized.inventory[2],
            record = Values.productionCopy(serialized),
            runtimeItemCount = (function()
                local count = 0
                for _ in pairs(record.inventory and record.inventory.items or {}) do
                    count = count + 1
                end
                return count
            end)(),
            markerID = markerID,
            markerType = markerType,
            roundTripMode = roundTrip
                and (roundTrip.inventoryPersistenceMode
                    or roundTripInventory and roundTripInventory.persistenceMode)
                or nil,
            roundTripItemCount = roundTripInventory
                and (function()
                    local count = 0
                    for _ in pairs(roundTripInventory.items or {}) do
                        count = count + 1
                    end
                    return count
                end)()
                or 0,
        }
    end)
    if not ok then
        return nil, "production_inventory_fixture_error:" .. tostring(result)
    end
    return result
end

local function boundedInventory(context, inventory)
    local source = type(inventory) == "table" and inventory or {}
    local output = {
        revision = source.revision,
        items = {},
    }
    local itemIDs = {}
    for itemID in pairs(type(source.items) == "table" and source.items or {}) do
        itemIDs[#itemIDs + 1] = tostring(itemID)
    end
    table.sort(itemIDs)
    for index = 1, math.min(#itemIDs, 512) do
        local itemID = itemIDs[index]
        local item = source.items[itemID]
        if type(item) == "table" then
            output.items[itemID] = {
                id = item.id or itemID,
                itemID = item.itemID or itemID,
                type = item.type,
                fullType = item.fullType,
                displayName = item.displayName or item.customName,
                stack = item.stack or item.quantity or item.count,
                container = item.container,
                equipped = item.equipped,
                equipSlot = item.equipSlot,
                condition = item.condition or item.cond,
                uses = item.uses,
            }
        end
    end
    return output
end

local function boundedRelationship(context)
    local scenario = context.Runtime.scenario or {}
    local npc = scenario.npc or {}
    local snapshot = context.SemanticAdapters
        and type(context.SemanticAdapters.relationshipSnapshotFor) == "function"
        and context.SemanticAdapters.relationshipSnapshotFor(
            context, npc.npcID or npc.id
        ) or npc.relationship
    local relationship = type(snapshot) == "table" and snapshot or {}
    local output = {}
    for _, key in ipairs({
        "baselineApproval", "baselineRespect", "approval", "respect",
        "familiarity", "state", "previousState", "revision",
        "interactionRevision", "lastInteractionAt", "memoryCount",
        "saturation", "cooldownUntil",
    }) do
        output[key] = relationship[key]
    end
    output.bond = context.Values.copy(relationship.bond)
    return output
end

local function actorStateProjection(context)
    local scenario = context.Runtime.scenario or {}
    local player = scenario.player or {}
    local npc = scenario.npc or {}
    local conversationSnapshot = context.Conversation
        and context.Conversation.contextSnapshot
        and context.Conversation.contextSnapshot(
            context,
            context.Runtime.view
        ) or {}
    local socialContext = type(conversationSnapshot.socialContext) == "table"
        and context.Values.copy(conversationSnapshot.socialContext)
        or nil
    local actorConversationContext = type(
        conversationSnapshot.actorConversationContext
    ) == "table" and context.Values.copy(
        conversationSnapshot.actorConversationContext
    ) or nil
    local speechStyleContext = type(conversationSnapshot.speechStyleContext)
        == "table" and context.Values.copy(
            conversationSnapshot.speechStyleContext
        ) or nil
    local function traits(value)
        local output = {}
        if type(value) ~= "table" then return output end
        for index = 1, math.min(#value, 64) do
            output[#output + 1] = value[index]
        end
        return output
    end
    return {
        ok = true,
        type = "actor_state",
        scenario = {
            player = {
                characterUUID = player.characterUUID,
                displayName = player.displayName,
                accountKey = player.accountKey,
                entityKey = player.entityKey,
                gender = player.gender,
                traits = traits(player.traits),
                inventory = boundedInventory(context, context.playerInventory
                    or player.inventory),
            },
            npc = {
                npcID = npc.npcID or npc.id,
                displayName = npc.displayName,
                gender = npc.gender,
                identityState = npc.identityState,
                recruited = npc.recruited,
                companion = npc.companion,
                ownedByPlayer = npc.ownedByPlayer,
                factionID = npc.factionID,
                communityID = npc.communityID,
                role = npc.role,
                isTrader = npc.isTrader,
                isHostile = npc.isHostile,
                activeBehavior = npc.activeBehavior,
                traits = traits(npc.traits),
                inventory = boundedInventory(context, context.npcInventory
                    or npc.inventory),
                relationship = boundedRelationship(context),
                socialContext = socialContext,
                actorConversationContext = actorConversationContext,
                speechStyleContext = speechStyleContext,
            },
        },
        productionKnowledgeRehydration = context.Values.copy(
            context.Runtime.productionKnowledgeRehydration
        ),
    }
end


Projection.productionInventoryFixture = productionInventoryFixture
Projection.actorStateProjection = actorStateProjection

function Projection.handle(context, command, payload)
    local Runtime = context.Runtime
    local Values = context.Values

    if command == "TEST_PRODUCTION_INVENTORY_FIXTURE" then
        return productionInventoryFixture(context, payload)
    elseif command == "INSTALL_ENGINE_ITEM_TYPES" then
        if not context.ProductionRehydration
            or type(context.ProductionRehydration
                .installEngineItemTypeFixture) ~= "function"
        then
            return nil, "engine_item_type_fixture_unavailable"
        end
        local count = context.ProductionRehydration
            .installEngineItemTypeFixture(context, payload)
        return {
            ok = true,
            type = "engine_item_type_fixture",
            count = count,
        }
    elseif command == "INSPECT_ACTOR_STATE" then
        return actorStateProjection(context)
    elseif command == "INSPECT_NPC_DOSSIER" then
        if context.ProductionRehydration
            and type(context.ProductionRehydration.refreshDiagnostics)
                == "function"
        then
            context.ProductionRehydration.refreshDiagnostics(context)
        end
        return {
            ok = true,
            type = "npc_dossier",
            npcDossier = context.Values.copy(
                context.Runtime.productionNpcDossier
            ),
            relationshipHistory = context.Values.copy(
                context.Runtime.productionRelationshipHistory
            ),
            productionKnowledgeRehydration = context.Values.copy(
                context.Runtime.productionKnowledgeRehydration
            ),
        }
    end
    return false
end

return Projection
