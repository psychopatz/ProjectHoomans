-- Generated semantic affordance provider.
--
-- This provider derives bounded conversational strategies from the already
-- selected DiscourseFrame / InteractionPlan. The historical provider ID stays
-- stable for player UI compatibility, while an explicit affordanceResponder
-- lets NPC/scene actors consume the same semantic frontier. It never parses
-- text and never executes gameplay authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}
PNC.ConvoEngine = PNC.ConvoEngine or {}

local Provider = PNC.ConvoEngine.DialogueGeneratedAffordanceProvider or {}
PNC.ConvoEngine.DialogueGeneratedAffordanceProvider = Provider

Provider.id = "projecthoomans.generated_affordances"
Provider.sourceKind = "generated_affordance"
Provider.order = 45
Provider.MAX_CANDIDATES = 8

local UtterancePlan = PNC.ConvoEngine.UtterancePlan
    or require "PNC/ConvoEngine/UtterancePlan"
local EvidenceProviders = require "PNC/ConvoEngine/Interaction/Providers"
local EvidenceResolver = require "PNC/Semantics/PNC_SemanticPragmaticResolver"
local Stimulus = require "PNC/ConvoEngine/Interaction/Stimulus"
local Relations = require "PNC/ConvoEngine/Interaction/Relations"
local ContinuationPolicy = require
    "PNC/ConvoEngine/Suggestions/AffordanceContinuationPolicy"
local Responder = require
    "PNC/ConvoEngine/Suggestions/AffordanceResponder"

local HOSTILE_ACTS = {
    INSULT = true,
    HOSTILE_REMARK = true,
    THREATEN = true,
    BOUNDARY_WARNING = true,
    RETALIATE_VERBALLY = true,
    CHALLENGE = true,
}

local function upper(value)
    return string.upper(tostring(value or ""))
end

local function copy(value, depth)
    if type(value) ~= "table" then return value end
    depth = tonumber(depth) or 0
    if depth >= 5 then return nil end
    local output = {}
    local count = 0
    for key, item in pairs(value) do
        if count >= 24 then break end
        if type(key) == "string" or type(key) == "number" then
            output[key] = copy(item, depth + 1)
            count = count + 1
        end
    end
    return output
end

local function discourse(context)
    if type(context.discourseFrame) == "table" then
        return context.discourseFrame
    end
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local extensions = type(ir.extensions) == "table" and ir.extensions or {}
    return type(extensions.discourseFrame) == "table"
        and extensions.discourseFrame or {}
end

local function topicID(value)
    if type(value) == "table" then
        value = value.id or value.topic or value.subject
    end
    value = tostring(value or "")
    if value == "" then return nil end
    return value
end

local function responsePlan(context)
    context = type(context) == "table" and context or {}
    if type(context.sceneResponsePlan) == "table" then
        return context.sceneResponsePlan, {
            source = "interaction_scene",
            sourcePoolID = context.sceneResponsePlan.sourcePoolID,
            selectionID = context.sceneResponsePlan.selectionID,
        }
    end
    local decision = type(context.dialogueDecision) == "table"
        and context.dialogueDecision or {}
    local response = type(decision.response) == "table"
        and decision.response or {}
    local plan = type(response.plan) == "table" and response.plan or {}
    return plan, response
end

local function pendingFollowUp(context)
    context = type(context) == "table" and context or {}
    local dialogue = type(context.semanticDialogueContext) == "table"
        and context.semanticDialogueContext or {}
    local pending = type(dialogue.pendingFollowUp) == "table"
        and dialogue.pendingFollowUp
        or type(context.pendingFollowUp) == "table"
            and context.pendingFollowUp or nil
    if type(pending) ~= "table"
        or tostring(pending.status or "open") == "closed"
    then
        return nil
    end
    return pending
end

local function npcResponseAct(context)
    local pending = pendingFollowUp(context)
    if pending and upper(pending.kind) == "QUESTION" then
        return "QUESTION"
    end
    local plan = responsePlan(context)
    local turns = type(plan.turns) == "table" and plan.turns or {}
    local last = turns[#turns]
    if type(last) == "table"
        and tostring(last.continuation or "") == "await_player"
    then
        return "QUESTION"
    end
    local act = upper(plan.dialogueAct)
    if act == "QUESTION_RECEIVED" then return "INFORM" end
    return act ~= "" and act or nil
end

local function currentFrame(context)
    local frame = copy(discourse(context)) or {}
    local plan, response = responsePlan(context)
    local pending = pendingFollowUp(context)
    local topic = pending and topicID(pending.topic)
        or topicID(plan.topic)
        or topicID(frame.topic)
        or topicID(frame.subject)
    frame.topic = topic
    local act = npcResponseAct(context)
    if pending then
        frame.replyTo = {
            kind = "pending_interaction",
            id = pending.id,
            interactionKind = pending.kind,
            topic = topicID(pending.topic),
            owner = pending.owner,
            flowID = pending.flowID,
            nodeID = pending.nodeID,
        }
    elseif act then
        frame.replyTo = {
            kind = "npc_response_plan",
            dialogueAct = act,
            sourcePoolID = response.sourcePoolID or plan.sourcePoolID,
            selectionID = response.selectionID,
            continuation = type(plan.turns) == "table"
                and type(plan.turns[#plan.turns]) == "table"
                and plan.turns[#plan.turns].continuation or nil,
        }
    end
    return frame
end

local function interactionPlan(context)
    if type(context.interactionPlan) == "table" then
        return context.interactionPlan
    end
    local decision = type(context.dialogueDecision) == "table"
        and context.dialogueDecision or {}
    return type(decision.interactionPlan) == "table"
        and decision.interactionPlan or {}
end

local function hostilityContext(context)
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local plan = interactionPlan(context)
    local features = type(ir.extensions) == "table"
        and type(ir.extensions.socialFeatures) == "table"
        and ir.extensions.socialFeatures or {}
    -- Generated player affordances answer the semantic stimulus, not the
    -- NPC's selected tone. A suspicious first-contact CHALLENGE after a
    -- harmless GREET must not be reclassified as player hostility.
    local sourceAct = upper(
        plan.sourceSpeechAct or plan.sourceIntent
        or ir.speechAct or ir.intent
    )
    return HOSTILE_ACTS[upper(ir.speechAct or ir.intent)] == true
        or HOSTILE_ACTS[sourceAct] == true
        or (tonumber(features.hostility) or 0) >= 0.55
end

local REALIZATION_BASE_STRATEGY = {
    CORROBORATE = "AGREE",
    CONFIRM_FACT = "AGREE",
    CONTRADICT = "DISAGREE",
    EXPRESS_UNCERTAINTY = "ASK_FOLLOWUP",
    REVEAL_SOURCE = "ACKNOWLEDGE",
    PROTECT_SOURCE = "REFUSE",
    ADD_FACT = "ACKNOWLEDGE",
    QUESTION_SOURCE = "ASK_WHY",
    MEDIATE = "DEESCALATE",
    DEFEND = "DISAGREE",
    ACCEPT_TREATMENT = "ACCEPT",
    REFUSE_TREATMENT = "REFUSE",
    VOLUNTEER = "AGREE",
    NEGOTIATE = "ASK_FOLLOWUP",
    REFUSE_UNSAFE_WORK = "REFUSE",
    POSTPONE = "DISMISS",
    REROUTE = "ASK_FOLLOWUP",
    REQUEST_ESCORT = "ASK_WHY",
    WITHDRAW = "END_CONVERSATION",
    REFUSE_INTERVENTION = "REFUSE",
}

local EPISTEMIC_DEFAULT_TEXT = {
    CORROBORATE = "That matches what I observed first-hand.",
    CONFIRM_FACT = "I can confirm that directly.",
    CONTRADICT = "That doesn't line up with what I actually saw there.",
    EXPRESS_UNCERTAINTY = "Hard to swear to the exact spot without stepping outside to check.",
    REVEAL_SOURCE = "Heard it straight from our scout before dusk.",
    PROTECT_SOURCE = "Never mind who passed word along—take the warning and stay clear.",
    ADD_FACT = "One more thing worth noting about that area.",
    QUESTION_SOURCE = "Did you see that yourself or hear it over the air?",
    MEDIATE = "Both sides have a point—let's reset the watch evenly and cool down.",
    DEFEND = "I wasn't shirking; let's look at what actually happened.",
    ACCEPT_TREATMENT = "Alright, wrap it up while it's clean.",
    REFUSE_TREATMENT = "Save the clean gauze—just a scrape.",
    VOLUNTEER = "I've got tools on me; I'll handle it.",
    NEGOTIATE = "I can cover that chore if we split the next watch.",
    REFUSE_UNSAFE_WORK = "Not pounding boards outside while threats are still loose.",
    POSTPONE = "Better hold until daylight clears the corner.",
    REROUTE = "Better detour through the back alleys around that hazard.",
    REQUEST_ESCORT = "Only running that route with another rifle backing me up.",
    WITHDRAW = "Stepping back before this gets louder.",
    REFUSE_INTERVENTION = "Keep out of this between us.",
}

local function semanticFor(strategy, frame, context)
    local topic = frame.topic or frame.subject or "conversation"
    local details = {}
    if strategy == "APOLOGIZE" then
        return "APOLOGIZE", "APOLOGIZE", "RECIPIENT", {
            directed = true,
            repair = true,
        }, details
    elseif strategy == "CORROBORATE" or strategy == "CONFIRM_FACT" then
        return "AGREE", "AGREE", frame.subject or topic, { epistemic = true, corroborate = true }, details
    elseif strategy == "CONTRADICT" then
        return "DISAGREE", "DISAGREE", frame.subject or topic, { epistemic = true, contradict = true }, details
    elseif strategy == "EXPRESS_UNCERTAINTY" then
        return "INFORM", "INFORM", frame.subject or "RUMOR", { epistemic = true, uncertain = true }, details
    elseif strategy == "REVEAL_SOURCE" or strategy == "ADD_FACT" then
        return "INFORM", "INFORM", frame.subject or "NEWS", { epistemic = true }, details
    elseif strategy == "PROTECT_SOURCE" or strategy == "REFUSE_INTERVENTION" or strategy == "REFUSE_TREATMENT" or strategy == "REFUSE_UNSAFE_WORK" then
        return "REFUSE", "REFUSE", frame.subject or topic, { epistemic = strategy == "PROTECT_SOURCE" }, details
    elseif strategy == "QUESTION_SOURCE" or strategy == "REQUEST_ESCORT" then
        return "QUESTION", "QUESTION", frame.subject or topic, { followUp = true }, details
    elseif strategy == "MEDIATE" then
        return "APOLOGIZE", "APOLOGIZE", "RECIPIENT", { directed = true, repair = true, deescalate = true, mediate = true }, details
    elseif strategy == "DEFEND" or strategy == "POSTPONE" then
        return "DISAGREE", "DISAGREE", frame.subject or topic, { boundary = true }, details
    elseif strategy == "WITHDRAW" then
        return "REFUSE", "REFUSE", "RECIPIENT", { withdraw = true }, details
    elseif strategy == "ACCEPT_TREATMENT" then
        return "ACCEPT", "ACCEPT", frame.subject or "WELLBEING", {}, details
    elseif strategy == "VOLUNTEER" or strategy == "NEGOTIATE" or strategy == "REROUTE" then
        return "OFFER", "OFFER", frame.subject or topic, { coordinate = true }, details
    elseif strategy == "CLAIM_JOKE" then
        return "APOLOGIZE", "APOLOGIZE", "RECIPIENT", {
            directed = true,
            repair = true,
            joking = true,
            soften = true,
        }, details
    elseif strategy == "DOUBLE_DOWN" then
        return "HOSTILE_REMARK", "HOSTILE_REMARK", "RECIPIENT", {
            directed = true,
            challenge = true,
            escalation = true,
            doubledDown = true,
        }, details
    elseif strategy == "DEESCALATE" then
        return "APOLOGIZE", "APOLOGIZE", "RECIPIENT", {
            directed = true,
            repair = true,
            deescalate = true,
        }, details
    elseif strategy == "CHALLENGE" or strategy == "CALL_BLUFF" then
        return "HOSTILE_REMARK", "HOSTILE_REMARK", "RECIPIENT", {
            directed = true,
            challenge = true,
        }, details
    elseif strategy == "DISMISS" then
        return "DISAGREE", "DISAGREE", topic, {
            dismissive = true,
        }, details
    elseif strategy == "ASK_WHY" then
        return "QUESTION", "QUESTION", "CONTEXT_REASON", {
            followUp = true,
        }, details
    elseif strategy == "ASK_FOLLOWUP" or strategy == "COMFORT" then
        return "QUESTION", "QUESTION", frame.subject or topic, {
            followUp = true,
        }, details
    elseif strategy == "AGREE" then
        return "AGREE", "AGREE", frame.subject or topic, {}, details
    elseif strategy == "DISAGREE" then
        return "DISAGREE", "DISAGREE", frame.subject or topic, {}, details
    elseif strategy == "ACKNOWLEDGE" then
        return "ACKNOWLEDGE", "ACKNOWLEDGE", frame.subject or topic, {}, details
    elseif strategy == "WELLBEING_POSITIVE"
        or strategy == "WELLBEING_NEUTRAL"
        or strategy == "WELLBEING_NEGATIVE"
    then
        local state = strategy == "WELLBEING_POSITIVE" and "good"
            or strategy == "WELLBEING_NEGATIVE" and "struggling"
            or "okay"
        details.slots = {
            state = { type = "WELLBEING", value = state },
        }
        details.socialContext = {
            directed = false,
            selfDirected = true,
            target = "SELF",
        }
        details.selfDirected = true
        return "INFORM", "INFORM", "WELLBEING", {
            selfState = true,
        }, details
    elseif strategy == "DISCLOSE_NAME" then
        local responderName = Responder.Name(context)
        if responderName == "" then return nil end
        details.slots = {
            identityClaim = { name = responderName },
        }
        details.socialContext = {
            directed = false,
            selfDirected = true,
            target = "SELF",
            identityClaim = true,
        }
        details.selfDirected = true
        details.utteranceSlots = { name = responderName }
        details.safeSlots = { name = true }
        return "INFORM", "INFORM", "IDENTITY", {
            identityClaim = true,
        }, details
    elseif strategy == "REFUSE_IDENTITY" then
        details.socialContext = {
            directed = true,
            target = "RECIPIENT",
        }
        return "REFUSE", "REFUSE", "IDENTITY", {
            privacy = true,
        }, details
    end
    if Relations.GetAct(strategy) then
        return strategy, strategy, frame.subject or topic, {}, details
    end
    return nil
end

local function strategyPlan(strategy, stance, context, frame, ir)
    local primary
    if strategy == "APOLOGIZE" then
        primary = "APOLOGY_SORRY"
    end
    local _, speechAct, _, _, details =
        semanticFor(strategy, frame, context)
    details = type(details) == "table" and details or {}
    local templateStrategy = REALIZATION_BASE_STRATEGY[strategy] or strategy
    local plan = UtterancePlan.New({
        speaker = Responder.Speaker(context),
        target = details.selfDirected and "self" or "recipient",
        dialogueAct = speechAct,
        strategy = templateStrategy,
        stance = stance,
        topic = frame.topic,
        subject = frame.subject,
        selectionSalt = tostring(
            type(context.semanticDialogueContext) == "table"
                and context.semanticDialogueContext.sequence
                or type(context.semanticContextState) == "table"
                    and context.semanticContextState.sequence
                or 0
        ),
        intensity = type(ir.extensions) == "table"
            and type(ir.extensions.socialFeatures) == "table"
            and ir.extensions.socialFeatures.intensity or 0,
        lexemes = primary and { primary = primary } or {},
        slots = details.utteranceSlots,
        safeSlots = details.safeSlots,
        provenance = {
            providerID = Provider.id,
            discourseReplyTo = copy(frame.replyTo),
            semanticStrategy = strategy,
        },
    })
    local realized = UtterancePlan.Realize(plan)
    if not realized then return nil end
    plan.strategy = strategy
    if EPISTEMIC_DEFAULT_TEXT[strategy] then
        local epistemic = type(context) == "table" and type(context.epistemic) == "table"
            and context.epistemic or nil
        if epistemic and type(epistemic.renderedByStrategy) == "table"
            and type(epistemic.renderedByStrategy[strategy]) == "string"
            and epistemic.renderedByStrategy[strategy] ~= ""
        then
            realized.text = epistemic.renderedByStrategy[strategy]
        else
            realized.text = EPISTEMIC_DEFAULT_TEXT[strategy]
        end
        realized.strategy = strategy
    end
    return plan, realized
end

local function candidate(strategy, stance, context, reason)
    local allowed = ContinuationPolicy.Allowed(strategy, context)
    if allowed ~= true then return nil end
    local frame = currentFrame(context)
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local intent, speechAct, subject, modifiers, details =
        semanticFor(strategy, frame, context)
    if not intent then return nil end
    local stimulus = Stimulus.FromIR({
        intent = intent, speechAct = speechAct, subject = subject,
    }, context)
    local query = EvidenceProviders.EvidenceQueryForStimulus(stimulus)
    local evidence = context.semanticEvidenceQuery
    if query then
        local signature = table.concat(query.relations, ":")
        local cache = context.semanticEvidenceCache or {}
        evidence = cache[signature] or EvidenceProviders.QueryEvidence(context, query)
        cache[signature] = evidence
    end
    local admission = EvidenceResolver.ResolveEvidence(stimulus,
        evidence or EvidenceProviders.QueryEvidence(context, {}))
    if admission.status == "unresolved" or admission.status == "ambiguous" then return nil end
    details = type(details) == "table" and details or {}
    local plan, realized = strategyPlan(
        strategy, stance, context, frame, ir
    )
    if not plan or not realized then return nil end

    local id = "generated." .. string.lower(strategy)
    local evidence = {
        reason = reason,
        topic = frame.topic,
        replyTo = frame.replyTo and frame.replyTo.kind or nil,
        contextualAdmission = admission,
    }
    return {
        id = id,
        topic = frame.topic or "conversation",
        groupID = "conversation_branch",
        providerID = Provider.id,
        providerOrder = Provider.order,
        origin = "GENERATED",
        stance = stance,
        strategy = strategy,
        contextReason = reason,
        semanticOwner = "projecthoomans.contextual_discourse",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = reason,
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = reason,
        },
        frame = {
            kind = "semantic_click_frame",
            topic = frame.topic,
            intent = intent,
            speechAct = speechAct,
            subject = subject,
            target = details.selfDirected
                and nil
                or Responder.RecipientTarget(context),
            slots = copy(details.slots) or {},
            modifiers = modifiers,
            socialContext = copy(details.socialContext) or {
                directed = subject == "RECIPIENT",
                target = subject == "RECIPIENT"
                    and "RECIPIENT" or nil,
            },
            extensions = {
                route = "semantic_provider",
                providerID = Provider.id,
                dynamicAffordance = {
                    origin = "GENERATED",
                    stance = stance,
                    strategy = strategy,
                    evidence = evidence,
                },
                discourseFrame = copy(frame),
                utterancePlan = copy(plan),
            },
            textFallback = realized.text,
        },
        display = {
            labelFallback = realized.text,
            utteranceFallback = realized.text,
            label = realized.text,
            utterance = realized.text,
            realization = realized,
        },
        utterancePlan = plan,
        visibility = Responder.Visibility(context),
    }
end

local function add(output, seen, value)
    if not value or #output >= Provider.MAX_CANDIDATES then return end
    local key = tostring(value.strategy or value.id or "")
    if key == "" or seen[key] then return end
    seen[key] = true
    output[#output + 1] = value
end

function Provider.collect(context)
    context = type(context) == "table" and context or {}
    local projected = {}
    for key, value in pairs(context) do projected[key] = value end
    projected.semanticEvidenceQuery = EvidenceProviders.QueryEvidence(context, {})
    projected.semanticEvidenceCache = {}
    context = projected
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local result = type(context.dialogueResult) == "table"
        and context.dialogueResult or nil
    local scenePlan = type(context.sceneResponsePlan) == "table"
        and context.sceneResponsePlan or nil
    if result and result.accepted == false
        and ir.intent == nil and ir.speechAct == nil
        and scenePlan == nil
    then
        return {}
    end
    if context.activeHubID ~= nil then
        return {}
    end
    local frame = currentFrame(context)
    if ir.intent == nil and ir.speechAct == nil
        and #context.semanticEvidenceQuery.rows == 0
        and scenePlan == nil
    then
        return {}
    end

    local output = {}
    local seen = {}
    -- A strong current-turn pragmatic family owns the direct-response
    -- frontier before generic relation acts. This prevents broad ACCEPT /
    -- AGREE / REFUSE rows from crowding out the actual repair/escalation
    -- choices that answer the NPC's current reaction.
    if hostilityContext(context) then
        add(output, seen, candidate(
            "APOLOGIZE", "POSITIVE", context, "hostility_repair"
        ))
        add(output, seen, candidate(
            "CLAIM_JOKE", "POSITIVE", context, "hostility_reframe_joke"
        ))
        add(output, seen, candidate(
            "DEESCALATE", "POSITIVE", context, "hostility_deescalate"
        ))
        add(output, seen, candidate(
            "DOUBLE_DOWN", "NEGATIVE", context, "hostility_double_down"
        ))
        add(output, seen, candidate(
            "CHALLENGE", "NEGATIVE", context, "hostility_challenge"
        ))
        add(output, seen, candidate(
            "DISMISS", "NEUTRAL", context, "hostility_dismiss"
        ))
        add(output, seen, candidate(
            "ASK_WHY", "NEUTRAL", context, "hostility_followup"
        ))
        local effective = Responder.EffectiveDisposition(context)
        if (tonumber(effective.bravery) or 50) >= 65
            and (tonumber(effective.confidence) or 50) >= 65
        then
            add(output, seen, candidate(
                "CALL_BLUFF", "NEGATIVE", context,
                Responder.DispositionReason(
                    context, "courage", { "Brave", "Desensitized" }
                )
            ))
        end
        if (tonumber(effective.compassion) or 50) >= 65 then
            add(output, seen, candidate(
                "COMFORT", "POSITIVE", context,
                Responder.DispositionReason(
                    context, "compassion",
                    { "Empathetic", "Kind", "KindHearted", "Pacifist" }
                )
            ))
        end
        return output
    end

    local pending = pendingFollowUp(context)
    if pending and upper(pending.kind) == "QUESTION" then
        local flowID = string.lower(tostring(pending.flowID or ""))
        local pendingTopic = string.lower(tostring(pending.topic or ""))
        if flowID == "wellbeing" or flowID == "greeting"
            or pendingTopic == "wellbeing"
        then
            add(output, seen, candidate(
                "WELLBEING_POSITIVE", "POSITIVE", context,
                "pending_question:" .. (flowID ~= "" and flowID or pendingTopic)
            ))
            add(output, seen, candidate(
                "WELLBEING_NEUTRAL", "NEUTRAL", context,
                "pending_question:" .. (flowID ~= "" and flowID or pendingTopic)
            ))
            add(output, seen, candidate(
                "WELLBEING_NEGATIVE", "NEGATIVE", context,
                "pending_question:" .. (flowID ~= "" and flowID or pendingTopic)
            ))
            return output
        elseif flowID == "identity" or pendingTopic == "identity" then
            add(output, seen, candidate(
                "DISCLOSE_NAME", "POSITIVE", context,
                "pending_question:identity"
            ))
            add(output, seen, candidate(
                "REFUSE_IDENTITY", "NEUTRAL", context,
                "pending_question:identity"
            ))
            return output
        end
    end

    if type(context.epistemic) == "table" or type(context.worldKnowledge) == "table" then
        local epistemic = type(context.epistemic) == "table" and context.epistemic or {}
        if epistemic.provenance == "witnessed" or epistemic.corroborated == true then
            add(output, seen, candidate("CORROBORATE", "POSITIVE", context, "epistemic_witnessed"))
            add(output, seen, candidate("ADD_FACT", "NEUTRAL", context, "epistemic_addition"))
        end
        if epistemic.contradicted == true then
            add(output, seen, candidate("CONTRADICT", "NEGATIVE", context, "epistemic_contradicted"))
        end
        if epistemic.provenance == "environmental" or epistemic.provenance == "told"
            or epistemic.status == "uncertain"
        then
            add(output, seen, candidate("EXPRESS_UNCERTAINTY", "NEUTRAL", context, "epistemic_uncertain"))
        end
        add(output, seen, candidate("REVEAL_SOURCE", "POSITIVE", context, "epistemic_source"))
        add(output, seen, candidate("PROTECT_SOURCE", "NEUTRAL", context, "epistemic_privacy"))
    end
    if upper(ir.subject or frame.subject) == "CONFLICT" or tostring(frame.topic or "") == "conflict" then
        add(output, seen, candidate("MEDIATE", "POSITIVE", context, "conflict_mediation"))
        add(output, seen, candidate("DEFEND", "NEUTRAL", context, "conflict_defense"))
        add(output, seen, candidate("WITHDRAW", "NEUTRAL", context, "conflict_withdraw"))
        add(output, seen, candidate("REFUSE_INTERVENTION", "NEGATIVE", context, "conflict_boundary"))
    end

    for _, act in ipairs(Relations.ContextualActs()) do
        add(output, seen, candidate(act, "NEUTRAL", context, "semantic_relation"))
    end

    local act = npcResponseAct(context)
        or upper(ir.speechAct or ir.intent)
    if act == "INFORM" or act == "ANSWER" or act == "DISCLOSE" then
        local reasonPrefix = act == "DISCLOSE"
            and "npc_disclosure" or "npc_answer"
        add(output, seen, candidate(
            "ACKNOWLEDGE", "NEUTRAL", context,
            reasonPrefix .. "_acknowledgement"
        ))
        add(output, seen, candidate(
            "ASK_FOLLOWUP", "NEUTRAL", context,
            reasonPrefix .. "_followup"
        ))
    elseif act == "AGREE" or act == "DISAGREE"
        or act == "ACKNOWLEDGE"
    then
        add(output, seen, candidate(
            "ASK_FOLLOWUP", "NEUTRAL", context, "topic_continuation"
        ))
        add(output, seen, candidate(
            "ACKNOWLEDGE", "NEUTRAL", context, "topic_acknowledgement"
        ))
    elseif act == "APOLOGIZE" then
        add(output, seen, candidate(
            "ACKNOWLEDGE", "POSITIVE", context, "repair_continuation"
        ))
        add(output, seen, candidate(
            "ASK_FOLLOWUP", "NEUTRAL", context, "repair_followup"
        ))
    end
    return output
end

-- Explicit actor entry point for autonomous Scene consumers. The ordinary
-- collect(context) path remains the registered player-compatible provider.
function Provider.collectForResponder(context, responder)
    if type(responder) ~= "table" then return {} end
    context = type(context) == "table" and context or {}
    local projected = {}
    for key, value in pairs(context) do projected[key] = value end
    projected.affordanceResponder = copy(responder)
    return Provider.collect(projected)
end

return Provider
