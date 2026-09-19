-- Project Zomboid engine and packaged-file boundaries used by the harness.

local RuntimeEnvironment = {}

local function packagedRoot(context, modID)
    if tostring(modID) == "ProjectHoomans" then
        return context.repository .. "/Contents/mods/ProjectHoomans/common"
    end
    if tostring(modID) == "PsychopatzCore" then
        return context.coreRepository .. "/Contents/mods/PsychopatzCore/common"
    end
    return nil
end

local function packagedReader(context, modID, relativePath)
    relativePath = tostring(relativePath or "")
    if relativePath == "" or string.sub(relativePath, 1, 1) == "/"
        or string.find(relativePath, "..", 1, true)
        or string.find(relativePath, "\\", 1, true)
    then
        return nil
    end
    local root = packagedRoot(context, modID)
    if not root then return nil end
    local handle = io.open(root .. "/" .. relativePath, "rb")
    if not handle then return nil end
    local closed = false
    return {
        readLine = function()
            if closed then return nil end
            return handle:read("*l")
        end,
        close = function()
            if not closed then
                closed = true
                handle:close()
            end
        end,
    }
end

function RuntimeEnvironment.configure(context)
    local Runtime = context.Runtime
    local Values = context.Values
    local scenario = Runtime.scenario or {}
    local playerData = scenario.player or {}
    local npcData = scenario.npc or {}
    local world = scenario.world or {}
    local runtime = scenario.runtime or {}
    context.scenario = scenario
    context.playerData = playerData
    context.npcData = npcData
    context.world = world
    context.runtime = runtime

    Translator = {
        getLanguage = function()
            return { toString = function()
                return context.Translations.scenarioLanguage(context)
            end }
        end,
    }
    Events = Events or {}
    Events.OnGameBoot = Events.OnGameBoot or { listeners = {} }
    Events.OnGameBoot.listeners = Events.OnGameBoot.listeners or {}
    Events.OnGameBoot.Add = Events.OnGameBoot.Add or function(callback)
        Events.OnGameBoot.listeners[#Events.OnGameBoot.listeners + 1] = callback
    end
    getText = function(key, ...)
        return context.Translations.nativeText(context, key, ...)
    end
    getModFileReader = function(modID, relativePath)
        return packagedReader(context, modID, relativePath)
    end

    local descriptor = {
        getForename = function() return playerData.forename end,
        getSurname = function() return playerData.surname end,
    }
    local player = {
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
        getInventory = function()
            return context.InventoryFixtures.nativeInventory(
                context.playerInventory
            )
        end,
    }
    context.player = player

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
        getDayPlusOne = function()
            return math.floor(Values.number(world.worldAgeHours, 0) / 24) + 1
        end,
        getMonth = function() return 0 end,
        getYear = function() return 1993 end,
    }
    local climate = {
        getPrecipitationIntensity = function()
            return world.weather == "rain" and 0.8 or 0
        end,
        isRaining = function() return world.weather == "rain" end,
        getFogIntensity = function()
            return world.weather == "fog" and 0.8 or 0
        end,
        isFoggy = function() return world.weather == "fog" end,
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

    PsychopatzCore = PsychopatzCore or {}
    PsychopatzCore.Conversation = PsychopatzCore.Conversation or {}
    PsychopatzCore.Conversation.Text = PsychopatzCore.Conversation.Text or {}
    if type(PsychopatzCore.Conversation.Text.Resolve) ~= "function" then
        PsychopatzCore.Conversation.Text.Resolve = function(value)
            return value and (value.fallback or value.text) or ""
        end
    end
    if type(PsychopatzCore.Conversation.Text.RegisterFallback) ~= "function" then
        PsychopatzCore.Conversation.Text.RegisterFallback = function(key, value)
            Runtime.fallbacks = Runtime.fallbacks or {}
            Runtime.fallbacks[key] = value
            return value
        end
    end
    PsychopatzCore.RuntimeRole = {
        AllowsServerCode = function() return true end,
    }
    PsychopatzCore.DebugTrace = {
        IsEnabled = function() return true end,
        Record = function(definition)
            Runtime.trace[#Runtime.trace + 1] = Values.copy(definition)
            return true
        end,
    }
end

return RuntimeEnvironment
