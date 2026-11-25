-- Companion mirror-sitting, leader moodle detection + follow-through acknowledgment,
-- and actor-agnostic follower-to-leader need requests with Yes/No branching smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 200000
local spoken = {}
local relEffects = {}
local startedScenes = {}
local stoppedScenes = {}

_G.MoodleType = {
    ENDURANCE = "ENDURANCE",
    TIRED = "TIRED",
    HUNGRY = "HUNGRY",
    THIRST = "THIRST",
    HEAVY_LOAD = "HEAVY_LOAD",
    PAIN = "PAIN",
    SICK = "SICK",
    FOOD_EATEN = "FOOD_EATEN",
}

local playerMoodles = {}
local playerSitting = false
local player = {
    x = 10, y = 10, z = 0,
    getX = function(self) return self.x end,
    getY = function(self) return self.y end,
    getZ = function(self) return self.z end,
    getUsername = function() return "Rick" end,
    getDisplayName = function() return "Rick" end,
    getOnlineID = function() return 1 end,
    isDead = function() return false end,
    isSitting = function() return playerSitting end,
    getVehicle = function() return nil end,
    getMoodles = function()
        return {
            getMoodleLevel = function(_, key) return playerMoodles[key] or 0 end,
        }
    end,
}

local followerA = {
    id = "npc_follower_1", name = "Daryl", alive = true, presenceState = "live",
    x = 11, y = 10, z = 0,
    orderSpec = { kind = "follow" },
    needs = { fatigue = 0.1, hunger = 0.1, thirst = 0.1, endurance = 0.9 },
    runtime = { followOrderActive = true },
}
local followerABody = { x = 11, y = 10, z = 0 }

local npcLeader = {
    id = "npc_boss", name = "Negan", alive = true, presenceState = "live",
    x = 50, y = 50, z = 0,
    needs = { fatigue = 0.1, hunger = 0.1, thirst = 0.1 },
    runtime = {},
}
local npcSquadMember = {
    id = "npc_grunt", name = "Simon", alive = true, presenceState = "live",
    x = 51, y = 50, z = 0,
    leaderId = "npc_boss",
    needs = { fatigue = 0.80, hunger = 0.1, thirst = 0.1 },
    runtime = {},
}
local npcGruntBody = { x = 51, y = 50, z = 0 }

local allRecords = { followerA, npcLeader, npcSquadMember }
local bodies = {
    [followerA.id] = followerABody,
    [npcSquadMember.id] = npcGruntBody,
}

_G.PNC = {
    Core = {
        Now = function() return simNow end,
        NowWorldAgeHours = function() return 12.5 end,
    },
    Const = { PRESENCE_LIVE = "live", ORDER_FOLLOW = "follow" },
    Registry = {
        Get = function(id)
            for _, r in ipairs(allRecords) do
                if tostring(r.id) == tostring(id) then return r end
            end
            return nil
        end,
        GetLiveZombie = function(id) return bodies[id] end,
        ForEach = function(fn)
            for _, r in ipairs(allRecords) do fn(r) end
        end,
    },
    BehaviorCommon = {
        GetOwner = function(rec)
            if rec and rec.id == followerA.id then return player end
            return nil
        end,
        HaltMovement = function() end,
    },
    AnimationScenes = {
        Start = function(rec, _, sceneId)
            rec.runtime = rec.runtime or {}
            rec.runtime.animationScene = { id = sceneId }
            startedScenes[#startedScenes + 1] = { id = rec.id, sceneId = sceneId }
            return true
        end,
        Stop = function(rec, _, reason)
            if rec.runtime then
                rec.runtime.animationScene = nil
                if rec.runtime.companionMirrorSit then
                    rec.runtime.companionMirrorSit.active = false
                end
            end
            stoppedScenes[#stoppedScenes + 1] = { id = rec.id, reason = reason }
            return true
        end,
    },
    LiveBodyControl = { Internal = { PRESENTATION_NATIVE_RESET_STATES = {} } },
    Relationships = {
        ApplyConversationEffect = function(actorId, targetKey, eff)
            relEffects[#relEffects + 1] = { actorId = actorId, targetKey = targetKey, approval = eff.approval, memoryType = eff.memoryType }
            return true
        end,
    },
    Semantics = {
        DialogueBeats = {},
        ConversationDirector = {
            RegisterTopicAxis = function() return true end,
            SelectSuggestionForNPC = function(_, _, frontier)
                -- Deterministic: pick YES (first entry)
                return frontier[1], 20
            end,
            EvaluateStanceImpact = function(speaker, addressee, _, topic, act)
                relEffects[#relEffects + 1] = { actorId = speaker.id, targetKey = "npc:" .. tostring(addressee.id), approval = act == "ACCEPT" and 2 or -2, memoryType = topic }
                return {}
            end,
        },
        SpeechTransport = {
            ResolveLine = function(speaker, spec)
                return tostring(speaker.id) .. ":" .. tostring(spec.poolID) .. ":" .. tostring(spec.role) .. ":" .. tostring(spec.tokens["addressee.name"]), { poolID = spec.poolID }
            end,
            Deliver = function(_, _, opts)
                spoken[#spoken + 1] = opts.text
                return 1
            end,
        },
    },
}

require "PNC/Core/Pathing/PNC_LiveBodyControl/PNC_LiveBodyControl_State_Presentation"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion_MirrorSit"
require "PNC/Semantics/Beats/PNC_SemanticBeats_CompanionNeeds"

local MirrorSit = PNC.BehaviorCompanion.Internal.MirrorSit
local Beats = PNC.Semantics.DialogueBeats

-- 1) Leader moodle detection (player exhausted -> companion suggests sitting)
playerMoodles = { ENDURANCE = 3 }
playerSitting = false
local acted1 = Beats.CheckCompanionNeeds(simNow)
T.equal(acted1, true, "companion detects exhausted player moodle and suggests sitting")
T.truthy(string.find(spoken[#spoken], "suggest_sit:Rick", 1, true) ~= nil, "spoke suggest_sit line to Rick")

-- 2) Player sits down -> companion mirrors sit AND acknowledges follow-through!
playerSitting = true
MirrorSit.TryStart(followerA, followerABody, player, 1.5, { ownerMoving = false }, nil, false, nil, simNow + 500)
T.truthy(string.find(spoken[#spoken], "ack_sit:Rick", 1, true) ~= nil, "companion acknowledges player sitting down after suggestion")
T.truthy(#relEffects >= 1 and relEffects[#relEffects].memoryType == "companion_advice_followed", "positive relationship delta on advice followed")

-- After reaction jitter, follower starts ambient.companion.sitGround and LiveBodyControl.IsSeated == true
local sat = MirrorSit.TryStart(followerA, followerABody, player, 1.5, { ownerMoving = false }, nil, false, nil, simNow + 2500)
T.equal(sat, true, "follower sits down to mirror seated player")
T.equal(PNC.LiveBodyControl.IsSeated(followerA), true, "LiveBodyControl.IsSeated recognizes companion mirror sit")

-- Player stands up -> OnSceneTick stands follower up immediately
playerSitting = false
local staySeated = MirrorSit.OnSceneTick(followerA, followerABody, followerA.runtime.animationScene, simNow + 3000)
T.equal(staySeated, false, "follower stands up when player stands up")
T.equal(PNC.LiveBodyControl.IsSeated(followerA), false, "LiveBodyControl.IsSeated clears when stood up")

-- 3) Follower-to-player need request with Yes/No branching
playerMoodles = {}
followerA.needs.fatigue = 0.55
simNow = simNow + 20000
local acted2 = Beats.CheckCompanionNeeds(simNow)
T.equal(acted2, true, "exhausted follower asks player for a break")
T.truthy(string.find(spoken[#spoken], "request_sit:Rick", 1, true) ~= nil, "spoke request_sit to player")

local choices = Beats.BuildPlayerNeedRequestChoices(player, followerA.id, simNow)
T.truthy(type(choices) == "table" and #choices == 2, "exposes Yes and No branching choices for player")
T.equal(choices[1].intent, "ACCEPT", "first choice is ACCEPT (Yes)")
T.equal(choices[2].intent, "REFUSE", "second choice is REFUSE (No)")

-- Player chooses YES -> follower takes break sit and replies gratefully
local okYes, resYes = Beats.TryResolvePlayerNeedReply(player, followerA.id, "yes", simNow + 1000)
T.equal(okYes, true, "player Yes reply resolves pending need request")
T.equal(resYes.approved, true, "decision recorded as approved")
T.truthy((followerA.runtime.companionBreakSitUntil or 0) > simNow + 1000, "follower granted break sit lease")
T.truthy(string.find(spoken[#spoken], "requester_approved:Rick", 1, true) ~= nil, "follower thanks player")

-- Player chooses NO on a hunger request -> follower reacts and relationship drops
followerA.needs.fatigue = 0.10
followerA.needs.hunger = 0.85
followerA.runtime.companionBreakSitUntil = nil
simNow = simNow + 20000
Beats.CheckCompanionNeeds(simNow)
T.truthy(string.find(spoken[#spoken], "request_eat:Rick", 1, true) ~= nil, "hungry follower asks player to eat")
local okNo, resNo = Beats.TryResolvePlayerNeedReply(player, followerA.id, "no", simNow + 1000)
T.equal(okNo, true, "player No reply resolves pending need request")
T.equal(resNo.approved, false, "decision recorded as denied")
T.truthy(string.find(spoken[#spoken], "requester_denied:Rick", 1, true) ~= nil, "follower reacts to denial")
T.truthy(relEffects[#relEffects].approval < 0, "denying urgent need applies negative approval delta")

-- 4) Actor-agnostic NPC-to-NPC group leader need request!
followerA.needs.hunger = 0.1
simNow = simNow + 20000
local beforeCount = #spoken
local acted3 = Beats.CheckCompanionNeeds(simNow)
T.equal(acted3, true, "NPC squad member asks NPC group leader for rest")
local sawReq, sawLeaderApprove, sawGruntApproved = false, false, false
for i = beforeCount + 1, #spoken do
    if string.find(spoken[i], "npc_grunt:semantic.companion.need_request:request_sleep:Negan", 1, true) then sawReq = true end
    if string.find(spoken[i], "npc_boss:semantic.companion.need_request:leader_approve:Simon", 1, true) then sawLeaderApprove = true end
    if string.find(spoken[i], "npc_grunt:semantic.companion.need_request:requester_approved:Negan", 1, true) then sawGruntApproved = true end
end
T.equal(sawReq, true, "NPC follower asked NPC group leader")
T.equal(sawLeaderApprove, true, "NPC group leader autonomously replied Yes")
T.equal(sawGruntApproved, true, "NPC follower reacted to NPC leader approval")

print("pnc_companion_mirror_sit_and_needs_smoke: OK")
