local T = require "tests/support/test"
T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "common_lua" },
    { "PsychopatzCore", "common" },
})

PNC = { Core = { Now = function() return 100000 end } }

local sim = {
    hour = 22, -- night
    powerOn = false,
}

function getGameTime()
    return {
        getTimeOfDay = function() return sim.hour end,
        getWorldAgeDaysSinceBegin = function() return 3 end,
    }
end

function getWorld()
    return { isHydroPowerOn = function() return sim.powerOn end }
end

function getClimateManager()
    return {
        isRaining = function() return false end,
        getRainIntensity = function() return 0 end,
        getFogIntensity = function() return 0 end,
        isSnowing = function() return false end,
        getSnowIntensity = function() return 0 end,
        getWindIntensity = function() return 0 end,
        getWindspeedKph = function() return 0 end,
        getTemperature = function() return 18 end,
        getIsThunderStorming = function() return false end,
        getWeatherPeriod = function() return { isRunning = function() return false end } end,
    }
end

-- 1. Load & verify all 3 new ConvoDSL packs
local Catalog = require "PNC/ConvoEngine/Dialogue/ResponseCatalog"
local ConvoDSL = require "PNC/ConvoEngine/ConvoDSL/ConvoDSL"
local convoFiles = {
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_immersion_beats.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_building_rooms.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_territory_arrival.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/world/world_vehicle_banter.convo",
    "Contents/mods/ProjectHoomans/common/media/translation/EN/ConvoBlocks/branches/story_quiet_moment.convo",
}
for _, path in ipairs(convoFiles) do
    local fh = assert(io.open(path, "r"), "convo file exists: " .. path)
    local text = fh:read("*a")
    fh:close()
    local script, err = ConvoDSL.ParseText(text, path, "EN")
    T.equal(err, nil, "parse clean: " .. path)
    ConvoDSL.ApplyScripts({ script }, "EN")
end

local poolChecks = {
    { "semantic.world.room.notice", "room_pharmacy_open" },
    { "semantic.world.room.notice", "room_armory_open" },
    { "semantic.world.room.notice", "room_police_open" },
    { "semantic.world.room.notice", "room_firestation_open" },
    { "semantic.world.room.notice", "room_military_open" },
    { "semantic.world.room.notice", "room_prison_open" },
    { "semantic.world.room.notice", "room_school_open" },
    { "semantic.world.room.notice", "room_grocery_open" },
    { "semantic.world.room.notice", "room_hardware_open" },
    { "semantic.world.room.notice", "room_gasstation_open" },
    { "semantic.world.room.notice", "room_warehouse_open" },
    { "semantic.world.room.notice", "room_farm_open" },
    { "semantic.world.room.notice", "room_house_open" },
    { "semantic.world.territory.arrival", "own_base_open" },
    { "semantic.world.territory.arrival", "allied_base_open" },
    { "semantic.world.territory.arrival", "neutral_base_open" },
    { "semantic.world.territory.arrival", "hostile_base_open" },
    { "semantic.world.territory.arrival", "left_hostile_base_open" },
    { "semantic.world.darkness", "dark_indoors_open" },
    { "semantic.world.darkness", "light_restored_open" },
    { "semantic.world.daycycle", "dusk_warning_open" },
    { "semantic.world.daycycle", "dawn_survived_open" },
    { "semantic.world.quiet_moment", "quiet_downtime_open" },
    { "semantic.world.vehicle.banter", "vehicle_enter_open" },
    { "semantic.world.vehicle.banter", "vehicle_low_fuel_open" },
    { "semantic.world.vehicle.banter", "vehicle_exit_open" },
}
for _, c in ipairs(poolChecks) do
    local sel = Catalog.Select(c[1], { npcID = "n1", combatReactionRole = c[2] }, "s1")
    T.truthy(sel ~= nil and type(sel.fallback) == "string" and #sel.fallback > 0,
        "resolved " .. c[1] .. " role=" .. c[2])
end

local quietStory = ConvoDSL.GetStory("convo.quiet_moment.downtime")
T.truthy(quietStory ~= nil, "story convo.quiet_moment.downtime compiled into FlowRegistry")

-- 2. Verify Room-Entry + Darkness/Light + Night->Dawn watchers (actor-agnostic AI squad)
local Beats = require "PNC/Semantics/PNC_SemanticDialogueBeats"
local Dir = PNC.Semantics.ConversationDirector

local aiA = { id = "ai1", alive = true, isIndoors = true, roomName = "pharmacy", hasLight = false }
local aiB = { id = "ai2", alive = true, isIndoors = true, roomName = "pharmacy", hasLight = false }
local aiGroup = { teamKey = "faction:road_crew", members = { aiA, aiB } }

local origFind = Beats.FindCalmGroupsNearPlayer
local origEmit = Beats.Emit
local origEmitGroups = Beats.EmitForNearbyGroups
local emitted = {}
Beats.FindCalmGroupsNearPlayer = function() return { aiGroup } end
Beats.Emit = function(ev, payload)
    emitted[#emitted + 1] = { ev = ev, payload = payload }
    return true, "ok"
end
Beats.EmitForNearbyGroups = function(ev, payload)
    emitted[#emitted + 1] = { ev = ev, payload = payload }
    return true, "ok", 1
end

Beats.ResetRuntime()
-- At night in unpowered pharmacy: triggers room_pharmacy + dark_indoors + dusk_warning
Beats.CheckStateWatchers(100000)
Beats.CheckStateWatchers(120000) -- dwell 20s arms darkness_lit & night_survived

-- Turn on light + advance to dawn (hour = 6)
aiA.hasLight = true
aiB.hasLight = true
sim.hour = 6
local BC = PNC.Semantics.BeatContext
BC.GetWorldWeather(130000, true)
Beats.CheckStateWatchers(130000)

local saw = {}
for _, e in ipairs(emitted) do
    local p = e.payload or {}
    if p.rolePrefix then saw[p.rolePrefix] = true end
end
T.equal(saw.room_pharmacy, true, "room_pharmacy onset fired")
T.equal(saw.dark_indoors, true, "dark_indoors onset fired")
T.equal(saw.light_restored, true, "light_restored remediation fired")
T.equal(saw.dawn_survived, true, "dawn_survived remediation fired")

-- 3. Verify bounded 5-entry Group Chronicle in ConversationDirector
for i = 1, 7 do
    Dir.RecordStoryMoment("faction:road_crew", {
        kind = "milestone_" .. tostring(i),
        topic = "road_morale",
        salience = 65,
    }, 200000 + i * 1000)
end
local chron = Dir.GetChronicle("faction:road_crew")
T.equal(#chron, 5, "Group Chronicle bounded to 5 entries")
T.equal(chron[1].kind, "milestone_7", "newest chronicle entry is first")

-- 4. Verify event-driven Vehicle Banter (low fuel, enter, exit, cooldowns)
emitted = {}
local lowFuelChar = {
    getVehicle = function() return { getRemainingFuelPercentage = function() return 10 end } end,
}
local fullFuelChar = {
    getVehicle = function() return { getRemainingFuelPercentage = function() return 80 end } end,
}
T.equal(Beats.OnVehicleEntered(lowFuelChar, 300000), true, "low fuel warning emits on enter")
T.equal(emitted[#emitted].payload.kind, "vehicle_low_fuel", "kind is vehicle_low_fuel")
T.equal(Beats.OnVehicleEntered(fullFuelChar, 301000), true, "normal enter emits when enter cooldown ready")
T.equal(emitted[#emitted].payload.kind, "vehicle_enter", "kind is vehicle_enter")
T.equal(Beats.OnVehicleEntered(fullFuelChar, 302000), false, "enter cooldown suppresses spam")
T.equal(Beats.OnVehicleExited(fullFuelChar, 303000), true, "vehicle exit emits")
T.equal(emitted[#emitted].payload.kind, "vehicle_exit", "kind is vehicle_exit")

-- 5. Verify unified TerritoryPerception + own_base arrival + hostile_base escape remediation
local Perception = require "PNC/Core/Perception/PNC_Perception/TerritoryPerception"
PNC.Communities = {
    List = function()
        return {
            { id = "comm_gang_1", name = "Iron Skulls", factionID = "fac_gang", status = "active", homeX = 500, homeY = 500, homeRadius = 30 },
        }
    end,
}
PNC.Factions = {
    Registry = {
        byID = {
            fac_gang = { id = "fac_gang", name = "Iron Skulls", isHostile = true },
            fac_ours = { id = "fac_ours", name = "Rosewood Crew" },
        },
    },
    AreHostile = function(a, b) return (a == "fac_ours" and b == "fac_gang") end,
}
PNC.SettlementRepository = {
    State = {
        bases = {
            base_home = { id = "base_home", name = "Rosewood HQ", factionId = "fac_ours", centerX = 100, centerY = 100, radius = 25 },
        },
    },
}

local homeRes = Perception.ResolveTerritoryAt(105, 105, 0, "fac_ours")
T.truthy(homeRes ~= nil and homeRes.relation == "own_base", "SettlementRepository base detected as own_base")
local gangRes = Perception.ResolveTerritoryAt(505, 505, 0, "fac_ours")
T.truthy(gangRes ~= nil and gangRes.relation == "hostile_base", "Hostile gang community detected as hostile_base")

emitted = {}
aiA.factionId = "fac_ours"
aiA.x, aiA.y = 505, 505
aiB.x, aiB.y = 506, 505
Beats.ResetRuntime()
Beats.CheckStateWatchers(500000) -- enters hostile gang turf -> hostile_base onset
Beats.CheckStateWatchers(512000) -- dwell 12s arms territory.hostile_escaped
aiA.x, aiA.y = 105, 105          -- returns safely to own_base!
aiB.x, aiB.y = 106, 105
Beats.CheckStateWatchers(520000) -- emits left_hostile_base remediation

local sawHostileOnset, sawLeftHostile = false, false
for _, e in ipairs(emitted) do
    local p = e.payload or {}
    if p.rolePrefix == "hostile_base" and p.phase == "onset" then sawHostileOnset = true end
    if p.rolePrefix == "left_hostile_base" and p.phase == "remediated" then sawLeftHostile = true end
end
T.equal(sawHostileOnset, true, "crossing into hostile gang radius fires hostile_base beat")
T.equal(sawLeftHostile, true, "leaving hostile gang radius fires left_hostile_base remediation beat")

Beats.FindCalmGroupsNearPlayer = origFind
Beats.Emit = origEmit
Beats.EmitForNearbyGroups = origEmitGroups
print("pnc_immersion_rooms_vehicles_chronicle_smoke: ok")
