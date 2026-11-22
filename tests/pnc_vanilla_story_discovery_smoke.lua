local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})
package.path = "../psychopatzCore/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;" .. package.path

local mockHours = 120
local hooks = {
    LoadChunk = {},
    OnSpawnVehicleEnd = {},
    OnSeeNewRoom = {},
}

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return mockHours / 24 end,
        getWorldAgeHours = function() return mockHours end,
    }
end
Events = {}
for k, v in pairs(hooks) do
    Events[k] = {
        Add = function(fn) v[#v + 1] = fn end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedWorldEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Discovery = Core.VanillaDiscoveryAdapter
local Location = Core.WorldEventLocation
local CoreWKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local scout = { id = "npc_scout", coreActorID = "actor_scout", name = "Eli", alive = true, x = 8155, y = 11525, z = 0 }
local bystander = { id = "npc_bystander", coreActorID = "actor_bystander", name = "Tessa", alive = true, x = 14000, y = 4000, z = 0 }

PNC = {
    Registry = {
        Get = function(id)
            if id == scout.id then return scout end
            if id == bystander.id then return bystander end
            return nil
        end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y)
            if math.abs(x - scout.x) < 150 and math.abs(y - scout.y) < 150 then
                return { scout }
            end
            return {}
        end,
    },
}

require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"

ScopedWorldEvents.Reset()
Observer.Reset()
Discovery.Reset()
CoreWKG.Reset()
Location.ClearProviders()
Location.RegisterProvider("rosewood_town", function(x, y)
    if x >= 8000 and x <= 8300 and y >= 11400 and y <= 11700 then
        return { settlementID = "settlement:rosewood", regionID = "region_south", label = "Rosewood Outskirts", kind = "settlement" }
    end
    return nil
end, 10)
PNC.WorldKnowledge.InstallCoreEventPerceptionHook()

-- 1. Chunk stream captures Ambulance Crash without fabricating omniscient knowledge
for _, fn in ipairs(hooks.LoadChunk) do
    fn({
        vehicleStorySpawnData = {
            story = { getName = function() return "Ambulance Crash" end },
            spawnX = 8150,
            spawnY = 11520,
        },
        zones = {
            {
                type = "ZoneStory",
                pickedRzStory = { getName = function() return "Murder Scene" end },
                pickedXForZoneStory = 8165,
                pickedYForZoneStory = 11535,
            },
        },
    })
end

local beforeScout = PNC.WorldKnowledge.QueryActorFact(scout, { topic = "ambulance crash" }, mockHours)
T.equal(beforeScout.epistemicStatus, "unknown", "no omniscience prior to actual discovery")

-- 2. Scout explores area -> discovers Ambulance Crash & Murder Scene firsthand with location grounding
local promoted = PNC.WorldKnowledge.DiscoverNearbyStories(scout, 80, mockHours)
T.equal(#promoted, 2, "scout discovers 2 nearby stories")

local ambScout = PNC.WorldKnowledge.QueryActorFact(scout, { topic = "ambulance crash" }, mockHours)
T.equal(ambScout.epistemicStatus, "known", "scout knows ambulance crash")
T.equal(ambScout.provenance, "witnessed", "ambulance discovery is witnessed")
T.truthy(ambScout.summary:find("ambulance crash near Rosewood Outskirts", 1, true) ~= nil,
    "ambulance discovery renders location-grounded: " .. tostring(ambScout.summary))

-- Bystander across map still knows nothing
local ambBystanderBefore = PNC.WorldKnowledge.QueryActorFact(bystander, { topic = "ambulance crash" }, mockHours)
T.equal(ambBystanderBefore.epistemicStatus, "unknown", "remote bystander stays ignorant")

-- 3. Propagate discovery rumor to bystander -> uncertain secondhand discovery summary
local shared = assert(PNC.WorldKnowledge.PropagateConversation(scout, bystander, {
    authorized = true,
    channel = "conversation",
    max = 4,
    now = mockHours + 1,
}))
T.equal(#shared, 2, "scout shares discovered stories")
local ambBystanderAfter = PNC.WorldKnowledge.QueryActorFact(bystander, { factID = ambScout.fact.factID }, mockHours + 1)
T.equal(ambBystanderAfter.provenance, "told", "bystander provenance is told")
T.equal(ambBystanderAfter.epistemicStatus, "uncertain", "told discovery stays uncertain")
T.truthy(ambBystanderAfter.summary:find("told me they found a ambulance crash near Rosewood Outskirts", 1, true) ~= nil,
    "told discovery summary: " .. tostring(ambBystanderAfter.summary))

-- 4. Gunstore siege discovered on OnSeeNewRoom -> nearby scout acquires witnessed fact
assert(Discovery.InspectRoomObservation({
    roomName = "gunstore",
    barricadeCount = 3,
    weaponBagCount = 2,
    deadBodyCount = 2,
    x = 8140,
    y = 11510,
}, { nowHours = mockHours + 2 }))
local gunScout = PNC.WorldKnowledge.QueryActorFact(scout, { topic = "sieged gunstore" }, mockHours + 2)
T.equal(gunScout.epistemicStatus, "known", "scout witnesses sieged gunstore")
T.equal(gunScout.provenance, "witnessed", "indoor room discovery marked witnessed")

T.finish("pnc_vanilla_story_discovery_smoke")
