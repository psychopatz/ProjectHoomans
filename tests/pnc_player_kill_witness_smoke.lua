local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "server" },
    { "ProjectHoomans", "shared" },
    { "PsychopatzCore", "common" },
})

local events = {}
local logs = {}
local relationshipBroadcasts = {}
local player = {
    kind = "player",
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local zombie = {
    kind = "zombie",
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}
local visible = {
    id = "visible_npc",
    alive = true,
    x = 2,
    y = 0,
    z = 0,
    seePlayer = true,
    seeZombie = true,
}
local farAway = {
    id = "far_npc",
    alive = true,
    x = 30,
    y = 0,
    z = 0,
    seePlayer = true,
    seeZombie = true,
}
local occluded = {
    id = "occluded_npc",
    alive = true,
    x = 2,
    y = 1,
    z = 0,
    seePlayer = false,
    seeZombie = true,
}
local dead = {
    id = "dead_npc",
    alive = true,
    x = 2,
    y = -1,
    z = 0,
    seePlayer = true,
    seeZombie = true,
}
local bodies = {
    { visible, { getX = function() return 2 end, getY = function() return 0 end, getZ = function() return 0 end } },
    { farAway, { getX = function() return 30 end, getY = function() return 0 end, getZ = function() return 0 end } },
    { occluded, { getX = function() return 2 end, getY = function() return 1 end, getZ = function() return 0 end } },
    { dead, {
        getX = function() return 2 end,
        getY = function() return -1 end,
        getZ = function() return 0 end,
        isDead = function() return true end,
    } },
}

isClient = function() return false end
isServer = function() return true end

PNC = {
    Const = { ZOMBIE_TARGET_RADIUS = 12 },
    Core = {
        DistanceSq = function(x1, y1, x2, y2)
            local dx = x2 - x1
            local dy = y2 - y1
            return (dx * dx) + (dy * dy)
        end,
        LogInfo = function(message) logs[#logs + 1] = message end,
    },
    EntityRef = {
        ForNPC = function(id) return "npc:" .. tostring(id) end,
    },
    Perception = {
        CanSeeWorldObject = function(record, target)
            if target == player then return record.seePlayer end
            if target == zombie then return record.seeZombie end
            return false
        end,
    },
    Registry = {
        ForEachLive = function(callback)
            for index = 1, #bodies do
                callback(bodies[index][1], bodies[index][2], bodies[index][1].id)
            end
        end,
    },
    SocialEvents = {
        Emit = function(eventSpec)
            events[#events + 1] = eventSpec
            return {
                ok = true,
                reason = nil,
                eventID = eventSpec.id,
                details = {
                    {
                        relationshipBefore = {
                            approval = 0,
                            respect = 0,
                            familiarity = 0,
                        },
                        relationshipAfter = {
                            approval = 2,
                            respect = 4,
                            familiarity = 2,
                        },
                    },
                },
            }
        end,
    },
    Network = {
        SendConversationRelationshipForNPC = function(
            targetPlayer, npcID, reason, context
        )
            relationshipBroadcasts[#relationshipBroadcasts + 1] = {
                targetPlayer = targetPlayer,
                npcID = npcID,
                reason = reason,
                context = context,
            }
            return true, nil
        end,
    },
    SocialEventHooks = {
        ResolvePlayerKey = function() return "player:tester:character" end,
        HandleClientZombieKill = function()
            return true, "neutralized_without_protection"
        end,
    },
    SocialEventHooksInternal = {
        ThreatIDFor = function(value)
            return value.threatID
        end,
        WorldAgeHours = function() return 100 end,
    },
}

zombie.threatID = "local:test_sp"
local Hooks = T.load("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_CombatAdapter.lua")
local H = PNC.SocialEventHooksInternal

local result, reason = H.OnZombieDead(player, zombie, {
    runtime = "single_player",
    threatID = "local:test_sp",
    killerSource = "weapon_hit_cache",
})
T.equal(result, true, "SP kill dispatch succeeds")
T.equal(reason, "neutralized_without_protection", "SP kill reason preserved")
T.equal(#events, 1, "only nearby visible NPC receives SP witness event")
T.equal(events[1].type, "witnessed_player_kill", "witness event type")
T.equal(events[1].actorKey, "player:tester:character", "witness actor key")
T.equal(events[1].targetKey, "npc:visible_npc", "witness observer key")
T.equal(events[1].context.threatID, "local:test_sp", "witness threat ID")
T.equal(#relationshipBroadcasts, 1,
    "SP witness uses the relationship presentation transport")
T.equal(relationshipBroadcasts[1].targetPlayer, player,
    "SP feedback is sent to the killer client")
T.equal(relationshipBroadcasts[1].npcID, "visible_npc",
    "SP feedback identifies the witnessing NPC")
T.equal(relationshipBroadcasts[1].context.relationshipDelta.approval, 2,
    "SP feedback carries the approval delta")
T.equal(relationshipBroadcasts[1].context.relationshipDelta.respect, 4,
    "SP feedback carries the respect delta")
T.equal(relationshipBroadcasts[1].context.ambientFlavor.flavorID,
    "social.witnessed_player_kill",
    "SP feedback carries the reusable flavor ID")
T.equal(relationshipBroadcasts[1].context.ambientFlavor.socialRole,
    "neutral",
    "SP feedback classifies the witness for flavor")
T.equal(relationshipBroadcasts[1].context.ambientFlavor.llmPriority,
    90,
    "SP feedback marks client LLM flavor as the highest social priority")
T.truthy(#logs >= 3, "SP witness detection is logged")

zombie.threatID = "online:test_mp"
local mpResult = H.OnZombieDead(player, zombie, {
    runtime = "dedicated_server",
    threatID = "online:test_mp",
    killerSource = "client_report",
})
T.equal(mpResult, true, "MP kill dispatch succeeds")
T.equal(#events, 2, "MP kill also produces a witness event")
T.equal(events[2].context.killerSource, "client_report",
    "MP witness preserves kill source")
T.equal(#relationshipBroadcasts, 2,
    "MP witness uses the relationship presentation transport")
T.equal(relationshipBroadcasts[2].reason, "witnessed_player_kill",
    "MP feedback preserves the witness event reason")
T.equal(relationshipBroadcasts[2].context.ambientFlavor.eventType,
    "witnessed_player_kill",
    "MP feedback carries the same client flavor event")

T.finish("pnc_player_kill_witness_smoke")
