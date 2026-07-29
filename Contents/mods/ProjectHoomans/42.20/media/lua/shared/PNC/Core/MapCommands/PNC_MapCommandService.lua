--[[
    Authority-side dispatcher for map-issued NPC commands.

    Transport, validation, and result formatting live here. Individual command
    handlers own gameplay authorization and behavior, allowing future RTS
    actions such as scavenge, guard, build, or investigate to remain isolated.
]]

PNC = PNC or {}
PNC.MapCommandService = PNC.MapCommandService or {}

local Service = PNC.MapCommandService
local Const = PNC.Const

Service.Handlers = Service.Handlers or {}

local function finiteNumber(value)
    value = tonumber(value)
    if value == nil or value ~= value
        or value == math.huge or value == -math.huge
    then
        return nil
    end
    return value
end

local function normalizeTarget(raw)
    raw = type(raw) == "table" and raw or {}
    local x = finiteNumber(raw.x)
    local y = finiteNumber(raw.y)
    local z = finiteNumber(raw.z) or 0
    local maximum = tonumber(Const.MAP_COMMAND_COORDINATE_LIMIT) or 1000000
    if not x or not y
        or math.abs(x) > maximum
        or math.abs(y) > maximum
        or math.abs(z) > 32
    then
        return nil
    end
    if getWorld then
        local world = getWorld()
        local metaGrid = world and world.getMetaGrid
            and world:getMetaGrid() or nil
        if metaGrid and metaGrid.isValidChunk
            and not metaGrid:isValidChunk(x / 10, y / 10)
        then
            return nil
        end
    end
    return { x = x, y = y, z = z }
end

local function normalizeIDs(raw)
    local output = {}
    local seen = {}
    local maximum = math.max(
        1,
        math.floor(tonumber(Const.MAP_COMMAND_MAX_SELECTION) or 32)
    )
    local i
    local id
    for i = 1, math.min(type(raw) == "table" and #raw or 0, maximum) do
        id = tostring(raw[i] or "")
        if id ~= "" and not seen[id] then
            seen[id] = true
            output[#output + 1] = id
        end
    end
    return output
end

function Service.RegisterHandler(id, definition)
    id = tostring(id or "")
    if id == "" or type(definition) ~= "table"
        or type(definition.execute) ~= "function"
    then
        return false
    end
    definition.id = id
    Service.Handlers[id] = definition
    return true
end

function Service.UnregisterHandler(id)
    id = tostring(id or "")
    if id == "" or Service.Handlers[id] == nil then return false end
    Service.Handlers[id] = nil
    return true
end

function Service.Execute(player, raw, context)
    raw = type(raw) == "table" and raw or {}
    context = type(context) == "table" and context or {}
    local commandID = tostring(raw.commandID or "")
    local handler = Service.Handlers[commandID]
    local target = normalizeTarget(raw.target)
    local npcIds = normalizeIDs(raw.npcIds)
    local allowed
    local reason
    local ok
    local payload
    local result = {
        requestId = raw.requestId and tostring(raw.requestId) or nil,
        commandID = commandID,
        ok = false,
        accepted = 0,
        rejected = 0,
        target = target,
    }

    if not handler then
        result.reason = "command_unknown"
        return result
    end
    if not target then
        result.reason = "target_invalid"
        return result
    end
    if #npcIds <= 0 then
        result.reason = "selection_empty"
        return result
    end
    if type(handler.authorize) == "function" then
        ok, allowed, reason = pcall(
            handler.authorize,
            player,
            npcIds,
            target,
            raw.options or {},
            context
        )
        if not ok then
            result.reason = "authorization_failed"
            return result
        end
        if allowed == false then
            result.reason = tostring(reason or "unauthorized")
            return result
        end
    end

    ok, payload = pcall(
        handler.execute,
        player,
        npcIds,
        target,
        raw.options or {},
        context
    )
    if not ok then
        result.reason = "handler_failed"
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "PNC map command failed id=" .. commandID
                    .. " error=" .. tostring(payload)
            )
        end
        return result
    end
    payload = type(payload) == "table" and payload or {}
    result.ok = payload.ok ~= false
    result.accepted = math.max(0, math.floor(tonumber(payload.accepted) or 0))
    result.rejected = math.max(0, math.floor(
        tonumber(payload.rejected) or (#npcIds - result.accepted)
    ))
    result.reason = payload.reason
    result.message = payload.message
    result.details = payload.details
    return result
end

return Service
