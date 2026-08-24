if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local CoreInventory = Internal.CoreInventory
local C = Internal.Constants
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"

function Internal.PlayerName(player)
    return player and player.getUsername
        and tostring(player:getUsername() or "") or ""
end

function Internal.NativeItemSpecs(items)
    local output = {}
    for _, item in ipairs(items or {}) do
        output[#output + 1] = {
            fullType = item and item.getFullType and item:getFullType() or nil,
            quantity = 1,
        }
    end
    return output
end

function Internal.StorageSelectionSpecs(storage, selections)
    local output = {}
    for _, selection in ipairs(selections or {}) do
        local record = storage and storage.inventory
            and storage.inventory.records[tonumber(selection.recordIndex) or 0]
        if record then
            output[#output + 1] = {
                typeId = record[C.TYPE_ID],
                quantity = math.max(1,
                    math.floor(tonumber(selection.quantity) or 1)),
            }
        end
    end
    return output
end

function Internal.RecordActivity(storage, operation, actor, items, reason)
    local eventType = string.upper(tostring(operation or "")) == "TAKE"
        and EventTypes.STORAGE_ITEM_WITHDRAWN
        or string.upper(tostring(operation or "")) == "STORE"
            and EventTypes.STORAGE_ITEM_DEPOSITED or nil
    if not eventType or not storage then return 0 end
    local grouped = {}
    local order = {}
    for _, item in ipairs(type(items) == "table" and items or {}) do
        local typeID = math.floor(tonumber(item and item.typeId) or 0)
        if typeID <= 0 then
            typeID = CoreInventory.getItemTypeId(item and item.fullType, false)
        end
        local quantity = math.max(0,
            math.floor(tonumber(item and item.quantity) or 0))
        if typeID and typeID > 0 and quantity > 0 then
            if not grouped[typeID] then
                grouped[typeID] = 0
                order[#order + 1] = typeID
            end
            grouped[typeID] = grouped[typeID] + quantity
        end
    end
    for _, typeID in ipairs(order) do
        Events.emit(eventType, storage.id, actor, typeID,
            grouped[typeID], reason)
    end
    return #order
end

function Internal.LogTransaction(player, args, action, ok, reason, storage,
    details)
    if not args or args.transactionLogging ~= true then return end
    local username = player and player.getUsername
        and tostring(player:getUsername() or "") or "local"
    local itemCount = type(args.itemIDs) == "table" and #args.itemIDs or 0
    local fields = {
        "[PNC][STORAGE_TX]",
        "action=" .. tostring(action or "unknown"),
        "outcome=" .. (ok == true and "commit" or "reject"),
        "reason=" .. tostring(reason or "none"),
        "player=" .. username,
        "request=" .. tostring(args.requestId or "none"),
        "storage=" .. tostring(storage and storage.id
            or args.storageId or "none"),
        "npc=" .. tostring(args.npcId or "none"),
        "item=" .. tostring(args.itemID or "none"),
        "items=" .. tostring(itemCount),
        "quantity=" .. tostring(args.quantity or itemCount),
    }
    if args.debugAction then
        fields[#fields + 1] = "debug=" .. tostring(args.debugAction)
    end
    if details and details.liveMirrorShortfall then
        fields[#fields + 1] = "mirror_shortfall="
            .. tostring(details.liveMirrorShortfall)
    end
    if PNC.Core and PNC.Core.LogInfo then
        PNC.Core.LogInfo(table.concat(fields, " "))
    end
end

function Internal.DebugAllowed(player)
    local access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    if string.lower(access) == "admin" then return true end
    if isServer and isServer() then return false end
    if isDebugEnabled then return isDebugEnabled() == true end
    return getCore and getCore() and getCore():getDebug() == true or false
end

function Internal.RememberRequest(player, requestID)
    requestID = tostring(requestID or "")
    if requestID == "" then return true end
    local playerKey = player and player.getUsername
        and tostring(player:getUsername() or "") or tostring(player)
    local bucket = Service.ProcessedRequests[playerKey]
        or { order = {}, byID = {} }
    Service.ProcessedRequests[playerKey] = bucket
    if bucket.byID[requestID] then return false end
    bucket.byID[requestID] = true
    bucket.order[#bucket.order + 1] = requestID
    while #bucket.order > 64 do
        local expired = table.remove(bucket.order, 1)
        bucket.byID[expired] = nil
    end
    return true
end

return Internal
