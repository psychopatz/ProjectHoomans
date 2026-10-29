-- Dispatcher for deterministic semantic question responses.
--
-- The public require path remains stable while the domain-specific resolvers
-- are loaded as cohesive spokes.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Response = PNC.Semantics.LocalResponse
local Internal = Response and Response.Internal or {}
Response.Internal = Internal
local Semantic = PsychopatzCore and PsychopatzCore.Semantics or nil
local IR = Semantic and Semantic.IR or nil

require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions_Observations"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions_Facts"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions_Context"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions_Conversation"
require "PNC/Semantics/PNC_SemanticDialogueLocalResponse_Questions_Whereabouts"

return function(ir, state, context)
    if type(ir) ~= "table" then return nil end
    local world = type(context) == "table" and context.worldContext or nil
    if ir.extensions
        and ir.extensions.dialogueFollowUp == "CONVERSATION_CONTINUATION"
    then
        return Internal.ResolveConversationContinuation(ir, state, context)
    end
    if ir.subject == "TIME" then return Internal.ResolveTime(world) end
    if ir.subject == "DATE" then return Internal.ResolveDate(world) end
    if ir.subject == "WEATHER" then return Internal.ResolveWeather(world) end
    if ir.subject == "IDENTITY" then
        return Internal.ResolveIdentityQuestion(ir, state, context)
    end
    if ir.subject == "RELATIONSHIP_STATUS" then
        return Internal.ResolveRelationshipStatus(ir, state, context)
    end
    if ir.subject == "ACTIVITY" then
        return Internal.ResolveActivity(ir, state, context)
    end
    if ir.subject == "CONVERSATION_TOPIC"
        and ir.extensions
        and ir.extensions.topic == "whats_up"
    then
        return Internal.ResolveWhatsUp(ir, state, context)
    end
    if ir.subject == "WELLBEING" then
        return Internal.ResolveWellbeing(ir, state, context)
    end
    if ir.subject == "WELLBEING_RECIPROCAL" then
        local wellbeing = IR and type(IR.Clone) == "function"
            and IR.Clone(ir) or nil
        if wellbeing then
            wellbeing.subject = "WELLBEING"
            return Internal.ResolveWellbeing(wellbeing, state, context)
        end
        return Internal.ResolveWellbeing(ir, state, context)
    end
    if ir.subject == "NPC_BITE_STATUS" then
        return Internal.ResolveMedicalBiteStatus(ir, state, context)
    end
    if ir.subject == "NPC_RESIDENCE" then
        return Internal.ResolveResidenceQuestion(ir, state, context)
    end
    if ir.subject == "NPC_HEALTH_STATE" then
        return Internal.ResolveHealthStateQuestion(ir, state, context)
    end
    if ir.subject == "NPC_KNOWLEDGE" then
        return Internal.ResolveKnowledgeQuestion(ir, state, context)
    end
    if ir.subject == "NPC_BACKSTORY" then
        return Internal.ResolveBackstoryQuestion(ir, state, context)
    end
    if ir.subject == "CONTEXT_REFERENCE" then
        return Internal.ResolveContextReferenceQuestion(ir, state, context)
    end
    if ir.subject == "COMMUNITY_ROLE_WHEREABOUTS" then
        return Internal.ResolveCommunityRoleWhereabouts(ir, state, context)
    end
    if ir.subject == "NEEDS" or ir.subject == "QUANTITY" then
        return Internal.ResolveNeeds(ir, state, context)
    end
    if ir.subject == "LOCATION" or ir.subject == "SEEN" then
        return Internal.ResolveLocationOrSeen(ir)
    end
    return nil
end
