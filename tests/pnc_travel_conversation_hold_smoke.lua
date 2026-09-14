local T = require "tests/support/test"

local now = 1000
local combatTicks = 0
local sceneInterrupts = 0
local travelMoves = 0
local threatActive = true
local enemy = {
    kind = "zombie",
    zombieId = "zombie-1",
    x = 3,
    y = 0,
    z = 0,
    visible = true,
    threatening = true,
}

local player = {
    getX = function() return 0 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "Tester" end,
}

local zombie = {
    isDead = function() return false end,
    getX = function() return 2 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
}

local record = {
    id = "traveler-1",
    alive = true,
    presenceState = "live",
    attackType = "auto",
    x = 2,
    y = 0,
    z = 0,
    orderSpec = { kind = "travel", journeyId = "journey-1" },
    travel = {
        journeyId = "journey-1",
        state = "en_route",
        destination = { x = 20, y = 0, z = 0 },
    },
    runtime = {},
}

PNC = {
    Const = {
        PRESENCE_LIVE = "live",
        ORDER_TRAVEL = "travel",
        ORDER_ROAM = "roam",
        ORDER_CAMP = "camp",
        ORDER_GUARD = "guard",
        ORDER_PATROL = "patrol",
        ORDER_LUMBER = "lumber",
        ORDER_FISHING = "fishing",
        ORDER_SCAVENGE = "scavenge",
        ATTACK_TYPE_AUTO = "auto",
        ATTACK_TYPE_NONE = "none",
        TARGET_IMMEDIATE_THREAT_RADIUS = 6,
        THREAT_GUARD_SCAN_MS = 350,
        THREAT_GUARD_VALIDATE_MS = 250,
        THREAT_GUARD_RELEASE_GRACE_MS = 900,
    },
    Core = {
        Now = function() return now end,
        ResolvePlayerByOnlineID = function(id)
            return id == 7 and player or nil
        end,
    },
    AnimationScenes = {
        definitions = {},
        Register = function(self, id, definition)
            self.definitions[id] = definition
            return true, definition
        end,
        Get = function(self, id)
            return self.definitions[id]
        end,
        Request = function(_, targetRecord, _, id)
            targetRecord.runtime.animationScene = {
                id = id,
                blocking = true,
            }
            return true, targetRecord.runtime.animationScene
        end,
        Stop = function(_, targetRecord)
            targetRecord.runtime.animationScene = nil
            return true
        end,
        Interrupt = function()
            sceneInterrupts = sceneInterrupts + 1
            return false
        end,
    },
    BehaviorMoveIntent = { Hold = function() return true end },
    BehaviorCommon = {
        SetCombatTarget = function(targetRecord, target)
            targetRecord.runtime.target = target
            return true
        end,
        ClearCombatTarget = function(targetRecord)
            targetRecord.runtime.target = nil
        end,
        MoveRecord = function()
            travelMoves = travelMoves + 1
            return true
        end,
    },
    BehaviorTargeting = {
        UpdateTargetFromWorld = function(_, current)
            return threatActive and current or nil
        end,
        ResolveImmediateZombieThreat = function()
            return threatActive and enemy or nil
        end,
    },
    BehaviorCompanion = {
        Internal = {
            ResolveThreatTarget = function()
                return threatActive and enemy or nil
            end,
            EngageResolvedTarget = function()
                return true
            end,
        },
    },
    CombatEngagement = {
        Tick = function()
            combatTicks = combatTicks + 1
            return true
        end,
    },
    SpatialIndex = {
        QueryZombies = function() return {} end,
        QueryNPCs = function() return {} end,
        FindPlayerByUsername = function(username)
            return username == "Tester" and player or nil
        end,
    },
    Relationships = {},
    PlayerCharacters = {
        GetEntityKey = function() return "player:Tester" end,
    },
    Conversation = {},
    Travel = {
        Service = {
            Get = function(targetRecord) return targetRecord.travel end,
            WorldHour = function() return 10 end,
            Advance = function() return true end,
            TickLive = function()
                return {
                    x = 20,
                    y = 0,
                    z = 0,
                    mode = "walk",
                    stopDistance = 0.7,
                }, "en_route"
            end,
        },
    },
}

local definitions = PNC.AnimationScenes.definitions
local registered = PNC.AnimationScenes.Register
local getDefinition = PNC.AnimationScenes.Get
local requestScene = PNC.AnimationScenes.Request
local stopScene = PNC.AnimationScenes.Stop
local interruptScene = PNC.AnimationScenes.Interrupt
PNC.AnimationScenes.Register = function(id, definition)
    return registered(PNC.AnimationScenes, id, definition)
end
PNC.AnimationScenes.Get = function(id)
    return getDefinition(PNC.AnimationScenes, id)
end
PNC.AnimationScenes.Request = function(targetRecord, body, id, options)
    return requestScene(PNC.AnimationScenes, targetRecord, body, id, options)
end
PNC.AnimationScenes.Stop = function(targetRecord, body, reason)
    return stopScene(PNC.AnimationScenes, targetRecord, body, reason)
end
PNC.AnimationScenes.Interrupt = function(targetRecord, body, reason)
    return interruptScene(targetRecord, body, reason)
end

isClient = function() return false end
getTimeInMillis = function() return now end
PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(_, _, fallback) return fallback end,
        },
    },
}

T.load("ProjectHoomans", "shared", "PNC/Conversation/PNC_ConversationScene.lua")
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Combat.lua"
)
T.load(
    "ProjectHoomans",
    "client",
    "PNC/Conversation/PNC_ConversationSafety.lua"
)
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Behaviors/PNC_Behavior_Travel.lua"
)

local Scene = PNC.ConversationScene
local ThreatGuard = PNC.BehaviorThreatGuard
local Safety = PNC.Conversation.Safety

local spec = {
    npcID = record.id,
    character = zombie,
    context = {
        player = player,
        entry = { id = record.id, record = record, zombie = zombie },
    },
}

local started, lease = Scene.Begin(
    record,
    zombie,
    player,
    "conversation-1",
    { maximumDistance = 5.5, dangerRadius = 6 }
)
T.truthy(started, "travel conversation did not begin")
T.equal(lease.travelHold, true, "travel conversation did not mark its hold")
T.equal(record.orderSpec.kind, "travel", "conversation replaced travel order")
T.equal(record.travel.destination.x, 20, "travel destination was lost")

local threatContext = ThreatGuard.Internal.ResolveContext(record)
T.truthy(threatContext, "travel conversation did not create threat context")
T.equal(threatContext.source, "conversation",
    "travel conversation used the wrong threat source")
T.equal(threatContext.ownerKind, "travel",
    "travel conversation used the wrong threat owner")

record.runtime.target = enemy
T.falsy(Scene.Pump(record, zombie, now),
    "travel conversation ended when danger appeared")
T.truthy(record.runtime.conversationLease,
    "travel conversation lease was lost during danger")
now = 1200
local heartbeat, heartbeatLease = Scene.Begin(
    record,
    zombie,
    player,
    "conversation-1",
    { maximumDistance = 5.5, dangerRadius = 6 }
)
T.truthy(heartbeat, "travel conversation heartbeat was blocked by danger")
T.truthy(heartbeatLease.expiresAt > now,
    "travel conversation heartbeat did not renew its lease")

T.truthy(ThreatGuard.Tick(record, zombie, now),
    "travel conversation did not enter ThreatGuard")
T.equal(record.activeBehavior, "CombatGuard:engaged",
    "travel conversation did not enter combat guard")

local combatResult = PNC.BehaviorCombat.TickEngage(record, zombie, enemy)
T.truthy(combatResult, "conversation scene blocked defensive combat")
T.equal(combatTicks, 1, "defensive combat did not reach the engagement layer")
T.equal(sceneInterrupts, 0,
    "travel conversation scene was interrupted by defensive combat")

threatActive = false
now = 1300
T.truthy(ThreatGuard.Tick(record, zombie, now),
    "ThreatGuard did not retain its release grace")
now = 2100
T.falsy(ThreatGuard.Tick(record, zombie, now),
    "ThreatGuard did not release after danger cleared")
T.truthy(record.runtime.conversationLease,
    "conversation lease was lost after danger cleared")
T.truthy(record.runtime.animationScene,
    "conversation hold scene was not restored after danger cleared")

record.runtime.target = enemy
local travelSafety = Safety.Check(spec)
T.falsy(travelSafety,
    "client conversation safety still closed travel dialogue on danger")

Scene.End(record, zombie, "conversation-1", "test_close", { player = player })
T.falsy(record.runtime.conversationLease,
    "conversation close did not release the lease")
T.falsy(record.runtime.animationScene,
    "conversation close did not release the hold scene")
T.equal(record.orderSpec.kind, "travel",
    "conversation close changed the travel order")
T.equal(record.travel.destination.x, 20,
    "conversation close changed the travel destination")
T.truthy(PNC.BehaviorTravel.Tick(record, zombie),
    "travel behavior did not resume after conversation close")
T.equal(travelMoves, 1,
    "travel behavior did not issue movement after conversation close")

record.orderSpec.kind = "guard"
record.travel = nil
record.runtime.target = enemy
local ordinarySafety = Safety.Check(spec)
T.equal(ordinarySafety, "danger",
    "ordinary conversation danger policy was changed")

T.finish("pnc_travel_conversation_hold_smoke")
