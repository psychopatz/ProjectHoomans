local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Core = { Now = function() return 100000 end } }
MoodleType = {
    WET = "WET",
    HYPOTHERMIA = "HYPOTHERMIA",
    HYPERTHERMIA = "HYPERTHERMIA",
    WINDCHILL = "WINDCHILL",
    HAS_A_COLD = "HAS_A_COLD",
}
CharacterStat = { WETNESS = "WETNESS" }

local state = {
    isRaining = true,
    rainIntensity = 0.55,
    fogIntensity = 0,
    isSnowing = false,
    snowIntensity = 0,
    windIntensity = 0.2,
    windKph = 12,
    temp = 14,
    isThunder = false,
    isBlizzard = false,
    isTropical = false,
    isOutside = true,
    wetLevel = 3,
    wetness = 78,
    hypoLevel = 0,
    hyperLevel = 0,
    windchillLevel = 0,
    coldMoodleLevel = 0,
    hasCold = false,
}

function getClimateManager()
    return {
        isRaining = function() return state.isRaining end,
        getRainIntensity = function() return state.rainIntensity end,
        getFogIntensity = function() return state.fogIntensity end,
        isSnowing = function() return state.isSnowing end,
        getSnowIntensity = function() return state.snowIntensity end,
        getWindIntensity = function() return state.windIntensity end,
        getWindspeedKph = function() return state.windKph end,
        getTemperature = function() return state.temp end,
        getIsThunderStorming = function() return state.isThunder end,
        getWeatherPeriod = function()
            return {
                isRunning = function() return state.isBlizzard or state.isTropical or state.isThunder end,
                isBlizzard = function() return state.isBlizzard end,
                isTropicalStorm = function() return state.isTropical end,
                isThunderStorm = function() return state.isThunder end,
            }
        end,
    }
end

function getPlayer()
    return {
        getX = function() return 100 end,
        getY = function() return 100 end,
        getZ = function() return 0 end,
        isOutside = function() return state.isOutside end,
        getMoodles = function()
            return {
                getMoodleLevel = function(_, mt)
                    if mt == MoodleType.WET then return state.wetLevel end
                    if mt == MoodleType.HYPOTHERMIA then return state.hypoLevel end
                    if mt == MoodleType.HYPERTHERMIA then return state.hyperLevel end
                    if mt == MoodleType.WINDCHILL then return state.windchillLevel end
                    if mt == MoodleType.HAS_A_COLD then return state.coldMoodleLevel end
                    return 0
                end,
            }
        end,
        getStats = function()
            return {
                get = function(_, cs)
                    if cs == CharacterStat.WETNESS then return state.wetness end
                    return 0
                end,
            }
        end,
        getBodyDamage = function()
            return { isHasACold = function() return state.hasCold end }
        end,
    }
end

-- Load ConvoDSL + new weather/exposure .convo files directly
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local convoFiles = {
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_weather_rain.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_weather_thunder.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_weather_conditions.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_exposure_suggest.convo",
}
for _, path in ipairs(convoFiles) do
    local fh = assert(io.open(path, "r"), "convo file exists: " .. path)
    local text = fh:read("*a")
    fh:close()
    local script, err = ConvoDSL.ParseText(text, path, "EN")
    T.equal(err, nil, "parse clean: " .. path)
    ConvoDSL.ApplyScripts({ script }, "EN")
end

-- 1. Verify all new weather, thunder, and exposure pools resolve cleanly
local checks = {
    { "semantic.world.weather.thunder", "thunder_strike_open" },
    { "semantic.world.weather.thunder", "thunder_rumble_open" },
    { "semantic.world.weather.rain", "weather_storm_open" },
    { "semantic.world.weather.snow", "weather_blizzard_open" },
    { "semantic.world.weather.fog", "weather_fog_open" },
    { "semantic.world.weather.wind", "weather_wind_open" },
    { "semantic.world.weather.temperature", "weather_heat_open" },
    { "semantic.world.exposure.suggest", "soaking_wet_rain_open" },
    { "semantic.world.exposure.suggest", "freezing_exposure_open" },
    { "semantic.world.exposure.suggest", "overheating_exposure_open" },
    { "semantic.world.exposure.suggest", "catching_cold_open" },
}
for _, c in ipairs(checks) do
    local sel = Catalog.Select(c[1], { npcID = "npc1", combatReactionRole = c[2] }, "s1")
    T.truthy(sel ~= nil and type(sel.fallback) == "string" and #sel.fallback > 0,
        "resolved " .. c[1] .. " role=" .. c[2])
end

-- 2. Verify BeatContext weather + exposure detection
local BC = require "PNC/Semantics/PNC_SemanticBeatContext"
local wRain = BC.GetWorldWeather(100000, true)
T.equal(wRain.weather, "rain", "rain classified")
T.equal(wRain.isHarshWeather, true, "rain is harsh weather")

local exp = BC.GetPlayerExposure(nil, 100000, true)
T.equal(exp.isOutside, true, "player outside detected")
T.equal(exp.isSoakingWet, true, "soaking wet detected from wetLevel=3/wetness=78")

-- 3. Verify Beats.CheckWeatherAndExposure + Beats.OnThunderEvent + upgraded AuditLog
local Beats = require "PNC/Semantics/PNC_SemanticDialogueBeats"
local emittedEvents = {}
local origEmitGroups = Beats.EmitForNearbyGroups
Beats.EmitForNearbyGroups = function(eventName, payload)
    emittedEvents[#emittedEvents + 1] = { eventName = eventName, payload = payload }
    return true, "ok", 1
end

local auditEvents = {}
PNC.PerformanceScalingDiagnostics = {
    BeatsAuditEnabled = true,
    LogBeatsAudit = function(ev, fields)
        auditEvents[ev] = fields
        return true
    end,
}

-- Loaded into already-raining world while outside and soaking wet -> fires soaking_wet_rain!
Beats.ResetRuntime()
local okExp = Beats.CheckWeatherAndExposure(200000)
T.equal(okExp, true, "exposure beat emits when soaking wet outside even without rain transition")
T.equal(emittedEvents[#emittedEvents].eventName, "environment.player_exposure", "emits player_exposure")
T.equal(emittedEvents[#emittedEvents].payload.condition, "soaking_wet_rain", "condition is soaking_wet_rain")

-- Indoors does not emit exposure beat
state.isOutside = false
local okIndoors = Beats.CheckWeatherAndExposure(500000)
T.equal(okIndoors, false, "indoors suppresses outdoor exposure beat")

-- Close thunder strike emits startled thunder beat, then respects cooldown
local okThunder = Beats.OnThunderEvent(350, 400, true, true, false, 600000)
T.equal(okThunder, true, "close thunder strike emits beat")
T.equal(emittedEvents[#emittedEvents].eventName, "environment.thunder_event", "emits thunder_event")
T.equal(emittedEvents[#emittedEvents].payload.isStrike, true, "marked as strike")
local okThunderCd = Beats.OnThunderEvent(350, 400, true, true, false, 610000)
T.equal(okThunderCd, false, "thunder strike cooldown prevents spam")

-- Audit snapshot emits upgraded snapshot + env_state + exposure_state
Beats.LogAuditSnapshot("test", 620000)
T.truthy(auditEvents.snapshot ~= nil, "audit snapshot logged")
T.truthy(auditEvents.env_state ~= nil, "audit env_state logged")
T.truthy(auditEvents.exposure_state ~= nil, "audit exposure_state logged")

Beats.EmitForNearbyGroups = origEmitGroups
print("pnc_weather_thunder_exposure_beats_smoke: ok")
