-- Shared semantic response text and observation helpers.

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
local Response = PNC.Semantics.LocalResponse
local Internal = Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse

local function clockText(world)
    local time = world and (world.time or world)
    if type(time) == "table" and time.available == false then return nil end
    local hour = tonumber(time and (time.hour or time.hour24))
    local minute = tonumber(time and (time.minute or time.minutes)) or 0
    if hour == nil then return nil end
    hour = math.floor(hour) % 24
    local suffix = hour >= 12 and "PM" or "AM"
    local displayHour = hour % 12
    if displayHour == 0 then displayHour = 12 end
    return string.format("It's %d:%02d %s.", displayHour, minute, suffix)
end

local MONTH_NAMES = {
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December",
}

local function dayText(world)
    world = type(world) == "table" and world or {}
    local calendar = type(world.calendar) == "table" and world.calendar or {}
    local year = tonumber(calendar.year)
    local month = tonumber(calendar.month)
    local day = tonumber(calendar.day)
    if year and month and day
        and year > 0 and month >= 1 and month <= 12
        and day >= 1 and day <= 31
    then
        return "It's " .. tostring(MONTH_NAMES[math.floor(month)]) .. " "
            .. tostring(math.floor(day)) .. ", " .. tostring(math.floor(year))
            .. "."
    end
    local gameDay = tonumber(world.gameDay)
    if gameDay ~= nil then return "It's day " .. tostring(math.floor(gameDay)) .. "." end
    return nil
end

local function weatherText(world)
    local weather = world and world.weather or nil
    if type(weather) ~= "table" then return nil end
    local raining = weather.raining == true
    local foggy = weather.foggy == true
    local snowing = weather.snowing == true
    if snowing and foggy then return "It's snowing and foggy out." end
    if snowing then return "It's snowing right now." end
    if raining and foggy then return "It's raining and foggy out." end
    if raining then return "It's raining right now." end
    if foggy then return "It's foggy out." end
    if weather.raining == false or weather.foggy == false then
        return "The weather looks clear right now."
    end
    local temperature = tonumber(weather.temperatureC)
    if temperature then
        return string.format("It's about %.1f degrees out.", temperature)
    end
    return nil
end

local function identityText(context)
    local name = type(context) == "table" and (
        context.npcFullName or context.npcName
    ) or nil
    local identityState = type(context) == "table"
        and context.identityState or nil
    name = tostring(name or "")
    if identityState == "known"
        and name ~= ""
        and string.lower(name) ~= "unknown survivor"
    then
        return "I'm " .. name .. "."
    end
    return "I'm a survivor."
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

local function locationText(ir, fact)
    local location = fact and fact.location or nil
    local name = targetText(ir and ir.target, fact)
    local band = location and location.distanceBand or nil
    local label = location and location.label or nil
    if label then return name .. " is at " .. tostring(label) .. "." end
    if band == "nearby" then return name .. " is nearby." end
    if band == "not_far" then
        return "I last saw " .. name .. " not far from here."
    end
    if band == "far" then return "I last saw " .. name .. " farther out." end
    return "I know where " .. name .. " is, but not exactly."
end

-- The question resolver is a pure domain spoke. These helpers are read-only
-- response utilities shared with it; the public Response.Resolve contract is
-- unchanged.
Response.Internal = Response.Internal or {}
local Internal = Response.Internal
Internal.CopyArgs = copyArgs
Internal.CatalogResponse = catalogResponse
Internal.ClockText = clockText
Internal.DayText = dayText
Internal.WeatherText = weatherText
Internal.IdentityText = identityText
Internal.TargetText = targetText
Internal.FactFor = factFor
Internal.LocationText = locationText

return Response
