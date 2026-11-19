local Codec = require "PNC/Core/Networking/PNC_RosterPortraitCodec"
local Patch = { Protocol = "pnc.roster-portrait.patch.v1" }

local MAX_CHANGES = 32
local slotMaps = { worn = true, wornVisuals = true, attached = true }
local defaultFields = {
    appearance = { hairStubble = false, beardStubble = false, outfitItems = {}, outfitItemSpecs = {} },
    equipment = { worn = {}, wornVisuals = {}, attached = {} },
}

function Patch.Equal(first, second)
    if first == second then return true end
    if type(first) ~= "table" or type(second) ~= "table" then return false end
    for key, value in pairs(first) do
        if not Patch.Equal(value, second[key]) then return false end
    end
    for key, _ in pairs(second) do
        if first[key] == nil then return false end
    end
    return true
end

local function copy(source)
    local output = {}
    for key, value in pairs(source) do output[key] = value end
    return output
end

local function append(changes, group, field, slot, value)
    local default = defaultFields[group][field]
    local op
    if value == nil then
        op = "clear"
    elseif slot == nil and default ~= nil and Patch.Equal(value, default) then
        op = "default"
    else
        op = "set"
    end
    local change = { group = group, field = field, slot = slot, op = op }
    if op == "set" then change.value = value end
    changes[#changes + 1] = change
end

local function diffSlots(changes, field, before, after)
    for slot, value in pairs(after) do
        if not Patch.Equal(before[slot], value) then
            append(changes, "equipment", field, slot, value)
        end
    end
    for slot, _ in pairs(before) do
        if after[slot] == nil then append(changes, "equipment", field, slot, nil) end
    end
end

function Patch.Create(before, after)
    if not Codec.IsProjection(before) or not Codec.IsProjection(after) then return nil end
    for key, value in pairs(before) do
        if key ~= "appearance" and key ~= "equipment" and value ~= after[key] then return nil end
    end
    for key, value in pairs(after) do
        if key ~= "appearance" and key ~= "equipment" and value ~= before[key] then return nil end
    end
    local changes = {}
    for _, group in ipairs({ "appearance", "equipment" }) do
        local old, new = before[group], after[group]
        for field, value in pairs(new) do
            if group == "equipment" and slotMaps[field]
                and type(value) == "table" and type(old[field]) == "table"
            then
                diffSlots(changes, field, old[field], value)
            elseif not Patch.Equal(old[field], value) then
                append(changes, group, field, nil, value)
            end
        end
        for field, _ in pairs(old) do
            if new[field] == nil then append(changes, group, field, nil, nil) end
        end
    end
    if #changes > 0 and #changes <= MAX_CHANGES then return changes end
    return nil
end

local function applyChange(groups, seen, change)
    if type(change) ~= "table" or type(change.group) ~= "string"
        or type(change.field) ~= "string" or not Codec.HasField(change.group, change.field)
    then
        return false
    end
    for key, _ in pairs(change) do
        if key ~= "group" and key ~= "field" and key ~= "slot"
            and key ~= "op" and key ~= "value"
        then
            return false
        end
    end
    local group, field, slot = change.group, change.field, change.slot
    if slot ~= nil and (group ~= "equipment" or not slotMaps[field]
        or type(slot) ~= "string" or #slot == 0 or #slot > 128)
    then
        return false
    end
    local fieldKey = group .. ":" .. field
    local uniqueKey = fieldKey
    if slot ~= nil then
        if seen[fieldKey] == true then return false end
        seen[fieldKey] = "slots"
        uniqueKey = fieldKey .. ":" .. slot
    end
    if seen[uniqueKey] then return false end
    seen[uniqueKey] = true

    local target, key = groups[group], field
    local default = defaultFields[group][field]
    if slot ~= nil then
        if type(target[field]) ~= "table" then return false end
        target, key = target[field], slot
    end
    if change.op == "set" then
        if change.value == nil then return false end
        target[key] = change.value
    elseif change.op == "clear" then
        if change.value ~= nil or (slot == nil and default ~= nil) then return false end
        target[key] = nil
    elseif change.op == "default" then
        if change.value ~= nil or slot ~= nil or default == nil then return false end
        if type(default) == "table" then
            target[key] = {}
        else
            target[key] = default
        end
    else
        return false
    end
    return true
end

function Patch.Apply(portrait, changes)
    if type(changes) ~= "table" or #changes == 0 or #changes > MAX_CHANGES
        or not Codec.IsProjection(portrait)
    then
        return nil
    end
    local output = copy(portrait)
    output.appearance = copy(portrait.appearance)
    output.equipment = copy(portrait.equipment)
    for field, _ in pairs(slotMaps) do
        local value = output.equipment[field]
        if type(value) == "table" then output.equipment[field] = copy(value) end
    end
    local seen = {}
    local count = 0
    for index, _ in pairs(changes) do
        if type(index) ~= "number" or index % 1 ~= 0 or index < 1 or index > #changes then
            return nil
        end
        count = count + 1
    end
    if count ~= #changes then return nil end
    for _, change in ipairs(changes) do
        if not applyChange(output, seen, change) then return nil end
    end
    if not Codec.IsProjection(output) then return nil end
    return output
end

return Patch
