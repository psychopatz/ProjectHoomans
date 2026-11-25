local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")

function isClient() return false end
function isServer() return true end

-- 1. Doorway/hazard O(1) anchor nudge in AmbientVisitService_MobileSites
local squares = {
    ["10:10:0"] = {
        getDoor = function(_, north) return north and { id = "door_1" } or nil end,
        isOutside = function() return false end,
    },
    ["11:10:0"] = {
        isOnFire = function() return true end,
        isOutside = function() return false end,
    },
    ["9:10:0"] = {
        getDeadBody = function() return { id = "corpse_1" } end,
        isOutside = function() return false end,
    },
    ["10:11:0"] = {
        isOutside = function() return false end,
        isSolidTrans = function() return false end,
    },
}
function getCell()
    return {
        getGridSquare = function(_, x, y, z)
            return squares[tostring(x) .. ":" .. tostring(y) .. ":" .. tostring(z)]
        end,
    }
end

PNC = {
    Core = { Now = function() return 100000 end },
    Const = { PRESENCE_LIVE = "live" },
    AmbientVisitService = {
        MAX_MOBILE_SITE_CACHE = 32,
        MOBILE_SHELTER_RETRY_HOURS = 0.5,
        Runtime = { mobileSites = {} },
        Internal = {
            MobileSites = {},
            number = function(v, fb) return tonumber(v) or fb end,
            primitiveCopy = function(v) return v end,
            recordID = function(r) return r and r.id end,
            mobileShelterKey = function() return "k1" end,
            boundsOverlap = function() return true end,
        },
    },
}

T.load(SERVER .. "World/PNC_AmbientVisitService_MobileSites.lua")
local MobileSites = PNC.AmbientVisitService.Internal.MobileSites
local shelterSite = {
    x = 10, y = 10, z = 0,
    movementX = 10, movementY = 10, movementZ = 0,
    roomBounds = { minX = 8, maxX = 12, minY = 8, maxY = 12 },
}
MobileSites.adjustAnchorAwayFromHazards(shelterSite)
T.equal(shelterSite.movementX, 10, "nudges away from doorway, fire, and corpse tiles (x)")
T.equal(shelterSite.movementY, 11, "nudges onto clean indoor tile (y)")

-- 2. Event-driven world-event reaction (faceLocation + WorldKnowledge.Acquire + ConvoDSL beat)
local emitted = {}
local registeredHooks = {}
PNC.Semantics = {
    DialogueBeats = {
        RegisterHook = function(name, def) registeredHooks[name] = def end,
        Emit = function(eventType, payload, now)
            emitted[#emitted + 1] = { eventType = eventType, payload = payload, now = now }
            return true
        end,
    },
}

local faced = {}
local npcA = {
    id = "neutral_a",
    actorID = "actor:neutral_a",
    alive = true,
    tacticalClass = "neutral",
    x = 20, y = 20, z = 0,
    zombie = {
        faceLocation = function(_, x, y)
            faced[#faced + 1] = { id = "neutral_a", x = x, y = y }
        end,
    },
    social = { relationships = {} },
}
local npcB = {
    id = "neutral_b",
    actorID = "actor:neutral_b",
    alive = true,
    tacticalClass = "neutral",
    x = 22, y = 20, z = 0,
    zombie = {
        faceLocation = function(_, x, y)
            faced[#faced + 1] = { id = "neutral_b", x = x, y = y }
        end,
    },
}
PNC.SpatialIndex = {
    QueryNPCs = function() return { npcA, npcB } end,
}

local acquired = {}
PsychopatzCore = {
    WorldKnowledge = {
        Acquire = function(actorID, factID)
            acquired[#acquired + 1] = { actorID = actorID, factID = factID }
            return true
        end,
    },
}

T.load(SERVER .. "Semantics/PNC_SemanticDialogueBeats_Environment.lua")
T.truthy(registeredHooks["ambient.rain_shelter.enter"], "registers rain_shelter.enter hook")
T.truthy(registeredHooks["ambient.rain_shelter.clear"], "registers rain_shelter.clear hook")
T.truthy(registeredHooks["ambient.world_event.react"], "registers world_event.react hook")
T.truthy(registeredHooks["ambient.player_sight"], "registers player_sight hook")

local okReact = PNC.Semantics.DialogueBeats.OnWorldEventNearNPCs({
    x = 35, y = 25, topic = "meta_gunshot", factID = "fact:gunshot_1",
}, 100000)
T.truthy(okReact, "nearby neutral pair reacts to gunshot")
T.equal(#faced, 2, "both nearby neutrals physically face gunshot location")
T.equal(faced[1].x, 35, "faces exact event x")
T.equal(#acquired, 2, "both acquire the WorldKnowledge fact so they remember it in dialogue")
T.equal(emitted[1].eventType, "ambient.world_event.react", "emits compiled ConvoDSL world_event.react beat")
T.equal(emitted[1].payload.topic, "meta_gunshot", "passes meta_gunshot topic")

-- 3. Player-proximity first-sight awareness (armed vs reunion vs cooldown)
T.load(SERVER .. "Tasking/Autonomy/PNC_CoPresenceService.lua")
local CoPresence = PNC.CoPresenceService
CoPresence.Reset()

local armedPlayer = {
    id = "player_1",
    getUsername = function() return "Alex" end,
    getX = function() return 24 end,
    getY = function() return 20 end,
    isAiming = function() return true end,
}
local okSight1, topic1 = CoPresence.EvaluatePlayerSight(npcA, armedPlayer, 100000)
T.truthy(okSight1, "neutral stranger reacts on first sight of aiming player")
T.equal(topic1, "armed", "aiming stranger triggers armed warning beat")

local okSightCd, reasonCd = CoPresence.EvaluatePlayerSight(npcA, armedPlayer, 110000)
T.falsy(okSightCd, "player-sight cooldown prevents spam")
T.equal(reasonCd, "cooldown", "reports cooldown")

-- Known friend triggers reunion beat after cooldown
npcA.social.relationships["Alex"] = { familiarity = 60, bond = { class = "friend" } }
local okSight2, topic2 = CoPresence.EvaluatePlayerSight(npcA, armedPlayer, 200000)
T.truthy(okSight2, "reacts again after cooldown expires")
T.equal(topic2, "reunion", "known friend triggers warm reunion beat")

T.finish("pnc_ambient_immersion_smoke")
