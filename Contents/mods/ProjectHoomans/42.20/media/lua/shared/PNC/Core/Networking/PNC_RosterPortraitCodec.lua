-- Wire aliases for already resolved portrait data. Asset IDs, variant
-- values, native appearance provenance, and authored seeds are untouched.
local Codec = {}
Codec.Fingerprint = "pnc.roster-portrait.aliases.v1"

local visual = {
    fullType = "f", baseTexture = "b", hue = "h", textureChoice = "t",
    decal = "d", modelIndex = "m", customColor = "c", tint = "i", color = "r",
}
local appearance = {
    outfit = "o", outfitMode = "m", skinTexture = "s", skinColor = "c",
    hairModel = "h", beardModel = "b", hairStubble = "t", beardStubble = "u",
    chestHair = "e", hairColor = "r", outfitItems = "i", outfitItemSpecs = "a",
}
local equipment = {
    primaryFullType = "p", secondaryFullType = "s", worn = "w",
    wornVisuals = "v", attached = "a", primaryVisual = "q",
}
local portrait = {
    identitySeed = "i", revision = "r", isFemale = "f", faceOnly = "b",
    appearance = "a", equipment = "e",
}

local visualMap = { slots = visual }
local children = {
    [portrait] = { appearance = appearance, equipment = equipment },
    [equipment] = { wornVisuals = visualMap, primaryVisual = visual },
}

local reverse = {}
for _, schema in ipairs({ visual, appearance, equipment, portrait }) do
    local inverse = {}
    for key, alias in pairs(schema) do inverse[alias] = key end
    reverse[schema] = inverse
end

local function convert(source, schema, decoding, validateOnly)
    if type(source) ~= "table" then return nil end
    local output = not validateOnly and {} or nil
    if schema.slots then
        local count = 0
        for slot, state in pairs(source) do
            count = count + 1
            if count > 64 or type(slot) ~= "string" or #slot > 128 then return nil end
            local value = convert(state, schema.slots, decoding, validateOnly)
            if not value then return nil end
            if output then output[slot] = value end
        end
        return output or true
    end
    local names = decoding and reverse[schema] or schema
    local nested = children[schema]
    for key, value in pairs(source) do
        local alias = names[key]
        if not alias then return nil end
        local child = nested and nested[decoding and alias or key]
        if child then
            value = convert(value, child, decoding, validateOnly)
            if not value then return nil end
        end
        if output then output[alias] = value end
    end
    return output or true
end

local groups = { appearance = appearance, equipment = equipment }

function Codec.HasField(group, field)
    return groups[group] ~= nil and groups[group][field] ~= nil
end

local function finite(value)
    return type(value) == "number" and value > -math.huge and value < math.huge
end

local function boundedString(value)
    return type(value) == "string" and #value <= 128
end

local function color(value)
    return type(value) == "table" and finite(value.r) and finite(value.g)
        and finite(value.b) and finite(value.a)
end

local function visualState(value)
    if type(value) ~= "table" or type(value.customColor) ~= "boolean" then return false end
    for _, key in ipairs({ "fullType", "decal" }) do
        if value[key] ~= nil and not boundedString(value[key]) then return false end
    end
    for _, key in ipairs({ "baseTexture", "hue", "textureChoice", "modelIndex" }) do
        if value[key] ~= nil and not finite(value[key]) then return false end
    end
    return (value.tint == nil or color(value.tint)) and (value.color == nil or color(value.color))
end

local function slotMap(value, validate)
    if type(value) ~= "table" then return false end
    local count = 0
    for key, child in pairs(value) do
        count = count + 1
        if count > 64 or not boundedString(key) or not validate(child) then return false end
    end
    return true
end

local function itemList(value)
    if type(value) ~= "table" or #value > 64 then return false end
    local count = 0
    for key, item in pairs(value) do
        if not finite(key) or key < 1 or key > #value or key % 1 ~= 0
            or not boundedString(item)
        then
            return false
        end
        count = count + 1
    end
    return count == #value
end

local function serializable(value, budget, depth)
    budget.remaining = budget.remaining - 1
    if budget.remaining < 0 or depth > 16 then return false end
    local kind = type(value)
    if kind == "table" then
        for key, child in pairs(value) do
            if (type(key) ~= "string" and not finite(key))
                or not serializable(child, budget, depth + 1)
            then
                return false
            end
        end
        return true
    end
    return kind == "string" or kind == "boolean" or finite(value)
end

function Codec.ValidateResolved(value)
    if type(value) ~= "table" or not finite(value.identitySeed)
        or value.identitySeed < 1 or value.identitySeed % 1 ~= 0
        or not finite(value.revision) or value.revision < 0 or value.revision % 1 ~= 0
        or type(value.isFemale) ~= "boolean" or value.faceOnly ~= true
        or type(value.appearance) ~= "table" or type(value.equipment) ~= "table"
    then
        return false
    end
    local look, gear = value.appearance, value.equipment
    for _, key in ipairs({ "outfit", "outfitMode", "skinTexture", "hairModel", "beardModel" }) do
        if look[key] ~= nil and not boundedString(look[key]) then return false end
    end
    for _, key in ipairs({ "primaryFullType", "secondaryFullType" }) do
        if gear[key] ~= nil and not boundedString(gear[key]) then return false end
    end
    return type(look.hairStubble) == "boolean" and type(look.beardStubble) == "boolean"
        and (look.chestHair == nil or type(look.chestHair) == "boolean")
        and (look.hairColor == nil or color(look.hairColor))
        and (look.skinColor == nil or color(look.skinColor))
        and itemList(look.outfitItems) and type(look.outfitItemSpecs) == "table"
        and slotMap(gear.worn, boundedString) and slotMap(gear.attached, boundedString)
        and slotMap(gear.wornVisuals, visualState)
        and (gear.primaryVisual == nil or visualState(gear.primaryVisual))
        and serializable(value, { remaining = 8192 }, 0)
end

function Codec.IsProjection(value)
    return Codec.ValidateResolved(value) and convert(value, portrait, false, true) ~= nil
end

function Codec.Pack(value)
    if not Codec.ValidateResolved(value) then return nil end
    return convert(value, portrait, false)
end

function Codec.Unpack(value)
    local unpacked = convert(value, portrait, true)
    if Codec.ValidateResolved(unpacked) then return unpacked end
    return nil
end

return Codec
