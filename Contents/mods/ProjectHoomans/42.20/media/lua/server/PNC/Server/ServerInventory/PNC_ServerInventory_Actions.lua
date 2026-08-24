if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ServerInventory = PNC.ServerInventory or {}
PNC.ServerInventory.Internal = PNC.ServerInventory.Internal or {}

local Service = PNC.ServerInventory
local Internal = Service.Internal
local Registry = PNC.Registry
local Inventory = PNC.Inventory
local Actions = PNC.InventoryActions
local Network = PNC.Network
local ItemTransfer = Internal.ItemTransfer
local canManage = Internal.canManage
local notify = Internal.notify
local checkRevision = Internal.checkRevision
local compactContainerHasItems = Internal.compactContainerHasItems
local portableCompactItemState = Internal.portableCompactItemState
local refreshLiveEquipment = Internal.refreshLiveEquipment
local syncResult = Internal.syncResult

local function dropItem(player, record, item, sinceRevision)
    local inv = Inventory.EnsureRecordInventory(record)
    if compactContainerHasItems(inv, item) then
        return false, "container_not_empty"
    end
    local body = Registry.GetLiveZombie(record.id)
    local square = body and body.getSquare and body:getSquare() or nil
    if not square and getCell and getCell() and getCell().getGridSquare then
        square = getCell():getGridSquare(
            math.floor(tonumber(record.x) or 0),
            math.floor(tonumber(record.y) or 0),
            math.floor(tonumber(record.z) or 0)
        )
    end
    if not square then return false, "square_unavailable" end
    local state = portableCompactItemState(record, item)
    local dropped, reason = ItemTransfer.DropToSquare(
        square,
        item.type,
        math.max(1, math.floor(tonumber(item.stack) or 1)),
        state
    )
    if not dropped then return false, reason end
    local removed, removeReason = Inventory.RemoveItems(
        record,
        { item.id },
        "inventory_action_drop"
    )
    if not removed then return false, removeReason end
    refreshLiveEquipment(record)
    syncResult(player, record, sinceRevision)
    return true, "dropped"
end

function Service.Action(player, args)
    args = args or {}
    local record = args.id and Registry.Get(tostring(args.id)) or nil
    local allowed, reason = canManage(player, record)
    if not allowed then return notify(player, false, reason, args) end
    local revisionOK, sinceRevision = checkRevision(record, args)
    if not revisionOK then
        if Network and Network.SendCharacterPayload then
            Network.SendCharacterPayload(player, record)
        end
        return notify(player, false, sinceRevision, args)
    end
    local inv = Inventory.EnsureRecordInventory(record)
    local item = inv.items[tostring(args.itemID or "")]
    if not item then return notify(player, false, "item_not_found", args) end
    if item.interactionLocked == true then
        return notify(player, false, "item_off_limits", args)
    end

    local success
    if tostring(args.actionID or "") == "drop" then
        success, reason = dropItem(player, record, item, sinceRevision)
    else
        local definition = Actions.Get and Actions.Get(args.actionID) or nil
        success, reason = Actions.Execute(
            args.actionID,
            player,
            record,
            item.id,
            args
        )
        if success then
            if not definition or definition.refreshEquipment ~= false then
                refreshLiveEquipment(record)
            end
            syncResult(player, record, sinceRevision)
        end
    end
    return notify(player, success, reason, args)
end
