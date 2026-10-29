PNC = PNC or {}
PNC.ActorFacing = PNC.ActorFacing or {}

local Facing = PNC.ActorFacing
local Registry = PNC.Registry
local Core = PNC.Core
local Const = PNC.Const or {}

Facing.DEFAULT_CACHED_MAX_AGE_MS = 1000

local function finite(value)
    local number = tonumber(value)
    if not number or number ~= number
        or number == math.huge or number == -math.huge
    then
        return nil
    end
    return number
end

local function normalized(x, y)
    x = finite(x)
    y = finite(y)
    if x == nil or y == nil then return nil end
    local length = math.sqrt((x * x) + (y * y))
    if length <= 0.000001 then return nil end
    return x / length, y / length, length
end

local function liveBody(record, options)
    if type(options) == "table" and options.body ~= nil then
        return options.body
    end
    if not record or not record.id or not Registry
        or type(Registry.GetLiveZombie) ~= "function"
    then
        return nil
    end
    return Registry.GetLiveZombie(record.id)
end

local function fromBody(body, now)
    local forward
    local x
    local y
    local length
    if not body or type(body.getForwardDirection) ~= "function" then
        return nil
    end
    forward = body:getForwardDirection()
    if not forward then return nil end
    if type(forward.getX) == "function" then
        x = forward:getX()
    else
        x = forward.x
    end
    if type(forward.getY) == "function" then
        y = forward:getY()
    else
        y = forward.y
    end
    x, y, length = normalized(x, y)
    if not x then return nil end
    return {
        x = x,
        y = y,
        source = "live_body",
        trustworthy = true,
        observedAt = now,
        sourceLength = length,
    }
end

local function fromCached(record, now, options)
    local runtime = record and record.runtime or nil
    local lane = runtime and runtime.pathing or nil
    local x
    local y
    local length
    local observedAt
    local maxAge
    if not lane then return nil end
    if record.presenceState ~= nil
        and Const.PRESENCE_LIVE ~= nil
        and record.presenceState ~= Const.PRESENCE_LIVE
    then
        return nil
    end
    observedAt = finite(lane.lastFacingAt)
    if not observedAt or observedAt <= 0 then return nil end
    maxAge = finite(options and options.maxCachedAgeMs)
        or Facing.DEFAULT_CACHED_MAX_AGE_MS
    if maxAge < 0 then maxAge = 0 end
    if now == nil or now - observedAt > maxAge then return nil end
    x, y, length = normalized(lane.lastFacingDirX, lane.lastFacingDirY)
    if not x then return nil end
    return {
        x = x,
        y = y,
        source = "pathing_cache",
        trustworthy = true,
        observedAt = observedAt,
        ageMs = math.max(0, now - observedAt),
        sourceLength = length,
    }
end

function Facing.Resolve(record, options)
    if type(record) ~= "table" then
        return nil, "RECORD_REQUIRED"
    end
    options = type(options) == "table" and options or {}
    local now = finite(options.now)
        or (Core and type(Core.Now) == "function" and finite(Core.Now()))
        or 0
    local body = liveBody(record, options)
    local result = fromBody(body, now)
    if result then return result end
    if options.allowCached == false then
        return nil, "HEADING_UNAVAILABLE"
    end
    result = fromCached(record, now, options)
    if result then return result end
    return nil, "HEADING_UNAVAILABLE"
end

return Facing
