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

function Observation.PlayerCanRespond(player, helper)
    local registry = PNC.Registry
    local body = registry and registry.GetLiveZombie and registry.GetLiveZombie(helper.id)
    if not body or not player or not player.getX or not player.getY or not player.getZ
        or (player.isDead and player:isDead()) or (body.isDead and body:isDead()) then return false end
    local dx, dy = player:getX() - body:getX(), player:getY() - body:getY()
    return math.abs(player:getZ() - body:getZ()) < 1 and dx * dx + dy * dy <= 144
end

local function hasOffer(beat, offerID)
    for i = 1, math.min(8, #(beat.offerIDs or {})) do
        if beat.offerIDs[i] == offerID then return true end
    end
    return false
end

local INVENTORY_EVIDENCE = {
    aid_supply_offer = "inventory.bandage_available",
    aid_disappointed = "inventory.bandage_available",
    aid_no_supply = "inventory.bandage_unavailable",
    aid_scarce = "inventory.bandage_available",
}

local function sendOutcome(helper, player, binding, role, node, now, inspection)
    local S = PNC.Semantics.CombatTargetCallouts
    local ref = binding.ref .. ":reply"
    local text, res = S.ResolveSemanticLine(helper, "combat_injury_visible_observation", "WARN", "human_hostile",
        ref, nil, {}, { replyRole = role, topic = "combat_injury", inCombat = false, poolID = "semantic.combat.injury.visible_observation" })
    if not text then return false end
    local proof = INVENTORY_EVIDENCE[role]
    if proof and S.InjuryEvidenceListener and inspection and inspection.inventory then
        S.InjuryEvidenceListener({
            utteranceEvidence = { clauses = { { claims = { proof } } } },
            authoritativeTruth = {
                source = "authoritative_injury_aid_inspection", knowledgeStatus = "known",
                inventory = { bandageAvailable = inspection.inventory.hasBandage },
            },
            text = text,
        })
    end
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
        presentationClass = offerPlan and "TACTICAL_PROMPT" or "BARK",
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

local FOLLOWUP = {
    observation_thanks = "aid_gratitude", observation_owe = "aid_debt", observation_sure = "aid_reassured",
}

local function rememberAid(helper, injured, binding, outcome, now)
    local S = PNC.Semantics.CombatTargetCallouts
    if S.RecordHighSalienceInjuryMemory then
        S.RecordHighSalienceInjuryMemory(injured, {
            kind = "triage_resolution", triageOutcome = outcome, eventRef = binding.ref,
            partId = binding.partID, actorId = helper.id, provenance = "experienced", now = now,
        })
    end
    local relationships = PNC.Relationships
    if not relationships or not relationships.ApplyConversationEffect then return end
    local gameTime = getGameTime and getGameTime()
    local worldAge = gameTime and gameTime.getWorldAgeHours and gameTime:getWorldAgeHours() or 0
    relationships.ApplyConversationEffect(tostring(injured.id), "npc:" .. tostring(helper.id), {
        interactionType = "injury_aid_received", memoryType = "injury_aid_received",
        approval = 3, familiarity = 1, decayPerDay = 0.15, tags = { injury = true, aid = true },
    }, { eventID = "injury-aid:" .. binding.ref, worldAgeHours = worldAge })
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
    local role, nextNode, inspection
    if binding.sceneID then
        local scene = runtime.Get(binding.sceneID)
        if not scene then return false, "injury_observation_scene_expired" end
        recordChoice(scene, injured, helper, offer)
        if binding.completedAid then
            role = FOLLOWUP[branch]
            if not role then return false, "injury_observation_reply_wrong_stage" end
        elseif branch == "observation_accept_aid" and binding.aid then
            local worked = Aid.Execute(helper, injured, binding.aid)
            role = "aid_changed"
            if worked then
                role = binding.aid.action == "bandage_transfer" and "aid_taken" or "aid_treated"
                binding.completedAid, binding.aid = true, nil
                nextNode = Offers.FOLLOWUP_NODE
                rememberAid(helper, injured, binding, role, now)
            end
        elseif branch == "observation_decline_aid" or branch == "observation_decline_costly" then
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
            local admitted, _
            admitted, _, inspection = Aid.Offer(helper, injured, { action = action, partID = binding.partID })
            if admitted and tostring(admitted.partID) == tostring(binding.partID) then
                binding.aid = admitted
                nextNode = Offers.SUPPLY_NODE
                role = action == "transfer_bandage" and "aid_supply_offer" or "aid_treatment_offer"
                if action == "transfer_bandage" and inspection and inspection.social
                    and inspection.social.policy == "disappointed" then role = "aid_disappointed" end
            elseif inspection and inspection.social and inspection.social.policy == "hostile" then
                role = "aid_hostile"
            elseif inspection and inspection.outcome == "refuse" and inspection.social
                and inspection.social.policy == "scarce" and inspection.inventory.bandageCount == 1 then
                role = "aid_scarce"
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

    local sent = sendOutcome(helper, player, binding, role, nextNode, now, inspection)
    if not sent or not nextNode then closeBinding(helper, binding, runtime, role) end
    return true, role
end

return Observation
