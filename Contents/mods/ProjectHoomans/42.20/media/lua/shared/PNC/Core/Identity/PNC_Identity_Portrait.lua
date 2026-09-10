-- Bounded identity and current-clothing metadata for lightweight portraits.

PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

local Identity = PNC.Identity
local STRING_MAX = 128
local MAP_MAX = 64
local ARRAY_MAX = 64

local function normalizeString(value)
    if value == nil or value == "" then return nil end
    return string.sub(tostring(value), 1, STRING_MAX)
end

local function normalizeColor(color)
    if type(color) ~= "table" then return nil end
    return {
        r = math.max(0, math.min(1, tonumber(color.r) or 0)),
        g = math.max(0, math.min(1, tonumber(color.g) or 0)),
        b = math.max(0, math.min(1, tonumber(color.b) or 0)),
        a = math.max(0, math.min(1, tonumber(color.a) or 1)),
    }
end

local function normalizeVisualState(source)
    local output
    local tint
    local color
    if type(source) ~= "table" then return nil end
    output = {
        fullType = normalizeString(source.fullType or source.type),
        baseTexture = tonumber(source.baseTexture),
        textureChoice = tonumber(source.textureChoice),
        decal = normalizeString(source.decal),
        modelIndex = tonumber(source.modelIndex),
        customColor = source.customColor == true,
    }
    tint = normalizeColor(source.tint)
    color = normalizeColor(source.color)
    if tint then output.tint = tint end
    if color then output.color = color end
    if not output.fullType and not output.baseTexture
        and not output.textureChoice and not output.decal
        and not output.modelIndex and not tint and not color
    then
        return nil
    end
    return output
end

local function normalizeMap(source, valueNormalizer)
    local output = {}
    local count = 0
    local key
    local value
    if type(source) ~= "table" then return output end
    for key, value in pairs(source) do
        if count >= MAP_MAX then break end
        key = normalizeString(key)
        value = valueNormalizer(value)
        if key and value ~= nil then
            output[key] = value
            count = count + 1
        end
    end
    return output
end

local function normalizeArray(source)
    local output = {}
    local index
    local value
    if type(source) ~= "table" then return output end
    for index = 1, math.min(#source, ARRAY_MAX) do
        value = normalizeString(source[index])
        if value then output[#output + 1] = value end
    end
    return output
end

local function normalizeEquipment(source)
    local output
    if type(source) ~= "table" then return nil end
    output = {
        primaryFullType = normalizeString(source.primaryFullType),
        secondaryFullType = normalizeString(source.secondaryFullType),
        worn = normalizeMap(source.worn, normalizeString),
        wornVisuals = normalizeMap(source.wornVisuals, normalizeVisualState),
        attached = normalizeMap(source.attached, normalizeString),
    }
    output.primaryVisual = normalizeVisualState(source.primaryVisual)
    return output
end

local function stableSignature(value, depth)
    local keys = {}
    local parts = {}
    local index
    local key
    depth = tonumber(depth) or 0
    if type(value) ~= "table" then return tostring(value or "") end
    if depth > 4 then return "[depth]" end
    for key, _ in pairs(value) do keys[#keys + 1] = key end
    table.sort(keys, function(left, right)
        return tostring(left) < tostring(right)
    end)
    for index = 1, #keys do
        key = keys[index]
        parts[#parts + 1] = tostring(key) .. "="
            .. stableSignature(value[key], depth + 1)
    end
    return "{" .. table.concat(parts, ";") .. "}"
end

function Identity.NormalizePortraitSummary(source, fallback)
    local appearance
    local equipment
    if type(source) ~= "table" then
        source = type(fallback) == "table" and fallback or nil
    end
    if type(source) ~= "table" then return nil end
    appearance = type(source.appearance) == "table"
        and source.appearance or source
    equipment = normalizeEquipment(source.equipment or source.equipmentSummary)
    return {
        identitySeed = Identity.NormalizeSeed(
            source.identitySeed,
            source.id or source.name or "portrait"
        ),
        revision = math.max(0, math.floor(tonumber(source.revision) or 0)),
        isFemale = source.isFemale == true,
        faceOnly = true,
        appearance = {
            skinTexture = normalizeString(appearance.skinTexture),
            skinColor = normalizeColor(appearance.skinColor),
            hairModel = normalizeString(appearance.hairModel),
            beardModel = source.isFemale == true
                and nil
                or normalizeString(appearance.beardModel),
            hairColor = normalizeColor(appearance.hairColor),
            outfitItems = normalizeArray(appearance.outfitItems),
        },
        equipment = equipment or {
            worn = {},
            wornVisuals = {},
            attached = {},
        },
    }
end

function Identity.BuildPortraitSummary(record)
    local identity
    local appearance
    local runtime
    local cacheKey
    local summary
    local hairColor
    local skinColor
    local equipment
    if type(record) ~= "table" then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    identity = Identity.GetCharacterSummary(record)
    appearance = runtime.appearanceCache
        or Identity.RollAppearance(record)
        or {}
    hairColor = type(appearance.hairColor) == "table"
        and appearance.hairColor or {}
    skinColor = type(appearance.skinColor) == "table"
        and appearance.skinColor or {}
    equipment = record.equipment or {}
    cacheKey = table.concat({
        tostring(identity.identitySeed or 1),
        tostring(identity.isFemale == true),
        tostring(runtime.appearanceCacheKey or ""),
        tostring(appearance.skinTexture or ""),
        tostring(appearance.hairModel or ""),
        tostring(appearance.beardModel or ""),
        tostring(hairColor.r or ""),
        tostring(hairColor.g or ""),
        tostring(hairColor.b or ""),
        tostring(skinColor.r or ""),
        tostring(skinColor.g or ""),
        tostring(skinColor.b or ""),
        stableSignature(appearance.outfitItems),
        stableSignature(equipment),
    }, "|")
    if runtime.portraitSummaryCacheKey == cacheKey
        and runtime.portraitSummaryCache
    then
        return runtime.portraitSummaryCache
    end
    summary = Identity.NormalizePortraitSummary({
        id = record.id,
        identitySeed = identity.identitySeed,
        isFemale = identity.isFemale == true,
        appearance = appearance,
        equipment = equipment,
    })
    summary.revision = Identity.HashText(cacheKey)
    runtime.portraitSummaryCacheKey = cacheKey
    runtime.portraitSummaryCache = summary
    return summary
end

return Identity
