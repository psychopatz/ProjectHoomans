-- Build the bounded server response contract for identity exchanges.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Semantics/PNC_SemanticDiagnostics"

local Result = {}
local Diagnostics = PNC and PNC.Semantics
    and PNC.Semantics.SemanticDiagnostics or nil

local function logResult(payload)
    if not Diagnostics
        or type(Diagnostics.IsEnabled) ~= "function"
        or Diagnostics.IsEnabled() ~= true
    then
        return false
    end
    payload = type(payload) == "table" and payload or {}
    return Diagnostics.Record("semantic.identity.result", {
        requestID = payload.requestID,
        npcID = payload.npcID,
        kind = payload.kind,
        accepted = payload.accepted == true,
        truthful = payload.truthful,
        reason = payload.reason,
    }, { requestID = payload.requestID })
end

function Result.RelationshipDelta(before, after)
    return {
        approval = (tonumber(after and after.approval) or 0)
            - (tonumber(before and before.approval) or 0),
        respect = (tonumber(after and after.respect) or 0)
            - (tonumber(before and before.respect) or 0),
        familiarity = (tonumber(after and after.familiarity) or 0)
            - (tonumber(before and before.familiarity) or 0),
    }
end

function Result.BuildRejected(args, reason)
    return {
        requestID = tostring(args and args.requestID or ""),
        npcID = tostring(args and args.npcID or ""),
        kind = tostring(args and args.kind or ""),
        accepted = false,
        reason = tostring(reason or "identity_exchange_rejected"),
    }
end

function Result.BuildAccepted(fields)
    fields = type(fields) == "table" and fields or {}
    local relationship = fields.relationship
    local details = fields.details
    local effect = fields.effect
    local lease = fields.lease
    return {
        requestID = fields.requestID,
        npcID = fields.npcID,
        kind = fields.kind,
        accepted = true,
        truthful = fields.truthful,
        trustLabel = fields.trustLabel,
        responseText = fields.responseText,
        responseKey = fields.responseKey,
        responseArgs = fields.responseArgs,
        relationship = relationship,
        relationshipBefore = fields.relationshipBefore,
        relationshipAfter = relationship,
        relationshipDelta = fields.relationshipDelta,
        relationshipRevision = relationship and relationship.revision,
        eventID = details and details.eventID or fields.eventID,
        memoryID = details and details.memoryID,
        memoryType = details and details.memoryType
            or effect and effect.memoryType,
        leaseToken = lease and lease.token,
    }
end

function Result.SendRejected(player, args, reason)
    local payload = Result.BuildRejected(args, reason)
    logResult(payload)
    local network = PNC and PNC.Network
    if network and type(network.SendSemanticIdentityResult) == "function" then
        network.SendSemanticIdentityResult(player, payload)
    end
    return false, payload.reason
end

function Result.SendAccepted(player, payload)
    logResult(payload)
    local network = PNC and PNC.Network
    if network and type(network.SendSemanticIdentityResult) == "function" then
        network.SendSemanticIdentityResult(player, payload)
    end
    if network and type(network.SendConversationRelationship) == "function" then
        network.SendConversationRelationship(
            player,
            payload.relationship,
            "semantic_identity",
            {
                source = "semantic_identity",
                eventID = payload.eventID,
                relationshipBefore = payload.relationshipBefore,
                relationshipAfter = payload.relationshipAfter,
                relationshipDelta = payload.relationshipDelta,
            }
        )
    end
    return true, payload
end

return Result
