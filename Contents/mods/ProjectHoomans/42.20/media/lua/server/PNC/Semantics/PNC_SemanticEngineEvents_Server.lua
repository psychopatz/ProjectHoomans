-- Server adapter for authoritative engine notifications.
--
-- The detector remains owned by PsychopatzCore and social combat keeps its
-- own consumer. This adapter has a separate consumer ID and only publishes a
-- bounded semantic event; it does not mutate relationship state or dispatch
-- gameplay commands.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Events = PNC.Semantics.EngineEvents
    or require "PNC/Semantics/PNC_SemanticEngineEvents"
local Detector = require
    "PsychopatzCore/ZombieKillDetector/PsychopatzZombieKillDetector"

local function call(object, method, ...)
    if not object or not object[method] then return nil end
    local ok, value = pcall(object[method], object, ...)
    return ok and value or nil
end

local function playerKey(player)
    local value = call(player, "getOnlineID")
        or call(player, "getUsername")
    value = tostring(value or "")
    return value ~= "" and value or "unknown"
end

local function worldAgeHours()
    if type(getGameTime) ~= "function" then return nil end
    local gameTime = getGameTime()
    return tonumber(call(gameTime, "getWorldAgeHours"))
end

local function onServerKill(killer, zombie, context)
    local nativeKills = tonumber(call(killer, "getZombieKills"))
    local zombieID = call(zombie, "getOnlineID")
    return Events.Publish("engine:zombie_killed", {
        actorKey = playerKey(killer),
        nativeKillCount = nativeKills,
        zombieKey = zombieID and tostring(zombieID) or nil,
        occurredAt = worldAgeHours(),
        source = context and context.source or "zombie_kill_detector",
    })
end

local registered, reason = Detector.RegisterConsumer(
    "ProjectHoomans.Semantics.EngineFacts",
    { onServerKill = onServerKill }
)

if PNC.Core and PNC.Core.LogInfo then
    PNC.Core.LogInfo(
        "[SemanticEngineEvents] consumer=ProjectHoomans.Semantics.EngineFacts "
        .. "registered=" .. tostring(registered)
        .. " reason=" .. tostring(reason or "nil")
    )
end

return Events
