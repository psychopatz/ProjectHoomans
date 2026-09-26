-- Validate Project A-Life payloads before passing them to flavor presentation.

PNC = PNC or {}
PNC.Compatibility = PNC.Compatibility or {}
PNC.Compatibility.ProjectALifeEvents =
    PNC.Compatibility.ProjectALifeEvents or {}

local Client = PNC.Compatibility.ProjectALifeEvents.Client or {
    seen = {},
    lastAccepted = {},
    installAttempts = 0,
}
PNC.Compatibility.ProjectALifeEvents.Client = Client
Client.COMMAND = "projectalife_flavor"
Client.seen = Client.seen or {}
Client.lastAccepted = Client.lastAccepted or {}
Client.installAttempts = tonumber(Client.installAttempts) or 0

function Client.CleanText(value, maximum)
    if type(value) ~= "string" then return nil end
    value = string.gsub(value, "[\r\n\t]", " ")
    value = string.gsub(value, "%s+", " ")
    value = string.gsub(value, "^%s+", "")
    value = string.gsub(value, "%s+$", "")
    if value == "" then return nil end
    return string.sub(value, 1, maximum or 120)
end

function Client.Coordinate(value)
    value = tonumber(value)
    if value == nil or value ~= value or value < -100000
        or value > 100000
    then
        return nil
    end
    return value
end

function Client.NowMs()
    local core = PNC.Core
    if core and type(core.Now) == "function" then
        local value = tonumber(core.Now())
        if value ~= nil then return value end
    end
    if type(getTimeInMillis) == "function" then
        local value = getTimeInMillis()
        if tonumber(value) ~= nil then return tonumber(value) end
    end
    return 0
end

function Client.NormalizeStance(value)
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

function Client.NormalizeMeta(payload)
    if type(payload) ~= "table" then return nil end
    local eventID = Client.CleanText(
        payload.eventId or payload.eventID, 120)
    local kind = Client.CleanText(payload.kind, 24)
    local x = Client.Coordinate(payload.x)
    local y = Client.Coordinate(payload.y)
    local z = Client.Coordinate(payload.z) or 0
    if not eventID or x == nil or y == nil then return nil end
    if kind ~= "gunfire" and kind ~= "heli" and kind ~= "military"
        and kind ~= "crash" and kind ~= "ambience"
    then
        return nil
    end
    return {
        category = "meta",
        eventID = "meta:" .. eventID,
        metaKind = kind,
        x = x,
        y = y,
        z = z,
    }
end

function Client.NormalizeServer(payload)
    if type(payload) ~= "table" or payload.schema ~= 1
        or payload.source ~= "ProjectALifeNPCs"
    then
        return nil
    end
    local eventID = Client.CleanText(payload.eventID, 120)
    local x = Client.Coordinate(payload.x)
    local y = Client.Coordinate(payload.y)
    local z = Client.Coordinate(payload.z) or 0
    if not eventID or x == nil or y == nil then return nil end
    if payload.kind ~= "encounter"
        and payload.kind ~= "faction_stance"
        and payload.kind ~= "faction_conflict"
    then
        return nil
    end
    return {
        category = payload.kind,
        eventID = eventID,
        stance = Client.NormalizeStance(payload.stance),
        factionName = Client.CleanText(payload.factionName, 64)
            or "that faction",
        direction = payload.kind == "faction_conflict"
            and (payload.direction == "outgoing" and "outgoing" or "incoming")
            or nil,
        damage = payload.kind == "faction_conflict"
            and math.max(0, tonumber(payload.damage) or 0)
            or nil,
        x = x,
        y = y,
        z = z,
    }
end

return Client
