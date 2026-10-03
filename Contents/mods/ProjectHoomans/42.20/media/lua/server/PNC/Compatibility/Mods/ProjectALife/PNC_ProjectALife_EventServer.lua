if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

-- Authority-checked transport for Project A-Life flavor events.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

local Server = PNC.Compatibility.ProjectALifeEvents.Server or {}
PNC.Compatibility.ProjectALifeEvents.Server = Server
Server.COMMAND = "projectalife_flavor"
Server.eventSequence = tonumber(Server.eventSequence) or 0

function Server.CleanText(value, maximum)
    if type(value) ~= "string" then return nil end
    value = string.gsub(value, "[\r\n\t]", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, maximum or 80)
end

function Server.Coordinate(value)
    value = tonumber(value)
    if value == nil or value ~= value or value < -100000
        or value > 100000
    then
        return nil
    end
    return value
end

function Server.NowMs()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        local value = tonumber(core.Now())
        if value ~= nil then return value end
    end
    if type(getTimestampMs) == "function" then
        local value = getTimestampMs()
        if tonumber(value) ~= nil then return tonumber(value) end
    end
    return 0
end

function Server.HasAuthority()
    local core = PNC.Core
    if core and type(core.IsAuthority) == "function" then
        local ok, allowed = pcall(core.IsAuthority)
        return ok and allowed == true
    end
    return type(isServer) == "function" and isServer() == true
end

function Server.EventPosition(point)
    if type(point) ~= "table" then return nil end
    local x = Server.Coordinate(point.x)
    local y = Server.Coordinate(point.y)
    local z = Server.Coordinate(point.z) or 0
    if x == nil or y == nil then return nil end
    return { x = x, y = y, z = z }
end

function Server.PlayerPosition(player)
    if not player then return nil end
    local point = {
        x = Server.Coordinate(player:getX()),
        y = Server.Coordinate(player:getY()),
        z = Server.Coordinate(player:getZ()),
    }
    if point.x == nil or point.y == nil or point.z == nil then
        return nil
    end
    return point
end

function Server.PlayerName(player)
    if type(player) == "string" then
        return Server.CleanText(player, 64)
    end
    if not player or not player.getUsername then return nil end
    return Server.CleanText(player:getUsername(), 64)
end

function Server.NextEventID(prefix, sourceID)
    Server.eventSequence = Server.eventSequence + 1
    return "projectalife:" .. tostring(prefix) .. ":"
        .. tostring(Server.CleanText(sourceID, 56) or "event") .. ":"
        .. tostring(Server.NowMs()) .. ":" .. tostring(Server.eventSequence)
end

function Server.NormalizeStance(value)
    value = string.lower(tostring(value or ""))
    if value == "allied" then value = "friendly" end
    if value == "suspicious" then value = "careful" end
    if value == "friendly" or value == "neutral"
        or value == "careful" or value == "hostile"
    then
        return value
    end
    return "unknown"
end

local function dispatchToPlayer(player, payload)
    local internal = PNC.Network and PNC.Network.Internal
    local send = internal and internal.SendToPlayer
    if type(send) == "function" then
        return send(player, Server.COMMAND, payload) ~= false
    end
    if type(sendServerCommand) == "function" then
        local module = PNC.Const and PNC.Const.MODULE or "PNC"
        sendServerCommand(player, module, Server.COMMAND, payload)
        return true
    end
    return false
end

local function publishToPlayers(payload, recipient, radius)
    local core = PNC.Core
    local point = Server.EventPosition(payload)
    local sent = 0
    if not point then return false end

    if type(isServer) ~= "function" or isServer() ~= true then
        local client = PNC.Client
        local player = getSpecificPlayer and getSpecificPlayer(0) or nil
        if client and type(client.HandleServerCommand) == "function"
            and (recipient == nil or Server.PlayerName(player) == recipient)
        then
            client.HandleServerCommand(Server.COMMAND, payload)
            return true
        end
        return false
    end

    if not core or type(core.ForEachPlayer) ~= "function" then
        return false
    end
    core.ForEachPlayer(function(player)
        if recipient ~= nil and Server.PlayerName(player) ~= recipient then
            return
        end
        local position = Server.PlayerPosition(player)
        if not position or math.abs(position.z - point.z) > 2 then
            return
        end
        local dx = position.x - point.x
        local dy = position.y - point.y
        if (dx * dx) + (dy * dy) <= radius * radius
            and dispatchToPlayer(player, payload)
        then
            sent = sent + 1
        end
    end)
    return sent > 0
end

function Server.Publish(eventName, source)
    if not Server.HasAuthority() or type(source) ~= "table" then
        return false
    end

    local kind
    local radius
    if eventName == "projectalife_encounter" then
        kind = "encounter"
        radius = 48
    elseif eventName == "projectalife_faction_stance" then
        kind = "faction_stance"
        radius = 36
    elseif eventName == "projectalife_faction_conflict" then
        kind = "faction_conflict"
        radius = 48
    else
        return false
    end

    local point = Server.EventPosition(source)
    local eventID = Server.CleanText(source.eventID, 120)
    if not point or not eventID then return false end

    local payload = {
        schema = 1,
        source = "ProjectALifeNPCs",
        kind = kind,
        eventID = eventID,
        x = point.x,
        y = point.y,
        z = point.z,
        atMs = tonumber(source.atMs) or Server.NowMs(),
        stance = Server.NormalizeStance(source.stance),
        count = math.max(0, math.min(100, math.floor(
            tonumber(source.count) or 0))),
    }
    if kind == "faction_stance" then
        payload.factionName = Server.CleanText(source.factionName, 64)
            or "that faction"
    elseif kind == "faction_conflict" then
        payload.factionName = Server.CleanText(source.factionName, 64)
            or "that faction"
        payload.direction = Server.CleanText(source.direction, 16)
            or "incoming"
        payload.damage = math.max(0, tonumber(source.damage) or 0)
        payload.sourceFaction = Server.CleanText(source.sourceFaction, 64)
        payload.targetFaction = Server.CleanText(source.targetFaction, 64)
    end

    return publishToPlayers(
        payload,
        Server.CleanText(source.recipientUsername, 64),
        radius)
end

function Server.Emit(eventName, payload)
    local api = PNC.Compatibility and PNC.Compatibility.API
    if not api or type(api.EmitEvent) ~= "function" then return false end
    local ok, emitted = pcall(api.EmitEvent, eventName, payload)
    return ok and (tonumber(emitted) or 0) > 0
end

return Server
