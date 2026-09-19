-- Read the local client position sources used to bound world observation.
PNC = PNC or {}

local Matcher = require "PNC/Semantics/PNC_SemanticWorldTargetMatcher"
local Origin = {}
local number = Matcher.Number

local function call(object, method, ...)
    local fn = object and object[method]
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, object, ...)
    return ok and value or nil
end

function Origin.NowMs()
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

local function coordinateSource(value)
    if not value then return nil end
    local x = call(value, "getX")
    local y = call(value, "getY")
    local z = call(value, "getZ")
    if x ~= nil and y ~= nil then
        return number(x), number(y), number(z) or 0
    end
    if type(value) == "table" then
        x = number(value.x or value.targetX)
        y = number(value.y or value.targetY)
        z = number(value.z or value.targetZ) or 0
        if x ~= nil and y ~= nil then return x, y, z end
    end
    return nil
end

local function liveNPCBody(npcID)
    local registry = PNC.Registry
    local body
    local sync
    local snapshot
    local key = tostring(npcID or "")
    if key == "" then return nil end
    if registry and type(registry.GetLiveZombie) == "function" then
        local ok, result = pcall(registry.GetLiveZombie, key)
        if ok and result then return result end
    end
    sync = PNC.ClientPresenceSync
    snapshot = PNC.Network and PNC.Network.ClientState
        and PNC.Network.ClientState.snapshots
        and PNC.Network.ClientState.snapshots[key] or nil
    if sync and type(sync.ResolveBodyForNPC) == "function" then
        local ok, result = pcall(sync.ResolveBodyForNPC, key, snapshot)
        if ok and result then body = result end
    end
    return body
end

function Origin.Resolve(context, options)
    context = type(context) == "table" and context or {}
    options = type(options) == "table" and options or {}
    local candidates = {}
    local function add(value) if value then candidates[#candidates + 1] = value end end
    add(options.origin)
    add(context.origin)
    add(context.worldOrigin)
    add(liveNPCBody(context.npcID or context.targetID))
    add(context.player)
    if type(getSpecificPlayer) == "function" then
        local ok, player = pcall(getSpecificPlayer, 0)
        if ok then add(player) end
    end
    for index = 1, #candidates do
        local x, y, z = coordinateSource(candidates[index])
        if x ~= nil and y ~= nil then
            return candidates[index], x, y, z
        end
    end
    return nil
end


return Origin
