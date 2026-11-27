if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Provider = PNC.Semantics.ActionPlanItemProvider
local Selector = Provider.ItemSelector

local function number(value)
    return tonumber(value)
end

local function find(record, step)
    if not Selector or type(Selector.Find) ~= "function" then
        return nil, "item_selector_unavailable"
    end
    return Selector.Find(record, Provider.ItemRequest(step), {
        maxItems = 256,
    })
end

local function runtime(plan)
    local service = Provider.Service
    if not service or type(service.GetRuntimeContext) ~= "function" then
        return nil
    end
    return service.GetRuntimeContext(plan.planID)
end

local function inventoryRevision(record)
    local inventory = Provider.Inventory
    if not inventory or type(inventory.EnsureRecordInventory) ~= "function" then
        return nil, "inventory_service_unavailable"
    end
    local state = inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    if type(state) ~= "table" then return nil, "inventory_unavailable" end
    return state, number(state.revision) or 0
end

function Provider.Give.Resolve(_, step, record)
    -- Resolve at the final step, not when the request is first admitted. The
    -- inventory may have changed while the NPC was walking.
    local selection, reason = find(record, step)
    if not selection then return nil, reason end
    return selection
end

function Provider.Give.Start(plan, step, record)
    local context = runtime(plan)
    local player = context and context.player
    local token = context and context.conversationToken
    local inventory
    local revision
    local selection
    local reason
    local service = Provider.ServerInventory
    if not player then return { blocked = true, reason = "player_unavailable" } end
    if tostring(token or "") == "" then
        return { blocked = true, reason = "conversation_lease_required" }
    end

    -- Re-select immediately before transfer so a stale assignment cannot
    -- move a different or no-longer-available item.
    selection, reason = find(record, step)
    if not selection then return { blocked = true, reason = reason } end
    inventory, revision = inventoryRevision(record)
    if not inventory then return { blocked = true, reason = revision } end
    if not service or type(service.SemanticTransferNPCToPlayer)
        ~= "function"
    then
        return { blocked = true, reason = "semantic_inventory_transfer_unavailable" }
    end

    local transferred, transferReason = service.SemanticTransferNPCToPlayer(
        player,
        record,
        {
            direction = "npc_to_player",
            itemIDs = { selection.itemID },
            quantity = selection.quantity,
            inventoryRevision = revision,
            playerContainer = context.playerContainer or "root",
            conversationToken = token,
            requestId = plan.requestID,
        }
    )
    if transferred ~= true then
        return { blocked = true, reason = transferReason or "item_transfer_failed" }
    end

    -- Play the 1-handed handover animation with the actual item prop visible
    -- in the NPC's hand (via ActionProps -> ClientActionProps).
    local reg = PNC and PNC.Registry or nil
    local scenes = PNC and PNC.AnimationScenes or nil
    local body = reg and type(reg.GetLiveZombie) == "function"
        and reg.GetLiveZombie(record.id) or nil
    if body and player and type(body.faceThisObject) == "function" then
        pcall(body.faceThisObject, body, player)
    elseif body and player and type(body.faceLocation) == "function"
        and type(player.getX) == "function" and type(player.getY) == "function"
    then
        pcall(body.faceLocation, body, player:getX(), player:getY())
    end
    if scenes and type(scenes.Request) == "function" and selection.fullType then
        pcall(scenes.Request, record, body, "social.item_share_give", {
            reason = "semantic_give_item",
            propPrimary = selection.fullType,
        })
    elseif selection.fullType then
        record.runtime = record.runtime or {}
        record.runtime.sceneActionProps = { primary = selection.fullType }
    end

    return { complete = true, result = {
        itemID = selection.itemID,
        fullType = selection.fullType,
        quantity = selection.quantity,
    } }
end

function Provider.Give.Tick(plan, step, record)
    return Provider.Give.Start(plan, step, record)
end

return Provider.Give
