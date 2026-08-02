local SHARED =
    "Contents/mods/ProjectHoomans/common/media/lua/shared/PNC/Conversation/"
local CLIENT =
    "Contents/mods/ProjectHoomans/common/media/lua/client/PNC/Conversation/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual), 2)
    end
end

local now = 1000
local candidates = {}
local stoppedReason
local held = 0
local definitions = {}
local staleAttacker
local pacifications = {}

local player = {
    x = 0,
    y = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function() return 0 end,
    getOnlineID = function() return 7 end,
    getUsername = function() return "Tester" end,
    getAttackedBy = function() return staleAttacker end,
}
local npc = {
    x = 2,
    y = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function() return 0 end,
    isDead = function() return false end,
    getTarget = function() return player end,
    getModData = function() return { PNC_UUID = "npc-1" } end,
}
local enemy = {
    x = 4,
    y = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function() return 0 end,
    isDead = function() return false end,
    getModData = function() return {} end,
}
local deadEnemy = {
    getX = function() return 1 end,
    getY = function() return 0 end,
    getZ = function() return 0 end,
    isDead = function() return true end,
}
local record = {
    id = "npc-1",
    alive = true,
    presenceState = "live",
    activeJob = "FollowOwner",
    activeBehavior = "FollowOwner",
    faction = "hostile",
    hostility = { attackPlayers = true },
    health = {},
    runtime = {},
}

PNC = {
    Const = { MODULE = "PNC", PRESENCE_LIVE = "live" },
    Core = {
        Now = function() return now end,
        ResolvePlayerByOnlineID = function(id)
            if id == 7 then return player end
        end,
    },
    AnimationScenes = {
        Register = function(id, definition)
            definitions[id] = definition
            return true, definition
        end,
        Get = function(id) return definitions[id] end,
        Request = function(targetRecord, _, id)
            targetRecord.runtime.animationScene = { id = id }
            held = held + 1
            return true, targetRecord.runtime.animationScene
        end,
        Stop = function(targetRecord, _, reason)
            targetRecord.runtime.animationScene = nil
            stoppedReason = reason
            return true
        end,
    },
    Registry = {
        Get = function(id)
            if id == "npc-1" then return record end
        end,
        GetLiveZombie = function(id)
            if id == "npc-1" then return npc end
        end,
        FindRecordByZombie = function() return nil end,
    },
    SpatialIndex = {
        QueryZombies = function() return candidates end,
        QueryNPCs = function() return {} end,
    },
    PlayerCharacters = {
        GetEntityKey = function()
            return "player:Tester:char_tester", "resolved"
        end,
    },
    Factions = {
        GetOrganizationalFactionID = function()
            return "faction_hostile"
        end,
        PacifyForPlayer = function(factionID, key, options)
            pacifications[#pacifications + 1] = {
                factionID = factionID,
                key = key,
                options = options,
            }
            return true, "pacified", {
                untilWorldAgeHours = 1,
            }
        end,
    },
}
PsychopatzCore = {
    Conversation = {
        Settings = {
            Get = function(key, fallback)
                if key == "maximumConversationDistance" then return 5.5 end
                if key == "conversationDangerRadius" then return 8 end
                if key == "closeConversationOnDanger" then return true end
                return fallback
            end,
        },
    },
}
isClient = function() return false end
getTimeInMillis = function() return now end
getSpecificPlayer = function() return player end
getCell = function()
    return {
        getZombieList = function()
            return {
                size = function() return #candidates end,
                get = function(_, index) return candidates[index + 1] end,
            }
        end,
    }
end

dofile(SHARED .. "PNC_ConversationScene.lua")
dofile(CLIENT .. "PNC_ConversationSafety.lua")
package.preload["PNC/Conversation/PNC_ConversationSafety"] =
    function() return PNC.Conversation.Safety end
dofile(CLIENT .. "PNC_ConversationLifecycle.lua")

local Scene = PNC.ConversationScene
local Safety = PNC.Conversation.Safety
local lifecycle = PNC.Conversation.Lifecycle.Create()
local spec = {
    npcID = "npc-1",
    character = npc,
    context = {
        player = player,
        entry = { id = "npc-1", zombie = npc, record = record },
    },
}

local started = Scene.Begin(record, npc, player, "lease-1", {
    maximumDistance = 5.5,
    dangerRadius = 8,
})
assertEqual(started, true, "conversation scene begins")
assertEqual(record.activeJob, "FollowOwner", "job is preserved")
assertEqual(record.activeBehavior, "FollowOwner", "behavior is preserved")
assertEqual(held, 1, "blocking idle requests movement hold")
staleAttacker = deadEnemy
assertEqual(Scene.HasThreat(record, npc, player, 8), false,
    "stale attacker and managed-body engine target are ignored")
assertEqual(Safety.Check(spec), nil,
    "stale engine combat references do not close the UI")

now = 1800
started = Scene.Begin(record, npc, player, "lease-1", {
    maximumDistance = 5.5,
    dangerRadius = 8,
})
assertEqual(started, true, "same lease heartbeat")
assertEqual(held, 1, "heartbeat does not restart the idle scene")

player.x = 12
assertEqual(Scene.Pump(record, npc, now), true,
    "server ends out-of-range conversation")
assertEqual(record.runtime.conversationLease, nil, "lease cleared")
assertEqual(stoppedReason, "conversation_distance",
    "distance stop reason")
assertEqual(record.nextThinkAt, now, "AI is scheduled to resume immediately")

player.x = 0
candidates = { npc }
assertEqual(Scene.HasThreat(record, npc, player, 8), false,
    "talking NPC is not its own threat")
candidates = { enemy }
local dangerStarted, dangerReason = Scene.Begin(
    record,
    npc,
    player,
    "lease-danger",
    { maximumDistance = 5.5, dangerRadius = 8 }
)
assertEqual(dangerStarted, false, "nearby enemy rejects conversation")
assertEqual(dangerReason, "danger", "server danger reason")
assertEqual(Safety.Check(spec), "danger", "client danger reason")

candidates = {}
player.x = 8
assertEqual(Safety.Check(spec), "distance", "client distance reason")
player.x = 0

local state, reason = lifecycle.begin({}, spec)
assert(type(state) == "table" and reason == nil,
    "project lifecycle starts and leases NPC")
now = now + 1200
assertEqual(lifecycle.update({}, spec, state), nil,
    "safe heartbeat keeps conversation active")
record.runtime.target = enemy
now = now + 200
assertEqual(lifecycle.update({}, spec, state), "danger",
    "combat snaps dialogue out")
record.runtime.target = nil
lifecycle.finish({}, spec, state, "danger")
assertEqual(record.runtime.conversationLease, nil,
    "finish releases idle scene")

-- The talking NPC can offer a short parley while it is targeting this
-- player. This only ignores that direct hostile target; nearby threats still
-- use the regular close-on-danger rule above.
candidates = {}
record.runtime = {
    target = { player = player },
    attackAction = { kind = "melee" },
    inCombatUntil = now + 1000,
}
spec.context.allowHostileParley = true
assertEqual(Safety.Check(spec), nil,
    "client allows direct hostile parley")
local parleyStarted, parleyLease = Scene.Begin(
    record,
    npc,
    player,
    "lease-parley",
    {
        maximumDistance = 5.5,
        dangerRadius = 8,
        allowHostileParley = true,
    }
)
assertEqual(parleyStarted, true, "server accepts hostile parley")
assertEqual(parleyLease.hostileParley, true,
    "lease records hostile parley")
assertEqual(record.runtime.conversationParley.playerKey,
    "player:Tester:char_tester", "parley ties to stable player key")
assertEqual(record.runtime.target, nil,
    "parley clears only the speaking NPC's current attack")
now = now + 1000
Scene.Begin(record, npc, player, "lease-parley", {
    maximumDistance = 5.5,
    dangerRadius = 8,
    allowHostileParley = true,
})
assertEqual(record.runtime.conversationParley.untilAt,
    now + Scene.LEASE_MS,
    "parley lease extends with conversation heartbeat")
local ceasefireOK = Scene.HandleClientCommand(
    player,
    Scene.CMD_CEASEFIRE,
    { id = "npc-1", token = "lease-parley" }
)
assertEqual(ceasefireOK, true, "ceasefire request accepted")
assertEqual(#pacifications, 1,
    "ceasefire creates player-scoped faction pacification")
assertEqual(pacifications[1].factionID, "faction_hostile",
    "ceasefire uses observer faction")
assertEqual(pacifications[1].options.durationHours,
    Scene.CEASEFIRE_HOURS, "ceasefire duration is explicit")
Scene.End(record, npc, "lease-parley", "test")
assertEqual(record.runtime.conversationParley, nil,
    "ending conversation restores normal hostile policy")

print("pnc_conversation_safety_smoke: ok")
