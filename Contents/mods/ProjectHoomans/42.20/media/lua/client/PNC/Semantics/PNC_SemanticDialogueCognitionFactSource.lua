-- Read-only fact provider backed by the server's conversation projection.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Facts = PNC.Semantics.DialogueFacts
    or require "PNC/Semantics/PNC_SemanticDialogueFacts"
local Cognition = PNC.Semantics.CognitionClient
    or require "PNC/Semantics/PNC_SemanticCognitionClient"

Facts.RegisterProvider("client_npc_cognition_projection", {
    priority = 150,
    Resolve = function(ir, state, context)
        local target = ir and ir.target or nil
        local targetID
        local npcID = context and context.npcID
        local world = context and context.worldContext or nil
        local worldAge = world and (
            world.worldAgeHours or world.ageHours
        ) or nil
        local fact
        local reason
        if type(target) ~= "table" or target.unresolved == true then
            return nil, "target_unresolved"
        end
        targetID = target.id or target.entityID or target.npcID
        if tostring(npcID or "") == "" then
            return nil, "observer_npc_required"
        end
        fact, reason = Cognition.GetFact(
            npcID,
            ir and ir.subject,
            targetID,
            worldAge
        )
        if not fact then return nil, reason or "fact_unavailable" end
        return fact
    end,
})

return Facts
