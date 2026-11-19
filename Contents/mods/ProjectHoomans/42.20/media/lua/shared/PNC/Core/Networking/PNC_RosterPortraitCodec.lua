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

local function convert(source, schema, decoding)
    if type(source) ~= "table" then return nil end
    local output = {}
    if schema.slots then
        local count = 0
        for slot, state in pairs(source) do
            count = count + 1
            if count > 64 or type(slot) ~= "string" or #slot > 128 then return nil end
            local value = convert(state, schema.slots, decoding)
            if not value then return nil end
            output[slot] = value
        end
        return output
    end
    local names = decoding and reverse[schema] or schema
    local nested = children[schema]
    for key, value in pairs(source) do
        local alias = names[key]
        if not alias then return nil end
        local child = nested and nested[decoding and alias or key]
        if child then
            value = convert(value, child, decoding)
            if not value then return nil end
        end
        output[alias] = value
    end
    return output
end

function Codec.Pack(value)
    return convert(value, portrait, false)
end

function Codec.Unpack(value)
    if type(value) ~= "table" or type(value.i) ~= "number"
        or type(value.a) ~= "table" or type(value.e) ~= "table"
    then
        return nil
    end
    return convert(value, portrait, true)
end

return Codec
