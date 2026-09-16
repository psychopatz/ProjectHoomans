-- Semantic aliases and bounded providers for generic world objects.
--
-- Resolution is server-side and read-only.  The result contains only a
-- stable object key and coordinates; Java objects never enter an action plan.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Resolver = PNC.Semantics.WorldTargetResolver
local Locator = PNC.NearbyResourceLocator
local Catalog = PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local SquareRules
local loadedRules, rules = pcall(
    require, "PsychopatzCore/World/PsychopatzSquareRules")
if loadedRules then SquareRules = rules end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function addValue(values, value)
    value = text(value)
    if value then values[#values + 1] = lower(value) end
end

local function objectMetadata(object)
    local labels = {}
    local sprites = {}
    local sprite = call(object, "getSprite")
    local spriteName = call(object, "getSpriteName")
    local container = call(object, "getContainer")
    local function addLabel(value) addValue(labels, value) end
    local function addSprite(value)
        value = text(value)
        if value then sprites[#sprites + 1] = lower(value) end
    end

    addLabel(call(object, "getObjectName"))
    addLabel(call(object, "getName"))
    addLabel(spriteName)
    addSprite(spriteName)
    addLabel(call(sprite, "getName"))
    addLabel(call(sprite, "getSpriteName"))
    addSprite(call(sprite, "getName"))
    addSprite(call(sprite, "getSpriteName"))
    addLabel(call(container, "getType"))
    if SquareRules and type(SquareRules.GetObjectProperty) == "function" then
        addLabel(SquareRules.GetObjectProperty(object, "CustomName"))
        addLabel(SquareRules.GetObjectProperty(object, "GroupName"))
        addLabel(SquareRules.GetObjectProperty(object, "Type"))
        addLabel(SquareRules.GetObjectProperty(object, "FurnitureType"))
    end
    return { labels = labels, spriteNames = sprites }
end

local function objectText(object)
    local metadata = objectMetadata(object)
    local values = {}
    for index = 1, #(metadata.labels or {}) do
        addValue(values, metadata.labels[index])
    end
    for index = 1, #(metadata.spriteNames or {}) do
        addValue(values, metadata.spriteNames[index])
    end
    return table.concat(values, " ")
end

local function contains(value, needle)
    return string.find(value, needle, 1, true) ~= nil
end

local function isRecycleBin(entry)
    local object = entry and entry.object
    local fullText = objectText(object)
    local sprite = lower(call(object, "getSpriteName"))
    if sprite == "" then
        sprite = lower(call(call(object, "getSprite"), "getName"))
    end
    if Catalog and type(Catalog.Matches) == "function"
        and Catalog.Matches("recycle_bin", objectMetadata(object))
    then
        return true
    end
    return contains(fullText, "recycle bin")
        or contains(fullText, "recycling bin")
        or contains(fullText, "trash bin")
        or contains(fullText, "garbage bin")
        or sprite == "trashcontainers_01_16"
end

local function originFor(context)
    context = type(context) == "table" and context or {}
    if context.origin then return context.origin end
    if context.body then return context.body end
    local record = context.record
    local x = tonumber(record and record.x)
    local y = tonumber(record and record.y)
    local z = tonumber(record and record.z) or 0
    if x == nil or y == nil then return nil end
    return {
        getX = function() return x end,
        getY = function() return y end,
        getZ = function() return z end,
    }
end

local function resolveObject(target, context, kind, predicate, missingReason)
    local origin = originFor(context)
    local radius = math.max(1, math.min(32,
        math.floor(tonumber(target and target.radius) or 16)))
    local hint
    local hintReason
    local hintPresent = target and type(target.clientHint) == "table"
    local hintAccepted = false
    local function find(useHint)
        local cacheKey = "semantic_object:" .. kind
        if useHint and Resolver.ClientHintKey then
            cacheKey = cacheKey .. ":hint:"
                .. Resolver.ClientHintKey(hint)
        end
        return Locator.FindObject(origin, {
            radius = radius,
            cacheMs = math.max(0, tonumber(target and target.cacheMs) or 1000),
            cacheKey = cacheKey,
            accept = function(candidate)
                if not predicate(candidate) then return false end
                return not useHint
                    or Resolver.NearClientHint(candidate, hint, 2.5)
            end,
        })
    end
    if not origin then return nil, "world_origin_unavailable" end
    if not Locator or type(Locator.FindObject) ~= "function" then
        return nil, "world_locator_unavailable"
    end
    if Resolver.ValidateClientHint then
        hint, hintReason = Resolver.ValidateClientHint(
            target, kind, origin, radius)
    end
    local entry
    if hint then
        entry = find(true)
        hintAccepted = entry ~= nil
    end
    if not entry then entry = find(false) end
    if not entry then return nil, missingReason end
    local x = tonumber(entry.x)
    local y = tonumber(entry.y)
    if x == nil or y == nil then
        return nil, "world_object_position_unavailable"
    end
    return {
        kind = kind,
        targetID = text(entry.key),
        x = x,
        y = y,
        z = tonumber(entry.z) or 0,
        mode = text(target and target.mode) or "walk",
        stopDistance = math.max(0.25,
            tonumber(target and target.stopDistance) or 1.25),
        objectKind = kind,
        resourceKey = text(entry.key),
        clientHintAccepted = hintAccepted,
        clientHintRejected = hintPresent and not hintAccepted,
        clientHintReason = hintReason,
    }
end

local function resolveRecycleBin(target, context)
    return resolveObject(
        target,
        context,
        "recycle_bin",
        isRecycleBin,
        "recycle_bin_not_found"
    )
end

Resolver.Register("recycle_bin", resolveRecycleBin)
local function resolveCatalogObject(target, context, profile)
    return resolveObject(
        target,
        context,
        profile.kind,
        function(entry)
            return Catalog.Matches(profile.kind,
                objectMetadata(entry and entry.object))
        end,
        profile.kind .. "_not_found"
    )
end

local function registerCatalogProfile(profile)
    if not profile then return false, "world_target_profile_missing" end
    for index = 1, #(profile.aliases or {}) do
        Resolver.RegisterAlias(profile.aliases[index], profile.kind)
    end
    -- Special profiles have a dedicated provider because their engine object
    -- may not be present in square:getObjects().
    if not profile.special and not Resolver.Providers[profile.kind] then
        Resolver.Register(profile.kind, function(target, context)
            return resolveCatalogObject(target, context, profile)
        end)
    end
    return true, profile.kind
end

function Resolver.RegisterCatalogProfile(kind)
    local profile = Catalog and Catalog.Get and Catalog.Get(kind) or nil
    return registerCatalogProfile(profile)
end

for _, profile in ipairs(Catalog and Catalog.List and Catalog.List() or {}) do
    registerCatalogProfile(profile)
end

return Resolver
