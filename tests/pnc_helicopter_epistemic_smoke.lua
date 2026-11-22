local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})
package.path = "../psychopatzCore/Contents/mods/PsychopatzCore/42.20/media/lua/shared/?.lua;" .. package.path

local heliState = { active = true, x = 8050, y = 11550 }
local spatialQueries = 0

isClient = function() return false end
isServer = function() return true end
getGameTime = function()
    return {
        getWorldAgeDaysSinceBegin = function() return 6 end,
        getWorldAgeHours = function() return 144 end,
    }
end
getWorld = function()
    return {
        helicopter = {
            isActive = function() return heliState.active end,
            x = heliState.x,
            y = heliState.y,
        },
    }
end
getCell = function()
    return {
        getGridSquare = function(_, x)
            -- Mock: x >= 8100 is indoors (has a Room), x < 8100 is outdoors
            if x >= 8100 then
                return {
                    getRoom = function() return { name = "livingroom" } end,
                }
            end
            return {
                getRoom = function() return nil end,
            }
        end,
    }
end

PsychopatzCore = {}
local Core = require "PsychopatzCore/00_PsychopatzCore_Init"
local ScopedWorldEvents = Core.ScopedWorldEvents
local Observer = Core.VanillaEventObserver
local Location = Core.WorldEventLocation
local CoreWKG = require "PsychopatzCore/WorldKnowledge/PsychopatzWorldKnowledge"

local outdoorNPC = {
    id = "npc_out", coreActorID = "actor_out", name = "Maya", alive = true,
    x = 8060, y = 11540, z = 0,
}
local indoorNPC = {
    id = "npc_in", coreActorID = "actor_in", name = "Leo", alive = true,
    x = 8120, y = 11540, z = 0,
}
local farNPC = {
    id = "npc_far", coreActorID = "actor_far", name = "Sora", alive = true,
    x = 12000, y = 4000, z = 0,
}
local radioNPC = {
    id = "npc_radio", coreActorID = "actor_radio", name = "Evan", alive = true,
    x = 13000, y = 4000, z = 0,
}

PNC = {
    Registry = {
        Get = function(id)
            local list = { outdoorNPC, indoorNPC, farNPC, radioNPC }
            for _, r in ipairs(list) do
                if r.id == id then return r end
            end
            return nil
        end,
    },
    SpatialIndex = {
        QueryNPCs = function()
            spatialQueries = spatialQueries + 1
            return { outdoorNPC, indoorNPC }
        end,
    },
}

require "PNC/WorldKnowledge/PNC_WorldKnowledge"
require "PNC/WorldKnowledge/PNC_WorldKnowledge_PZ"

ScopedWorldEvents.Reset()
Observer.Reset()
CoreWKG.Reset()
PNC.WorldKnowledge.ResetWorldStateRuntime()
Location.ClearProviders()
Location.RegisterProvider("hoomans_town", function(x, y)
    if x >= 8000 and x <= 8200 then
        return {
            settlementID = "settlement:rosewood",
            regionID = "region_south",
            label = "Rosewood",
            kind = "settlement",
        }
    end
    return nil
end, 10)

local res = assert(PNC.WorldKnowledge.ObserveHelicopterEpisode(144, {
    helicopter = {
        isActive = function() return heliState.active end,
        x = heliState.x,
        y = heliState.y,
    },
}))
T.equal(res.action, "started", "helicopter started")
T.equal(spatialQueries, 1, "used single bounded spatial query (no full NPC scan)")
T.equal(ScopedWorldEvents.GetStats().activeCount, 1, "one canonical ScopedWorldEvents entry for all NPCs")

-- 1. Outdoor witness has witnessed provenance & location-grounded rendering
local qOut = PNC.WorldKnowledge.QueryActorFact(outdoorNPC, { factID = res.factID }, 144)
T.equal(qOut.epistemicStatus, "known", "outdoor witness knows helicopter")
T.equal(qOut.provenance, "witnessed", "outdoor provenance is witnessed")
T.truthy(qOut.summary:find("saw a helicopter pass over Rosewood", 1, true) ~= nil,
    "outdoor witness renders grounded location: " .. tostring(qOut.summary))

-- 2. Indoor nearby listener has environmental provenance & cautious indoor rendering
local qIn = PNC.WorldKnowledge.QueryActorFact(indoorNPC, { factID = res.factID }, 144)
T.equal(qIn.epistemicStatus, "known", "indoor listener heard helicopter")
T.equal(qIn.provenance, "environmental", "indoor provenance is environmental")
T.equal(qIn.reference.acquisitionPath, "helicopter_indoor_audio", "indoor acquisition path")
T.truthy(qIn.summary:find("heard a helicopter", 1, true) ~= nil,
    "indoor listener renders hearing helicopter: " .. tostring(qIn.summary))
T.falsy(qIn.summary:find("saw", 1, true),
    "indoor listener does not falsely claim visual sighting")

-- 3. Uninformed far NPC is unknown until told; radio recipient gets radio provenance
local qFarBefore = PNC.WorldKnowledge.QueryActorFact(farNPC, { factID = res.factID }, 144)
T.equal(qFarBefore.epistemicStatus, "unknown", "far NPC does not know helicopter omnisciently")

local shared = assert(PNC.WorldKnowledge.PropagateConversation(outdoorNPC, farNPC, {
    authorized = true,
    channel = "conversation",
    now = 145,
}))
T.equal(#shared, 1, "told propagation shares single canonical fact")
local qFarAfter = PNC.WorldKnowledge.QueryActorFact(farNPC, { factID = res.factID }, 145)
T.equal(qFarAfter.provenance, "told", "far NPC gets told provenance")
T.equal(qFarAfter.epistemicStatus, "uncertain", "told rumor is uncertain")
T.truthy(qFarAfter.summary:find("told me", 1, true) ~= nil, "told summary reflects hearsay")

local radioShared = assert(PNC.WorldKnowledge.PropagateConversation(outdoorNPC, radioNPC, {
    authorized = true,
    channel = "radio",
    now = 146,
}))
T.equal(#radioShared, 1, "radio propagation shares same canonical fact")
local qRadio = PNC.WorldKnowledge.QueryActorFact(radioNPC, { factID = res.factID }, 146)
T.equal(qRadio.provenance, "radio", "radio provenance preserved")
T.truthy(qRadio.summary:find("Radio traffic", 1, true) ~= nil, "radio summary reflects radio channel")

T.finish("pnc_helicopter_epistemic_smoke")
