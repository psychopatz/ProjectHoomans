-- Companion mirror-sitting, leader moodle detection + follow-through acknowledgment,
-- and actor-agnostic follower-to-leader need requests with Yes/No branching smoke test.
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

local simNow = 200000
local spoken = {}
local spokenMeta = {}
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
                local urgency = spec.context and spec.context.needUrgency or ""
                spokenMeta[#spokenMeta + 1] = {
                    speakerId = tostring(speaker.id),
                    poolID = tostring(spec.poolID),
                    role = tostring(spec.role),
                    needUrgency = tostring(urgency),
                    addressee = tostring(spec.tokens["addressee.name"]),
                }
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

-- 5) Intensity classification (light / medium / critical)
T.equal(Beats.ClassifyNeedIntensity("hunger", 0.30), "light", "hunger 0.30 classifies as light")
T.equal(Beats.ClassifyNeedIntensity("hunger", 0.55), "medium", "hunger 0.55 classifies as medium")
T.equal(Beats.ClassifyNeedIntensity("hunger", 1.00), "critical", "hunger 1.00 classifies as critical")
T.equal(Beats.ClassifyNeedIntensity("hunger", 0.20, 0.50), "critical", "starvation ailment forces critical")
T.equal(Beats.ClassifyNeedIntensity("cold", 0, 0.20), "light", "cold 0.20 classifies as light")
T.equal(Beats.ClassifyNeedIntensity("cold", 0, 0.50), "medium", "cold 0.50 classifies as medium")
T.equal(Beats.ClassifyNeedIntensity("cold", 0, 1.00), "critical", "cold 1.00 classifies as critical")

-- 6) Standalone starving + injured colonist (no follow order, no leader) voices critical self_eat
--    AND nearby calm NPC reassures them with reassure_eat!
_G.getSpecificPlayer = function() return player end
local starvingColonist = {
    id = "npc_sam", name = "Sam", alive = true, presenceState = "live",
    x = 12, y = 10, z = 0,
    health = {
        state = "injured",
        body = {
            wholeBodyAilments = {
                starvation = { severity = 1.0 },
                cold = { severity = 1.0 },
            },
        },
    },
    needs = { fatigue = 0.1, hunger = 1.0, thirst = 0.1 },
    runtime = {},
}
allRecords[#allRecords + 1] = starvingColonist
npcSquadMember.needs.fatigue = 0.1
simNow = simNow + 20000
local beforeSam = #spokenMeta
local acted4 = Beats.CheckCompanionNeeds(simNow)
T.equal(acted4, true, "standalone starving+injured colonist voices self_eat need")
T.equal(spokenMeta[beforeSam + 1].speakerId, "npc_sam", "Sam spoke his first-person need")
T.equal(spokenMeta[beforeSam + 1].role, "self_eat", "standalone colonist uses self_eat role")
T.equal(spokenMeta[beforeSam + 1].needUrgency, "critical", "100% starvation routes to critical intensity")
T.truthy(spokenMeta[beforeSam + 2] ~= nil, "nearby NPC responded with reassurance")
T.equal(spokenMeta[beforeSam + 2].speakerId, "npc_follower_1", "nearby teammate Daryl reassured Sam")
T.equal(spokenMeta[beforeSam + 2].role, "reassure_eat", "reassurance uses reassure_eat role")
T.equal(spokenMeta[beforeSam + 2].needUrgency, "critical", "reassurance matches critical intensity")
T.equal(spokenMeta[beforeSam + 2].addressee, "Sam", "reassurance addresses Sam")

-- 7) Escalation from light -> critical bypasses lower-tier cooldown
local escalatingNpc = {
    id = "npc_esc", name = "Glenn", alive = true, presenceState = "live",
    x = 12, y = 11, z = 0,
    needs = { fatigue = 0.1, hunger = 0.30, thirst = 0.1 },
    runtime = {},
}
starvingColonist.needs.hunger = 0.0
starvingColonist.health.body.wholeBodyAilments = {}
allRecords[#allRecords + 1] = escalatingNpc
simNow = simNow + 20000
local beforeLight = #spokenMeta
local actedLight = Beats.CheckCompanionNeeds(simNow)
T.equal(actedLight, true, "light hunger triggers self_eat")
T.equal(spokenMeta[beforeLight + 1].speakerId, "npc_esc", "Glenn spoke light hunger")
T.equal(spokenMeta[beforeLight + 1].needUrgency, "light", "first trigger is light intensity")

escalatingNpc.needs.hunger = 0.95
simNow = simNow + 15000 -- still inside 150s light cooldown, but escalated to critical!
local beforeCrit = #spokenMeta
local actedCrit = Beats.CheckCompanionNeeds(simNow)
T.equal(actedCrit, true, "escalation from light to critical bypasses lower-tier cooldown")
T.equal(spokenMeta[beforeCrit + 1].speakerId, "npc_esc", "Glenn spoke critical hunger")
T.equal(spokenMeta[beforeCrit + 1].needUrgency, "critical", "escalated trigger is critical intensity")

-- 8) Third-person companion -> player (and NPC -> NPC) suggest_* still works with zero conflict
escalatingNpc.needs.hunger = 0.0
playerMoodles = { HUNGRY = 4 }
simNow = simNow + 20000
local beforePlayerSuggest = #spokenMeta
local actedPlayerCrit = Beats.CheckCompanionNeeds(simNow)
T.equal(actedPlayerCrit, true, "companion still performs third-person check on critically hungry player")
T.equal(spokenMeta[beforePlayerSuggest + 1].poolID, "semantic.companion.moodle_suggest", "uses third-person moodle_suggest pool")
T.equal(spokenMeta[beforePlayerSuggest + 1].role, "suggest_eat", "uses third-person suggest_eat role")
T.equal(spokenMeta[beforePlayerSuggest + 1].needUrgency, "critical", "level-4 HUNGRY maps to critical third-person suggest")
T.equal(spokenMeta[beforePlayerSuggest + 1].addressee, "Rick", "addresses player Rick")

-- 9) Knox Virus staged progression, frequent sneeze/growl SFX+anim, teammate reaction, and 3-stance branching
local performedFX = {}
PNC.Semantics.SpeechPerformance = {
    Perform = function(rec, spec)
        performedFX[#performedFX + 1] = { id = rec.id, anim = spec.anim, voice = spec.voice }
        return true
    end,
}
playerMoodles = {}
simNow = simNow + 100000 -- expire prior player eat suggestion watch
local knoxNpc = {
    id = "npc_jim", name = "Jim", alive = true, presenceState = "live",
    x = 12, y = 12, z = 0,
    health = {
        state = "injured",
        body = {
            infection = { active = true, stage = "terminal", progress = 0.92 },
            wholeBodyAilments = { knox_fever = { severity = 0.92 } },
        },
    },
    needs = { fatigue = 0.1, hunger = 0.1, thirst = 0.1 },
    runtime = {},
}
allRecords[#allRecords + 1] = knoxNpc
simNow = simNow + 20000
local beforeKnox = #spokenMeta
local actedKnox = Beats.CheckCompanionNeeds(simNow)
T.equal(actedKnox, true, "terminal Knox NPC triggers staged distress + reaction")
T.truthy(#performedFX >= 1 and (performedFX[#performedFX].voice == "zombie_growl" or performedFX[#performedFX].voice == "zombie_snarl"),
    "terminal Knox plays zombie growl/snarl SFX + anim via SpeechPerformance")
T.equal(spokenMeta[beforeKnox + 1].speakerId, "npc_jim", "Jim spoke critical Knox distress")
T.equal(spokenMeta[beforeKnox + 1].role, "self_knox_critical", "terminal Knox uses self_knox_critical role")
T.truthy(spokenMeta[beforeKnox + 2] ~= nil and spokenMeta[beforeKnox + 2].role == "react_knox_critical",
    "nearby NPC reacts to terminal Knox with react_knox_critical")

local knoxChoices = Beats.BuildPlayerNeedRequestChoices(player, knoxNpc.id, simNow)
T.truthy(type(knoxChoices) == "table" and #knoxChoices == 3, "exposes 3-stance Knox branching dialogue choices for player")
T.equal(knoxChoices[1].stance, "stance_positive", "first Knox choice is positive/comfort")
T.equal(knoxChoices[2].stance, "stance_neutral", "second Knox choice is neutral/distance")
T.equal(knoxChoices[3].stance, "stance_negative", "third Knox choice is negative/confront")

local okKnoxReply, resKnoxReply = Beats.TryResolvePlayerNeedReply(player, knoxNpc.id, "comfort", simNow + 1000)
T.equal(okKnoxReply, true, "player comfort reply resolves pending Knox branch")
T.equal(resKnoxReply.stance, "comfort", "resolved stance is comfort")
T.equal(spokenMeta[#spokenMeta].role, "knox_reply_comfort", "infected NPC replies with knox_reply_comfort")
T.truthy(relEffects[#relEffects].approval > 0, "comforting infected NPC applies positive approval delta")

print("pnc_companion_mirror_sit_and_needs_smoke: OK")
