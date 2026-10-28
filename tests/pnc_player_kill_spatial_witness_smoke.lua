local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
})

local spatialQueries = 0
local fallbackScans = 0
local emitted = 0
local record = { id = "npc1", alive = true }
local body = {
    isDead = function() return false end,
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local killer = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local zombie = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

PNC = {
    Core = {},
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Registry = {
        GetLiveZombie = function(id) return id == "npc1" and body or nil end,
        ForEachLive = function()
            fallbackScans = fallbackScans + 1
        end,
    },
    SpatialIndex = {
        QueryNPCs = function(x, y, radius)
            spatialQueries = spatialQueries + 1
            T.equal(x, 1, "query centered on kill x")
            T.equal(y, 0, "query centered on kill y")
            T.truthy(radius > 0, "positive witness radius")
            return { record }
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function()
            return true, "sent"
        end,
    },
    Semantics = {
        SocialReactions = {
            Resolve = function()
                return {
                    fallback = "Good shot.",
                    offerIDs = {},
                    semanticAct = "REACT",
                    topic = "combat",
                    responsePlanID = "test",
                    realizationFamily = "test",
                    realizationID = "test",
                    groundedFactRefs = {},
                }
            end,
        },
        SocialContext = {
            ResolveNPCType = function() return "neutral" end,
        },
    },
    SocialEvents = {
        Emit = function(spec)
            emitted = emitted + 1
            return {
                ok = true,
                reason = "applied",
                eventID = spec.id,
                details = {{
                    relationshipBefore = {},
                    relationshipAfter = {},
                }},
            }
        end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:test" end,
    },
    SocialEventHooksInternal = {
        CombatCall = function(object, method)
            return object and object[method] and object[method](object) or nil
        end,
        CombatAudit = function() end,
        CombatCoordinate = function(object, method, fallback)
            local value = object and object[method] and object[method](object)
            return tonumber(value ~= nil and value or fallback)
        end,
        CombatDistanceSq = function(x1, y1, x2, y2)
            local dx, dy = x2 - x1, y2 - y1
            return dx * dx + dy * dy
        end,
        CombatCanSee = function() return true end,
        CombatRelationshipDelta = function() return {} end,
        CombatRelationshipState = function() return "neutral" end,
        CombatRelationshipTier = function() return "reserved" end,
        CombatSocialRole = function() return "neutral" end,
        CombatDayIndex = function() return 1 end,
        CombatMemoryToday = function() return nil end,
        CombatRememberZombieAwareness = function() return true end,
        CombatReserveAwarenessPresentation = function() return true end,
        CombatCountBand = function() return "few" end,
        CombatPlayerCanHearNPC = function() return true end,
        CombatNewZombieAwarenessEventID = function() return "event" end,
        CombatEmitZombieAwareness = function() return 0 end,
        ThreatIDFor = function() return "threat" end,
        WorldAgeHours = function() return 10 end,
    },
}

local Hooks = T.load(
    "ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter_Witnesses.lua"
)
local count, candidates =
    PNC.SocialEventHooksInternal.RecordPlayerKillWitnesses(
        killer, zombie, { threatID = "threat", source = "test" }
    )
T.equal(spatialQueries, 1, "kill witness uses spatial query")
T.equal(fallbackScans, 0, "normal witness path does not scan all live NPCs")
T.equal(candidates, 1, "one local witness candidate")
T.equal(count, 1, "one witness event emitted")
T.equal(emitted, 1, "social event emitted once")

T.finish("pnc_player_kill_spatial_witness_smoke")
