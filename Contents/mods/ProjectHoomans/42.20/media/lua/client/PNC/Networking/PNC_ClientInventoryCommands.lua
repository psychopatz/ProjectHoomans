--[[
    PNC Client Inventory Commands
    Applies character payloads, inventory deltas, and operation results.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local Core = PNC.Core
local ClientState = PNC.Network.ClientState

local function removeFromContainer(inventory, itemID)
    local container
    local i
    for _, container in pairs(inventory and inventory.containers or {}) do
        for i = #(container.items or {}), 1, -1 do
            if container.items[i] == itemID then
                table.remove(container.items, i)
            end
        end
    end
end

local function rebuildCachedEquipment(cached, authoritativeEquipment)
    local inventory = cached and cached.inventory or nil
    local equipment = Core.DeepCopy(authoritativeEquipment or {})
    local itemID
    local item
    if not inventory then return end

    inventory.equipped = {}
    inventory.worn = {}
    inventory.attached = {}
    for itemID, item in pairs(inventory.items or {}) do
        if item.equipSlot then inventory.equipped[item.equipSlot] = itemID end
        if item.wornSlot then inventory.worn[item.wornSlot] = itemID end
        if item.attachedSlot then inventory.attached[item.attachedSlot] = itemID end
    end

    equipment.worn = equipment.worn or {}
    equipment.attached = equipment.attached or {}
    if authoritativeEquipment == nil then
        equipment.primaryFullType = inventory.equipped.primary
            and inventory.items[inventory.equipped.primary]
            and inventory.items[inventory.equipped.primary].type or nil
        equipment.secondaryFullType = inventory.equipped.secondary
            and inventory.items[inventory.equipped.secondary]
            and inventory.items[inventory.equipped.secondary].type or nil
        equipment.worn = {}
        equipment.attached = {}
        for itemID, item in pairs(inventory.items or {}) do
            if item.wornSlot then equipment.worn[item.wornSlot] = item.type end
            if item.attachedSlot then equipment.attached[item.attachedSlot] = item.type end
        end
    end
    cached.equipment = equipment
    cached.snapshot = cached.snapshot or {}
    cached.snapshot.equipmentSummary = Core.DeepCopy(equipment)
    if cached.snapshot.id and ClientState.snapshots then
        ClientState.snapshots[cached.snapshot.id] = cached.snapshot
    end
end

local function applyInventoryDelta(args)
    local cached = args and ClientState.characterPayloads and ClientState.characterPayloads[args.npcId] or nil
    local inventory = cached and cached.inventory or nil
    local i
    local op
    local item
    local container
    if not inventory or type(inventory.items) ~= "table" or type(args.ops) ~= "table" then
        Client.RequestCharacterPayload(args and args.npcId)
        return false
    end
    for i = 1, #args.ops do
        op = args.ops[i]
        if op.op == "add" and type(op.item) == "table" and op.item.id then
            item = Core.DeepCopy(op.item)
            inventory.items[item.id] = item
            container = inventory.containers[item.container or op.container or "root"]
            if container then
                container.items[#container.items + 1] = item.id
            end
        elseif op.op == "remove" and op.itemID then
            removeFromContainer(inventory, op.itemID)
            inventory.items[op.itemID] = nil
        elseif op.op == "move" and op.itemID and inventory.items[op.itemID] then
            removeFromContainer(inventory, op.itemID)
            inventory.items[op.itemID].container = op.to
            container = inventory.containers[op.to]
            if container then
                container.items[#container.items + 1] = op.itemID
            end
        elseif op.op == "update" and op.itemID and inventory.items[op.itemID] then
            item = inventory.items[op.itemID]
            if op.stack ~= nil then item.stack = op.stack end
            if op.uses ~= nil then item.uses = op.uses end
            if op.cond ~= nil then item.cond = op.cond end
            if op.ammoCount ~= nil then item.ammoCount = op.ammoCount end
            if op.fav ~= nil then item.fav = op.fav == true end
            if op.interactionLocked ~= nil then
                item.interactionLocked = op.interactionLocked == true
                item.interactionLockReason = item.interactionLocked
                    and op.interactionLockReason or nil
            end
        elseif op.op == "equip" and op.slot then
            inventory.equipped = inventory.equipped or {}
            if op.oldSlot and inventory.equipped[op.oldSlot] == op.itemID then
                inventory.equipped[op.oldSlot] = nil
            end
            if op.previousItemID and inventory.items[op.previousItemID] then
                inventory.items[op.previousItemID].equipSlot = nil
            end
            inventory.equipped[op.slot] = op.itemID
            if op.itemID and inventory.items[op.itemID] then
                inventory.items[op.itemID].equipSlot = op.slot
            end
        elseif op.op == "wear" and op.slot then
            inventory.worn = inventory.worn or {}
            if op.oldSlot and inventory.worn[op.oldSlot] == op.itemID then
                inventory.worn[op.oldSlot] = nil
            end
            if op.previousItemID and inventory.items[op.previousItemID] then
                inventory.items[op.previousItemID].wornSlot = nil
            end
            inventory.worn[op.slot] = op.itemID
            if op.itemID and inventory.items[op.itemID] then
                inventory.items[op.itemID].wornSlot = op.slot
            end
        end
    end
    inventory.summary = Core.DeepCopy(args.summary or inventory.summary or {})
    inventory.summary.revision = tonumber(args.inventoryRevision) or inventory.summary.revision
    inventory.revision = inventory.summary.revision
    rebuildCachedEquipment(cached, args.equipment)
    return true
end

Internal.RegisterServerCommand(Const.CMD_CHARACTER_PAYLOAD, function(args)
    if not args.npcId then
        return
    end
    ClientState.characterPayloads = ClientState.characterPayloads or {}
    ClientState.characterPayloads[args.npcId] = args
    if args.snapshot and args.snapshot.id then
        ClientState.snapshots[args.snapshot.id] = args.snapshot
    end
end)

Internal.RegisterServerCommand(Const.CMD_INVENTORY_DELTA, function(args)
    if args.npcId then
        applyInventoryDelta(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_INVENTORY_RESULT, function(args)
    ClientState.inventoryResult = Core.DeepCopy(args)
    if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
        PNC.InventoryWindow.OnResult(ClientState.inventoryResult)
    end
end)
