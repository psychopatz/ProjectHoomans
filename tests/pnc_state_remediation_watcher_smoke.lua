local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Core = { Now = function() return 100000 end } }

local weatherState = {
    isRaining = true,
    rainIntensity = 0.85, -- storm
    fogIntensity = 0,
    isSnowing = false,
    snowIntensity = 0,
    windIntensity = 0.3,
    windKph = 18,
    temp = 14,
    isThunder = false,
    isBlizzard = false,
    isTropical = false,
}

function getClimateManager()
    return {
        isRaining = function() return weatherState.isRaining end,
        getRainIntensity = function() return weatherState.rainIntensity end,
        getFogIntensity = function() return weatherState.fogIntensity end,
        isSnowing = function() return weatherState.isSnowing end,
        getSnowIntensity = function() return weatherState.snowIntensity end,
        getWindIntensity = function() return weatherState.windIntensity end,
        getWindspeedKph = function() return weatherState.windKph end,
        getTemperature = function() return weatherState.temp end,
        getIsThunderStorming = function() return weatherState.isThunder end,
        getWeatherPeriod = function()
            return {
                isRunning = function() return weatherState.isBlizzard or weatherState.isTropical or weatherState.isThunder end,
                isBlizzard = function() return weatherState.isBlizzard end,
                isTropicalStorm = function() return weatherState.isTropical end,
                isThunderStorm = function() return weatherState.isThunder end,
            }
        end,
    }
end

-- 1. Load & verify both relief .convo packs
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local convoFiles = {
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_exposure_relief.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/needs/needs_relief.convo",
}
for _, path in ipairs(convoFiles) do
    local fh = assert(io.open(path, "r"), "convo file exists: " .. path)
    local text = fh:read("*a")
    fh:close()
    local script, err = ConvoDSL.ParseText(text, path, "EN")
    T.equal(err, nil, "parse clean: " .. path)
    ConvoDSL.ApplyScripts({ script }, "EN")
end

local reliefChecks = {
    { "semantic.world.exposure.relief", "out_of_rain_open" },
    { "semantic.world.exposure.relief", "dried_off_open" },
    { "semantic.world.exposure.relief", "warmed_up_open" },
    { "semantic.world.exposure.relief", "cooled_down_open" },
    { "semantic.world.exposure.relief", "weather_cleared_open" },
    { "semantic.needs.relief", "wound_healed_open" },
    { "semantic.needs.relief", "fed_hydrated_open" },
    { "semantic.needs.relief", "rested_open" },
    { "semantic.needs.relief", "cold_recovered_open" },
    { "semantic.needs.relief", "panic_calmed_open" },
}
for _, c in ipairs(reliefChecks) do
    local sel = Catalog.Select(c[1], { npcID = "ai1", combatReactionRole = c[2] }, "s1")
    T.truthy(sel ~= nil and type(sel.fallback) == "string" and #sel.fallback > 0,
        "resolved " .. c[1] .. " role=" .. c[2])
end

-- 2. Test actor-agnostic AI-controlled group + hysteresis + remediation + StoryMoment
local Beats = require "PNC/Semantics/PNC_SemanticDialogueBeats"
local Dir = PNC.Semantics.ConversationDirector

-- Pure AI-controlled squad (no player owner, no player moodles)
local aiMemberA = {
    id = "ai_alpha",
    alive = true,
    isIndoors = false,
    health = { state = "injured", bleeding = true },
    needs = { hunger = 0.2, thirst = 0.2, fatigue = 0.2 },
    conditionStats = { wetness = 50, wetLevel = 2, panic = 0, stress = 0 },
}
local aiMemberB = {
    id = "ai_beta",
    alive = true,
    isIndoors = false,
    health = { state = "normal", bleeding = false },
    needs = { hunger = 0.2, thirst = 0.2, fatigue = 0.2 },
    conditionStats = { wetness = 45, wetLevel = 2, panic = 0, stress = 0 },
}
local aiGroup = {
    key = "faction:ai_squad_1",
    members = { aiMemberA, aiMemberB },
}

local origFindGroups = Beats.FindCalmGroupsNearPlayer
local origEmit = Beats.Emit
local origEmitGroups = Beats.EmitForNearbyGroups
local emitted = {}
Beats.FindCalmGroupsNearPlayer = function() return { aiGroup } end
Beats.Emit = function(eventName, payload)
    emitted[#emitted + 1] = { eventName = eventName, payload = payload }
    return true, "ok"
end
Beats.EmitForNearbyGroups = function(eventName, payload)
    emitted[#emitted + 1] = { eventName = eventName, payload = payload }
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

Beats.ResetRuntime()

-- Step A: Hysteresis check (outside for 3s < 10s, then indoors -> must NOT emit relief)
Beats.CheckStateWatchers(100000)
aiMemberA.isIndoors = true
aiMemberB.isIndoors = true
Beats.CheckStateWatchers(103000)
T.equal(#emitted, 0, "short 3s flicker below hysteresis does not emit relief")

-- Step B: AI squad goes outside in storm for 15s (arms rain_shelter + wound_healed + weather_cleared)
aiMemberA.isIndoors = false
aiMemberB.isIndoors = false
Beats.CheckStateWatchers(200000)
Beats.CheckStateWatchers(225000) -- dwell = 25s >= all minActiveMs

-- Now AI squad ducks indoors AND aiMemberA's wound is healed AND storm clears!
aiMemberA.isIndoors = true
aiMemberB.isIndoors = true
aiMemberA.health.state = "normal"
aiMemberA.health.bleeding = false
weatherState.isRaining = false
weatherState.rainIntensity = 0

Beats.CheckStateWatchers(235000)

local sawRainRelief = false
local sawWoundRelief = false
local sawWeatherCleared = false
for _, e in ipairs(emitted) do
    local p = e.payload or {}
    if p.rolePrefix == "out_of_rain" and p.phase == "remediated" then sawRainRelief = true end
    if p.rolePrefix == "wound_healed" and p.phase == "remediated" then sawWoundRelief = true end
    if p.rolePrefix == "weather_cleared" and p.phase == "remediated" then sawWeatherCleared = true end
end
T.equal(sawRainRelief, true, "AI group stepping indoors fires out_of_rain remediation beat")
T.equal(sawWoundRelief, true, "AI actor wound healed fires wound_healed remediation beat")
T.equal(sawWeatherCleared, true, "storm clearing fires weather_cleared remediation beat")

-- Verify StoryMoment recorded in ConversationDirector for the AI squad
local recall = Dir.GatherStoryRecall(aiGroup.key, aiGroup.members, nil, 236000)
T.truthy(type(recall) == "table" and #recall >= 1, "ConversationDirector recorded StoryMoment for AI group remediation")

-- Verify watcher_state in audit snapshot
Beats.LogAuditSnapshot("test", 240000)
T.truthy(auditEvents.watcher_state ~= nil, "audit snapshot includes watcher_state")

Beats.FindCalmGroupsNearPlayer = origFindGroups
Beats.Emit = origEmit
Beats.EmitForNearbyGroups = origEmitGroups
print("pnc_state_remediation_watcher_smoke: ok")
