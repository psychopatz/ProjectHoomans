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
local Core = PNC.Core
local ItemTransfer =
    require "PsychopatzCore/Inventory/PsychopatzItemTransfer"

local function canUseDebug(player)
    local coreDebug = PsychopatzCore and PsychopatzCore.Debug
    if not coreDebug or type(coreDebug.CanUse) ~= "function" then
        local ok, loaded = pcall(require, "PsychopatzCore/Debug/PsychopatzDebug")
        if ok then coreDebug = loaded end
    end
    return coreDebug and coreDebug.CanUse
        and coreDebug.CanUse(player) == true or false
end

local function notify(player, success, reason, args, details)
    local payload = {
        success = success == true,
        reason = tostring(reason or (success and "ok" or "failed")),
        npcId = args and args.id and tostring(args.id) or nil,
        requestId = args and args.requestId and tostring(args.requestId) or nil,
        gift = args and args.gift == true or false,
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
    local tacticalClass = tostring(record.tacticalClass or "")
    if tacticalClass == tostring(Const.TACTICAL_CLASS_HOSTILE) then
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
                guardThreats = lease.guardThreats ~= false,
                allowHostileParley = false,
            }
        )
        if ok ~= true then return false, reason or "conversation_unavailable" end
    end
    return true, "gift_authorized", lease
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
    local inv = Inventory.EnsureRecordInventory(record, {
        reconcileWaterContainer = false,
    })
    local expected = tonumber(args and args.inventoryRevision)
    local actual = tonumber(inv and inv.revision) or 0
    if expected == nil then return false, "revision_missing" end
    if expected ~= actual then
        if Core and Core.LogWarn then
            Core.LogWarn(
                "[PNC][INVENTORY] revision conflict npc="
                    .. tostring(record and record.id or "")
                    .. " action=" .. tostring(args and args.actionID
                        or args and args.direction or "")
                    .. " item=" .. tostring(args and args.itemID or "")
                    .. " expected=" .. tostring(expected)
                    .. " current=" .. tostring(actual)
                    .. " request=" .. tostring(args and args.requestId or "")
            )
        end
        return false, "revision_conflict", {
            expectedInventoryRevision = expected,
            currentInventoryRevision = actual,
        }
    end
    return true, expected
end

local function auditScalar(value, maxBytes)
    local valueType = type(value)
    if valueType == "string" then
        return string.sub(value, 1, maxBytes)
    end
    if valueType == "number" or valueType == "boolean" then
        return string.sub(tostring(value), 1, maxBytes)
    end
    if value == nil then return "" end
    return "<" .. valueType .. ">"
end

local function auditInventoryRequest(
    eventName,
    stage,
    record,
    args,
    authority,
    authorityReason,
    adapterResult,
    result,
    reason,
    revisionBefore
)
    local diagnostics = PNC.PerformanceScalingDiagnostics
    if not diagnostics or diagnostics.InventoryAuditEnabled ~= true
        or type(diagnostics.LogInventoryAudit) ~= "function"
    then
        return false
    end
    args = type(args) == "table" and args or {}

    local direction = args.direction
    if direction ~= "player_to_npc" and direction ~= "npc_to_player" then
        direction = "invalid"
    elseif args.gift == true then
        direction = "gift_" .. direction
    end
    local actionID = auditScalar(args.actionID, 32)
    local route = actionID ~= "" and "action:" .. actionID or direction
    local targetContainer
    if args.direction == "npc_to_player" then
        targetContainer = args.playerContainer
    elseif args.direction == "player_to_npc" then
        targetContainer = args.npcContainer
    end
    local itemIDs = type(args.itemIDs) == "table" and args.itemIDs or nil
    local itemCount = itemIDs and #itemIDs
        or args.itemID ~= nil and 1 or 0
    local selection = "quantity=" .. auditScalar(args.quantity, 16)
        .. ",bulk=" .. (args.bulk == true and "true" or "false")
    if args.gift == true then selection = selection .. ",gift=true" end
    local currentRevision = record and record.inventory
        and record.inventory.revision or nil
    local fields = {
        "stage=" .. auditScalar(stage, 24),
        "npc=" .. auditScalar(record and record.id or args.id, 64),
        "request=" .. auditScalar(args.requestId, 48),
        "route=" .. auditScalar(route, 48),
        "target=" .. auditScalar(targetContainer, 48),
        "item_count=" .. auditScalar(itemCount, 12),
        "item=" .. auditScalar(args.itemID, 48),
        "selection=" .. selection,
        "authority=" .. auditScalar(authority, 24),
        "authority_reason=" .. auditScalar(authorityReason, 48),
        "adapter_result=" .. auditScalar(adapterResult, 24),
        "result=" .. auditScalar(result, 8),
        "reason=" .. auditScalar(reason, 48),
        "revision_expected=" .. auditScalar(args.inventoryRevision, 16),
        "revision_before=" .. auditScalar(revisionBefore, 16),
        "revision_after=" .. auditScalar(currentRevision, 16),
    }
    diagnostics.LogInventoryAudit(auditScalar(eventName, 64), fields)
    return true
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
Internal.auditInventoryRequest = auditInventoryRequest
Internal.syncResult = syncResult
Internal.refreshLiveEquipment = refreshLiveEquipment
