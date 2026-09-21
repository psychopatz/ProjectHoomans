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
require "PNC/Conversation/Memory/PNC_ConversationMemory"

local Projection = PNC.Semantics.CognitionProjection
    or require "PNC/Semantics/PNC_SemanticCognitionProjection"
local Service = PNC.Semantics.CognitionService or {}
PNC.Semantics.CognitionService = Service

local Core = PNC.Core
local Registry = PNC.Registry
local MemoryEvents = PNC.Conversation
    and PNC.Conversation.Memory
    and PNC.Conversation.Memory.Events or nil

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
    -- Service writes and record loading both normalize this table; keep read
    -- paths from deep-copying and sorting it again on every lookup.
    if type(record.semanticCognition) == "table"
        and record.semanticCognition.schemaVersion == Projection.VERSION
        and tostring(record.semanticCognition.npcID or "")
            == tostring(record.id or "")
        and type(record.semanticCognition.facts) == "table"
    then
        return record.semanticCognition
    end
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

local function currentPlayerKey(player)
    local PlayerCharacters = PNC.PlayerCharacters
    local ok
    local key
    if not player or not PlayerCharacters
        or type(PlayerCharacters.GetEntityKey) ~= "function"
    then
        return nil
    end
    ok, key = pcall(
        PlayerCharacters.GetEntityKey,
        player,
        { callback = "semantic_cognition_gossip" }
    )
    if not ok or type(key) ~= "string" or key == "" then
        return nil
    end
    return key
end

local function currentPlayerName(player)
    local ok
    local name
    if not player then return nil end
    if type(player.getUsername) == "function" then
        ok, name = pcall(player.getUsername, player)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    if type(player.getDisplayName) == "function" then
        ok, name = pcall(player.getDisplayName, player)
        if ok and type(name) == "string" and name ~= "" then
            return name
        end
    end
    return nil
end

local function attachMemoryGossip(projection, speakerRecord, options, player)
    local targetValue = options.targetID or options.target
    local target
    local subjectName
    local codes
    local selfQuery = tostring(targetValue or "") == "self"
    if not projection or not MemoryEvents
        or type(MemoryEvents.ResolveTarget) ~= "function"
        or type(MemoryEvents.BuildGossipCodes) ~= "function"
    then
        return
    end
    if selfQuery then
        targetValue = currentPlayerKey(player)
        target = targetValue
            and MemoryEvents.ResolveTarget(targetValue) or nil
        subjectName = target and target.kind == "player"
            and (currentPlayerName(player) or "you")
            or target and target.record and target.record.name or nil
        if target and type(subjectName) == "string" and subjectName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                target,
                subjectName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
        end
    else
        target = MemoryEvents.ResolveTarget(targetValue)
        subjectName = target and target.record and target.record.name or nil
        if target and type(subjectName) == "string" and subjectName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                target,
                subjectName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
        end
    end
    if selfQuery and (type(codes) ~= "table" or #codes == 0) then
        local EntityRef = PNC.EntityRef
        local selfTargetKey = EntityRef and EntityRef.ForNPC
            and EntityRef.ForNPC(speakerRecord.id) or nil
        local selfTarget = selfTargetKey
            and MemoryEvents.ResolveTarget(selfTargetKey) or nil
        local selfName = selfTarget and selfTarget.record
            and selfTarget.record.name or speakerRecord.name or "me"
        if selfTarget and type(selfName) == "string" and selfName ~= "" then
            codes = MemoryEvents.BuildGossipCodes(
                speakerRecord,
                selfTarget,
                selfName,
                speakerRecord.tacticalClass,
                MemoryEvents.MAX_GOSSIP
            )
            subjectName = selfName
        end
    end
    if type(codes) == "table" and #codes > 0 then
        projection._memoryGossip = {
            codes = codes,
            subject = subjectName,
        }
    end
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
    local projection
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
    projection = Projection.BuildClientProjection(
        storeFor(record),
        record.id,
        requestOptions(options)
    )
    if projection then
        local identity = type(record.identity) == "table"
            and record.identity or nil
        projection.identitySeed = record.identitySeed
            or identity and (identity.identitySeed or identity.seed)
        attachMemoryGossip(projection, record, options, player)
    end
    return projection
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
