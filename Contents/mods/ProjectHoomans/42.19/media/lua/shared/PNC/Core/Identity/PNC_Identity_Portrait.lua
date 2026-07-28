-- Bounded face-only identity metadata for lightweight client portraits.

PNC = PNC or {}
PNC.Identity = PNC.Identity or {}

local Identity = PNC.Identity
local STRING_MAX = 128

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

function Identity.NormalizePortraitSummary(source, fallback)
    local appearance
    if type(source) ~= "table" then
        source = type(fallback) == "table" and fallback or nil
    end
    if type(source) ~= "table" then return nil end
    appearance = type(source.appearance) == "table"
        and source.appearance or source
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
            hairModel = normalizeString(appearance.hairModel),
            beardModel = source.isFemale == true
                and nil
                or normalizeString(appearance.beardModel),
            hairColor = normalizeColor(appearance.hairColor),
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
    if type(record) ~= "table" then return nil end
    runtime = record.runtime or {}
    record.runtime = runtime
    identity = Identity.GetCharacterSummary(record)
    appearance = runtime.appearanceCache
        or Identity.RollAppearance(record)
        or {}
    hairColor = type(appearance.hairColor) == "table"
        and appearance.hairColor or {}
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
    })
    summary.revision = Identity.HashText(cacheKey)
    runtime.portraitSummaryCacheKey = cacheKey
    runtime.portraitSummaryCache = summary
    return summary
end

return Identity
