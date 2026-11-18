-- Canonical draft edits. No live player, world inventory, or second save format.
require "PNC/Core/Identity/PNC_Identity_Appearance"
require "PNC/Identity/PNC_UniqueNPCOutfitCapture"
PNC.NPCAuthoringLoadout = PNC.NPCAuthoringLoadout or {}
local Model = PNC.NPCAuthoringLoadout
local Appearance = PNC.Identity.Appearance
local function copy(value)
    if type(value) ~= "table" then return value end
    local out = {}
    for key, child in pairs(value) do out[key] = copy(child) end
    return out
end

local function slotKey(value)
    return string.lower(string.match(tostring(value or ""), "([^:]+)$") or tostring(value or ""))
end

function Model.Items(draft)
    return copy(draft and draft.startingItems or {})
end

local function editSlot(draft, slot, spec)
    if not draft or not slot then return false, "draft_unavailable" end
    local bagSlot = slot.kind == "worn" and spec and spec.maxWeight ~= nil
    if slot.kind == "worn" then
        local appearance = Appearance.Normalize(draft.appearance)
        for location in pairs(appearance.slots) do
            if location ~= slot.id and slotKey(location) == slotKey(slot.id) then appearance.slots[location] = nil end
        end
        if spec then
            for location, policy in pairs(appearance.slots) do
                if location ~= slot.id and policy.mode == "item"
                    and Appearance.AreExclusive(location, slot.id)
                then return false, "clothing_conflict" end
            end
        end
        appearance.slots[slot.id] = spec and not bagSlot and { mode = "item", type = spec.type,
            wornSlot = slot.id, itemState = copy(spec.itemState) } or { mode = "none" }
        -- Slot policy overrides the named outfit; unmodified generated slots
        -- retain their seeded choices rather than adopting preview clothing.
        appearance.outfit = { mode = "none" }
        draft.appearance = appearance
        draft.appearanceAuthored = draft.appearanceAuthored or {}
        draft.appearanceAuthored.appearance = true
    end
    do
        local items = Model.Items(draft)
        local output = {}
        for index, item in ipairs(items) do
            local replace = slot.kind == "worn" and item.wornSlot and slotKey(item.wornSlot) == slotKey(slot.id)
                or slot.kind == "held" and item.equipSlot == slot.id
                or slot.kind == "attached" and item.attachedSlot == slot.id
                or slot.kind == "item" and (slot.index and index == slot.index
                    or not slot.index and slot.id ~= nil and item.key == slot.id)
            if not replace then output[#output + 1] = item end
        end
        if spec and (slot.kind ~= "worn" or bagSlot) then
            if #output >= 128 then return false, "item_limit" end
            local item = copy(spec)
            item.equipSlot, item.attachedSlot = nil, nil
            if bagSlot then item.wornSlot = slot.id end
            if slot.kind == "held" then item.equipSlot = slot.id end
            if slot.kind == "attached" then item.attachedSlot = slot.id end
            item.key = slot.kind == "carry" and "authoring:carry:" .. tostring(#items + 1)
                or "authoring:" .. slot.kind .. ":" .. tostring(slot.id)
            local seen = {}
            for _, existing in ipairs(output) do seen[existing.key] = true end
            while seen[item.key] do item.key = item.key .. ":new" end
            output[#output + 1] = item
        end
        if slot.kind == "held" then
            draft.equipmentSpawnMode = "none"
        end
        if slot.kind ~= "worn" or bagSlot or #output ~= #items then
            draft.startingItems = output
            draft.authoredFields = draft.authoredFields or {}
            draft.authoredFields.startingItems = true
            draft.authoringClears = draft.authoringClears or {}
            draft.authoringClears.startingItems = #output == 0 or nil
        end
    end
    -- Runtime export must not overwrite newly authored startingItems.
    draft.runtimeRecord = nil
    draft._dirty = true
    return true
end

function Model.SetSlot(draft, slot, spec, baseline)
    if not draft then return false, "draft_unavailable" end
    local fields = { "appearance", "appearanceAuthored", "startingItems",
        "equipmentSpawnMode", "authoredFields", "authoringClears" }
    local candidate = {}
    for _, field in ipairs(fields) do candidate[field] = copy(draft[field]) end
    if slot and slot.kind == "worn" and baseline then
        local appearance = Appearance.Normalize(candidate.appearance)
        for _, item in pairs(baseline.inventory and baseline.inventory.items or {}) do
            local existing = item.wornSlot and appearance.slots[item.wornSlot]
            if item.wornSlot and slotKey(item.wornSlot) ~= slotKey(slot.id) and not item.maxWeight
                and (not existing or existing.mode == "random")
            then
                appearance.slots[item.wornSlot] = { mode = "item", type = item.type,
                    wornSlot = item.wornSlot, itemState = copy(item.itemState) }
            end
        end
        candidate.appearance = appearance
    end
    local ok, reason = editSlot(candidate, slot, spec)
    if not ok then return false, reason end
    for _, field in ipairs(fields) do draft[field] = candidate[field] end
    draft.runtimeRecord = nil
    draft._dirty = true
    return true
end

function Model.SetOutfit(draft, appearance)
    local items = {}
    for _, item in ipairs(draft.startingItems or {}) do
        if not item.wornSlot or item.equipSlot or item.maxWeight or item.bagContainer then items[#items + 1] = copy(item) end
    end
    draft.appearance = copy(appearance)
    draft.startingItems = items
    draft.authoredFields = draft.authoredFields or {}
    draft.authoredFields.startingItems = true
    draft.authoringClears = draft.authoringClears or {}
    draft.authoringClears.startingItems = #items == 0 or nil
    draft.runtimeRecord = nil
    draft._dirty = true
end

Model.CaptureOutfit = PNC.UniqueNPCOutfitCapture.Capture

return Model
