-- Shared data access and primitive-value helpers for client world-object
-- perception.  Keep engine userdata behind this boundary; providers and
-- snapshot consumers communicate through the Internal table only.
PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception.WorldObjects or {}
PNC.Perception.WorldObjects = Perception

local Catalog = PNC.Semantics and PNC.Semantics.WorldTargetCatalog
    or require "PNC/Semantics/PNC_SemanticWorldTargetCatalog"
local CampSite = PNC.Semantics and PNC.Semantics.CampSite
    or require "PNC/Semantics/PNC_SemanticCampSite"
local Geometry = PNC.Semantics and PNC.Semantics.CampSiteGeometry
    or require "PNC/Semantics/PNC_SemanticCampSiteGeometry"
local ObservationCache = PNC.Semantics
    and PNC.Semantics.ClientWorldTargetObservationCache
    or require "PNC/Semantics/PNC_SemanticWorldTargetObservationCache"

local SquareRules = PsychopatzCore and PsychopatzCore.World
    and PsychopatzCore.World.SquareRules or nil
if not SquareRules then
    local loaded, value = pcall(require,
        "PsychopatzCore/World/PsychopatzSquareRules")
    if loaded then SquareRules = value end
end

Perception.VERSION = 1
Perception.DEFAULT_RADIUS = 16
Perception.MAX_RADIUS = 24
Perception.DEFAULT_CACHE_MS = 500
Perception.MAX_OBJECTS = ObservationCache.MAX_OBJECTS or 512
Perception.CAMPFIRE_RADIUS = 16
Perception.Providers = Perception.Providers or {}
Perception.ProviderOrder = Perception.ProviderOrder or {}
Perception.ProviderVersion = tonumber(Perception.ProviderVersion) or 0
Perception.SnapshotCache = Perception.SnapshotCache or {}
Perception.Internal = Perception.Internal or {}

local Internal = Perception.Internal
Internal.Catalog = Catalog
Internal.CampSite = CampSite
Internal.Geometry = Geometry
Internal.ObservationCache = ObservationCache
Internal.SquareRules = SquareRules

local LIST_FACTS = {
    semanticKinds = true,
    semanticNames = true,
    semanticLabels = true,
    usage = true,
    jobs = true,
    capabilities = true,
    diagnostics = true,
}

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

local function text(value, maximum)
    local result = tostring(value or "")
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function addUnique(values, value, normalizer)
    if type(values) ~= "table" then return end
    value = text(value)
    if not value then return end
    local key = normalizer and normalizer(value) or value
    for index = 1, #values do
        local existing = normalizer and normalizer(values[index]) or values[index]
        if existing == key then return end
    end
    values[#values + 1] = value
end

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

local function position(value)
    local x = number(call(value, "getX"))
    local y = number(call(value, "getY"))
    local z = number(call(value, "getZ")) or 0
    if x ~= nil and y ~= nil then return x, y, z end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function nowMs()
    if type(getTimestampMs) == "function" then
        local ok, value = pcall(getTimestampMs)
        if ok and number(value) then return number(value) end
    end
    if type(getTimeInMillis) == "function" then
        local ok, value = pcall(getTimeInMillis)
        if ok and number(value) then return number(value) end
    end
    return 0
end

local function currentPlayer()
    if type(getSpecificPlayer) ~= "function" then return nil end
    local ok, player = pcall(getSpecificPlayer, 0)
    return ok and player or nil
end

local function currentCell()
    if type(getCell) ~= "function" then return nil end
    local ok, cell = pcall(getCell)
    return ok and cell or nil
end

local function objectName(metadata)
    metadata = type(metadata) == "table" and metadata or {}
    local display = text(metadata.displayName, 96)
    local native = text(metadata.objectName, 96)
    local sprite = text(metadata.spriteName, 96)
    if display and display ~= "IsoObject" then return display end
    if native and native ~= "IsoObject" then return native end
    return sprite or display or native or "IsoObject"
end

local function mergeFacts(target, source)
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if LIST_FACTS[key] and type(value) == "table" then
            for index = 1, #value do addUnique(target[key], value[index]) end
        elseif key == "providerStates" and type(value) == "table" then
            for index = 1, #value do
                target.providerStates[#target.providerStates + 1] =
                    copyPrimitive(value[index])
            end
        elseif value ~= nil then
            target[key] = value
        end
    end
end

Internal.Call = call
Internal.Number = number
Internal.Text = text
Internal.AddUnique = addUnique
Internal.CopyPrimitive = copyPrimitive
Internal.Position = position
Internal.NowMs = nowMs
Internal.CurrentPlayer = currentPlayer
Internal.CurrentCell = currentCell
Internal.ObjectName = objectName
Internal.MergeFacts = mergeFacts
Perception._Internal = Internal

return Internal
