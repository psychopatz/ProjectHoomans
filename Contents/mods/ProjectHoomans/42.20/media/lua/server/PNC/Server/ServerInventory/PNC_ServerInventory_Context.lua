if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Const = PNC.Const
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local Network = PNC.Network
local ItemTransfer =
    require "PsychopatzCore/Inventory/PsychopatzItemTransfer"

local function canUseDebug(player)
    local access
    if not isServer or not isServer() then
        if isDebugEnabled then return isDebugEnabled() == true end
        return getCore and getCore() and getCore():getDebug() == true or false
    end
    access = player and player.getAccessLevel
        and tostring(player:getAccessLevel() or "") or ""
    return string.lower(access) == "admin"
end

local function notify(player, success, reason, args, details)
    local payload = {
        success = success == true,
        reason = tostring(reason or (success and "ok" or "failed")),
        npcId = args and args.id and tostring(args.id) or nil,
        requestId = args and args.requestId and tostring(args.requestId) or nil,
    }
    for key, value in pairs(type(details) == "table" and details or {}) do
        payload[key] = value
    end
    if player and sendServerCommand then
        sendServerCommand(player, Const.MODULE, Const.CMD_INVENTORY_RESULT, payload)
    end
    return success == true, payload.reason, payload
end

local function canGift(player, record, args)
    if not player or not record then return false, "npc_not_found" end
    if args.direction ~= "player_to_npc" then
        return false, "gift_direction_invalid"
    end
    local lease = record.runtime and record.runtime.conversationLease or nil
    if not lease or tostring(lease.token or "")
        ~= tostring(args.conversationToken or "")
    then
        return false, "conversation_lease_required"
    end
    local faction = tostring(record.faction or "")
    if faction == tostring(Const.FACTION_HOSTILE) then
        return false, "hostile_gift_forbidden"
    end
    if PNC.ConversationScene and PNC.ConversationScene.Begin then
        local ok, reason = PNC.ConversationScene.Begin(
            record,
            Registry.GetLiveZombie(record.id),
            player,
            args.conversationToken,
            {
                maximumDistance = lease.maximumDistance,
                dangerRadius = lease.dangerRadius,
                allowHostileParley = false,
            }
        )
        if ok ~= true then return false, reason or "conversation_unavailable" end
    end
    return true, "gift_authorized"
end

local function relationshipSnapshot(value)
    value = type(value) == "table" and value or {}
    return {
        approval = tonumber(value.approval) or 0,
        respect = tonumber(value.respect) or 0,
        familiarity = tonumber(value.familiarity) or 0,
        state = value.state,
    }
end

local function canManage(player, record)
    if not record then return false, "npc_not_found" end
    if canUseDebug(player) then return true, "debug_authorized" end
    if not PNC.CompanionCommands or not PNC.CompanionCommands.CanPlayerCommand then
        return false, "command_service_unavailable"
    end
    return PNC.CompanionCommands.CanPlayerCommand(
        record,
        player,
        tonumber(Const.INVENTORY_INTERACTION_RADIUS) or 3
    )
end

local function checkRevision(record, args)
    local inv = Inventory.EnsureRecordInventory(record)
    local expected = tonumber(args and args.inventoryRevision)
    if expected == nil then return false, "revision_missing" end
    if expected ~= tonumber(inv and inv.revision) then
        return false, "revision_conflict"
    end
    return true, expected
end

local function syncResult(player, record, sinceRevision)
    if Network and Network.SendInventoryDelta then
        Network.SendInventoryDelta(player, record, sinceRevision)
    elseif Network and Network.SendCharacterPayload then
        Network.SendCharacterPayload(player, record)
    end
end

local function refreshLiveEquipment(record)
    local body = record and record.id and Registry.GetLiveZombie(record.id) or nil
    if body and PNC.Equipment and PNC.Equipment.Apply then
        PNC.Equipment.Apply(body, record)
    end
end

Internal.ItemTransfer = ItemTransfer
Internal.canUseDebug = canUseDebug
Internal.notify = notify
Internal.canGift = canGift
Internal.relationshipSnapshot = relationshipSnapshot
Internal.canManage = canManage
Internal.checkRevision = checkRevision
Internal.syncResult = syncResult
Internal.refreshLiveEquipment = refreshLiveEquipment
