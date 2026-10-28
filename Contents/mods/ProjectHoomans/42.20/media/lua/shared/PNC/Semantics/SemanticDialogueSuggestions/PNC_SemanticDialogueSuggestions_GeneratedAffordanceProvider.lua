-- Generated semantic player-affordance provider.
--
-- This provider derives bounded conversational strategies from the already
-- selected DiscourseFrame / InteractionPlan. It never parses text and never
-- executes gameplay authority.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueGeneratedAffordanceProvider or {}
PNC.Semantics.DialogueGeneratedAffordanceProvider = Provider

Provider.id = "projecthoomans.generated_affordances"
Provider.sourceKind = "generated_affordance"
Provider.order = 45
Provider.MAX_CANDIDATES = 8

local UtterancePlan = PNC.Semantics.UtterancePlan
    or require "PNC/Semantics/PNC_SemanticUtterancePlan"

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

local function traitListHas(traits, trait)
    if type(traits) ~= "table" then return false end
    if traits[trait] == true then return true end
    for key, value in pairs(traits) do
        if type(key) == "string" and value == true
            and tostring(key) == trait
        then
            return true
        end
        if tostring(value) == trait then return true end
        if type(value) == "table"
            and tostring(value.id or value.type or value.name or "") == trait
        then
            return true
        end
    end
    return false
end

local function playerHasTrait(context, trait)
    context = type(context) == "table" and context or {}
    if traitListHas(context.playerTraits, trait) then return true end
    local player = type(context.player) == "table" and context.player or {}
    return traitListHas(player.traits, trait)
end

local function playerHasAnyTrait(context, values)
    for _, trait in ipairs(values or {}) do
        if playerHasTrait(context, trait) then return trait end
    end
    return nil
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

local function semanticFor(strategy, frame, context)
    local topic = frame.topic or frame.subject or "conversation"
    local details = {}
    if strategy == "APOLOGIZE" then
        return "APOLOGIZE", "APOLOGIZE", "RECIPIENT", {
            directed = true,
            repair = true,
        }, details
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
        local playerName = tostring(
            type(context) == "table" and context.playerName or ""
        )
        if playerName == "" then return nil end
        details.slots = {
            identityClaim = { name = playerName },
        }
        details.socialContext = {
            directed = false,
            selfDirected = true,
            target = "SELF",
            identityClaim = true,
        }
        details.selfDirected = true
        details.utteranceSlots = { name = playerName }
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
    local plan = UtterancePlan.New({
        speaker = "player",
        target = details.selfDirected and "self" or "recipient",
        dialogueAct = speechAct,
        strategy = strategy,
        stance = stance,
        topic = frame.topic,
        subject = frame.subject,
        intensity = type(ir.extensions) == "table"
            and type(ir.extensions.socialFeatures) == "table"
            and ir.extensions.socialFeatures.intensity or 0,
        lexemes = primary and { primary = primary } or {},
        slots = details.utteranceSlots,
        safeSlots = details.safeSlots,
        provenance = {
            providerID = Provider.id,
            discourseReplyTo = copy(frame.replyTo),
        },
    })
    local realized = UtterancePlan.Realize(plan)
    if not realized then return nil end
    return plan, realized
end

local function candidate(strategy, stance, context, reason)
    local frame = currentFrame(context)
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local intent, speechAct, subject, modifiers, details =
        semanticFor(strategy, frame, context)
    if not intent then return nil end
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
                or { kind = "conversation_actor", ref = "npc" },
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
        visibility = "player",
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
    local ir = type(context.dialogueIR) == "table"
        and context.dialogueIR or {}
    local frame = currentFrame(context)
    if next(ir) == nil or next(frame) == nil then return {} end

    local output = {}
    local seen = {}
    if hostilityContext(context) then
        add(output, seen, candidate(
            "APOLOGIZE", "POSITIVE", context, "hostility_repair"
        ))
        add(output, seen, candidate(
            "CLAIM_JOKE", "POSITIVE", context, "hostility_reframe_joke"
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
        local challengeTrait = playerHasAnyTrait(
            context, { "Brave", "Desensitized" }
        )
        if challengeTrait then
            add(output, seen, candidate(
                "CALL_BLUFF", "NEGATIVE", context,
                "player_trait:" .. challengeTrait
            ))
        end
        local empathyTrait = playerHasAnyTrait(
            context,
            { "Empathetic", "Kind", "KindHearted", "Pacifist" }
        )
        if empathyTrait then
            add(output, seen, candidate(
                "COMFORT", "POSITIVE", context,
                "player_trait:" .. empathyTrait
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

    local act = npcResponseAct(context)
        or upper(ir.speechAct or ir.intent)
    if act == "INFORM" or act == "ANSWER" then
        add(output, seen, candidate(
            "ACKNOWLEDGE", "NEUTRAL", context, "npc_answer_acknowledgement"
        ))
        add(output, seen, candidate(
            "ASK_FOLLOWUP", "NEUTRAL", context, "npc_answer_followup"
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

return Provider
