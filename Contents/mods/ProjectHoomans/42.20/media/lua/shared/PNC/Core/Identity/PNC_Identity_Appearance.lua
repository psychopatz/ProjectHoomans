--[[
    PNC Unique NPC appearance policy.

    Appearance is intentionally separate from the runtime identity seed.  A
    policy says whether a value is inherited/random, explicitly absent, or an
    exact native item.  This removes the old nil == random ambiguity while
    keeping the definition compact and compatible with the existing inventory
    itemState visual metadata.
]]

PNC = PNC or {}
PNC.Identity = PNC.Identity or {}
PNC.Identity.Appearance = PNC.Identity.Appearance or {}

local Appearance = PNC.Identity.Appearance
local Core = PNC.Core

Appearance.SCHEMA_VERSION = 2
Appearance.MODES = { random = true, none = true, item = true }

local function copy(value, seen)
    if Core and Core.DeepCopy then return Core.DeepCopy(value) end
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local output = {}
    seen[value] = output
    for key, child in pairs(value) do
        output[copy(key, seen)] = copy(child, seen)
    end
    return output
end

local function stringValue(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function modeValue(value, fallback)
    value = stringValue(value)
    if value == "explicit" or value == "selected" then value = "item" end
    if Appearance.MODES[value] then return value end
    return fallback or "random"
end

local function normalizeSlot(source)
    local input = type(source) == "table" and source or {}
    local mode = modeValue(input.mode, nil)
    local fullType = stringValue(input.type or input.fullType)
    if mode == "item" and not fullType then mode = "none" end
    return {
        mode = mode,
        type = fullType,
        wornSlot = stringValue(input.wornSlot or input.bodyLocation),
        itemState = type(input.itemState) == "table"
            and copy(input.itemState) or nil,
    }
end

function Appearance.Normalize(source, legacyOutfit)
    local input = type(source) == "table" and source or {}
    local output = {
        schemaVersion = Appearance.SCHEMA_VERSION,
        outfit = { mode = "random" },
        slots = {},
        voice = { mode = "random" },
    }
    local outfit = input.outfit
    local voice = input.voice
    local slot
    local key

    if type(outfit) == "string" and outfit ~= "" then
        output.outfit = { mode = "item", id = outfit }
    elseif type(outfit) == "table" then
        output.outfit = {
            mode = modeValue(outfit.mode, "random"),
            id = stringValue(outfit.id or outfit.name or outfit.type),
        }
        if output.outfit.mode == "item" and not output.outfit.id then
            output.outfit.mode = "random"
        end
    elseif stringValue(legacyOutfit) then
        -- Legacy outfit values were only labels used by the old runtime. Keep
        -- them as an explicit preset marker without changing old behavior.
        output.outfit = { mode = "item", id = stringValue(legacyOutfit) }
    end

    if type(input.slots) == "table" then
        for key, slot in pairs(input.slots) do
            output.slots[tostring(key)] = normalizeSlot(slot)
        end
    end

    if type(input.items) == "table" then
        for _, slot in ipairs(input.items) do
            if type(slot) == "table" and stringValue(slot.type) then
                key = stringValue(slot.wornSlot or slot.bodyLocation)
                if key and output.slots[key] == nil then
                    output.slots[key] = normalizeSlot({
                        mode = "item",
                        type = slot.type,
                        wornSlot = key,
                        itemState = slot.itemState,
                    })
                end
            end
        end
    end

    if type(voice) == "string" and voice ~= "" then
        output.voice = { mode = "item", prefix = voice }
    elseif type(voice) == "table" then
        output.voice = {
            mode = modeValue(voice.mode, "random"),
            prefix = stringValue(voice.prefix),
            type = tonumber(voice.type),
            pitch = tonumber(voice.pitch),
        }
    end
    if output.voice.mode == "item" and not output.voice.prefix
        and output.voice.type == nil and output.voice.pitch == nil
    then
        output.voice.mode = "random"
    end
    return output
end

local function nativeItem(fullType)
    local equipment = PNC.Equipment
    local item
    if not equipment or not equipment.CreateItem or not fullType then
        return nil
    end
    local ok, result = pcall(equipment.CreateItem, fullType)
    if not ok then return nil end
    item = type(result) == "table" and result[1] or result
    return item
end

function Appearance.ResolveBodyLocation(fullType)
    local item = nativeItem(fullType)
    local ok
    local location
    if not item or type(item.getBodyLocation) ~= "function" then return nil end
    ok, location = pcall(item.getBodyLocation, item)
    return ok and stringValue(location) or nil
end

local function nativeBodyLocation(value)
    local resource
    local ok
    local resolved
    if value == nil or tostring(value) == "" then return nil end
    if ItemBodyLocation and ItemBodyLocation.get
        and ResourceLocation and ResourceLocation.of
    then
        ok, resource = pcall(ResourceLocation.of, tostring(value))
        if ok and resource then
            ok, resolved = pcall(ItemBodyLocation.get, resource)
            if ok and resolved then return resolved end
        end
    end
    return value
end

-- An item/none slot is an authored clothing decision.  A random-only slot is
-- intentionally not authoritative and may coexist with a named outfit or an
-- archetype look.  This distinction lets the creator express both "use this
-- exact shirt" and "leave this body location empty" without treating nil as
-- an accidental random request.
function Appearance.HasExplicitSlots(source)
    local policy = Appearance.Normalize(source)
    for _, slot in pairs(policy.slots or {}) do
        if slot.mode == "item" or slot.mode == "none" then
            return true
        end
    end
    return false
end

function Appearance.AreExclusive(first, second)
    local group = BodyLocations and BodyLocations.getGroup
        and BodyLocations.getGroup("Human") or nil
    local left
    local right
    local success
    local result
    if not group or not group.isExclusive or tostring(first or "") == ""
        or tostring(second or "") == ""
        or tostring(first) == tostring(second)
    then
        return false
    end
    left = nativeBodyLocation(first)
    right = nativeBodyLocation(second)
    if not left or not right then return false end
    success, result = pcall(group.isExclusive, group, left, right)
    return success and result == true
end

function Appearance.Validate(source)
    local policy = Appearance.Normalize(source)
    local selected = {}
    local left
    local right
    for slot, value in pairs(policy.slots or {}) do
        if value.mode == "item" and value.type then
            selected[#selected + 1] = {
                slot = tostring(slot),
                location = tostring(value.wornSlot or slot),
            }
        end
    end
    for index = 1, #selected do
        left = selected[index]
        for otherIndex = index + 1, #selected do
            right = selected[otherIndex]
            if Appearance.AreExclusive(left.location, right.location) then
                return false, "exclusive_slots:" .. left.slot .. ":" .. right.slot
            end
        end
    end
    return true
end

local function removeSlot(items, slot)
    local output = {}
    local item
    for _, item in ipairs(items or {}) do
        if tostring(item.wornSlot or "") ~= tostring(slot or "") then
            output[#output + 1] = item
        end
    end
    return output
end

local function baseSpec(fullType)
    local slot = Appearance.ResolveBodyLocation(fullType)
    return {
        type = stringValue(fullType),
        wornSlot = slot,
        itemState = nil,
    }
end

function Appearance.Resolve(record, baseItems)
    local source = record and record.appearance
    local policy = Appearance.Normalize(source, record and record.outfit)
    local output = {}
    local base = {}
    local input
    local slot
    local item

    -- Random inherits the archetype's deterministic factory look. A named
    -- outfit is already a complete native preset, so do not append the
    -- archetype items beneath it. None deliberately starts empty.
    if policy.outfit.mode == "random" then
        for _, input in ipairs(baseItems or {}) do
            if type(input) == "table" then
                item = baseSpec(input.type)
                item.wornSlot = stringValue(input.wornSlot)
                    or item.wornSlot
                item.itemState = type(input.itemState) == "table"
                    and copy(input.itemState) or nil
                base[#base + 1] = item
            else
                item = baseSpec(input)
                if item.type then base[#base + 1] = item end
            end
        end
    end

    for slot, input in pairs(policy.slots) do
        input = normalizeSlot(input)
        if input.mode == "none" then
            base = removeSlot(base, slot)
        elseif input.mode == "item" and input.type then
            base = removeSlot(base, slot)
            base[#base + 1] = {
                type = input.type,
                wornSlot = input.wornSlot or slot,
                itemState = copy(input.itemState),
            }
        end
    end

    for _, item in ipairs(base) do
        if item.type then
            output[#output + 1] = item
        end
    end

    return {
        policy = policy,
        itemSpecs = output,
        items = (function()
            local values = {}
            for _, entry in ipairs(output) do values[#values + 1] = entry.type end
            return values
        end)(),
    }
end

function Appearance.CaptureItemSpec(item, fallbackSlot)
    if type(item) ~= "table" or not stringValue(item.type) then return nil end
    return {
        mode = "item",
        type = stringValue(item.type),
        wornSlot = stringValue(item.wornSlot) or stringValue(fallbackSlot)
            or Appearance.ResolveBodyLocation(item.type),
        itemState = type(item.itemState) == "table"
            and copy(item.itemState) or nil,
    }
end

local function signatureValue(value, output, seen)
    output = output or {}
    seen = seen or {}
    if type(value) ~= "table" then
        output[#output + 1] = tostring(value)
        return output
    end
    if seen[value] then
        output[#output + 1] = "<cycle>"
        return output
    end
    seen[value] = true
    local keys = {}
    for key in pairs(value) do
        keys[#keys + 1] = { raw = key, text = tostring(key) }
    end
    table.sort(keys, function(left, right) return left.text < right.text end)
    for _, entry in ipairs(keys) do
        output[#output + 1] = entry.text
        signatureValue(value[entry.raw], output, seen)
    end
    return output
end

function Appearance.Signature(source)
    return table.concat(signatureValue(Appearance.Normalize(source)), "|")
end

return Appearance
