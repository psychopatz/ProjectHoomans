-- Conversation continuation, relationship, and location question responses.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local copyArgs = Internal.CopyArgs
local catalogResponse = Internal.CatalogResponse
local targetText = Internal.TargetText
local factFor = Internal.FactFor

local function continuationResponse(templateID, topic)
    return {
        templateID = templateID,
        dialogueAct = "CONVERSATION_CONTINUATION",
        topic = topic,
        uncertainty = "unknown",
        tone = "conversational",
        selectionSource = "conversation_context",
    }
end

local function resolveConversationContinuation(ir, state, context)
    local recentAnswer = type(Internal.RecentAnswer) == "function"
        and Internal.RecentAnswer(context, 4) or nil
    local subject = recentAnswer and recentAnswer.subject or nil
    local topic = recentAnswer and recentAnswer.topic or nil

    if subject == "WELLBEING" or topic == "wellbeing" then
        local response = catalogResponse(
            "semantic.question.wellbeing.follow_up", ir, state, context
        )
        if response then
            response.dialogueAct = "CONVERSATION_CONTINUATION"
            response.selectionSource = "conversation_context"
            return response
        end
    end
    if subject == "GOSSIP" or topic == "gossip" then
        local gossip = context and context.npcGossip
        local hasMemory = type(gossip) == "table"
            and type(gossip.statements) == "table"
            and #gossip.statements > 0
        return continuationResponse(
            hasMemory
                and "semantic.conversation.continuation.gossip_memory"
                or "semantic.conversation.continuation.gossip_unknown",
            "gossip"
        )
    end
    if subject == "NPC_RESIDENCE" or topic == "location"
        or topic == "residence"
    then
        return continuationResponse(
            "semantic.conversation.continuation.residence",
            "RESIDENCE"
        )
    end
    if subject == "NPC_BITE_STATUS" or subject == "NPC_HEALTH_STATE"
        or topic == "medical"
    then
        local situation = context and context.dialogueSituation
        local npc = situation and situation.npc
        local healthState = npc and npc.healthState
        local healthKnown = type(healthState) == "string"
            and healthState ~= ""
            and healthState ~= "unknown"
        return continuationResponse(
            healthKnown
                and "semantic.conversation.continuation.medical_known"
                or "semantic.conversation.continuation.medical_unknown",
            "MEDICAL"
        )
    end
    if subject == "NPC_KNOWLEDGE" or topic == "knowledge" then
        return continuationResponse(
            "semantic.conversation.continuation.knowledge",
            "KNOWLEDGE"
        )
    end
    return continuationResponse(
        "semantic.conversation.continuation.default",
        topic or "conversation"
    )
end

local function isCommittedRelation(value)
    if type(value) ~= "string" then return false end
    value = string.lower(value)
    value = string.gsub(value, "[%s%-]", "_")
    value = string.gsub(value, "[^%w_]", "")
    return value == "lover" or value == "partner" or value == "spouse"
end

local function hasKnownCurrentPartner(context)
    context = type(context) == "table" and context or {}
    local relationship = type(context.relationship) == "table"
        and context.relationship or {}
    local npcRecord = type(context.npcRecord) == "table"
        and context.npcRecord or {}
    local npcGeneration = type(npcRecord.generation) == "table"
        and npcRecord.generation or {}
    local entry = type(context.entry) == "table" and context.entry or {}
    local entryRecord = type(entry.record) == "table" and entry.record or {}
    local entryGeneration = type(entryRecord.generation) == "table"
        and entryRecord.generation or {}

    return isCommittedRelation(context.relationshipState)
        or isCommittedRelation(context.conversationRelationshipID)
        or isCommittedRelation(context.relationshipKind)
        or isCommittedRelation(context.conversationRelationship)
        or isCommittedRelation(relationship.category)
        or isCommittedRelation(relationship.status)
        or isCommittedRelation(relationship.relationshipKind)
        or isCommittedRelation(relationship.relationshipState)
        or isCommittedRelation(npcGeneration.relationshipKind)
        or isCommittedRelation(entryGeneration.relationshipKind)
end

local function followsRecentCompliment(context)
    local recentTurns = type(Internal.RecentTurns) == "function"
        and Internal.RecentTurns(context, 2) or {}
    if type(recentTurns) ~= "table" or #recentTurns < 2 then
        return false
    end

    local npcReply = recentTurns[1]
    local playerCompliment = recentTurns[2]
    return type(npcReply) == "table"
        and npcReply.speaker == "npc"
        and npcReply.speechAct == "COMPLIMENT_RESPONSE"
        and type(playerCompliment) == "table"
        and playerCompliment.speaker == "player"
        and (playerCompliment.intent == "COMPLIMENT"
            or playerCompliment.speechAct == "COMPLIMENT")
end

local function resolveRelationshipStatus(ir, state, context)
    local followsCompliment = followsRecentCompliment(context)
    if hasKnownCurrentPartner(context) then
        if followsCompliment then
            local response = catalogResponse(
                "semantic.question.relationship_status.committed_after_compliment",
                ir,
                state,
                context
            )
            if response then return response end
        end
        return catalogResponse(
            "semantic.question.relationship_status.committed",
            ir,
            state,
            context
        )
    end

    if followsCompliment then
        local response = catalogResponse(
            "semantic.question.relationship_status.unknown_after_compliment",
            ir,
            state,
            context
        )
        if response then return response end
    end

    -- A missing partner fact is not evidence that the NPC is single. Keep the
    -- deterministic answer open-ended until the character has an authored or
    -- authoritative relationship status.
    return catalogResponse(
        "semantic.question.relationship_status.unknown",
        ir,
        state,
        context
    )
end

local function resolveLocationOrSeen(ir)
    local fact = factFor(ir)
    if fact and fact.status == "known" then
        if ir.subject == "LOCATION" then
            local location = fact.location or {}
            local band = location.distanceBand
            local templateID = "semantic.question.location.unknown"
            if location.label then
                templateID = "semantic.question.location.named"
            elseif band == "nearby" then
                templateID = "semantic.question.location.nearby"
            elseif band == "not_far" then
                templateID = "semantic.question.location.not_far"
            elseif band == "far" then
                templateID = "semantic.question.location.far"
            end
            return {
                templateID = templateID,
                args = copyArgs({
                    target = targetText(ir.target, fact),
                    location = location.label,
                    freshness = fact.freshness,
                }),
            }
        end
        if fact.value == true then
            return {
                templateID = "semantic.question.seen_yes",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        end
        if fact.value == false then
            return {
                templateID = "semantic.question.seen_no",
                args = copyArgs({ target = targetText(ir.target, fact) }),
            }
        end
    elseif fact and fact.status == "ambiguous" then
        return {
            templateID = "semantic.question.fact_clarification",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    elseif ir.subject == "LOCATION" then
        return {
            templateID = "semantic.question.location_unknown",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    else
        return {
            templateID = "semantic.question.seen_unknown",
            args = copyArgs({ target = targetText(ir.target, fact) }),
        }
    end
end

Internal.ResolveConversationContinuation = resolveConversationContinuation
Internal.ResolveRelationshipStatus = resolveRelationshipStatus
Internal.ResolveLocationOrSeen = resolveLocationOrSeen

return Response
