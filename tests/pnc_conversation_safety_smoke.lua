local T = require "tests/support/test"

local SHARED =
    T.path("ProjectHoomans", "shared", "PNC/Conversation/")
local CLIENT =
    T.path("ProjectHoomans", "client", "PNC/Conversation/")

local now = 1000
local candidates = {}
local stoppedReason
local held = 0
local definitions = {}
local staleAttacker
local pacifications = {}
local enemyTarget

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
    getTarget = function() return enemyTarget end,
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
    tacticalClass = "hostile",
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
    Network = {
        ClientState = {
            snapshots = {},
        },
    },
    Factions = {
        GetFactionID = function()
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

T.load(SHARED .. "PNC_ConversationScene.lua")
T.load(CLIENT .. "PNC_ConversationSafety.lua")
package.preload["PNC/Conversation/PNC_ConversationSafety"] =
    function() return PNC.Conversation.Safety end
T.load(CLIENT .. "PNC_ConversationLifecycle.lua")

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
T.equal(started, true, "conversation scene begins")
T.equal(record.activeJob, "FollowOwner", "job is preserved")
T.equal(record.activeBehavior, "FollowOwner", "behavior is preserved")
T.equal(held, 1, "blocking idle requests movement hold")
staleAttacker = deadEnemy
T.equal(Scene.HasThreat(record, npc, player, 8), false,
    "stale attacker and managed-body engine target are ignored")
T.equal(Safety.Check(spec), nil,
    "stale engine combat references do not close the UI")

now = 1800
started = Scene.Begin(record, npc, player, "lease-1", {
    maximumDistance = 5.5,
    dangerRadius = 8,
})
T.equal(started, true, "same lease heartbeat")
T.equal(held, 1, "heartbeat does not restart the idle scene")

player.x = 12
local activeHeartbeat = Scene.Begin(
    record,
    npc,
    player,
    "lease-1",
    {
        maximumDistance = 5.5,
        dangerRadius = 8,
        enforceDistance = false,
    }
)
T.equal(activeHeartbeat, true,
    "active lease heartbeat may continue after the NPC leaves the radius")
T.equal(Scene.Pump(record, npc, now), false,
    "server keeps an active conversation when the NPC moves away")
T.truthy(record.runtime.conversationLease,
    "active lease survives conversation distance")
T.equal(stoppedReason, nil,
    "distance does not stop the active conversation")
local farReserved = Scene.ReserveLLMRequest(
    record, npc, player, "lease-1", "request-far"
)
T.equal(farReserved, true,
    "active LLM request is not rejected by conversation distance")
Scene.ClearLLMRequest(record, "test")
Scene.End(record, npc, "lease-1", "test")
T.equal(record.runtime.conversationLease, nil, "explicit end clears lease")

player.x = 0
candidates = { npc }
T.equal(Scene.HasThreat(record, npc, player, 8), false,
    "talking NPC is not its own threat")
candidates = { enemy }
local idleStarted = Scene.Begin(
    record,
    npc,
    player,
    "lease-idle-enemy",
    { maximumDistance = 5.5, dangerRadius = 8 }
)
T.equal(idleStarted, true,
    "idle nearby enemy does not reject conversation")
Scene.End(record, npc, "lease-idle-enemy", "test")
T.equal(Safety.Check(spec), nil,
    "idle nearby enemy does not close client conversation")
enemyTarget = player
local dangerStarted, dangerReason = Scene.Begin(
    record,
    npc,
    player,
    "lease-danger",
    { maximumDistance = 5.5, dangerRadius = 8 }
)
T.equal(dangerStarted, false,
    "nearby enemy in combat rejects conversation")
T.equal(dangerReason, "danger", "server danger reason")
T.equal(Safety.Check(spec), "danger",
    "client detects nearby enemy in combat")

candidates = {}
enemyTarget = nil
player.x = 8
T.equal(Safety.Check(spec), "distance", "client distance reason")
player.x = 0

local state, reason = lifecycle.begin({}, spec)
T.truthy(type(state) == "table" and reason == nil,
    "project lifecycle starts and leases NPC")
now = now + 1200
T.equal(lifecycle.update({}, spec, state), nil,
    "safe heartbeat keeps conversation active")
record.runtime.target = enemy
now = now + 200
T.equal(lifecycle.update({}, spec, state), "danger",
    "combat snaps dialogue out")
record.runtime.target = nil
lifecycle.finish({}, spec, state, "danger")
T.equal(record.runtime.conversationLease, nil,
    "finish releases idle scene")

-- A non-hostile conversation may leave the speaking NPC's passive target on
-- the player while its movement/animation lease is active. That target is not
-- itself a danger signal; active combat state remains one.
record.tacticalClass = "neutral"
record.hostility = { attackPlayers = false }
record.runtime = { target = { player = player } }
spec.context.allowHostileParley = false
T.equal(Safety.Check(spec), nil,
    "passive talking target does not close a neutral conversation")
T.equal(Scene.HasThreat(record, npc, player, 8), false,
    "server ignores passive talking target")
record.runtime.attackAction = { kind = "melee" }
T.equal(Safety.Check(spec), "danger",
    "active attack on the speaking player still closes the UI")
T.equal(Scene.HasThreat(record, npc, player, 8), true,
    "server preserves active attack danger")

-- The talking NPC can offer a short parley while it is targeting this
-- player. This only ignores that direct hostile target; nearby threats still
-- use the regular close-on-danger rule above.
candidates = {}
record.tacticalClass = "hostile"
record.hostility = { attackPlayers = true }
record.runtime = {
    target = { player = player },
    attackAction = { kind = "melee" },
    inCombatUntil = now + 1000,
}
spec.context.allowHostileParley = true
T.equal(Safety.Check(spec), nil,
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
T.equal(parleyStarted, true, "server accepts hostile parley")
T.equal(parleyLease.hostileParley, true,
    "lease records hostile parley")
T.equal(record.runtime.conversationParley.playerKey,
    "player:Tester:char_tester", "parley ties to stable player key")
T.equal(record.runtime.target, nil,
    "parley clears only the speaking NPC's current attack")
now = now + 1000
Scene.Begin(record, npc, player, "lease-parley", {
    maximumDistance = 5.5,
    dangerRadius = 8,
    allowHostileParley = true,
})
T.equal(record.runtime.conversationParley.untilAt,
    now + Scene.LEASE_MS,
    "parley lease extends with conversation heartbeat")
local ceasefireOK = Scene.HandleClientCommand(
    player,
    Scene.CMD_CEASEFIRE,
    { id = "npc-1", token = "lease-parley" }
)
T.equal(ceasefireOK, true, "ceasefire request accepted")
T.equal(#pacifications, 1,
    "ceasefire creates player-scoped faction pacification")
T.equal(pacifications[1].factionID, "faction_hostile",
    "ceasefire uses observer faction")
T.equal(pacifications[1].options.durationHours,
    Scene.CEASEFIRE_HOURS, "ceasefire duration is explicit")
Scene.End(record, npc, "lease-parley", "test")
T.equal(record.runtime.conversationParley, nil,
    "ending conversation restores normal hostile policy")

-- A hostile full-screen conversation is handed to the nameplate input before
-- it can create a combat-gated scene lease. The fallback keeps the exact
-- selected entry instead of resolving a different nearest NPC.
local fallbackCalls = {}
PNC.HoomansLLM = {
    RequestInlineFallback = function(entry, reason, view)
        fallbackCalls[#fallbackCalls + 1] = {
            entry = entry,
            reason = reason,
            view = view,
        }
        return true
    end,
}
record.runtime = {}
record.tacticalClass = "hostile"
record.hostility = { attackPlayers = true }
spec.context.allowHostileParley = true
spec.context.nameplateConversation = nil
local fallbackLifecycle = PNC.Conversation.Lifecycle.Create()
local fallbackStarted, fallbackReason = fallbackLifecycle.begin(
    { kind = "full_conversation" },
    spec
)
T.equal(fallbackStarted, false,
    "hostile full conversation is not started")
T.equal(fallbackReason, "nameplate_fallback",
    "hostile conversation reports the nameplate handoff")
T.equal(#fallbackCalls, 1,
    "hostile conversation requests one nameplate handoff")
T.equal(fallbackCalls[1].entry, spec.context.entry,
    "handoff keeps the selected conversation entry")
T.equal(fallbackCalls[1].reason, "hostile_nameplate_fallback",
    "handoff records a diagnostic reason")
PNC.HoomansLLM = nil

-- The visual conversation can close while the provider is still working. A
-- request lease keeps only that exact asynchronous request authorized.
record.tacticalClass = "neutral"
record.hostility = { attackPlayers = false }
record.runtime = {}
player.x = 0
candidates = {}
local llmStarted = Scene.Begin(
    record,
    npc,
    player,
    "lease-llm",
    { maximumDistance = 5.5, dangerRadius = 8 }
)
T.equal(llmStarted, true, "LLM conversation scene begins")
local reserved, llmLease = Scene.ReserveLLMRequest(
    record,
    npc,
    player,
    "lease-llm",
    "request-llm"
)
T.equal(reserved, true, "LLM request lease is reserved")
T.equal(llmLease.requestID, "request-llm", "request lease binds request ID")
local released, releaseReason = Scene.ReleaseLLMRequest(
    record,
    player,
    "lease-llm",
    "request-llm",
    "request_completed"
)
T.equal(released, true, "completed LLM request lease is released")
T.equal(releaseReason, "released", "LLM request release is acknowledged")
T.equal(record.runtime.llmRequestLease, nil,
    "completed LLM request lease is cleared")
reserved, llmLease = Scene.ReserveLLMRequest(
    record,
    npc,
    player,
    "lease-llm",
    "request-llm-2"
)
T.equal(reserved, true, "conversation can reserve its next LLM request")
Scene.End(
    record,
    npc,
    "lease-llm",
    "message_submitted",
    { llmRequestID = "request-llm-2", player = player }
)
T.equal(record.runtime.conversationLease, nil,
    "closing the visual conversation releases its short lease")
T.truthy(record.runtime.llmRequestLease,
    "closing the visual conversation keeps the request lease")
local llmValid, _, validatedLease = Scene.ValidateLLMRequest(
    record,
    npc,
    player,
    "lease-llm",
    "request-llm-2"
)
T.equal(llmValid, true, "reserved LLM request remains valid after close")
T.equal(validatedLease, record.runtime.llmRequestLease,
    "validation returns the reserved request lease")
now = record.runtime.llmRequestLease.expiresAt + 1
local expired, expiredReason = Scene.ValidateLLMRequest(
    record,
    npc,
    player,
    "lease-llm",
    "request-llm-2"
)
T.equal(expired, false, "expired LLM request is rejected")
T.equal(expiredReason, "llm_request_expired",
    "expired LLM request has a diagnostic reason")
T.equal(record.runtime.llmRequestLease, nil,
    "expired LLM request is cleaned up")

-- In multiplayer the client can retain the NPC's replicated snapshot while
-- the local live zombie body is absent. The nameplate LLM host is allowed to
-- perform its client-side distance/liveness gate from that snapshot; the
-- authoritative server lease still resolves and validates its live body.
local snapshotOnly = {
    id = "snapshot-npc",
    x = 2,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
    hostility = { attackPlayers = false },
}
PNC.Network.ClientState.snapshots["snapshot-npc"] = snapshotOnly
isClient = function() return true end
local snapshotSpec = {
    npcID = "snapshot-npc",
    context = {
        player = player,
        nameplateConversation = true,
        entry = { id = "snapshot-npc", snapshot = snapshotOnly },
    },
}
T.equal(Safety.Check(snapshotSpec), nil,
    "MP nameplate LLM accepts a snapshot-only NPC")
snapshotSpec.context.entry.snapshot = {
    id = "snapshot-npc",
    x = 100,
    y = 0,
    z = 0,
    alive = true,
    presenceState = "live",
}
T.equal(Safety.Check(snapshotSpec), nil,
    "MP safety prefers the current snapshot over a stale entry")
local sentClientCommand
sendClientCommand = function(module, command, args)
    sentClientCommand = { module = module, command = command, args = args }
end
local snapshotState, snapshotReason = lifecycle.begin({}, snapshotSpec)
T.truthy(type(snapshotState) == "table" and snapshotReason == nil,
    "MP snapshot-only lifecycle starts locally")
T.equal(sentClientCommand.command, Scene.CMD_BEGIN,
    "MP snapshot-only lifecycle sends authoritative begin")
lifecycle.finish({}, snapshotSpec, snapshotState, "test")
T.equal(sentClientCommand.command, Scene.CMD_END,
    "MP snapshot-only lifecycle sends authoritative end")
sendClientCommand = nil
isClient = function() return false end
T.finish("pnc_conversation_safety_smoke")

T.finish("pnc_conversation_safety_smoke")
