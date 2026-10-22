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

    if context.activeHubID == "whats_up" then
        if not ownedCompanion and not closeRelationship then return {} end
        return {
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
    end

    if topic ~= ""
        and topic ~= "greeting"
        and topic ~= "wellbeing"
        and topic ~= "whats_up"
    then
        return {}
    end
    if roles.companion ~= true or authority.owned ~= true then return {} end
    return {
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
end

return Provider
