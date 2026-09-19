-- Apply an admitted identity exchange through the authoritative relationship service.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Mutation = {}
local Identity = require "PNC/Semantics/PNC_SemanticIdentityExchange"

function Mutation.Apply(request)
    if type(request) ~= "table"
        or tostring(request.npcID or "") == ""
        or tostring(request.targetKey or "") == ""
        or tostring(request.eventID or "") == ""
        or type(request.effect) ~= "table"
    then
        return false, "identity_mutation_invalid"
    end
    local relationships = PNC and PNC.Relationships
    if type(relationships) ~= "table"
        or type(relationships.ApplyConversationEffect) ~= "function"
    then
        return false, "relationship_service_unavailable"
    end

    return relationships.ApplyConversationEffect(
        request.npcID,
        request.targetKey,
        request.effect,
        {
            blockID = "semantic_identity",
            choiceID = request.kind,
            outcomeID = request.requestID,
            eventID = request.eventID,
            interactionType = request.effect.interactionType,
            worldAgeHours = request.worldAgeHours,
            sourceSystem = "semantic_identity",
            interaction = {
                kind = request.kind,
                source = "semantic_dialogue",
                interactionType = request.effect.interactionType,
                claimedName = request.kind == Identity.EVENT_CLAIM
                    and request.claimedName or nil,
                truthful = request.truthful,
                applied = true,
                eventID = request.eventID,
                at = request.worldAgeHours,
                worldAgeHours = request.worldAgeHours,
            },
        }
    )
end

return Mutation
