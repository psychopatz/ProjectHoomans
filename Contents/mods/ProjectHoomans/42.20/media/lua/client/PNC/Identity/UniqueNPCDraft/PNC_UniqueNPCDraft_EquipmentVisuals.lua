-- Preview-only visual continuity across inventory/body reconstruction. Match
-- logical template/placement and type, never freshly allocated runtime IDs.
local Visuals = {}
local function key(item)
    if not item or not item.type then return nil end
    local identity = item.templateKey and ('template:' .. tostring(item.templateKey))
        or item.wornSlot and ('worn:' .. tostring(item.wornSlot))
        or item.equipSlot and ('held:' .. tostring(item.equipSlot))
        or item.attachedSlot and ('attached:' .. tostring(item.attachedSlot))
    if not identity then return nil end
    return tostring(item.type) .. '|' .. identity
end
function Visuals.Remember(record)
    local equipment, output = PNC.Equipment, {}
    if not equipment or not equipment.VisualStateFromItemState then return output end
    for _, item in pairs(record and record.inventory and record.inventory.items or {}) do
        local id = key(item)
        local state = id and equipment.VisualStateFromItemState(item.itemState, item.type)
        if state then
            -- Duplicate logical keys cannot safely identify one old item.
            if output[id] ~= nil then output[id] = false else output[id] = state end
        end
    end
    return output
end
function Visuals.Restore(record, previous)
    local equipment = PNC.Equipment
    if not equipment or not equipment.VisualStateFromItemState or not equipment.StoreVisualStateInItemState then return end
    for _, item in pairs(record and record.inventory and record.inventory.items or {}) do
        local id = key(item)
        local state = id and previous and previous[id]
        if type(state) == 'table' and not equipment.VisualStateFromItemState(item.itemState, item.type) then
            equipment.StoreVisualStateInItemState(item, state)
        end
    end
end
return Visuals
