-- Bounded contextual social/relationship choice provider.
--
-- This provider contributes an existing WELLBEING semantic frame for an
-- owned companion. It does not expose relationship scores or private facts,
-- and the existing DialogueInput route remains authoritative at click time.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Provider = PNC.Semantics.DialogueSocialChoiceProvider or {}
PNC.Semantics.DialogueSocialChoiceProvider = Provider

Provider.id = "projecthoomans.social_context"
Provider.sourceKind = "social_context"
Provider.order = 55

local function relationshipProposalCandidate(context, relationship, bond, groupID)
    -- The provider only advertises a proposal when the production service is
    -- present and says the current actor is eligible.  The click path still
    -- calls the same authority again, so this is never a policy duplicate.
    local service = PNC.Relationships
    if not service or type(service.EvaluateProposal) ~= "function"
        or type(service.Propose) ~= "function"
    then
        return nil
    end
    local actor = context.actorConversationContext or {}
    local situation = actor.situation or {}
    local healthState = string.lower(tostring(situation.healthState or ""))
    local activeBehavior = string.lower(
        tostring(situation.activeBehavior or "")
    )
    if healthState == "critical" or activeBehavior == "fleeing" then
        return nil
    end
    local npcID = context.npcID or actor.npcID or actor.id
    if not npcID then return nil end
    local ok, evaluation = pcall(service.EvaluateProposal, npcID)
    if not ok or type(evaluation) ~= "table"
        or evaluation.eligible ~= true
    then
        return nil
    end
    return {
        id = "social.relationship_proposal",
        topic = "relationship",
        groupID = groupID or "topic:relationship",
        providerID = Provider.id,
        providerOrder = Provider.order,
        rank = 2,
        semanticOwner = "projecthoomans.relationship.service",
        contextReason = "production_relationship_proposal_eligible",
        eligibility = {
            status = "allowed",
            allowed = true,
            reason = "production_relationship_proposal_eligible",
        },
        source = {
            kind = Provider.sourceKind,
            providerID = Provider.id,
            reason = "production_relationship_proposal_eligible",
        },
        frame = {
            kind = "semantic_click_frame",
            topic = "relationship",
            intent = "REQUEST",
            speechAct = "REQUEST",
            action = "RELATIONSHIP_PROPOSAL",
            subject = "RELATIONSHIP_PROPOSAL",
            target = { kind = "conversation_actor", ref = "npc" },
            slots = {
                npcID = { kind = "conversation_actor", ref = "npc" },
            },
            extensions = {
                route = "semantic_provider",
                providerID = Provider.id,
                actionID = "relationship_proposal",
                relationshipState = relationship.state,
                bond = bond.class,
            },
            textKey =
                "UI_PNC_Conversation_Suggestion_RelationshipProposal_Utterance",
            textFallback = "Would you like to be together?",
            labelKey =
                "UI_PNC_Conversation_Suggestion_RelationshipProposal_Label",
        },
        display = {
            labelKey =
                "UI_PNC_Conversation_Suggestion_RelationshipProposal_Label",
            labelFallback = "Propose a relationship",
            utteranceKey =
                "UI_PNC_Conversation_Suggestion_RelationshipProposal_Utterance",
            utteranceFallback = "Would you like to be together?",
        },
        visibility = "player",
    }
end

function Provider.collect(context)
    context = type(context) == "table" and context or {}
    local actor = context.actorConversationContext or {}
    local roles = actor.roles or {}
    local relationship = actor.relationship or {}
    local bond = actor.bond or {}
    local authority = context.actorAuthority or {}
    local topic = tostring(context.currentTopic or "")
    local relationshipState = string.lower(tostring(relationship.state or ""))
    local role = string.lower(tostring(roles.role or ""))
    local hostile = roles.hostile == true or role == "enemy"
        or relationshipState == "enemy" or relationshipState == "rival"
    if hostile then return {} end

    local ownedCompanion = roles.companion == true
        and roles.owned == true
        and roles.authorityEligible == true
    local bondClass = string.lower(tostring(bond.class or ""))
    local closeRelationship = relationshipState == "friend"
        and (tonumber(relationship.familiarity) or 0) >= 20
        and (bondClass == "" or bondClass == "friend"
            or bondClass == "family" or bondClass == "lover")

    local proposal = relationshipProposalCandidate(
        context, relationship, bond,
        context.activeHubID == "whats_up"
            and "semantic_hub.whats_up" or "topic:relationship"
    )

    if context.activeHubID == "whats_up" then
        if not ownedCompanion and not closeRelationship and not proposal then
            return {}
        end
        local output = {
            {
                id = "social.personal_check_in",
                topic = "wellbeing",
                groupID = "semantic_hub.whats_up",
                providerID = Provider.id,
                providerOrder = Provider.order,
                rank = 1,
                semanticOwner = "projecthoomans.semantic.wellbeing",
                contextReason = ownedCompanion
                    and "owned_companion_context"
                    or "trusted_close_relationship",
                eligibility = {
                    status = "allowed",
                    allowed = true,
                    reason = ownedCompanion
                        and "owned_companion_context"
                        or "trusted_close_relationship",
                },
                source = {
                    kind = Provider.sourceKind,
                    providerID = Provider.id,
                    reason = "close_relationship_disclosure",
                },
                frame = {
                    kind = "semantic_click_frame",
                    topic = "wellbeing",
                    intent = "QUESTION",
                    speechAct = "QUESTION",
                    subject = "WELLBEING",
                    target = { kind = "conversation_actor", ref = "npc" },
                    slots = {
                        npcID = { kind = "conversation_actor", ref = "npc" },
                    },
                    socialContext = {
                        directed = true,
                        personalQuestion = true,
                        target = "SELF",
                    },
                    extensions = {
                        route = "semantic_provider",
                        providerID = Provider.id,
                        topic = "wellbeing",
                        hubID = "whats_up",
                        hubAvenue = true,
                    },
                    textKey =
                        "UI_PNC_Conversation_Suggestion_PersonalCheckIn_Utterance",
                    textFallback = "Anything bothering you?",
                    labelKey =
                        "UI_PNC_Conversation_Suggestion_PersonalCheckIn_Label",
                },
                display = {
                    labelKey =
                        "UI_PNC_Conversation_Suggestion_PersonalCheckIn_Label",
                    labelFallback = "Ask what's on their mind",
                    utteranceKey =
                        "UI_PNC_Conversation_Suggestion_PersonalCheckIn_Utterance",
                    utteranceFallback = "Anything bothering you?",
                },
                visibility = "player",
            },
        }
        if proposal then output[#output + 1] = proposal end
        return output
    end

    if topic ~= ""
        and topic ~= "greeting"
        and topic ~= "wellbeing"
        and topic ~= "whats_up"
    then
        return {}
    end
    if roles.companion ~= true and not proposal then return {} end
    if roles.companion ~= true or authority.owned ~= true then
        return proposal and { proposal } or {}
    end
    local output = {
        {
            id = "social.check_in",
            topic = "wellbeing",
            providerID = Provider.id,
            providerOrder = Provider.order,
            source = { kind = Provider.sourceKind, providerID = Provider.id },
            frame = {
                kind = "semantic_click_frame",
                textKey = "UI_PNC_Conversation_Suggestion_CheckIn_Utterance",
                textFallback = "How are we doing?",
                labelKey = "UI_PNC_Conversation_Suggestion_CheckIn_Label",
                topic = "wellbeing",
                intent = "QUESTION",
                speechAct = "QUESTION",
                subject = "WELLBEING",
                extensions = {
                    route = "semantic_provider",
                    providerID = Provider.id,
                },
                target = { kind = "conversation_actor", ref = "npc" },
                slots = {
                    npcID = { kind = "conversation_actor", ref = "npc" },
                },
            },
            display = {
                labelKey = "UI_PNC_Conversation_Suggestion_CheckIn_Label",
                labelFallback = "Check in with them",
                utteranceKey = "UI_PNC_Conversation_Suggestion_CheckIn_Utterance",
                utteranceFallback = "How are we doing?",
            },
            visibility = "player",
        },
    }
    if proposal then output[#output + 1] = proposal end
    return output
end

return Provider
