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

local function objectText(object)
    local values = {}
    addValue(values, call(object, "getObjectName"))
    addValue(values, call(object, "getName"))
    addValue(values, call(object, "getSpriteName"))
    local sprite = call(object, "getSprite")
    addValue(values, call(sprite, "getName"))
    addValue(values, call(sprite, "getSpriteName"))
    if SquareRules and type(SquareRules.GetObjectProperty) == "function" then
        addValue(values, SquareRules.GetObjectProperty(object, "CustomName"))
        addValue(values, SquareRules.GetObjectProperty(object, "GroupName"))
        addValue(values, SquareRules.GetObjectProperty(object, "Type"))
        addValue(values, SquareRules.GetObjectProperty(object, "FurnitureType"))
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
    if not origin then return nil, "world_origin_unavailable" end
    if not Locator or type(Locator.FindObject) ~= "function" then
        return nil, "world_locator_unavailable"
    end
    local entry = Locator.FindObject(origin, {
        radius = math.max(1, math.min(32,
            math.floor(tonumber(target and target.radius) or 16))),
        cacheMs = math.max(0, tonumber(target and target.cacheMs) or 1000),
        cacheKey = "semantic_object:" .. kind,
        accept = predicate,
    })
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
Resolver.RegisterAlias("recycle bin", "recycle_bin")
Resolver.RegisterAlias("recycling bin", "recycle_bin")
Resolver.RegisterAlias("trash bin", "recycle_bin")
Resolver.RegisterAlias("garbage bin", "recycle_bin")
Resolver.RegisterAlias("campfire", "campfire")
Resolver.RegisterAlias("fire pit", "campfire")

return Resolver
