-- Projects live world objects into primitive observation records.
-- This boundary owns object metadata, special target IDs, and decoration copying.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = PNC.Semantics.ClientWorldTargetObservationProjection or {}
PNC.Semantics.ClientWorldTargetObservationProjection = Projection

local SquareRules
local loadedRules, loadedSquareRules = pcall(
    require, "PsychopatzCore/World/PsychopatzSquareRules")
if loadedRules then SquareRules = loadedSquareRules end
local CampSite = PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

local function number(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function text(value)
    value = tostring(value or "")
    return value ~= "" and value or nil
end

local function addUnique(values, seen, value, normalizer)
    value = text(value)
    if not value then return end
    local key = normalizer and normalizer(value) or value
    if key == "" or seen[key] then return end
    seen[key] = true
    values[#values + 1] = value
end

-- Decoration is an optional client-local extension point. Keep the cache
-- boundary primitive even when a perception provider briefly inspects a Java
-- object: only booleans, numbers, strings, and plain nested tables survive.
local function copyPrimitive(value, depth)
    local valueType = type(value)
    depth = tonumber(depth) or 0
    if valueType == "number" or valueType == "string"
        or valueType == "boolean"
    then
        return value
    end
    if valueType ~= "table" or depth >= 5 then return nil end
    local output = {}
    for key, child in pairs(value) do
        local keyType = type(key)
        if keyType == "string" or keyType == "number"
            or keyType == "boolean"
        then
            local copied = copyPrimitive(child, depth + 1)
            if copied ~= nil then output[key] = copied end
        end
    end
    return output
end

function Projection.MetadataFor(object)
    local labels = {}
    local sprites = {}
    local seenLabels = {}
    local seenSprites = {}
    local sprite = call(object, "getSprite")
    local spriteName = call(object, "getSpriteName")
    local container = call(object, "getContainer")

    addUnique(labels, seenLabels, call(object, "getObjectName"))
    addUnique(labels, seenLabels, call(object, "getName"))
    addUnique(labels, seenLabels, spriteName)
    addUnique(sprites, seenSprites, spriteName, string.lower)
    addUnique(labels, seenLabels, call(sprite, "getName"))
    addUnique(labels, seenLabels, call(sprite, "getSpriteName"))
    addUnique(sprites, seenSprites, call(sprite, "getName"), string.lower)
    addUnique(sprites, seenSprites,
        call(sprite, "getSpriteName"), string.lower)
    addUnique(labels, seenLabels, call(container, "getType"))

    if SquareRules and type(SquareRules.GetObjectProperty) == "function" then
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "CustomName"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "GroupName"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "Type"))
        addUnique(labels, seenLabels,
            SquareRules.GetObjectProperty(object, "FurnitureType"))
    end
    return {
        labels = labels,
        spriteNames = sprites,
        objectName = text(call(object, "getObjectName")),
        displayName = text(call(object, "getName")),
        spriteName = text(spriteName),
    }
end

function Projection.AddObservation(output, seen, object, square, originZ,
    specialKind, objectIndex, decorate, suppliedMetadata)
    if not object or seen[object] then return end
    local squareX = number(call(square, "getX"))
    local squareY = number(call(square, "getY"))
    local squareZ = number(call(square, "getZ")) or originZ
    local x = number(call(object, "getX")) or squareX
    local y = number(call(object, "getY")) or squareY
    local z = number(call(object, "getZ")) or squareZ
    if x == nil or y == nil or z ~= originZ then return end

    local metadata = suppliedMetadata or Projection.MetadataFor(object)
    metadata.special = specialKind
        or (call(object, "isCampfire") == true and "campfire" or nil)
    seen[object] = true
    local observationKey
    if metadata.special == "campfire" then
        observationKey = CampSite.CampfireKey(x, y, z)
    else
        observationKey = "world_object:" .. tostring(x) .. ":"
            .. tostring(y) .. ":" .. tostring(z) .. ":"
            .. tostring(objectIndex or 0)
    end
    local observation = {
        x = x,
        y = y,
        z = z,
        objectIndex = objectIndex,
        objectKey = observationKey,
        targetID = observationKey,
        resourceKey = observationKey,
        metadata = metadata,
        source = "client_loaded_world",
    }
    if type(decorate) == "function" then
        local ok, facts = pcall(decorate, object, square, observation)
        if ok and type(facts) == "table" then
            observation.facts = copyPrimitive(facts)
        end
    end
    output[#output + 1] = observation
end

return Projection
