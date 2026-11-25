-- Unified Conversation Director smoke test:
-- 1) Sandbox ChatterDensity (Quiet / Cinematic / Lively) pacing
-- 2) VoiceProfile chattiness differentiation (talkative vs withdrawn)
-- 3) TopicSaturation escalation-only wound suppression
-- 4) StoryRecall continuity weaving (post_chopper / post_alarm)
-- 5) Actor-agnostic NPC suggestion picker (positive, friction, 3rd-party defuse)
-- 6) Autonomous NPC-to-NPC relationship delta + hourly pair cap
package.path = "./tests/?.lua;./tests/?/init.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/shared/?.lua;./Contents/mods/ProjectHoomans/42.20/media/lua/server/?.lua;" .. package.path

local T = require "support.test"

_G.SandboxVars = { ProjectHoomans = { ChatterDensity = 2 } }
local simNow = 100000
local simWorldHours = 12.0
_G.getGameTime = function()
    return { getWorldAgeHours = function() return simWorldHours end }
end

_G.PNC = _G.PNC or {}
PNC.Const = { PRESENCE_LIVE = "live" }
PNC.Core = {
    Now = function() return simNow end,
    ForEachPlayer = function(fn)
        fn({
            getX = function() return 100 end,
            getY = function() return 100 end,
            getZ = function() return 0 end,
            getDescriptor = function() return { getForename = function() return "Rick" end } end,
        })
    end,
}

require "PNC/Core/Base/PNC_Sandbox"
require "PNC/Semantics/PNC_SemanticDialogueBeats"

local sandbox = PNC.Sandbox
local Dir = PNC.Semantics.ConversationDirector
local Beats = PNC.Semantics.DialogueBeats

T.truthy(type(Dir) == "table", "ConversationDirector module loaded")

-- 1) Sandbox ChatterDensity profiles
SandboxVars.ProjectHoomans.ChatterDensity = 1
T.equal(sandbox.ChatterDensityProfile(), "quiet", "density 1 is quiet")
local qProf = Dir.GetDensityProfile()
T.truthy(qProf.cooldownScale > 1.2 and qProf.thresholdScale > 1.1, "quiet scales up cooldown & threshold")

SandboxVars.ProjectHoomans.ChatterDensity = 2
T.equal(sandbox.ChatterDensityProfile(), "cinematic", "density 2 is cinematic")
local cProf = Dir.GetDensityProfile()
T.equal(cProf.cooldownScale, 1.0, "cinematic cooldownScale is 1.0")

SandboxVars.ProjectHoomans.ChatterDensity = 3
T.equal(sandbox.ChatterDensityProfile(), "lively", "density 3 is lively")
local lProf = Dir.GetDensityProfile()
T.truthy(lProf.cooldownScale < 0.85 and lProf.thresholdScale < 0.9, "lively lowers cooldown & threshold")

-- Reset to cinematic for remaining tests
SandboxVars.ProjectHoomans.ChatterDensity = 2
Dir.ResetRuntime()

-- 2) VoiceProfile chattiness differentiation
local talkative = {
    id = "npc_talk",
    name = "Maya",
    alive = true,
    presenceState = "live",
    x = 101, y = 100, z = 0,
    social = { personality = { socialStyle = "warm", sociability = 0.95 } },
}
local withdrawn = {
    id = "npc_quiet",
    name = "Cole",
    alive = true,
    presenceState = "live",
    x = 102, y = 100, z = 0,
    social = { personality = { socialStyle = "withdrawn", sociability = 0.10 } },
}

local vTalk = Dir.ResolveVoiceProfile(talkative, simNow)
local vQuiet = Dir.ResolveVoiceProfile(withdrawn, simNow)
T.truthy(vTalk.chattiness > vQuiet.chattiness * 1.6, "talkative NPC has substantially higher chattiness than withdrawn NPC")

local okTalk = Dir.EvaluateCandidate({
    speaker = talkative,
    scopeKey = "voice_test_talk",
    topic = "ambient_idle",
    salience = 48,
    silenceThreshold = 46,
    deterministic = true,
    now = simNow,
})
local okQuiet = Dir.EvaluateCandidate({
    speaker = withdrawn,
    scopeKey = "voice_test_quiet",
    topic = "ambient_idle",
    salience = 48,
    silenceThreshold = 46,
    deterministic = true,
    now = simNow,
})
T.equal(okTalk, true, "talkative NPC admits moderate salience candidate")
T.equal(okQuiet, false, "withdrawn NPC stays silent on moderate salience candidate")

-- 3) TopicSaturation escalation-only wound suppression
Dir.ResetRuntime()
local okW1 = Dir.EvaluateCandidate({
    speaker = talkative,
    scopeKey = "wound:npc_talk",
    topic = "combat_wound",
    tier = 1,
    urgency = 55,
    salience = 65,
    saturationWindowMs = 35000,
    silenceThreshold = 40,
    deterministic = true,
    now = simNow,
})
T.equal(okW1, true, "first minor wound admitted")

local okW2, infoW2 = Dir.EvaluateCandidate({
    speaker = talkative,
    scopeKey = "wound:npc_talk",
    topic = "combat_wound",
    tier = 1,
    urgency = 55,
    salience = 65,
    saturationWindowMs = 35000,
    silenceThreshold = 40,
    deterministic = true,
    now = simNow + 5000,
})
T.equal(okW2, false, "repeated minor wound within saturation window suppressed")
T.equal(infoW2.reason, "saturated", "suppression reason is saturated")

local okW3 = Dir.EvaluateCandidate({
    speaker = talkative,
    scopeKey = "wound:npc_talk",
    topic = "combat_wound",
    tier = 3,
    urgency = 86,
    salience = 85,
    saturationWindowMs = 35000,
    silenceThreshold = 40,
    deterministic = true,
    now = simNow + 6000,
})
T.equal(okW3, true, "escalated severe wound breaks saturation and is admitted")

-- 4) StoryRecall continuity weaving in GroupBanter
Dir.ResetRuntime()
Beats.ResetRuntime()
local delivered = {}
PNC.Semantics.SpeechTransport.ResolveLine = function(speaker, poolID, act, domain, ref, addressee, tokens, opts)
    local topic = opts and opts.topic or "unknown"
    local role = opts and opts.replyRole or "open"
    return tostring(topic) .. "|" .. tostring(role), { poolID = poolID }
end
PNC.Semantics.SpeechTransport.Deliver = function(speaker, now, opts)
    delivered[#delivered + 1] = {
        speaker = speaker and speaker.id or nil,
        text = opts and opts.text or nil,
        topic = opts and opts.topic or nil,
        role = opts and opts.replyRole or nil,
    }
    return true
end
PNC.SpatialIndex = {
    QueryNPCs = function() return { talkative, withdrawn } end,
}
PNC.Perception = {
    GetTeamKey = function() return "team_alpha" end,
    GetActiveSkirmish = function() return nil end,
}
PNC.Registry = {
    Get = function(id)
        if id == talkative.id then return talkative end
        if id == withdrawn.id then return withdrawn end
        return nil
    end,
}

Dir.RecordStoryMoment("team_alpha", {
    kind = "chopper_ended",
    topic = "post_chopper",
    actorId = talkative.id,
    salience = 84,
    valence = -1,
    ttlMs = 360000,
}, simNow)

local recall = Dir.GatherStoryRecall("team_alpha", { talkative, withdrawn }, nil, simNow + 5000)
T.truthy(#recall >= 1 and recall[1].topic == "post_chopper", "GatherStoryRecall surfaces recent post_chopper story moment")

local emittedBanter = Beats.CheckGroupBanter(simNow + 10000)
T.equal(emittedBanter, true, "CheckGroupBanter emits continuity banter")
Beats.Pump(simNow + 10000)
Beats.Pump(simNow + 15000)
T.truthy(#delivered >= 1, "continuity banter delivered at least one turn")
T.equal(delivered[1].topic, "post_chopper", "group banter selected post_chopper continuity topic")

-- 5) Actor-agnostic NPC suggestion picker (positive, negative friction, 3rd-party defuse)
local relState = {}
PNC.Relationships = {
    Get = function(obsId, targetKey)
        return relState[tostring(obsId) .. "->" .. tostring(targetKey)]
    end,
    ApplyConversationEffect = function(obsId, targetKey, effect)
        local k = tostring(obsId) .. "->" .. tostring(targetKey)
        relState[k] = relState[k] or { approval = 0, respect = 0, familiarity = 0 }
        relState[k].approval = relState[k].approval + (tonumber(effect.approval) or 0)
        relState[k].respect = relState[k].respect + (tonumber(effect.respect) or 0)
        relState[k].familiarity = relState[k].familiarity + (tonumber(effect.familiarity) or 0)
        return true
    end,
}

local hostile = {
    id = "npc_grumpy",
    name = "Daryl",
    alive = true,
    social = { personality = { socialStyle = "hostile", sociability = 0.4 } },
    conditionStats = { stress = 0.85, panic = 65 },
}
local mediator = {
    id = "npc_med",
    name = "Glenn",
    alive = true,
    social = { personality = { socialStyle = "protective", sociability = 0.7 } },
}
relState["npc_talk->npc:npc_grumpy"] = { approval = 40, respect = 30 }
relState["npc_grumpy->npc:npc_talk"] = { approval = -45, respect = -25 }

local frontier = {
    { id = "f_agree", speechAct = "AGREE", priority = 10 },
    { id = "f_praise", speechAct = "PRAISE", priority = 10 },
    { id = "f_crit", speechAct = "CRITICIZE", priority = 10 },
    { id = "f_ant", speechAct = "ANTAGONIZE", priority = 10 },
}

local warmPick = Dir.SelectSuggestionForNPC(talkative, hostile, frontier, { deterministic = true, now = simNow })
T.truthy(warmPick and (warmPick.speechAct == "AGREE" or warmPick.speechAct == "PRAISE"),
    "warm high-approval NPC picks positive suggestion")

local hostilePick = Dir.SelectSuggestionForNPC(hostile, talkative, frontier, { deterministic = true, sceneTension = 35, now = simNow })
T.truthy(hostilePick and (hostilePick.speechAct == "CRITICIZE" or hostilePick.speechAct == "ANTAGONIZE"),
    "hostile low-composure low-approval NPC picks negative friction suggestion")

local medFrontier = {
    { id = "m_defuse", speechAct = "DEFUSE", priority = 10 },
    { id = "m_crit", speechAct = "CRITICIZE", priority = 10 },
    { id = "m_agree", speechAct = "AGREE", priority = 10 },
}
local medPick = Dir.SelectSuggestionForNPC(mediator, hostile, medFrontier, { deterministic = true, sceneTension = 35, now = simNow })
T.equal(medPick and medPick.speechAct, "DEFUSE", "protective 3rd NPC picks DEFUSE when scene tension is elevated")

-- 6) Autonomous NPC-to-NPC relationship evolution + hourly pair cap
Dir.ResetRuntime()
relState = {}
local appliedCount = 0
for i = 1, 6 do
    local okDelta = Dir.ApplyAutonomousRelationshipDelta(talkative, hostile, "PRAISE", simNow + i * 1000)
    if okDelta then appliedCount = appliedCount + 1 end
end
local finalRel = relState["npc_talk->npc:npc_grumpy"]
T.truthy(finalRel ~= nil, "autonomous relationship delta persisted via RelationshipService.ApplyConversationEffect")
T.truthy(finalRel.approval <= 6 and finalRel.approval > 0, "positive approval delta capped at +6 per pair per in-game hour")
T.truthy(finalRel.respect <= 4 and finalRel.respect > 0, "positive respect delta capped at +4 per pair per in-game hour")
T.truthy(appliedCount < 6, "hourly cap stops repeated mutations within the same in-game hour")

-- 7) BeatsAudit & Director debug state snapshots (gated when disabled, detailed when enabled)
local auditEvents = {}
PNC.PerformanceScalingDiagnostics = {
    BeatsAuditEnabled = false,
    LogBeatsAudit = function(ev, fields)
        auditEvents[#auditEvents + 1] = { event = ev, fields = fields }
        return true
    end,
}
T.equal(Beats.LogAuditSnapshot("disabled_check", simNow), false, "LogAuditSnapshot is a no-op when BeatsAuditEnabled is false")
T.equal(#auditEvents, 0, "no audit logs emitted when BeatsAuditEnabled is false")

PNC.PerformanceScalingDiagnostics.BeatsAuditEnabled = true
Dir.RecordStoryMoment("team_alpha", { kind = "house_alarm_ended", topic = "post_alarm", salience = 75 }, simNow)
Dir.SelectSuggestionForNPC(talkative, hostile, frontier, { deterministic = true, now = simNow })
local auditState = Dir.GetAuditState(simNow)
T.equal(auditState.densityName, "cinematic", "Director.GetAuditState reports densityName")
T.truthy(auditState.storyMomentCount >= 1, "Director.GetAuditState counts active story moments")
T.truthy(auditState.relationshipDeltaCount >= 1, "Director.GetAuditState tracks relationship deltas")

T.equal(Beats.LogAuditSnapshot("manual_check", simNow), true, "LogAuditSnapshot succeeds when enabled")
local sawDirectorState, sawBanterState, sawStoryMoment, sawSuggestion = false, false, false, false
for i = 1, #auditEvents do
    local ev = auditEvents[i].event
    if ev == "director_state" then sawDirectorState = true end
    if ev == "banter_state" then sawBanterState = true end
    if ev == "director_story_moment" then sawStoryMoment = true end
    if ev == "director_suggestion" then sawSuggestion = true end
end
T.truthy(sawDirectorState, "BeatsAudit snapshot includes director_state")
T.truthy(sawBanterState, "BeatsAudit snapshot includes banter_state")
T.truthy(sawStoryMoment, "BeatsAudit logs director_story_moment")
T.truthy(sawSuggestion, "BeatsAudit logs director_suggestion")

-- 8) Modular extension registries (RegisterTopicPolicy, RegisterStoryRecallProvider, RegisterSocialActProfile, GateEmitter)
Dir.ResetRuntime()
T.equal(Dir.RegisterTopicPolicy("custom_quest_chatter", {
    tier = 1, urgency = 35, salience = 62, saturationWindowMs = 20000, silenceThreshold = 44,
}), true, "RegisterTopicPolicy registers custom topic")
local okGate1 = Dir.GateEmitter("custom_quest_chatter", talkative, { deterministic = true, now = simNow })
local okGate2, infoGate2 = Dir.GateEmitter("custom_quest_chatter", talkative, { deterministic = true, now = simNow + 3000 })
T.equal(okGate1, true, "GateEmitter admits first custom topic emission")
T.equal(okGate2, false, "GateEmitter suppresses repeat within registered saturation window")
T.equal(infoGate2 and infoGate2.reason, "saturated", "GateEmitter suppression reason is saturated")

T.equal(Dir.RegisterStoryRecallProvider("test_quest_provider", function(gKey)
    if gKey == "team_alpha" then
        return { { kind = "quest_completed", topic = "post_fight", salience = 90 } }
    end
    return {}
end), true, "RegisterStoryRecallProvider registers custom recall provider")
local extRecall = Dir.GatherStoryRecall("team_alpha", { talkative }, nil, simNow)
T.truthy(#extRecall >= 1 and extRecall[1].source == "test_quest_provider", "GatherStoryRecall invokes registered providers")
T.equal(Dir.UnregisterStoryRecallProvider("test_quest_provider"), true, "UnregisterStoryRecallProvider cleans up provider")

T.equal(Dir.RegisterSocialActProfile("TEASE", {
    valence = 1, styleBias = { warm = 20 }, approval = 1, respect = 0, familiarity = 2, socialType = "social.tease",
}), true, "RegisterSocialActProfile registers custom social act")
local teasePick = Dir.SelectSuggestionForNPC(talkative, hostile, {
    { id = "f_tease", speechAct = "TEASE", priority = 10 },
    { id = "f_crit", speechAct = "CRITICIZE", priority = 10 },
}, { deterministic = true, now = simNow })
T.equal(teasePick and teasePick.speechAct, "TEASE", "SelectSuggestionForNPC uses registered custom social act")

-- 9) Organic Stance Alignment & Witness Ripple (5 RPG mechanics)
Dir.ResetRuntime()
relState = {}
local player = { isPlayer = true, username = "Rick" }
local maya = { id = "sa_maya", name = "Maya", alive = true, social = { personality = { socialStyle = "warm", sociability = 0.8 } } }
local daryl = { id = "sa_daryl", name = "Daryl", alive = true, social = { personality = { socialStyle = "hostile", sociability = 0.4 } } }
local braveCole = { id = "sa_cole", name = "Cole", alive = true, social = { personality = { socialStyle = "protective", sociability = 0.6 } } }

-- Player calls pastor broadcast bullshit in front of Maya (direct, warm) & Daryl (bystander, hostile):
-- Maya clashes (-approval), while Daryl ALIGNS (+approval, +respect) as an overhearing bystander!
local impacts = Dir.EvaluateStanceImpact(player, maya, { daryl }, "pastor_radio", "stance_negative", {
    now = simNow,
    topicInstanceKey = "pastor:ep1",
})
T.equal(#impacts, 2, "EvaluateStanceImpact evaluates direct addressee + overhearing witness")
T.truthy(relState["sa_maya->player:Rick"].approval < 0, "warm Maya dislikes player calling pastor bullshit")
T.truthy(relState["sa_daryl->player:Rick"].approval > 0, "hostile Daryl likes player calling pastor bullshit (witness alignment)")
T.truthy(relState["sa_daryl->player:Rick"].respect > 0, "hostile Daryl gains respect for player on aligned cynical stance")

-- Anti-farming diminishing returns & topic dedupe (3rd repeat on same topicInstanceKey skipped)
Dir.EvaluateStanceImpact(player, maya, nil, "pastor_radio", "stance_negative", { now = simNow + 1000, topicInstanceKey = "pastor:ep1" })
local imp3 = Dir.EvaluateStanceImpact(player, maya, nil, "pastor_radio", "stance_negative", { now = simNow + 2000, topicInstanceKey = "pastor:ep1" })
T.equal(imp3[1] and imp3[1].skipped, "topic_diminished", "3rd repeat on same topic instance is skipped (anti-farming)")

-- Relationship inertia: close ally (approval=60) softens clash to -1
Dir.ResetRuntime()
relState = { ["sa_maya->player:Rick"] = { approval = 60, respect = 40, familiarity = 50 } }
local allyImp = Dir.EvaluateStanceImpact(player, maya, nil, "pastor_radio", "stance_negative", { now = simNow, topicInstanceKey = "pastor:ep2" })
T.equal(allyImp[1] and allyImp[1].approval, -1, "trusted ally softens stance clash to -1 via relationship inertia")

-- NPC-to-NPC autonomous stance impact (Daryl pushes back on Maya -> Maya loses approval toward Daryl)
Dir.ResetRuntime()
relState = {}
local npcImp = Dir.EvaluateStanceImpact(daryl, maya, { braveCole }, "open_band_refugee", "stance_negative", { now = simNow, topicInstanceKey = "ref:1" })
T.equal(#npcImp, 2, "NPC-to-NPC stance impact evaluates both addressee and bystander")
T.truthy(relState["sa_maya->npc:sa_daryl"].approval < 0, "Maya loses approval toward Daryl after clashing over refugees")
T.truthy(relState["sa_cole->npc:sa_daryl"].approval < 0, "protective Cole bystander also reacts negatively to Daryl's dismissal")

print("pnc_conversation_director_smoke: OK")
