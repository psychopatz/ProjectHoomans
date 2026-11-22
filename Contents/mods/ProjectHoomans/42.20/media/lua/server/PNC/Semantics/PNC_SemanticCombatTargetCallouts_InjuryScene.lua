-- Beat -> Interactive Scene handoff and active triage state recording for combat injuries.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.Semantics.CombatTargetCalloutsInternal = PNC.Semantics.CombatTargetCalloutsInternal or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local S = PNC.Semantics.CombatTargetCallouts or {}
local I = PNC.Semantics.CombatTargetCalloutsInternal
PNC.Semantics.CombatTargetCallouts = S

local MAX_SCENE_PARTICIPANTS = 4

local function cleanId(v)
    if v == nil then return nil end
    local s = tostring(v)
    s = string.gsub(s, "[^%w_%.:%-]", "_")
    return s ~= "" and s or nil
end

local function makeParticipantProjection(id, healthState)
    return {
        identity = { id = id, state = "known" },
        npcState = {
            healthState = healthState or "injured",
            activeBehavior = "combat",
        },
        knowledge = { factRefs = {} },
    }
end

local function buildParticipants(record, context, spec)
    local out, seen = {}, {}
    local function push(id, actor, isPlayer, healthState)
        id = cleanId(id)
        if not id or seen[id] or #out >= MAX_SCENE_PARTICIPANTS then return end
        seen[id] = true
        out[#out + 1] = {
            id = id,
            actor = actor or { id = id },
            projection = makeParticipantProjection(id, healthState),
            isPlayer = isPlayer == true,
            kind = isPlayer == true and "player" or "npc",
        }
    end

    local playerID = (spec and spec.playerID)
        or (context and (context.playerID or context.speakerID))
        or "player:0"
    push(playerID, context and context.player or { id = playerID, isPlayer = true }, true, "normal")

    if type(record) == "table" and record.id ~= nil then
        push(tostring(record.id), record, false, "injured")
    elseif context and context.npcID ~= nil then
        push(tostring(context.npcID), { id = tostring(context.npcID) }, false, "injured")
    end

    local custom = spec and spec.participants or nil
    if type(custom) == "table" then
        for i = 1, #custom do
            local entry = custom[i]
            if type(entry) == "table" then
                push(entry.id or (entry.actor and entry.actor.id), entry.actor or entry, entry.isPlayer == true, "normal")
            end
        end
    end

    if #out < MAX_SCENE_PARTICIPANTS and type(record) == "table" and type(I.FindSquadmates) == "function" then
        local mates = I.FindSquadmates(record, 14) or {}
        for i = 1, #mates do
            if #out >= MAX_SCENE_PARTICIPANTS then break end
            local ally = mates[i]
            if type(ally) == "table" and ally.id ~= nil then
                push(tostring(ally.id), ally, false, "normal")
            end
        end
    end

    return out
end

function S.HandoffInjuryBeatToScene(record, threadID, spec)
    spec = type(spec) == "table" and spec or {}
    local context = type(spec.context) == "table" and spec.context or {}
    if type(record) ~= "table" then
        record = context.npcRecord or context.record
    end
    local beat = context.interactionLifecycle and context.interactionLifecycle.activeBeat or nil
    local tid = cleanId(threadID or spec.threadID or (beat and (beat.threadID or beat.eventRef))
        or (type(record) == "table" and record.id and ("wound:" .. tostring(record.id))))
        or "wound:triage"

    local cancelled = 0
    if type(S.CancelPendingRepliesForThread) == "function" then
        cancelled = S.CancelPendingRepliesForThread(tid)
    end
    local beatsApi = PNC.Semantics and PNC.Semantics.DialogueBeats
    if type(beatsApi) == "table" and type(beatsApi.CancelThread) == "function" then
        cancelled = cancelled + (tonumber(beatsApi.CancelThread(tid)) or 0)
    end

    local runtime = spec.runtime or (PNC.ConvoEngine and PNC.ConvoEngine.InteractionSceneRuntime)
    if type(runtime) ~= "table" then
        local loaded = require "PNC/ConvoEngine/Interaction/SceneRuntime"
        runtime = type(loaded) == "table" and loaded or nil
    end

    local participants = buildParticipants(record, context, spec)
    local sceneID = cleanId(spec.sceneID or ("scene:triage:" .. tid))
    local scene, openedID
    if type(runtime) == "table" then
        local existing = type(runtime.Get) == "function"
            and (type(runtime.scheduler) == "table" and runtime:Get(sceneID) or runtime.Get(sceneID))
            or nil
        if type(existing) == "table" then
            scene, openedID = existing, existing.id
        elseif #participants >= 2 then
            local openSpec = {
                id = sceneID,
                participants = participants,
                playerParticipant = true,
                perceived = true,
                topic = "combat_injury",
                ttlMs = tonumber(spec.ttlMs) or 20000,
                maxTurns = tonumber(spec.maxTurns) or 6,
            }
            if type(runtime.scheduler) == "table" then
                scene, openedID = runtime:Open(openSpec)
            elseif type(runtime.Open) == "function" then
                scene, openedID = runtime.Open(openSpec)
            end
        end
    end

    local ir = type(spec.ir) == "table" and spec.ir or nil
    local flow = type(spec.flow) == "table" and spec.flow or nil
    local stateValue = spec.stateValue
        or (ir and (ir.stateValue or (ir.slots and ir.slots.state and ir.slots.state.value)))
        or nil
    local nodeId = (flow and (flow.toNodeId or flow.nodeId)) or spec.nodeId or "injury_report_open"
    local now = (S.Finite and S.Finite(spec.now))
        or (PNC.Core and type(PNC.Core.Now) == "function" and tonumber(PNC.Core.Now()))
        or 0

    local triageState = {
        threadID = tid,
        sceneID = (type(scene) == "table" and scene.id) or sceneID,
        flowId = (flow and flow.flowId) or "combat.injury.triage_exchange",
        nodeId = nodeId,
        status = (flow and flow.status) or (nodeId == "triage_resolution" and "retired" or "active"),
        stateValue = stateValue,
        intent = ir and ir.intent or spec.intent,
        participantCount = #participants,
        cancelledBeatReplies = cancelled,
        updatedAt = now,
        playerProtectedBitten = stateValue == "bite_psychopath_threatened"
            or stateValue == "reassured_bond"
            or stateValue == "bite_non_lethal_stabilized",
        playerOrderedQuarantine = stateValue == "bite_quarantined",
        playerOrderedFallback = stateValue == "ordered_fallback",
        playerCoveredTreatment = stateValue == "covered_for_treatment",
    }

    if type(record) == "table" then
        record.runtime = record.runtime or {}
        record.runtime.activeInjuryTriageState = triageState
    end
    if type(context) == "table" then
        context.activeInjuryTriageState = triageState
        if type(context.interactionLifecycle) == "table" and type(scene) == "table" then
            context.interactionLifecycle.activeScene = {
                id = scene.id,
                topic = "combat_injury",
                threadID = tid,
                participantCount = #participants,
            }
        end
    end

    return scene, triageState
end

return S
