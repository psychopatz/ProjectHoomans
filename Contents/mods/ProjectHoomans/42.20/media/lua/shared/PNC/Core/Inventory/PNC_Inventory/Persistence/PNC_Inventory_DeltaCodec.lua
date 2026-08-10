-- PNC template-plus-delta persistence codec.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Internal = PNC.Inventory.Internal
local Core = PNC.Core

local function tablesEqual(left, right)
    local key
    local value
    if left == right then return true end
    if type(left) ~= "table" or type(right) ~= "table" then
        return false
    end
    for key, value in pairs(left) do
        if type(value) == "table" then
            if not tablesEqual(value, right[key]) then return false end
        elseif value ~= right[key] then
            return false
        end
    end
    for key, _ in pairs(right) do
        if left[key] == nil then return false end
    end
    return true
end

local function applySavedSlots(inv, item, changed)
    if changed.wornSlot == nil and changed.attachedSlot == nil and changed.equipSlot == nil then
        return
    end
    Internal.clearItemRefs(inv, item.id)
    if changed.wornSlot == false then
        item.wornSlot = nil
    else
        item.wornSlot = Internal.normalizeString(changed.wornSlot)
    end
    if changed.attachedSlot == false then
        item.attachedSlot = nil
    else
        item.attachedSlot = Internal.normalizeString(changed.attachedSlot)
    end
    if changed.equipSlot == false then
        item.equipSlot = nil
    else
        item.equipSlot = Internal.normalizeString(changed.equipSlot)
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

function Internal.applySavedDelta(record, inv, delta)
    local unresolved = 0
    local templateKey
    local changed
    local item
    local i
    if type(delta) ~= "table" then return end
    for i = 1, #(delta.removedTemplateKeys or {}) do
        item = Internal.findItemByTemplateKey(inv, delta.removedTemplateKeys[i])
        if item then
            Internal.removeItemByID(inv, item.id)
        else
            unresolved = unresolved + 1
        end
    end
    for i = 1, #(delta.moved or {}) do
        changed = delta.moved[i]
        item = changed and changed.templateKey
            and Internal.findItemByTemplateKey(inv, changed.templateKey)
            or nil
        if item then
            Internal.setItemContainer(inv, item, Internal.resolveSavedContainer(inv, changed.to))
        else
            unresolved = unresolved + 1
        end
    end
    if type(delta.changed) == "table" then
        for templateKey, changed in pairs(delta.changed) do
            item = Internal.findItemByTemplateKey(inv, templateKey)
            if item and type(changed) == "table" then
                if changed.stack ~= nil then
                    item.stack = math.max(1, math.floor(tonumber(changed.stack) or item.stack or 1))
                end
                if changed.uses == false then
                    item.uses = nil
                elseif changed.uses ~= nil then
                    item.uses = tonumber(changed.uses)
                end
                if changed.cond == false then
                    item.cond = nil
                elseif changed.cond ~= nil then
                    item.cond = tonumber(changed.cond)
                end
                if changed.ammoCount ~= nil then
                    if changed.ammoCount == false then
                        item.ammoCount = nil
                    else
                        item.ammoCount = math.max(0,
                            math.floor(tonumber(changed.ammoCount) or 0))
                    end
                end
                if changed.fav ~= nil then item.fav = changed.fav == true end
                if changed.interactionLocked ~= nil then
                    item.interactionLocked = changed.interactionLocked == true
                    item.interactionLockReason = item.interactionLocked
                        and Internal.normalizeString(
                            changed.interactionLockReason
                        )
                        or nil
                end
                if changed.interactionLockReason == false then
                    item.interactionLockReason = nil
                elseif changed.interactionLockReason ~= nil then
                    item.interactionLockReason = Internal.normalizeString(
                        changed.interactionLockReason
                    )
                end
                if changed.itemState == false then
                    item.itemState = {}
                elseif type(changed.itemState) == "table" then
                    item.itemState = Internal.sanitizeItemState(
                        changed.itemState
                    )
                end
                if changed.container ~= nil then
                    Internal.setItemContainer(inv, item,
                        Internal.resolveSavedContainer(inv, changed.container))
                end
                applySavedSlots(inv, item, changed)
            elseif type(changed) == "table" then
                unresolved = unresolved + 1
            end
        end
    end
    for i = 1, #(delta.added or {}) do
        changed = delta.added[i]
        if type(changed) == "table" then
            changed = Core.DeepCopy(changed)
            changed.container = Internal.resolveSavedContainer(inv, changed.container)
            Internal.createItem(record, inv, changed)
        end
    end
    if unresolved > 0 and Core.LogWarn then
        Core.LogWarn("PNC inventory discarded unresolved template deltas npc="
            .. tostring(record and record.id)
            .. " count=" .. tostring(unresolved))
    end
end

function Internal.buildCompactDelta(record, inv)
    local template = Internal.buildTemplateSnapshot(record)
    local removedTemplateKeys = {}
    local moved = {}
    local changed = {}
    local added = {}
    local templateItem
    local item
    local itemID
    local itemChanges
    for itemID, item in pairs(inv.items or {}) do
        if item.templateKey then
            templateItem = Internal.findItemByTemplateKey(template, item.templateKey)
            if not templateItem then
                added[#added + 1] = Internal.itemToPersistencePayload(item)
            else
                if item.container ~= templateItem.container then
                    moved[#moved + 1] = {
                        templateKey = item.templateKey,
                        to = item.container,
                    }
                end
                itemChanges = {}
                if (tonumber(item.stack) or 1)
                    ~= (tonumber(templateItem.stack) or 1)
                then itemChanges.stack = item.stack end
                if tonumber(item.uses) ~= tonumber(templateItem.uses)
                then
                    itemChanges.uses = item.uses ~= nil
                        and item.uses or false
                end
                if tonumber(item.cond) ~= tonumber(templateItem.cond)
                then
                    itemChanges.cond = item.cond ~= nil
                        and item.cond or false
                end
                if item.ammoCount ~= templateItem.ammoCount then
                    itemChanges.ammoCount = item.ammoCount ~= nil
                        and item.ammoCount or false
                end
                if (item.fav == true) ~= (templateItem.fav == true) then
                    itemChanges.fav = item.fav == true
                end
                if (item.interactionLocked == true)
                    ~= (templateItem.interactionLocked == true)
                then
                    itemChanges.interactionLocked =
                        item.interactionLocked == true
                end
                if item.interactionLockReason
                    ~= templateItem.interactionLockReason
                then
                    itemChanges.interactionLockReason =
                        item.interactionLockReason or false
                end
                local itemState = Internal.sanitizeItemState(
                    item.itemState
                )
                local templateItemState = Internal.sanitizeItemState(
                    templateItem.itemState
                )
                if not tablesEqual(itemState, templateItemState) then
                    itemChanges.itemState =
                        Internal.countMapEntries(itemState) > 0
                            and itemState or false
                end
                if item.wornSlot ~= templateItem.wornSlot then
                    itemChanges.wornSlot = item.wornSlot or false
                end
                if item.attachedSlot ~= templateItem.attachedSlot then
                    itemChanges.attachedSlot = item.attachedSlot or false
                end
                if item.equipSlot ~= templateItem.equipSlot then
                    itemChanges.equipSlot = item.equipSlot or false
                end
                if Internal.countMapEntries(itemChanges) > 0 then
                    changed[item.templateKey] = itemChanges
                end
            end
        else
            added[#added + 1] = Internal.itemToPersistencePayload(item)
        end
    end
    for itemID, item in pairs(template.items or {}) do
        if item.templateKey and not Internal.findItemByTemplateKey(inv, item.templateKey) then
            removedTemplateKeys[#removedTemplateKeys + 1] = item.templateKey
        end
    end
    return {
        added = added,
        removedTemplateKeys = removedTemplateKeys,
        moved = moved,
        changed = changed,
    }
end
