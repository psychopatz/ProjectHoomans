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
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function requestInventoryResync(npcID, reason)
    local pending
    local sent
    if not npcID or not Client.RequestCharacterInventoryPayload then
        return false
    end
    ClientState.inventoryResyncPending = ClientState.inventoryResyncPending or {}
    pending = ClientState.inventoryResyncPending[npcID]
    if pending == true then return true end
    ClientState.inventoryResyncPending[npcID] = true
    if Core and Core.LogWarn then
        Core.LogWarn(
            "[PNC][INVENTORY] client resync npc=" .. tostring(npcID)
                .. " reason=" .. tostring(reason or "delta_rejected")
        )
    end
    sent = Client.RequestCharacterInventoryPayload(npcID)
    if sent ~= true then
        ClientState.inventoryResyncPending[npcID] = nil
    end
    return sent == true
end

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

Internal.InventoryDelta = {
    ClientState = ClientState,
    Core = Core,
    Diagnostics = Diagnostics,
    requestInventoryResync = requestInventoryResync,
    removeFromContainer = removeFromContainer,
    rebuildCachedEquipment = rebuildCachedEquipment,
}

require "PNC/Networking/PNC_ClientInventoryCommands_DeltaOperations"
require "PNC/Networking/PNC_ClientInventoryCommands_Delta"

local function applyCharacterInventoryPayload(args, source)
    local npcID = args and args.npcId and tostring(args.npcId) or nil
    local pending = ClientState.pendingCharacterInventoryRequest
    local inventory = args and args.inventory or nil
    local requestID = args and args.requestID and tostring(args.requestID) or nil
    local incomingRevision
    local cached
    local currentRevision
    local snapshot
    if not npcID or not requestID or not pending
        or tostring(pending.npcId or "") ~= npcID
        or tostring(pending.requestID or "") ~= requestID
    then
        return false
    end
    if type(inventory) ~= "table" or args.inventoryFull ~= true then
        ClientState.pendingCharacterInventoryRequest = nil
        if ClientState.inventoryResyncPending then
            ClientState.inventoryResyncPending[npcID] = nil
        end
        return false
    end

    ClientState.characterPayloads = ClientState.characterPayloads or {}
    cached = ClientState.characterPayloads[npcID]
    if type(cached) ~= "table" then
        cached = { npcId = npcID }
    end
    incomingRevision = tonumber(inventory.revision
        or inventory.summary and inventory.summary.revision)
    currentRevision = cached.inventory
        and tonumber(cached.inventory.revision
            or cached.inventory.summary
            and cached.inventory.summary.revision) or nil
    if incomingRevision and currentRevision
        and incomingRevision < currentRevision
    then
        ClientState.pendingCharacterInventoryRequest = nil
        if ClientState.inventoryResyncPending then
            ClientState.inventoryResyncPending[npcID] = nil
        end
        if PNC.InventoryWindow
            and PNC.InventoryWindow.OnInventoryPayloadApplied
        then
            PNC.InventoryWindow.OnInventoryPayloadApplied(
                npcID, currentRevision, source or "inventory_payload")
        end
        return true
    end

    cached.npcId = cached.npcId or npcID
    cached.inventory = inventory
    cached.inventoryFull = true
    snapshot = ClientState.snapshots
        and ClientState.snapshots[npcID] or cached.snapshot
    if snapshot and inventory.summary then
        snapshot.inventorySummary = Core.DeepCopy(inventory.summary)
        cached.snapshot = snapshot
    end
    ClientState.characterPayloads[npcID] = cached
    ClientState.pendingCharacterInventoryRequest = nil
    if ClientState.inventoryResyncPending then
        ClientState.inventoryResyncPending[npcID] = nil
    end

    if Diagnostics and Diagnostics.InventoryAuditEnabled == true
        and Diagnostics.LogInventoryAudit
    then
        Diagnostics.LogInventoryAudit("client_inventory_payload_applied", {
            "npc=" .. tostring(npcID),
            "inventoryRevision=" .. tostring(incomingRevision or ""),
            "source=" .. tostring(source or "inventory_payload"),
        })
    end
    if PNC.InventoryWindow
        and PNC.InventoryWindow.OnInventoryPayloadApplied
    then
        PNC.InventoryWindow.OnInventoryPayloadApplied(
            npcID, incomingRevision, source or "inventory_payload")
    end
    return true
end

Internal.ApplyCharacterInventoryPayload = applyCharacterInventoryPayload

Internal.RegisterServerCommand(Const.CMD_CHARACTER_PAYLOAD, function(args)
    local id
    local currentPayload
    local incomingRevision
    local currentPayloadRevision
    local incomingInventoryRevision
    local currentInventoryRevision
    local currentSnapshot
    local snapshotIsStale
    local inventoryAction = "replace"
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
        and args.inventoryFull ~= true
    then
        args.inventory = currentPayload.inventory
        inventoryAction = "reuse_cached_equal_or_newer"
    end
    ClientState.characterPayloads[id] = args
    if ClientState.inventoryResyncPending then
        ClientState.inventoryResyncPending[id] = nil
    end
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
    if Diagnostics and Diagnostics.InventoryAuditEnabled == true
        and Diagnostics.LogInventoryAudit
    then
        Diagnostics.LogInventoryAudit("client_payload_applied", {
            "npc=" .. tostring(id),
            "payloadRevision=" .. tostring(incomingRevision or ""),
            "inventoryRevision=" .. tostring(incomingInventoryRevision or ""),
            "inventoryFull=" .. tostring(args.inventoryFull == true),
            "inventoryAction=" .. tostring(inventoryAction),
        })
    end
    if PNC.InventoryWindow
        and PNC.InventoryWindow.OnInventoryPayloadApplied
    then
        PNC.InventoryWindow.OnInventoryPayloadApplied(
            id, incomingInventoryRevision, "character_payload")
    end
end)

Internal.RegisterServerCommand(Const.CMD_CHARACTER_INVENTORY_PAYLOAD,
    function(args)
        applyCharacterInventoryPayload(args, "inventory_payload")
    end)

Internal.RegisterServerCommand(Const.CMD_INVENTORY_DELTA, function(args)
    if args.npcId then
        Internal.ApplyInventoryDelta(args)
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
