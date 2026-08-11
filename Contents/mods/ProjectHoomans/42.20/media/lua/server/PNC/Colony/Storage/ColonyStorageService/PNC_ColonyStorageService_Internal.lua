local Service = PNC.ColonyStorageService
local Internal = Service.Internal
local Definitions = require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"
local Repository = require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
local CoreInventory = require "PsychopatzCore/Inventory/PsychopatzInventory"
local C = require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

Service.Metrics = Service.Metrics or {
    deposits = 0, withdrawals = 0, transferFailures = 0,
    capacityRejects = 0, compactions = 0, validationFailures = 0,
}
Service.ProcessedRequests = Service.ProcessedRequests or {}
Internal.Definitions = Definitions
Internal.Repository = Repository
Internal.CoreInventory = CoreInventory
Internal.Constants = C

function Internal.LogTransaction(player, args, action, ok, reason, storage, details)
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
        "storage=" .. tostring(storage and storage.id or args.storageId or "none"),
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

local function activeColony(factionID)
    if not PNC.Communities or not PNC.Communities.GetForFaction then return nil end
    for _, community in ipairs(PNC.Communities.GetForFaction(factionID) or {}) do
        if community.status == "active" then return community end
    end
    return nil
end

function Service.ResolveForPlayer(player, requestedStorageID)
    local faction, reason = PNC.Factions and PNC.Factions.GetPlayerFaction
        and PNC.Factions.GetPlayerFaction(player) or nil, "unaffiliated"
    if not faction then return nil, reason end
    local colony = activeColony(faction.id)
    local storage
    storage, reason = Repository.GetPrimary(faction.id, colony and colony.id or nil)
    if not storage then return nil, reason end
    if requestedStorageID and tostring(requestedStorageID) ~= storage.id then
        return nil, "storage_not_owned"
    end
    if storage.ownerFactionId ~= faction.id then return nil, "storage_not_owned" end
    return storage, nil, faction, colony
end

function Internal.RememberRequest(player, requestID)
    requestID = tostring(requestID or "")
    if requestID == "" then return true end
    local playerKey = player and player.getUsername
        and tostring(player:getUsername() or "") or tostring(player)
    local bucket = Service.ProcessedRequests[playerKey] or { order = {}, byID = {} }
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

function Internal.Preflight(storage, records)
    local required = 0
    for index = 1, #(records or {}) do
        required = required + (tonumber(records[index][C.UNIT_WEIGHT]) or 0)
            * (tonumber(records[index][C.QUANTITY]) or 0)
    end
    local capacity = Definitions.GetCapacity(storage.tier)
    local used = storage.inventory:getWeight()
    local details = {
        requiredWeight = required,
        availableWeight = math.max(0, capacity - used),
        usedWeight = used,
        capacity = capacity,
    }
    if used + required > capacity + 0.000001 then
        Service.Metrics.capacityRejects = Service.Metrics.capacityRejects + 1
        return false, "storage_full", details
    end
    return true, nil, details
end

function Internal.CommitStorage(storage)
    storage.revision = storage.revision + 1
    storage.inventory.maxWeight = Definitions.GetCapacity(storage.tier)
    Repository.MarkDirty()
end

function Internal.TransferIntoStorage(storage, source, quantity)
    local preview, reason = source:preview()
    if not preview then return false, reason end
    local ok, _, details = Internal.Preflight(storage, preview)
    if not ok then return false, "storage_full", details end
    ok, reason = CoreInventory.transfer(
        source, storage.inventory, nil, quantity or #preview
    )
    if not ok then return false, reason, details end
    if source.mirrorShortfall then
        details.liveMirrorShortfall = source.mirrorShortfall
    end
    Internal.CommitStorage(storage)
    Service.Metrics.deposits = Service.Metrics.deposits + 1
    return true, "deposited", details
end

return Internal
