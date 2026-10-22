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
    local authority = context.actorAuthority or {}
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
