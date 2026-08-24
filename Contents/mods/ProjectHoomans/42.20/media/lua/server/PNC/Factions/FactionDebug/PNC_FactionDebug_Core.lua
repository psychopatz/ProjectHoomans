if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionDebug = PNC.FactionDebug or {}
PNC.FactionDebug.Internal = PNC.FactionDebug.Internal or {}

local Debug = PNC.FactionDebug
local Internal = Debug.Internal
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance


local Debug = PNC.FactionDebug
local Factions = PNC.Factions
local Archetypes = PNC.FactionArchetypes
local Types = PNC.FactionTypes
local Core = PNC.Core
local Balance = PNC.FactionBalance

Debug.LastValidation = Debug.LastValidation or nil
Debug.LastScenario = Debug.LastScenario or nil

local function groupSpec(player, args, at)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        siteSelection = "random_house",
        communityMode = "settled",
        groupSize = args and args.groupSize,
        presenceMode = args and args.presenceMode,
        worldAgeHours = at,
        debug = true,
    }
end

local function mobileGroupSpec(player, args, at)
    return {
        x = player and player.getX and player:getX() or 0,
        y = player and player.getY and player:getY() or 0,
        z = player and player.getZ and player:getZ() or 0,
        groupSize = args and args.groupSize,
        presenceMode = args and args.presenceMode,
        mobilePathMode = args and args.mobilePathMode,
        worldAgeHours = at,
        debug = true,
    }
end

local function generatedFactionName(archetypeID, at)
    local Generator = PNC.FactionNameGenerator
    if not Generator or not Generator.GenerateFactionName then
        return "Survivor " .. tostring(archetypeID)
    end
    local randomSalt = 0
    if ZombRand then
        local ok
        local value
        ok, value = pcall(ZombRand, 1000000)
        if ok then randomSalt = tonumber(value) or 0 end
    end
    local used = {}
    for _, faction in ipairs(Factions.List()) do
        used[faction.name] = true
    end
    local attempt
    for attempt = 1, 32 do
        local seed = table.concat({
            tostring(archetypeID),
            tostring(math.floor((tonumber(at) or 0) * 1000)),
            tostring(randomSalt),
            tostring(attempt),
        }, ":")
        local name = Generator.GenerateFactionName(
            archetypeID,
            seed
        )
        if not used[name] then return name end
    end
    return "New " .. Generator.GenerateFactionName(
        archetypeID,
        tostring(at) .. ":fallback"
    )
end

local function copy(value)
    return Core.DeepCopy(value)
end

local function worldAgeHours()
    if getGameTime and getGameTime()
        and getGameTime().getWorldAgeHours
    then
        return math.max(
            0,
            tonumber(getGameTime():getWorldAgeHours()) or 0
        )
    end
    return 0
end


Internal.groupSpec = groupSpec
Internal.mobileGroupSpec = mobileGroupSpec
Internal.generatedFactionName = generatedFactionName
Internal.copy = copy
Internal.worldAgeHours = worldAgeHours

return Debug
