-- Projects GameTime and climate-manager values into the shared world snapshot.
-- The root supplies its safe Java/API readers so both providers keep the same
-- accessor and failure behavior.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Environment = PNC.Semantics.WorldContextEnvironment or {}
PNC.Semantics.WorldContextEnvironment = Environment

local function calendarDay(gameTime, readers)
    local day = readers.readNumber(gameTime, "getDayPlusOne")
    if day ~= nil then return day end
    day = readers.readNumber(gameTime, "getDay")
    return day ~= nil and day + 1 or nil
end

local function calendarMonth(gameTime, readers)
    local month = readers.readNumber(gameTime, "getMonth")
    return month ~= nil and month + 1 or nil
end

function Environment.TimeSnapshot(gameTime, worldAgeHours, resolver, readers)
    local timeOfDay = readers.readNumber(gameTime, "getTimeOfDay")
    local hour = readers.readNumber(gameTime, "getHour")
    local minutes = readers.readNumber(gameTime, "getMinutes")
    local available = gameTime ~= nil
        and (timeOfDay ~= nil or hour ~= nil or minutes ~= nil)
    if hour == nil and timeOfDay ~= nil then hour = math.floor(timeOfDay) end
    if hour == nil then hour = 12 end
    if minutes == nil and timeOfDay ~= nil then
        minutes = math.floor((timeOfDay - math.floor(timeOfDay)) * 60 + 0.5)
    end
    minutes = minutes or 0
    if timeOfDay == nil then timeOfDay = hour + minutes / 60 end
    local calendar = {
        year = readers.readNumber(gameTime, "getYear"),
        month = calendarMonth(gameTime, readers),
        day = calendarDay(gameTime, readers),
    }
    local gameDay = math.floor((tonumber(worldAgeHours) or 0) / 24)
    local timeBand = type(resolver) == "function"
        and resolver(timeOfDay) or nil
    return {
        available = available,
        worldAgeHours = tonumber(worldAgeHours) or 0,
        gameDay = gameDay,
        timeOfDay = timeOfDay,
        hour = math.floor(hour),
        minute = math.max(0, math.min(59, math.floor(minutes))),
        band = timeBand,
        calendar = calendar,
    }
end

function Environment.WeatherSnapshot(climate, player, readers)
    local precipitation = readers.firstNumber(climate, {
        "getPrecipitationIntensity",
    })
    local raining = readers.firstBoolean(climate, { "isRaining" })
    if raining == nil then
        local value = readers.readMember(climate, "isRaining")
        if value == true or value == false then raining = value end
    end
    if raining == nil and precipitation ~= nil then
        raining = precipitation > 0
    end

    local fogIntensity = readers.firstNumber(climate, {
        "getFogIntensity",
    })
    if fogIntensity == nil and readers.isCharacterArgument(player) then
        local ok, value = readers.call1(
            climate, "getFogIntensityForCharacter", player)
        if ok then fogIntensity = tonumber(value) end
    end
    local foggy = readers.firstBoolean(climate, { "isFoggy" })
    if foggy == nil then
        local value = readers.readMember(climate, "isFoggy")
        if value == true or value == false then foggy = value end
    end
    if foggy == nil and fogIntensity ~= nil then foggy = fogIntensity > 0.10 end

    local rainIntensity = readers.firstNumber(climate, { "getRainIntensity" })
    local snowIntensity = readers.firstNumber(climate, { "getSnowIntensity" })
    local snowing = readers.firstBoolean(climate, { "isSnowing" })
    if snowing == nil then
        snowing = readers.firstBoolean(climate, { "getPrecipitationIsSnow" })
    end
    if snowing == nil and snowIntensity ~= nil then
        snowing = snowIntensity > 0
    end

    local temperature = nil
    if readers.isCharacterArgument(player) then
        local ok, value = readers.call2(
            climate, "getAirTemperatureForCharacter", player, false)
        if ok then temperature = tonumber(value) end
    end
    temperature = temperature or readers.firstNumber(climate, {
        "getTemperature",
        "getAirTemperature",
    })

    return {
        source = climate and "climate_manager" or "unavailable",
        precipitationIntensity = precipitation,
        raining = raining,
        rainIntensity = rainIntensity,
        snowing = snowing,
        snowIntensity = snowIntensity,
        fogIntensity = fogIntensity,
        foggy = foggy,
        temperatureC = temperature,
        windIntensity = readers.firstNumber(climate, {
            "getWindIntensity", "getWindPower",
        }),
        cloudIntensity = readers.readNumber(climate, "getCloudIntensity"),
        humidity = readers.readNumber(climate, "getHumidity"),
        season = readers.readString(climate, "getSeasonName"),
    }
end

return Environment
