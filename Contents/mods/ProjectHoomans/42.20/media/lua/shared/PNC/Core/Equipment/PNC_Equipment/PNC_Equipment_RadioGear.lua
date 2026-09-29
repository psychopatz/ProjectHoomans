--[[
    Colonist radio gear.

    A colonist can only be reached by radio while they carry two-way radio gear
    on their person. The equipment model is the single source of truth:
    `record.equipment.attached` is authored at spawn from the archetype loadout
    and mirrored back from the inventory on every mutation, so the same
    predicate answers for a materialized body and for an abstract record.

    Presentation (an item visibly clipped to the belt) is a separate, optional
    lane: ApplyToBody only ever adds, never clears, so a failure here degrades
    the visual without ever breaking the radio command gate.
]]

PNC = PNC or {}
PNC.Equipment = PNC.Equipment or {}

local Equipment = PNC.Equipment
local Core = PNC.Core

local RadioGear = Equipment.RadioGear or {}
Equipment.RadioGear = RadioGear

-- The inventory module is resolved per call: this file loads before it in some
-- compositions, and a stale capture would silently disable radio adoption.
local function inventoryModule()
    return PNC.Inventory
end

-- Belt/webbing locations that vanilla radio gear attaches to. "Walkie Belt
-- Right" is the first entry of Internal.AttachmentTypeSlotPriority.Walkie, so
-- it is the authored default and only a fallback if that table is missing.
RadioGear.DEFAULT_LOCATION = "Walkie Belt Right"
RadioGear.PREFERRED_SLOT_TYPE = "SmallBeltRight"
RadioGear.DEFAULT_FULL_TYPE = "Base.WalkieTalkie2"

-- Vanilla script names, used only when the item script cannot be inspected.
local RADIO_NAME_PATTERN = "Walkie"

local typeCache = {}

function RadioGear.IsRadioType(fullType)
    local key
    local cached
    local item
    local attachmentType
    local ok
    if type(fullType) ~= "string" or fullType == "" then return false end
    key = fullType
    cached = typeCache[key]
    if cached ~= nil then return cached end
    item = Equipment.CreateItem and Equipment.CreateItem(fullType) or nil
    if item then
        ok, attachmentType = pcall(function() return item:getAttachmentType() end)
        if ok and type(attachmentType) == "string" then
            cached = attachmentType == "Walkie"
            typeCache[key] = cached
            return cached
        end
    end
    -- Script lookup unavailable: fall back to the vanilla naming so the gate
    -- still fails closed on obviously unrelated gear.
    cached = string.find(fullType, RADIO_NAME_PATTERN, 1, true) ~= nil
    typeCache[key] = cached
    return cached
end

local function consider(sources, fullType, slot)
    if RadioGear.IsRadioType(fullType) then
        sources.equipped = true
        sources.fullType = sources.fullType or tostring(fullType)
        sources.location = sources.location or slot
    end
end

-- Reports whether the record carries radio gear, and where. Reads the
-- authoritative equipment mirror first, then the compact inventory so a record
-- whose equipment mirror has not been rebuilt yet still answers correctly.
function RadioGear.Describe(record)
    local output = { equipped = false, fullType = nil, location = nil }
    local equipment
    local inv
    local slot
    local fullType
    if type(record) ~= "table" then return output end
    equipment = record.equipment
    if type(equipment) == "table" then
        for slot, fullType in pairs(equipment.attached or {}) do
            consider(output, fullType, tostring(slot))
        end
        for slot, fullType in pairs(equipment.worn or {}) do
            consider(output, fullType, tostring(slot))
        end
        consider(output, equipment.primaryFullType, "primary")
        consider(output, equipment.secondaryFullType, "secondary")
    end
    if output.equipped then return output end
    inv = record.inventory
    if type(inv) == "table" then
        for itemID, item in pairs(inv.items or {}) do
            if type(item) == "table"
                and (item.attachedSlot or item.wornSlot or item.equipSlot)
            then
                consider(output, item.type,
                    item.attachedSlot or item.wornSlot or item.equipSlot
                        or tostring(itemID))
            end
        end
    end
    return output
end

function RadioGear.HasEquipped(record)
    return RadioGear.Describe(record).equipped == true
end

local function occupiedLocations(equipment)
    local output = {}
    for slot, _ in pairs(equipment and equipment.attached or {}) do
        output[tostring(slot)] = true
    end
    return output
end

function RadioGear.ResolveLocation(fullType, equipment)
    local item = Equipment.CreateItem and Equipment.CreateItem(fullType) or nil
    local location
    if not item or not Equipment.ResolveAttachedLocation then
        return nil
    end
    location = Equipment.ResolveAttachedLocation(
        item,
        RadioGear.PREFERRED_SLOT_TYPE,
        occupiedLocations(equipment)
    )
    return location or nil
end

-- Moves radio gear that is already in the colonist inventory onto their belt.
-- Used when a colonist is handed a radio; the equipment data is the
-- authoritative result and the visual is applied by the caller's equipment
-- refresh.
function RadioGear.AdoptFromInventory(record, itemID, fullType)
    local equipment
    local inventory
    local location
    if not record or not itemID or not fullType then
        return false, "missing_argument"
    end
    -- Argument validation precedes state so a caller that hands over the wrong
    -- item always learns that, instead of being told the colonist is equipped.
    if not RadioGear.IsRadioType(fullType) then return false, "not_radio_gear" end
    if RadioGear.HasEquipped(record) then return false, "already_equipped" end
    inventory = inventoryModule()
    if not inventory or type(inventory.SetAttached) ~= "function" then
        return false, "inventory_mutation_unavailable"
    end
    equipment = Equipment.EnsureRecordEquipment
        and Equipment.EnsureRecordEquipment(record) or record.equipment
    location = RadioGear.ResolveLocation(fullType, equipment)
    if not location then return false, "no_attachment_location" end
    return inventory.SetAttached(record, itemID, location, "radio_gear_issued")
end

-- Belt presentation for a materialized body. Deliberately additive: it never
-- clears the attachment map, so a holstered weapon is never disturbed and a
-- failure cannot cascade into the other equipment lanes.
function RadioGear.ApplyToBody(zombie, equipment)
    local entries
    local applied = 0
    local failed = 0
    local i
    local entry
    local item
    local ok
    local errorMessage
    if not zombie or type(equipment) ~= "table" then
        return false, "missing_body_or_equipment"
    end
    if not Equipment.GetOrderedAttachedEntries then
        return false, "attachment_lookup_unavailable"
    end
    entries = Equipment.GetOrderedAttachedEntries(equipment)
    for i = 1, #entries do
        entry = entries[i]
        if RadioGear.IsRadioType(entry.fullType) then
            item = Equipment.CreateItem and Equipment.CreateItem(entry.fullType)
            ok = false
            errorMessage = "item_unavailable"
            if item then
                ok, errorMessage = Equipment.Internal.safeInvoke(
                    zombie,
                    "setAttachedItem",
                    entry.location,
                    item
                )
                if ok == true then
                    if item.setAttachedToModel then
                        item:setAttachedToModel(entry.location)
                    end
                    if item.setAttachedSlotType and entry.slotType then
                        item:setAttachedSlotType(entry.slotType)
                    end
                end
            end
            if ok == true then
                applied = applied + 1
            else
                failed = failed + 1
                if Core and Core.LogWarn then
                    Core.LogWarn("PNC radio gear failed to attach "
                        .. tostring(entry.fullType) .. " at "
                        .. tostring(entry.location) .. ": "
                        .. tostring(errorMessage))
                end
            end
        end
    end
    if failed > 0 then
        return false, "radio:applied=" .. tostring(applied)
            .. ",failed=" .. tostring(failed)
    end
    return true, "radio:" .. tostring(applied)
end

return RadioGear
