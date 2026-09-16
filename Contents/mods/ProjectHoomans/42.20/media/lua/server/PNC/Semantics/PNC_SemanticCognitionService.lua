-- Authoritative NPC-cognition storage and conversation projection.
--
-- The service is deliberately smaller than the NLU layer.  It records facts
-- supplied by perception, communication, or authored gameplay systems and
-- exposes only a bounded, conversation-scoped projection to a client.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Projection = PNC.Semantics.CognitionProjection
    or require "PNC/Semantics/PNC_SemanticCognitionProjection"
local Service = PNC.Semantics.CognitionService or {}
PNC.Semantics.CognitionService = Service

local Core = PNC.Core
local Registry = PNC.Registry

Service.VERSION = 1

local function authority()
    return Core and Core.IsAuthority and Core.IsAuthority() == true
end

local function resolveRecord(npcID)
    local id = tostring(npcID or "")
    local record
    if id == "" or not Registry or not Registry.Get then
        return nil, "npc_id_required"
    end
    record = Registry.Get(id)
    if type(record) ~= "table" or tostring(record.id or "") ~= id then
        return nil, "npc_not_found"
    end
    if record.alive == false then return nil, "npc_unavailable" end
    return record
end

local function storeFor(record)
    if not record then return nil end
    record.semanticCognition = Projection.Normalize(
        record.semanticCognition,
        record.id
    )
    return record.semanticCognition
end

local function requestOptions(args)
    args = type(args) == "table" and args or {}
    local output = {
        subject = args.subject,
        targetID = args.targetID or args.target,
        subjects = args.subjects,
    }
    return output
end

function Service.Get(npcID)
    if not authority() then return nil, "not_authority" end
    local record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    return storeFor(record)
end

function Service.GetFact(npcID, factSubject, targetID, worldAgeHours)
    local projection, reason = Service.Get(npcID)
    if not projection then return nil, reason end
    return Projection.Get(
        projection,
        factSubject,
        targetID,
        worldAgeHours
    )
end

-- Perception and communication systems call this method after they have
-- established the evidence.  Cognition never scans the world or performs an
-- action on its own.
function Service.Remember(npcID, factSpec)
    if not authority() then return false, "not_authority" end
    local record, reason = resolveRecord(npcID)
    local projection
    local accepted
    local result
    if not record then return false, reason end
    if type(factSpec) ~= "table" then return false, "invalid_fact" end
    projection = storeFor(record)
    accepted, result, projection = Projection.Upsert(
        projection,
        factSpec,
        record.id
    )
    if not accepted then return false, result end
    record.semanticCognition = projection
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "semantic_cognition")
    end
    return true, result, projection
end

function Service.Forget(npcID, factSubject, targetID)
    if not authority() then return false, "not_authority" end
    local record, reason = resolveRecord(npcID)
    local accepted
    local result
    local projection
    if not record then return false, reason end
    projection = storeFor(record)
    accepted, result, projection = Projection.Remove(
        projection,
        factSubject,
        targetID,
        record.id
    )
    if not accepted then return false, result end
    record.semanticCognition = projection
    if Registry.MarkDirty then
        Registry.MarkDirty(record, "semantic_cognition")
    end
    return true, result, projection
end

function Service.BuildProjection(npcID, options)
    if not authority() then return nil, "not_authority" end
    local record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    return Projection.BuildClientProjection(
        storeFor(record),
        record.id,
        options
    )
end

function Service.BuildForConversation(player, npcID, options)
    local record
    local reason
    local valid
    options = type(options) == "table" and options or {}
    if not authority() then return nil, "not_authority" end
    record, reason = resolveRecord(npcID)
    if not record then return nil, reason end
    if not PNC.ConversationScene
        or not PNC.ConversationScene.ValidateConversationLease
    then
        return nil, "conversation_authority_unavailable"
    end
    valid, reason = PNC.ConversationScene.ValidateConversationLease(
        record,
        player,
        options.conversationToken or options.token
    )
    if valid ~= true then return nil, reason or "invalid_conversation" end
    return Projection.BuildClientProjection(
        storeFor(record),
        record.id,
        requestOptions(options)
    )
end

function Service.HandleRequest(player, args)
    local projection
    local reason
    local Network = PNC.Network
    args = type(args) == "table" and args or {}
    projection, reason = Service.BuildForConversation(
        player,
        args.npcID,
        args
    )
    if Network and Network.SendSemanticCognition then
        Network.SendSemanticCognition(
            player,
            projection,
            reason,
            args.requestID,
            args.npcID
        )
    end
    return projection ~= nil, reason, projection
end

return Service
