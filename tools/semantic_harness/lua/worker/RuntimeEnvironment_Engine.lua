-- Headless Project Zomboid engine objects used by the semantic runtime.

local Engine = {}

function Engine.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local playerData = context.playerData
    local world = context.world
    local runtime = context.runtime
    local descriptor = {
        getForename = function() return playerData.forename end,
        getSurname = function() return playerData.surname end,
    }
    local player = {
        isFemale = function()
            return playerData.gender == "female"
        end,
        getUsername = function()
            return playerData.username or playerData.accountKey
                or playerData.displayName
                or "harness-player"
        end,
        getPlayerNum = function()
            return playerData.playerNum
        end,
        getPlayerIndex = function()
            return playerData.playerNum
        end,
        getModData = function()
            Runtime.playerModData = Runtime.playerModData or {}
            return Runtime.playerModData
        end,
        getOnlineID = function()
            return playerData.onlineID or 1
        end,
        getDescriptor = function() return descriptor end,
        getDisplayName = function()
            return playerData.displayName
                or context.SemanticAdapters.playerName(context, playerData)
        end,
        getX = function() return 0 end,
        getY = function() return 0 end,
        getZ = function() return 0 end,
        getHoursSurvived = function()
            return Values.number(world.worldAgeHours, 0)
        end,
        getZombieKills = function()
            return world.zombieKills
        end,
        getInventory = function()
            return context.InventoryFixtures.nativeInventory(
                context.playerInventory
            )
        end,
    }
    player.characterUUID = playerData.characterUUID
    context.player = player
    -- Project Zomboid supplies ZombRand to Core ID generation. Keep the
    -- worker deterministic while preserving that production API boundary.
    ZombRand = function(maximum)
        maximum = tonumber(maximum) or 1
        if maximum <= 1 then return 0 end
        return math.floor((tonumber(Runtime.now) or 0) % maximum)
    end

    local gameTime = {
        getWorldAgeHours = function()
            return Values.number(world.worldAgeHours, 0)
        end,
        getTimeOfDay = function() return Values.number(world.timeOfDay, 12) end,
        getHour = function()
            return math.floor(Values.number(world.timeOfDay, 12))
        end,
        getMinutes = function()
            local time = Values.number(world.timeOfDay, 12)
            return math.floor((time - math.floor(time)) * 60 + 0.5)
        end,
        -- Build 42's Identity resolver reads the zero-based calendar day;
        -- keep the headless engine seam explicit instead of special-casing
        -- backstory reconstruction in the worker command.
        getDay = function()
            return math.floor(Values.number(world.worldAgeHours, 0) / 24) % 28
        end,
        getDayPlusOne = function()
            return math.floor(Values.number(world.worldAgeHours, 0) / 24) + 1
        end,
        getMonth = function() return 0 end,
        getYear = function() return 1993 end,
    }
    local climate = {
        getPrecipitationIntensity = function()
            if world.weather == "rain" then return 0.8 end
            if world.weather == "clear" or world.weather == "fog"
                or world.weather == "snow"
            then
                return 0
            end
            return nil
        end,
        isRaining = function()
            if world.weather == "rain" then return true end
            if world.weather == "clear" or world.weather == "fog"
                or world.weather == "snow"
            then
                return false
            end
            return nil
        end,
        getFogIntensity = function()
            if world.weather == "fog" then return 0.8 end
            if world.weather == "clear" or world.weather == "rain"
                or world.weather == "snow"
            then
                return 0
            end
            return nil
        end,
        getSnowIntensity = function()
            if world.weather == "snow" then return 0.8 end
            if world.weather == "clear" or world.weather == "rain"
                or world.weather == "fog"
            then
                return 0
            end
            return nil
        end,
        isSnowing = function()
            if world.weather == "snow" then return true end
            if world.weather == "clear" or world.weather == "rain"
                or world.weather == "fog"
            then
                return false
            end
            return nil
        end,
        isFoggy = function()
            if world.weather == "fog" then return true end
            if world.weather == "clear" or world.weather == "rain"
                or world.weather == "snow"
            then
                return false
            end
            return nil
        end,
        getTemperature = function() return 20 end,
    }

    getGameTime = function() return gameTime end
    getClimateManager = function() return climate end
    getTimeInMillis = function() return Runtime.now end
    getTimestampMs = function() return Runtime.now end
    getSpecificPlayer = function(index) return index == 0 and player or nil end
    getPlayer = function() return player end
    instanceof = function(value, className)
        return value == player and className == "IsoGameCharacter"
    end
    isServer = function() return runtime.mode == "multiplayer" end
    isClient = function() return runtime.mode == "multiplayer" end
end

return Engine
