local Inventory = PNC.Inventory
local Internal = Inventory.Internal

local function buildItem(record, spec, fullType, profile)
    return {
        id = Internal.normalizeString(spec.id)
            or Internal.nextItemID(record),
        type = fullType,
        stack = math.max(
            1,
            math.floor(tonumber(spec.stack) or tonumber(spec.uses) or 1)
        ),
        uses = tonumber(spec.uses),
        cond = tonumber(spec.cond),
        ammoCount = spec.ammoCount ~= nil
            and math.max(0, math.floor(tonumber(spec.ammoCount) or 0))
            or nil,
        fav = spec.fav == true,
        interactionLocked = spec.interactionLocked == true,
        interactionLockReason = Internal.normalizeString(
            spec.interactionLockReason
        ),
        container = Internal.normalizeString(spec.container) or "root",
        bagContainer = Internal.normalizeString(spec.bagContainer),
        maxWeight = tonumber(spec.maxWeight)
            or (profile.capacity > 0 and profile.capacity or nil),
        weightReduction = spec.weightReduction ~= nil
            and Internal.normalizeItemWeightReduction(spec.weightReduction)
            or profile.weightReduction,
        wearableSlot = Internal.normalizeString(spec.wearableSlot)
            or profile.wearableSlot,
        templateKey = Internal.normalizeString(spec.templateKey),
        legacyTemplateKey = Internal.normalizeString(spec.legacyTemplateKey),
        preferredContainer = Internal.normalizeString(spec.preferredContainer),
        wornSlot = Internal.normalizeString(spec.wornSlot),
        attachedSlot = Internal.normalizeString(spec.attachedSlot),
        equipSlot = Internal.normalizeString(spec.equipSlot),
        customName = Internal.normalizeString(spec.customName),
        identityNPCId = Internal.normalizeString(spec.identityNPCId),
        identityNPCName = Internal.normalizeString(spec.identityNPCName),
        itemState = Internal.sanitizeItemState(spec.itemState),
    }
end

local function attachItem(inv, item)
    inv.items[item.id] = item
    Internal.addItemToContainer(inv, item.id, item.container)
    if item.maxWeight and item.maxWeight > 0 then
        Internal.ensureContainer(
            inv,
            "bag_" .. tostring(item.id),
            item.maxWeight
        )
        item.bagContainer = "bag_" .. tostring(item.id)
    elseif item.bagContainer then
        Internal.ensureContainer(inv, item.bagContainer, 0)
    end
    if item.wornSlot then inv.worn[item.wornSlot] = item.id end
    if item.attachedSlot then inv.attached[item.attachedSlot] = item.id end
    if item.equipSlot == "primary" then
        inv.equipped.primary = item.id
    elseif item.equipSlot == "secondary" then
        inv.equipped.secondary = item.id
    elseif item.equipSlot == "bag" then
        inv.equipped.bag = item.id
    end
end

function Internal.createItem(record, inv, spec)
    local fullType = Internal.normalizeItemType(spec.type)
    local item
    if not fullType then return nil end
    item = buildItem(
        record,
        spec,
        fullType,
        Internal.getContainerProfile(fullType)
    )
    attachItem(inv, item)
    return item
end

function Internal.normalizeLegacyBagSlot(inv)
    local itemID = inv and inv.equipped and inv.equipped.bag or nil
    local item = itemID and inv.items and inv.items[itemID] or nil
    local slot
    if not item then
        if inv and inv.equipped then inv.equipped.bag = nil end
        return false
    end
    slot = Internal.normalizeString(item.wearableSlot)
        or Internal.getContainerProfile(item.type).wearableSlot
    item.equipSlot = nil
    inv.equipped.bag = nil
    if slot and (not inv.worn[slot] or inv.worn[slot] == item.id) then
        item.wearableSlot = slot
        item.wornSlot = slot
        inv.worn[slot] = item.id
        return true
    end
    return false
end

function Internal.ensureIdentityCard(record, inv)
    local item
    local displayName
    if not record or not inv or type(inv.items) ~= "table" then
        return nil
    end
    item = Internal.findItemByTemplateKey(inv, "tmpl:identity_card:0")
    displayName = tostring(
        record.name or record.displayName or "Unknown NPC"
    )
    if not item then
        item = Internal.createItem(record, inv, {
            type = "Base.IDcard",
            container = "root",
            templateKey = "tmpl:identity_card:0",
        })
    end
    if item then
        -- Repair generator revision 3's incorrectly-cased script item ID.
        item.type = "Base.IDcard"
        item.customName = "ID Card: " .. displayName
        item.identityNPCId = tostring(record.id)
        item.identityNPCName = displayName
        item.interactionLocked = true
        item.interactionLockReason = "identity_card"
    end
    return item
end
