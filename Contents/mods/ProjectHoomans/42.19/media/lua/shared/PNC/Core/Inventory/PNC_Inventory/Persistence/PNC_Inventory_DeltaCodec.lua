-- PNC template-plus-delta persistence codec.

PNC = PNC or {}
PNC.Inventory = PNC.Inventory or {}

local Internal = PNC.Inventory.Internal
local Core = PNC.Core

local function applySavedSlots(inv, item, changed)
    if changed.wornSlot == nil and changed.attachedSlot == nil and changed.equipSlot == nil then
        return
    end
    Internal.clearItemRefs(inv, item.id)
    item.wornSlot = Internal.normalizeString(changed.wornSlot)
    item.attachedSlot = Internal.normalizeString(changed.attachedSlot)
    item.equipSlot = Internal.normalizeString(changed.equipSlot)
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
                if changed.uses ~= nil then item.uses = tonumber(changed.uses) end
                if changed.cond ~= nil then item.cond = tonumber(changed.cond) end
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
    for itemID, item in pairs(inv.items or {}) do
        if item.templateKey then
            templateItem = Internal.findItemByTemplateKey(template, item.templateKey)
            if not templateItem then
                added[#added + 1] = Internal.itemToPayload(item)
            else
                if item.container ~= templateItem.container then
                    moved[#moved + 1] = {
                        templateKey = item.templateKey,
                        to = item.container,
                    }
                end
                if (tonumber(item.stack) or 1) ~= (tonumber(templateItem.stack) or 1)
                    or (tonumber(item.uses) or 0) ~= (tonumber(templateItem.uses) or 0)
                    or (tonumber(item.cond) or 0) ~= (tonumber(templateItem.cond) or 0)
                    or item.wornSlot ~= templateItem.wornSlot
                    or item.attachedSlot ~= templateItem.attachedSlot
                    or item.equipSlot ~= templateItem.equipSlot
                then
                    changed[item.templateKey] = {
                        stack = item.stack,
                        uses = item.uses,
                        cond = item.cond,
                        container = item.container,
                        wornSlot = item.wornSlot,
                        attachedSlot = item.attachedSlot,
                        equipSlot = item.equipSlot,
                    }
                end
            end
        else
            added[#added + 1] = Internal.itemToPayload(item)
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
