-- Binds an observation offer to the existing server-leased triage Scene.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Offers = require "PNC/ConvoEngine/Dialogue/InjuryTriageOffers"
local Observation = {}
local TTL_MS = 12000

function Observation.Bind(observer, injured, ref, partID, now)
    observer.runtime = observer.runtime or {}
    observer.runtime.activeInjuryObservation = {
        targetID = tostring(injured.id), ref = ref, partID = partID, untilAt = now + TTL_MS,
    }
end

local function hasOffer(beat, offerID)
    for i = 1, math.min(8, #(beat.offerIDs or {})) do
        if beat.offerIDs[i] == offerID then return true end
    end
    return false
end

local function sendOutcome(helper, player, binding, role, node, now)
    local S = PNC.Semantics.CombatTargetCallouts
    local ref = binding.ref .. ":reply"
    local text, res = S.ResolveSemanticLine(helper, "combat_injury_visible_observation", "WARN", "human_hostile",
        ref, nil, {}, { replyRole = role, topic = "combat_injury", inCombat = false, poolID = "semantic.combat.injury.visible_observation" })
    if not text then return false end
    local offerIDs = node and Offers.IDs(node) or nil
    local offerPlan = offerIDs and #offerIDs > 0
    local sent = S.DeliverBark(helper, now, {
        eventType = "combat_injury_visible_observation", eventRef = ref, threadID = ref,
        text = text, act = "WARN", topic = "combat_injury", family = "combat_injury_triage_response",
        cooldownMs = 0, familyCooldownMs = 0, priority = 73, priorityHoldMs = 0,
        streamKey = ref, ttlMs = TTL_MS, flowID = Offers.FLOW_ID,
        responsePlanID = offerPlan and Offers.PlanID(node) or (res and res.responsePlanID),
        realizationID = res and res.realizationID or "semantic.combat.injury.visible_observation." .. role,
        offerIDs = offerIDs, factRefs = { ref }, recipientKind = "player",
        lightweightBark = not offerPlan, observerOnly = not offerPlan,
        audienceFilter = function(candidate) return candidate == player end,
        context = {
            eventType = "combat_injury_visible_observation", eventRef = ref,
            transient = true, sceneID = binding.sceneID,
        },
    })
    if (tonumber(sent) or 0) <= 0 then return false end
    if offerPlan then
        binding.ref, binding.untilAt = ref, now + TTL_MS
    end
    return true
end

local function recordChoice(scene, injured, helper, offer)
    if not scene.EmitSemanticAct then return end
    scene:EmitSemanticAct({
        sourceID = tostring(injured.id), responderID = tostring(helper.id),
        intent = offer.frame.intent, speechAct = offer.frame.speechAct,
        subject = offer.frame.subject, topic = "combat_injury",
        providerID = "pnc.injury_observation_choice",
    })
end

local function closeBinding(helper, binding, runtime, reason)
    helper.runtime.activeInjuryObservation = nil
    if binding.sceneID then runtime.Close(binding.sceneID, reason) end
end

function Observation.Respond(player, playerID, helper, beat, offerID, now)
    local binding = helper.runtime and helper.runtime.activeInjuryObservation
    if not binding or not beat or beat.flowID ~= Offers.FLOW_ID
        or beat.eventRef ~= binding.ref or now >= binding.untilAt
        or (binding.playerID and binding.playerID ~= playerID) or not hasOffer(beat, offerID) then
        return false, "injury_observation_reply_stale"
    end
    local offer = Offers.Resolve(beat.responsePlanID, offerID)
    local branch = offer and offer.frame and offer.frame.stateValue
    if not branch then return false, "injury_observation_offer_unknown" end
    local registry = PNC.Registry
    local injured = registry and registry.Get and registry.Get(binding.targetID)
    if not injured or injured.alive == false then return false, "injured_actor_unavailable" end

    local runtime = require "PNC/ConvoEngine/Interaction/SceneRuntime"
    local S = PNC.Semantics.CombatTargetCallouts
    local Aid = require "PNC/Semantics/PNC_SemanticInjuryAid"
    local role, nextNode
    if binding.sceneID then
        local scene = runtime.Get(binding.sceneID)
        if not scene then return false, "injury_observation_scene_expired" end
        recordChoice(scene, injured, helper, offer)
        if branch == "observation_accept_aid" and binding.aid then
            local worked = Aid.Execute(helper, injured, binding.aid)
            role = worked and (binding.aid.action == "bandage_transfer" and "aid_taken" or "aid_treated") or "aid_changed"
        elseif branch == "observation_decline_aid" then
            role = "aid_acknowledged"
        else
            return false, "injury_observation_reply_wrong_stage"
        end
    else
        local scene = S.HandoffInjuryBeatToScene(helper, binding.ref, {
            playerID = playerID, context = { player = player, playerID = playerID },
            participants = { injured }, now = now,
            stateValue = branch, nodeId = Offers.INITIAL_NODE, ttlMs = TTL_MS,
        })
        if not scene then return false, "injury_observation_scene_unavailable" end
        binding.sceneID, binding.playerID = scene.id, playerID
        recordChoice(scene, injured, helper, offer)
        if branch == "observation_dismiss" then
            role = "aid_dismissed"
        elseif branch == "observation_no_dressing" or branch == "observation_help" then
            local action = branch == "observation_no_dressing" and "transfer_bandage" or "treat"
            local admitted, _, inspection = Aid.Offer(helper, injured, { action = action })
            if admitted and tostring(admitted.partID) == tostring(binding.partID) then
                binding.aid = admitted
                nextNode = Offers.SUPPLY_NODE
                role = action == "transfer_bandage" and "aid_supply_offer" or "aid_treatment_offer"
            elseif inspection and inspection.reason == "missing_bandage" then
                role = "aid_no_supply"
            elseif inspection and inspection.outcome == "refuse" then
                role = "aid_refused"
            else
                role = "aid_changed"
            end
        else
            role = "aid_acknowledged"
        end
    end

    local sent = sendOutcome(helper, player, binding, role, nextNode, now)
    if not sent or not nextNode then closeBinding(helper, binding, runtime, role) end
    return true, role
end

return Observation
