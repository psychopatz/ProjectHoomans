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

local function receiveRelationshipAfter(npcID, after, delta, source, eventID)
    local relationship = PNC.Conversation
        and PNC.Conversation.Relationship
    if type(after) ~= "table" or not relationship
        or not relationship.ReceiveAfter
    then
        return false
    end
    return relationship.ReceiveAfter(npcID, after, delta, {
        source = source or "inventory",
        eventID = eventID or after.eventID,
        revision = after.revision,
    })
end

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
        ClientState.snapshots[tostring(cached.snapshot.id)] = cached.snapshot
    end
end

local function applyInventoryDelta(args)
    local npcID = args and args.npcId and tostring(args.npcId) or nil
    local cached = npcID and ClientState.characterPayloads
        and ClientState.characterPayloads[npcID] or nil
    local inventory = cached and cached.inventory or nil
    local currentRevision
    local incomingRevision
    local fromRevision
    local i
    local op
    local item
    local container
    if not inventory or type(inventory.items) ~= "table" or type(args.ops) ~= "table" then
        Client.RequestCharacterPayload(npcID)
        return false
    end
    currentRevision = tonumber(inventory.revision)
        or tonumber(inventory.summary and inventory.summary.revision) or 0
    incomingRevision = tonumber(args.inventoryRevision)
    fromRevision = tonumber(args.fromRevision)
    if args.fullRequired == true or incomingRevision == nil
        or incomingRevision < currentRevision
    then
        Client.RequestCharacterPayload(npcID)
        return false
    end
    if incomingRevision == currentRevision then
        return #args.ops == 0
    end
    if fromRevision ~= nil and fromRevision ~= currentRevision then
        Client.RequestCharacterPayload(npcID)
        return false
    end
    inventory = Core.DeepCopy(inventory)
    inventory.containers = inventory.containers or {}
    for i = 1, #args.ops do
        op = args.ops[i]
        if op.op == "add" and type(op.item) == "table" and op.item.id then
            item = Core.DeepCopy(op.item)
            if inventory.items[item.id] then
                Client.RequestCharacterPayload(npcID)
                return false
            end
            inventory.items[item.id] = item
            container = inventory.containers[item.container or op.container or "root"]
            if container then
                container.items[#container.items + 1] = item.id
            end
        elseif op.op == "remove" and op.itemID then
            if not inventory.items[op.itemID] then
                Client.RequestCharacterPayload(npcID)
                return false
            end
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
        elseif op.op == "move" or op.op == "update" then
            Client.RequestCharacterPayload(npcID)
            return false
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
    cached.inventory = inventory
    rebuildCachedEquipment(cached, args.equipment)
    return true
end

Internal.RegisterServerCommand(Const.CMD_CHARACTER_PAYLOAD, function(args)
    local id
    local currentPayload
    local incomingRevision
    local currentPayloadRevision
    local incomingInventoryRevision
    local currentInventoryRevision
    local currentSnapshot
    local snapshotIsStale
    if not args.npcId then
        return
    end
    id = tostring(args.npcId)
    ClientState.characterPayloads = ClientState.characterPayloads or {}
    currentPayload = ClientState.characterPayloads[id]
    incomingRevision = tonumber(args.revision)
    currentPayloadRevision = currentPayload and tonumber(currentPayload.revision) or nil
    if incomingRevision and currentPayloadRevision
        and incomingRevision < currentPayloadRevision
    then
        return
    end
    incomingInventoryRevision = args.inventory
        and tonumber(args.inventory.revision or args.inventory.summary
            and args.inventory.summary.revision) or nil
    currentInventoryRevision = currentPayload and currentPayload.inventory
        and tonumber(currentPayload.inventory.revision
            or currentPayload.inventory.summary
            and currentPayload.inventory.summary.revision) or nil
    if currentPayload and incomingInventoryRevision
        and currentInventoryRevision
        and incomingInventoryRevision < currentInventoryRevision
    then
        return
    end
    currentSnapshot = ClientState.snapshots and ClientState.snapshots[id] or nil
    snapshotIsStale = args.snapshot and currentSnapshot
        and Internal.IsStaleSnapshot
        and Internal.IsStaleSnapshot(currentSnapshot, args.snapshot)
    if snapshotIsStale and currentSnapshot then
        args.snapshot = currentSnapshot
    end
    if currentPayload and incomingInventoryRevision
        and currentInventoryRevision
        and incomingInventoryRevision <= currentInventoryRevision
    then
        args.inventory = currentPayload.inventory
    end
    ClientState.characterPayloads[id] = args
    if args.snapshot and args.snapshot.id then
        if Internal.StoreSnapshot then
            args.snapshot = Internal.StoreSnapshot(args.snapshot, false)
        else
            ClientState.snapshots[tostring(args.snapshot.id)] = args.snapshot
            if PNC.Network.RefreshClientBodyIdentityIndex then
                PNC.Network.RefreshClientBodyIdentityIndex()
            end
        end
    end
end)

Internal.RegisterServerCommand(Const.CMD_INVENTORY_DELTA, function(args)
    if args.npcId then
        applyInventoryDelta(args)
    end
end)

Internal.RegisterServerCommand(Const.CMD_INVENTORY_RESULT, function(args)
    ClientState.inventoryResult = Core.DeepCopy(args)
    if args.relationshipDelta then
        ClientState.lastConversationDelta = {
            npcID = args.npcId,
            source = args.giftEffect and "gift" or "inventory",
            delta = Core.DeepCopy(args.relationshipDelta),
            before = Core.DeepCopy(args.relationshipBefore),
            after = Core.DeepCopy(args.relationshipAfter),
            effects = Core.DeepCopy(args.giftEffect),
            itemTypes = Core.DeepCopy(args.itemTypes),
            at = Core.Now(),
        }
        receiveRelationshipAfter(
            args.npcId,
            args.relationshipAfter,
            args.relationshipDelta,
            args.giftEffect and "gift" or "inventory",
            args.eventID or args.requestId
        )
    end
    if PNC.InventoryWindow and PNC.InventoryWindow.OnResult then
        PNC.InventoryWindow.OnResult(ClientState.inventoryResult)
    end
end)
