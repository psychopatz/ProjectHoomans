local Internal = PNC.Client.Internal
local H = Internal.InventoryDelta
if not H then return Internal end

local ClientState = H.ClientState
local Core = H.Core
local Diagnostics = H.Diagnostics
local requestInventoryResync = H.requestInventoryResync
local rebuildCachedEquipment = H.rebuildCachedEquipment
if not H.ApplyInventoryDeltaOperation then
    require "PNC/Networking/PNC_ClientInventoryCommands_DeltaOperations"
end
local applyInventoryDeltaOperation = H.ApplyInventoryDeltaOperation

function Internal.ApplyInventoryDelta(args)
    local npcID = args and args.npcId and tostring(args.npcId) or nil
    local cached = npcID and ClientState.characterPayloads
        and ClientState.characterPayloads[npcID] or nil
    local inventory = cached and cached.inventory or nil
    local currentRevision
    local incomingRevision
    local fromRevision
    local i
    local op
    if not inventory or type(inventory.items) ~= "table" or type(args.ops) ~= "table" then
        requestInventoryResync(npcID, "payload_missing")
        return false
    end
    currentRevision = tonumber(inventory.revision)
        or tonumber(inventory.summary and inventory.summary.revision) or 0
    incomingRevision = tonumber(args.inventoryRevision)
    fromRevision = tonumber(args.fromRevision)
    if args.fullRequired == true or incomingRevision == nil
        or incomingRevision < currentRevision
    then
        requestInventoryResync(npcID, "revision_invalid")
        return false
    end
    if incomingRevision == currentRevision then
        return #args.ops == 0
    end
    if fromRevision ~= nil and fromRevision ~= currentRevision then
        requestInventoryResync(npcID, "revision_gap")
        return false
    end
    inventory = Core.DeepCopy(inventory)
    inventory.containers = inventory.containers or {}
    for i = 1, #args.ops do
        op = args.ops[i]
        local applied, failureReason = applyInventoryDeltaOperation(
            inventory,
            op
        )
        if not applied then
            requestInventoryResync(npcID, failureReason)
            return false
        end
    end
    inventory.summary = Core.DeepCopy(args.summary or inventory.summary or {})
    inventory.summary.revision = tonumber(args.inventoryRevision) or inventory.summary.revision
    inventory.revision = inventory.summary.revision
    cached.inventory = inventory
    if ClientState.inventoryResyncPending then
        ClientState.inventoryResyncPending[npcID] = nil
    end
    rebuildCachedEquipment(cached, args.equipment)
    if Diagnostics and Diagnostics.InventoryAuditEnabled == true
        and Diagnostics.LogInventoryAudit
    then
        local fields = {
            "npc=" .. tostring(npcID or ""),
            "fromRevision=" .. tostring(fromRevision or ""),
            "inventoryRevision=" .. tostring(incomingRevision or ""),
            "opCount=" .. tostring(#args.ops),
        }
        for index = 1, #args.ops do
            op = args.ops[index]
            fields[#fields + 1] = "op" .. tostring(index) .. "="
                .. tostring(op and op.op or "unknown")
                .. ":item=" .. tostring(op and op.itemID
                    or op and op.item and op.item.id or "")
            if op and op.itemState then
                fields[#fields + 1] = "op" .. tostring(index)
                    .. "Fluid=" .. tostring(op.itemState.fluidAmount or "")
                    .. "/" .. tostring(op.itemState.fluidCapacity or "")
                    .. "/" .. tostring(op.itemState.fluidPrimaryType or "")
            end
        end
        Diagnostics.LogInventoryAudit("client_delta_applied", fields)
    end
    if PNC.InventoryWindow
        and PNC.InventoryWindow.OnInventoryPayloadApplied
    then
        PNC.InventoryWindow.OnInventoryPayloadApplied(
            npcID, incomingRevision, "inventory_delta")
    end
    return true
end

return Internal
