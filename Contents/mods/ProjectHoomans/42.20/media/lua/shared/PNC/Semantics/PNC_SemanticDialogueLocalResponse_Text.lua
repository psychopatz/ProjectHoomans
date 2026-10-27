-- Shared semantic response text and observation helpers.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Response = PNC.Semantics.LocalResponse
local Internal = Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse

local function clockFacts(world)
    local time = world and (world.time or world)
    if type(time) == "table" and time.available == false then return nil end
    local hour = tonumber(time and (time.hour or time.hour24))
    local minute = tonumber(time and (time.minute or time.minutes)) or 0
    if hour == nil then return nil end
    hour = math.floor(hour) % 24
    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    if displayHour == 0 then displayHour = 12 end
    return {
        display = string.format("%d:%02d %s", displayHour, minute, suffix),
        hour = hour,
        minute = minute,
    }
end

local function dayFacts(world)
    world = type(world) == "table" and world or {}
    local calendar = type(world.calendar) == "table" and world.calendar or {}
    local year = tonumber(calendar.year)
    local month = tonumber(calendar.month)
    local day = tonumber(calendar.day)
    if year and month and day
        and year > 0 and month >= 1 and month <= 12
        and day >= 1 and day <= 31
    then
        return {
            year = math.floor(year),
            month = math.floor(month),
            day = math.floor(day),
        }
    end
    local gameDay = tonumber(world.gameDay)
    if gameDay ~= nil then return { gameDay = math.floor(gameDay) } end
    return nil
end

local function weatherFacts(world)
    local weather = world and world.weather or nil
    if type(weather) ~= "table" then return nil end
    local raining = weather.raining == true
    local foggy = weather.foggy == true
    local snowing = weather.snowing == true
    if snowing then return { kind = "snowing", foggy = foggy } end
    if raining then return { kind = "raining", foggy = foggy } end
    if foggy then return { kind = "foggy" } end
    if weather.raining == false or weather.foggy == false then
        return { kind = "clear" }
    end
    local temperature = tonumber(weather.temperatureC)
    if temperature then
        return { kind = "temperature", temperature = temperature }
    end
    return nil
end

local function identityFacts(context)
    local name = type(context) == "table" and (
        context.npcFullName or context.npcName
    ) or nil
    local identityKnown = Internal.IdentityKnown(context)
    name = tostring(name or "")
    if identityKnown
        and name ~= ""
        and string.lower(name) ~= "unknown survivor"
    then
        return { name = name, known = true }
    end
    return { name = nil, known = false }
end

local function targetText(target, fact)
    local value = fact and fact.targetName or nil
    if value == nil and type(target) == "table" then
        value = target.name or target.text or target.value
    end
    value = tostring(value or "them")
    return value ~= "" and value or "them"
end

local function factFor(ir)
    local extensions = ir and ir.extensions or nil
    local facts = type(extensions) == "table" and extensions.facts or nil
    local subject = ir and ir.subject or nil
    local fact = type(facts) == "table" and facts[subject] or nil
    return type(fact) == "table" and fact or nil
end

local function locationFacts(ir, fact)
    local location = fact and fact.location or nil
    local name = targetText(ir and ir.target, fact)
    local band = location and location.distanceBand or nil
    local label = location and location.label or nil
    return {
        target = name,
        location = label,
        distanceBand = band,
    }
end

-- The question resolver is a pure domain spoke. These helpers are read-only
-- response utilities shared with it; the public Response.Resolve contract is
-- unchanged.
Response.Internal = Response.Internal or {}
local Internal = Response.Internal
Internal.CopyArgs = copyArgs
Internal.CatalogResponse = catalogResponse
Internal.ClockFacts = clockFacts
Internal.DayFacts = dayFacts
Internal.WeatherFacts = weatherFacts
Internal.IdentityFacts = identityFacts
Internal.TargetText = targetText
Internal.FactFor = factFor
Internal.LocationFacts = locationFacts

return Response
