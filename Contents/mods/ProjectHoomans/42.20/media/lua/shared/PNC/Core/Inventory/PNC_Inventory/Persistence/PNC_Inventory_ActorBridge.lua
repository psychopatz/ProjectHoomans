-- Bridge between compact PsychopatzCore ActorInventory payloads and the
-- richer ProjectHoomans logical inventory used only while an actor is
-- hydrated into Hoomans gameplay.
PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}
PNC.Inventory.Internal = PNC.Inventory.Internal or {}

local Inventory = PNC.Inventory
local Internal = Inventory.Internal
local ActorInventory =
    require "PsychopatzCore/Actors/PsychopatzActorInventory"
local CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
local C =
    require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"
local Util =
    require "PsychopatzCore/Inventory/PsychopatzInventoryUtil"
local Json =
    require "PsychopatzCore/Serialization/PsychopatzJson"
local StateCodec =
    require "PNC/Core/Inventory/PNC_Inventory/Persistence/PNC_Inventory_CoreStateCodec"

local Bridge = Inventory.ActorInventoryBridge or {}
Inventory.ActorInventoryBridge = Bridge

local function copy(value)
    return Util.copy(value)
end

local function encodedEqual(left, right)
    return Json.Encode(left) == Json.Encode(right)
end

local function profileFor(fullType)
    if Internal.getContainerProfile then
        return Internal.getContainerProfile(fullType) or {}
    end
    return {}
end

local function durablePNCMetadata(item)
    local profile = profileFor(item.type)
    local data = {}

    if item.maxWeight ~= nil
        and tonumber(item.maxWeight) ~= tonumber(profile.capacity)
    then
        data.maxWeight = tonumber(item.maxWeight)
    end
    if item.weightReduction ~= nil
        and tonumber(item.weightReduction)
            ~= tonumber(profile.weightReduction)
    then
        data.weightReduction = tonumber(item.weightReduction)
    end
    if item.wearableSlot ~= nil
        and tostring(item.wearableSlot)
            ~= tostring(profile.wearableSlot or "")
    then
        data.wearableSlot = tostring(item.wearableSlot)
    end

    for _, key in ipairs({
        "templateKey", "legacyTemplateKey", "preferredContainer",
        "interactionLockReason", "identityNPCId", "identityNPCName",
    }) do
        if item[key] ~= nil then data[key] = copy(item[key]) end
    end
    if item.interactionLocked == true then
        data.interactionLocked = true
    end

    local expectedBag = "bag_" .. tostring(item.id or "")
    if item.bagContainer ~= nil
        and tostring(item.bagContainer) ~= expectedBag
    then
        data.bagContainer = tostring(item.bagContainer)
    end

    if next(data) == nil then return {} end
    return { pnc = data }
end

local function parentItemID(recordInventory, item)
    local container = tostring(item.container or "root")
    if container == "root" or container == "" then return nil end
    if string.sub(container, 1, 4) == "bag_" then
        local candidate = string.sub(container, 5)
        if recordInventory.items
            and recordInventory.items[candidate]
        then
            return candidate
        end
    end
    return nil
end

local function targetEntry(recordInventory, item)
    local encoded, reason = CoreInventory.encodeItem(
        StateCodec.pseudoItem(item),
        math.max(1, math.floor(tonumber(item.stack) or 1))
    )
    if not encoded then return nil, reason end
    local fullType = CoreInventory.getItemFullType(encoded[C.TYPE_ID])
    if not fullType then return nil, "actor_inventory_item_type_unavailable" end

    local metadata = durablePNCMetadata(item)
    local container = tostring(item.container or "root")
    if container ~= "root"
        and parentItemID(recordInventory, item) == nil
    then
        metadata.pnc = metadata.pnc or {}
        metadata.pnc.containerName = container
    end

    return {
        itemId = tostring(item.id),
        fullType = fullType,
        record = encoded,
        containerId = parentItemID(recordInventory, item),
        metadata = metadata,
    }
end

local function physicalSignature(inv, item)
    local entry, reason = targetEntry(inv, item)
    if not entry then return nil, reason end
    return {
        entry = entry,
        wornSlot = item.wornSlot,
        attachedSlot = item.attachedSlot,
        equipSlot = item.equipSlot,
        container = item.container,
    }
end

local function targetEntries(inv, provenance)
    local ids = {}
    local entries = {}
    provenance = type(provenance) == "table" and provenance or {}
    local sourceEntries = provenance.sourceEntries or {}
    local sourceSignatures = provenance.signatures or {}
    for itemId in pairs(inv.items or {}) do
        ids[#ids + 1] = tostring(itemId)
    end
    table.sort(ids)
    for _, itemId in ipairs(ids) do
        local item = inv.items[itemId]
        local signature, reason = physicalSignature(inv, item)
        if not signature then return nil, reason end
        local encodedSignature = Json.Encode(signature)
        local entry
        if sourceEntries[itemId]
            and sourceSignatures[itemId] == encodedSignature
        then
            entry = copy(sourceEntries[itemId])
        else
            entry = signature.entry
        end
        entries[#entries + 1] = entry
    end
    return entries
end

local function targetEquipment(inv)
    local equipment = { worn = {}, equipped = {}, attached = {} }
    for slot, itemId in pairs(inv.worn or {}) do
        equipment.worn[tostring(slot)] = tostring(itemId)
    end
    for slot, itemId in pairs(inv.attached or {}) do
        equipment.attached[tostring(slot)] = tostring(itemId)
    end
    for slot, itemId in pairs(inv.equipped or {}) do
        if itemId ~= nil then
            equipment.equipped[tostring(slot)] = tostring(itemId)
        end
    end
    return equipment
end

local function pncSpec(entry)
    local spec, reason = StateCodec.readValidatedState(entry.record)
    if not spec then return nil, reason end
    spec.id = entry.itemId
    spec.type = entry.fullType
    spec.stack = math.max(
        1,
        math.floor(tonumber(entry.record[C.QUANTITY]) or 1)
    )
    spec.container = "root"
    spec.wornSlot = entry.wornSlot
    spec.attachedSlot = entry.attachedSlot
    spec.equipSlot = entry.equippedSlot
    spec.origin = "world"

    local extra = entry.metadata
        and entry.metadata.pnc or nil
    for key, value in pairs(extra or {}) do
        if key ~= "containerName" then
            spec[key] = copy(value)
        end
    end
    return spec
end

local function desiredContainer(entry)
    if entry.containerId then
        return "bag_" .. tostring(entry.containerId)
    end
    local extra = entry.metadata
        and entry.metadata.pnc or nil
    if extra and extra.containerName then
        return tostring(extra.containerName)
    end
    return "root"
end

function Bridge.HydrateRecord(record, actor)
    if type(record) ~= "table" or type(actor) ~= "table" then
        return nil, "actor_inventory_hydration_input_required"
    end
    local payload = actor.personalInventory
    if type(payload) ~= "table" then
        return nil, "actor_personal_inventory_required"
    end

    local ledger, reason = ActorInventory.Decode(payload)
    if not ledger then return nil, reason end
    local inv = Internal.createBaseInventory(record)
    if not inv then return nil, "hoomans_inventory_create_failed" end

    local entries = ledger:List()
    local byID = {}
    for _, entry in ipairs(entries) do
        local spec
        spec, reason = pncSpec(entry)
        if not spec then return nil, reason end
        local item = Internal.createItem(record, inv, spec)
        if not item then return nil, "hoomans_inventory_item_create_failed" end
        byID[entry.itemId] = item
    end

    for _, entry in ipairs(entries) do
        local container = desiredContainer(entry)
        if container ~= "root" then
            if Internal.ensureContainer then
                Internal.ensureContainer(inv, container, 0)
            end
            if not Internal.setItemContainer
                or not Internal.setItemContainer(
                    inv, byID[entry.itemId], container)
            then
                return nil, "hoomans_inventory_container_failed"
            end
        end
    end

    inv.revision = math.max(
        tonumber(inv.revision) or 0,
        tonumber(payload.revision) or 0
    )
    inv.persistenceMode = tostring(payload.mode or "FULL")
    record.inventory = inv
    record.personalInventory = copy(payload)
    record.runtime = record.runtime or {}
    record.runtime.coreInventoryHydrated = true
    record.runtime.coreInventorySourceMode = tostring(payload.mode or "FULL")

    if Inventory.SyncEquipmentFromInventory then
        Inventory.SyncEquipmentFromInventory(record)
    end
    if Inventory.RebuildCaches then Inventory.RebuildCaches(record) end

    local provenance = {
        sourceEntries = {},
        signatures = {},
    }
    for _, entry in ipairs(entries) do
        provenance.sourceEntries[entry.itemId] = copy(entry)
    end
    for itemId, item in pairs(inv.items or {}) do
        local signature, signatureReason = physicalSignature(inv, item)
        if not signature then return nil, signatureReason end
        provenance.signatures[tostring(itemId)] = Json.Encode(signature)
    end
    record.runtime.coreInventoryHydration = provenance
    return inv, tostring(payload.mode or "FULL")
end

local function reconcileLedger(ledger, inv, provenance)
    local entries, reason = targetEntries(inv, provenance)
    if not entries then return nil, reason end
    local targetByID = {}
    for _, entry in ipairs(entries) do
        targetByID[entry.itemId] = entry
    end

    for _, current in ipairs(ledger:List()) do
        if not targetByID[current.itemId] then
            local removed
            removed, reason = ledger:Remove(current.itemId)
            if not removed then return nil, reason end
        end
    end

    for _, target in ipairs(entries) do
        local current = ledger:Get(target.itemId)
        if not current then
            local added
            added, reason = ledger:Add({
                itemId = target.itemId,
                fullType = target.fullType,
                record = target.record,
                metadata = target.metadata,
            })
            if not added then return nil, reason end
        elseif not encodedEqual({
            fullType = current.fullType,
            record = current.record,
            metadata = current.metadata or {},
        }, {
            fullType = target.fullType,
            record = target.record,
            metadata = target.metadata or {},
        }) then
            local updated
            updated, reason = ledger:Update(target.itemId, {
                fullType = target.fullType,
                record = target.record,
                metadata = target.metadata,
            })
            if not updated then return nil, reason end
        end
    end

    for _, target in ipairs(entries) do
        local current = ledger:Get(target.itemId)
        local currentContainer = current and current.containerId or nil
        if tostring(currentContainer or "")
            ~= tostring(target.containerId or "")
        then
            local moved
            moved, reason = ledger:SetContainer(
                target.itemId, target.containerId)
            if not moved then return nil, reason end
        end
    end

    local equipment = targetEquipment(inv)
    if not encodedEqual(ledger.equipment, equipment) then
        local equipped
        equipped, reason = ledger:SetEquipmentState(equipment)
        if not equipped then return nil, reason end
    end
    return ledger
end

function Bridge.CaptureRecord(record, actor)
    if type(record) ~= "table" or type(actor) ~= "table" then
        return nil, "actor_inventory_capture_input_required"
    end
    if type(record.inventory) ~= "table" then
        return nil, "hoomans_inventory_required"
    end
    local source = actor.personalInventory
    if type(source) ~= "table" then
        return nil, "actor_personal_inventory_required"
    end

    local sourceMode = tostring(source.mode or "FULL")
    local ledger
    local reason
    if sourceMode == "FULL" then
        ledger, reason = ActorInventory.Decode(source)
    else
        ledger, reason = ActorInventory.CreateBaselineFromPayload(source)
    end
    if not ledger then return nil, reason end

    ledger, reason = reconcileLedger(
        ledger,
        record.inventory,
        record.runtime and record.runtime.coreInventoryHydration
    )
    if not ledger then return nil, reason end

    local payload
    local mode
    if sourceMode == "FULL" then
        payload, reason = ledger:ToPayload("FULL")
        if not payload then return nil, reason end
        local compact, compactReason = ActorInventory.CompactPayload(payload)
        if compact then
            payload = compact
            mode = tostring(compact.mode or "FULL")
            reason = compactReason
        else
            mode = "FULL"
        end
    else
        payload, mode = ActorInventory.ToSmallestPayload(ledger)
        if not payload then return nil, mode end
        reason = "captured_" .. tostring(mode)
    end

    record.personalInventory = copy(payload)
    record.runtime = record.runtime or {}
    record.runtime.coreInventoryHydrated = nil
    record.runtime.coreInventorySourceMode = nil
    record.runtime.coreInventoryHydration = nil
    return payload, mode, reason
end

return Bridge
