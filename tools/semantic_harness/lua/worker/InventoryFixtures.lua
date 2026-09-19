-- Scenario inventory shapes and native-like inventory boundary objects.

local InventoryFixtures = {}

local function normalizeInventory(context, inventory)
    local number = context.Values.number
    inventory = type(inventory) == "table" and inventory or {}
    local source = type(inventory.items) == "table" and inventory.items or {}
    local items = {}
    for key, item in pairs(source) do
        if type(item) == "table" then
            local itemID = tostring(item.itemID or item.id or key or "")
            if itemID ~= "" then
                item.id = itemID
                item.itemID = item.itemID or itemID
                item.type = item.type or item.fullType or ""
                item.fullType = item.fullType or item.type
                item.stack = math.max(1, math.floor(number(item.stack, 1)))
                items[itemID] = item
            end
        end
    end
    inventory.items = items
    inventory.containers = type(inventory.containers) == "table"
        and inventory.containers or {}
    inventory.revision = math.max(0, math.floor(number(inventory.revision, 1)))
    return inventory
end

function InventoryFixtures.inventoryIDs(inventory)
    local output = {}
    for itemID in pairs(inventory and inventory.items or {}) do
        output[#output + 1] = tostring(itemID)
    end
    table.sort(output)
    return output
end

local function nativeList(values)
    return {
        size = function() return #values end,
        get = function(_, index) return values[index + 1] end,
    }
end

local function nativeItem(spec)
    local item = {}
    item.getID = function() return spec.id end
    item.getFullType = function() return spec.fullType or spec.type end
    item.getType = function() return spec.fullType or spec.type end
    item.getDisplayName = function()
        return spec.displayName or spec.customName or spec.fullType or spec.type
    end
    item.getName = function() return spec.customName end
    item.isFavorite = function() return spec.favorite == true or spec.fav == true end
    item.isEquipped = function()
        return spec.equipped == true or spec.equipSlot ~= nil
    end
    item.getCondition = function() return spec.condition or spec.cond end
    item.getUsedDelta = function() return spec.usedDelta or spec.uses end
    item.getItemContainer = function()
        local contents = spec.contents or spec.items
        if type(contents) ~= "table" then return nil end
        local children = {}
        for key, child in pairs(contents) do
            if type(child) == "table" then
                child.id = child.id or child.itemID or tostring(key)
                child.fullType = child.fullType or child.type
                children[#children + 1] = nativeItem(child)
            end
        end
        table.sort(children, function(left, right)
            return tostring(left:getID()) < tostring(right:getID())
        end)
        return { getItems = function() return nativeList(children) end }
    end
    item.getInventory = item.getItemContainer
    return item
end

function InventoryFixtures.nativeInventory(inventory)
    return {
        getItems = function()
            local output = {}
            for _, itemID in ipairs(InventoryFixtures.inventoryIDs(inventory)) do
                output[#output + 1] = nativeItem(inventory.items[itemID])
            end
            return nativeList(output)
        end,
    }
end

local function scenarioItemByType(context, fullType)
    local scenario = context.Runtime.scenario or {}
    for _, ownerName in ipairs({ "player", "npc" }) do
        local owner = scenario[ownerName] or {}
        local inventory = owner.inventory or {}
        for _, item in pairs(inventory.items or {}) do
            if tostring(item.fullType or item.type or "") == tostring(fullType or "") then
                return item
            end
        end
    end
    return nil
end

local function marketSenseFor(context, fullType)
    local item = scenarioItemByType(context, fullType)
    local definition = item and (item.marketSense or item.classification) or nil
    return type(definition) == "table" and definition or nil
end

local function itemDisplayName(item)
    return tostring(item and (item.displayName or item.customName
        or item.fullType or item.type) or "item")
end

local function queueGiftResult(context, result, itemTypes)
    local Runtime = context.Runtime
    local first = itemTypes and itemTypes[1] or "item"
    local display = tostring(first or "item")
    local source = context.npcInventory.items
    for _, item in pairs(source or {}) do
        if tostring(item.fullType or item.type or "") == display then
            display = itemDisplayName(item)
            break
        end
    end
    local payload = {
        key = "semantic.gift.received",
        text = "Thank you for the " .. display .. ".",
        fallback = "Thank you for the " .. display .. ".",
        args = { giftItemName = display },
    }
    Runtime.queued[#Runtime.queued + 1] = {
        speaker = "npc",
        payload = payload,
        metadata = {
            source = { kind = "semantic", channel = "gift_result" },
            provenance = {
                provider = "mock_authoritative_inventory",
                parser = "production_gift_selection",
            },
        },
    }
    Runtime.transcript[#Runtime.transcript + 1] = Runtime.queued[#Runtime.queued]
    return result
end

local function configureMarketSense(context)
    MarketSense = {
        GetTags = function(fullType)
            local details = marketSenseFor(context, fullType) or {}
            return {
                primary = details.primary,
                category = details.category,
                tags = context.Values.copy(details.tags),
                expandedTags = context.Values.copy(details.expandedTags),
                themes = context.Values.copy(details.themes),
            }
        end,
        GetPriceDetails = function(fullType)
            local details = marketSenseFor(context, fullType)
            return details and context.Values.copy(details) or nil
        end,
        GetPriceDetailsForInstance = function(fullType)
            local details = marketSenseFor(context, fullType)
            return details and context.Values.copy(details) or nil
        end,
        GetItemCapabilities = function(fullType)
            local details = marketSenseFor(context, fullType) or {}
            return { capabilities = context.Values.copy(details.capabilities) or {} }
        end,
    }
end

local function configureInventoryTransfer(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local number = Values.number
    local playerData = context.playerData
    local npcData = context.npcData
    local runtime = context.runtime
    local playerInventory = context.playerInventory
    local npcInventory = context.npcInventory

    PNC.Client.RequestSemanticInventoryQuery = function(request, _)
        request = type(request) == "table" and request or {}
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "SemanticInventoryQuery",
            payload = Values.copy(request),
        }
        local service = PNC.Semantics
            and PNC.Semantics.InventoryQueryService or nil
        local result = service and type(service.HandleRequest) == "function"
            and service.HandleRequest(request, {
                internal = true,
                npcID = request.npcID,
                player = context.player,
            }) or {
                accepted = false,
                status = "failed",
                reason = "inventory_service_unavailable",
                requestID = request.requestID,
                npcID = request.npcID,
                query = Values.copy(request.query),
                items = {},
                totalCount = 0,
                distinctItems = 0,
            }
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = runtime.mode,
            command = "SemanticInventoryQueryResult",
            payload = Values.copy(result),
        }
        return result.accepted == true, result.reason, result
    end

    PNC.Client.SendInventoryTransfer = function(args)
        args = type(args) == "table" and args or {}
        local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or {}
        local requested = args.quantity ~= nil
            and math.max(1, math.floor(number(args.quantity, 1))) or nil
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "client_to_server",
            mode = runtime.mode,
            command = "InventoryTransfer",
            payload = Values.copy(args),
        }
        if tostring(args.direction or "") ~= "player_to_npc"
            or tostring(args.id or "") ~= tostring(npcData.npcID or "")
        then
            return false, "invalid_direction"
        end
        local moved = 0
        local remaining = requested
        local itemTypes = {}
        local newItemIDs = {}
        for index = 1, #itemIDs do
            local sourceID = tostring(itemIDs[index] or "")
            local sourceItem = playerInventory.items[sourceID]
            if not sourceItem then return false, "item_not_found" end
            local available = math.max(1, math.floor(number(sourceItem.stack, 1)))
            local amount = remaining and math.min(available, remaining) or available
            if amount > 0 then
                local newID = "npc_gift_" .. tostring(Runtime.turn)
                    .. "_" .. tostring(index)
                local gifted = Values.copy(sourceItem)
                gifted.id = newID
                gifted.itemID = newID
                gifted.stack = amount
                gifted.container = args.npcContainer or "root"
                npcInventory.items[newID] = gifted
                itemTypes[#itemTypes + 1] = gifted.fullType or gifted.type
                newItemIDs[#newItemIDs + 1] = newID
                moved = moved + amount
                available = available - amount
                if available > 0 then
                    sourceItem.stack = available
                else
                    playerInventory.items[sourceID] = nil
                end
                if remaining then
                    remaining = remaining - amount
                    if remaining <= 0 then break end
                end
            end
        end
        if moved < 1 or (remaining and remaining > 0) then
            return false, "quantity_unavailable"
        end
        playerInventory.revision = playerInventory.revision + 1
        npcInventory.revision = npcInventory.revision + 1
        local effect = PNC.Gifts and PNC.Gifts.EvaluateEffect
            and PNC.Gifts.EvaluateEffect(itemTypes) or {
                approval = 0, respect = 0, familiarity = 0,
            }
        local before = context.SemanticAdapters.relationshipSnapshotFor(
            context, npcData.npcID
        )
        local applied, applyReason, relationshipResult =
            PNC.Relationships.ApplyConversationEffect(
                npcData.npcID,
                "player:" .. tostring(playerData.characterUUID),
                effect,
                { eventID = "gift:" .. tostring(Runtime.turn) }
            )
        local after = context.SemanticAdapters.relationshipSnapshotFor(
            context, npcData.npcID
        )
        local details = {
            itemTypes = itemTypes,
            itemIDs = newItemIDs,
            itemCount = moved,
            giftEffect = effect,
            relationshipBefore = before,
            relationshipAfter = after,
            relationshipDelta = {
                approval = after.approval - before.approval,
                respect = after.respect - before.respect,
                familiarity = after.familiarity - before.familiarity,
            },
            eventID = relationshipResult and relationshipResult.eventID
                or "gift:" .. tostring(Runtime.turn),
            applied = applied == true,
            applyReason = applyReason,
            giftReplyKey = "gift.received." .. tostring(effect.kind or "general"),
        }
        local result = {
            success = true,
            reason = "transferred_to_npc",
            npcId = npcData.npcID,
            requestId = args.requestId,
            gift = args.gift == true,
        }
        for key, value in pairs(details) do result[key] = Values.copy(value) end
        Runtime.transport[#Runtime.transport + 1] = {
            direction = "server_to_client",
            mode = runtime.mode,
            command = "InventoryResult",
            payload = Values.copy(result),
        }
        local payload = args.gift == true and queueGiftResult(context, result, itemTypes)
            or result
        if PNC.Network.ClientState.characterPayloads then
            PNC.Network.ClientState.characterPayloads[npcData.npcID] = {
                inventory = { revision = npcInventory.revision },
            }
        end
        return true, "transferred_to_npc", payload
    end
end

function InventoryFixtures.configure(context)
    local scenario = context.Runtime.scenario or {}
    local playerData = scenario.player or {}
    local npcData = scenario.npc or {}
    context.playerData = playerData
    context.npcData = npcData
    context.playerInventory = normalizeInventory(context, playerData.inventory)
    context.npcInventory = normalizeInventory(context, npcData.inventory)

    configureMarketSense(context)
    PNC.Inventory = PNC.Inventory or {}
    PNC.Inventory.EnsureRecordInventory = function(record)
        return normalizeInventory(context, record and record.inventory)
    end
    PNC.Client = PNC.Client or {}
    configureInventoryTransfer(context)
end

return InventoryFixtures
