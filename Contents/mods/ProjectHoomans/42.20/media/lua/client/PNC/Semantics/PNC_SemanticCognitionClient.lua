-- Client-side cache for conversation-scoped NPC-cognition projections.
--
-- This module is intentionally read-only with respect to the simulation.  A
-- server response can update this cache, but the cache never becomes an
-- authority and never creates a fact locally.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local Client = PNC.Semantics.CognitionClient or {}
PNC.Semantics.CognitionClient = Client

local Projection = PNC.Semantics.CognitionProjection
    or require "PNC/Semantics/PNC_SemanticCognitionProjection"
local Network = PNC.Network or {}
local ClientState = Network.ClientState or {}
if Network.ClientState == nil then Network.ClientState = ClientState end
local Core = PNC.Core
require "PNC/Conversation/Memory/PNC_ConversationMemory"
local Memory = PNC.Conversation and PNC.Conversation.Memory or nil

Client.VERSION = 1

local function now()
    return Core and Core.Now and Core.Now() or 0
end

local function npcKey(npcID)
    npcID = tostring(npcID or "")
    return npcID ~= "" and npcID or nil
end

function Client.Reset()
    ClientState.semanticCognition = {}
    ClientState.pendingSemanticCognition = {}
    ClientState.semanticMemoryGossip = {}
    ClientState.lastSemanticCognitionRequestAt = {}
    ClientState.lastSemanticCognitionReceiveAt = 0
    ClientState.lastSemanticCognitionFailure = nil
end

local function pendingMatches(pending, payload)
    return type(pending) == "table"
        and payload and payload.requestID ~= nil
        and pending.requestID ~= nil
        and tostring(payload.requestID) == tostring(pending.requestID)
end

local function safeGossipSubject(value)
    local output
    if type(value) ~= "string" and type(value) ~= "number" then
        return nil
    end
    output = string.gsub(tostring(value), "%c", "")
    output = string.gsub(output, "^%s+", "")
    output = string.gsub(output, "%s+$", "")
    if output == "" then return nil end
    return string.sub(output, 1, 80)
end

local function applyMemoryGossip(id, payload, pending)
    local subject = safeGossipSubject(payload and payload.gs)
    local codes = type(payload) == "table" and payload.g or nil
    local output = {}
    local seen = {}
    local index
    local code
    local template
    if not pendingMatches(pending, payload) then
        return false
    end
    ClientState.semanticMemoryGossip =
        ClientState.semanticMemoryGossip or {}
    ClientState.semanticMemoryGossip[id] = nil
    if not subject or type(codes) ~= "table"
        or tostring(pending.targetID or "") == ""
        or not Memory
        or type(Memory.GetGossipTemplateByCode) ~= "function"
    then
        return true
    end
    for index = 1, math.min(#codes, Memory.Events.MAX_GOSSIP or 4) do
        code = tonumber(codes[index])
        if code and code == math.floor(code)
            and code > 0 and code <= 65535 and not seen[code]
        then
            template = Memory.GetGossipTemplateByCode(code)
            if template then
                seen[code] = true
                output[#output + 1] = code
            end
        end
    end
    if #output > 0 then
        ClientState.semanticMemoryGossip[id] = {
            requestID = tostring(payload.requestID),
            targetID = tostring(pending.targetID),
            subject = subject,
            codes = output,
        }
    end
    return true
end

function Client.GetGossipContext(npcID, targetID)
    local id = npcKey(npcID)
    local entry = id and ClientState.semanticMemoryGossip
        and ClientState.semanticMemoryGossip[id] or nil
    local statements = {}
    local index
    local packet
    local text
    if not entry then return nil end
    if targetID == nil or tostring(targetID) == ""
        or tostring(targetID) ~= tostring(entry.targetID or "")
    then
        return nil
    end
    if not Memory or type(Memory.BuildGossipPacket) ~= "function"
        or type(Memory.RenderGossipPacket) ~= "function"
    then
        return nil
    end
    for index = 1, math.min(#entry.codes, Memory.Events.MAX_GOSSIP or 4) do
        packet = Memory.BuildGossipPacket(
            entry.codes[index],
            { subject = entry.subject }
        )
        text = packet and Memory.RenderGossipPacket(packet) or nil
        if type(text) == "string" and text ~= "" then
            statements[#statements + 1] = text
        end
    end
    if #statements == 0 then return nil end
    return {
        subject = entry.subject,
        statements = statements,
    }
end

function Client.Get(npcID)
    local id = npcKey(npcID)
    return id and ClientState.semanticCognition
        and ClientState.semanticCognition[id] or nil
end

function Client.GetIdentitySeed(npcID)
    local projection = Client.Get(npcID)
    return projection and projection.identitySeed or nil
end

function Client.GetFact(npcID, factSubject, targetID, worldAgeHours)
    local projection = Client.Get(npcID)
    if not projection then return nil, "cognition_unavailable" end
    return Projection.Get(
        projection,
        factSubject,
        targetID,
        worldAgeHours
    )
end

function Client.ApplyPayload(payload)
    local projection = type(payload) == "table"
        and payload.projection or nil
    local id = projection and npcKey(projection.npcID or projection.n)
        or payload and npcKey(payload.npcID) or nil
    local merged
    local changed
    local reason
    local pending = id and ClientState.pendingSemanticCognition
        and ClientState.pendingSemanticCognition[id] or nil
    local matchingRequest = pendingMatches(pending, payload)
    if not id then
        ClientState.lastSemanticCognitionFailure =
            payload and payload.reason or "npc_id_required"
        return false, ClientState.lastSemanticCognitionFailure
    end
    if not projection then
        ClientState.lastSemanticCognitionFailure =
            payload.reason or "cognition_projection_unavailable"
        if matchingRequest then
            applyMemoryGossip(id, payload, pending)
            ClientState.pendingSemanticCognition[id] = nil
        end
        return false, ClientState.lastSemanticCognitionFailure
    end
    ClientState.semanticCognition = ClientState.semanticCognition or {}
    merged, changed, reason = Projection.Merge(
        ClientState.semanticCognition[id],
        projection,
        id
    )
    if not merged then
        ClientState.lastSemanticCognitionFailure = reason
        return false, reason
    end
    ClientState.semanticCognition[id] = merged
    ClientState.lastSemanticCognitionReceiveAt = now()
    ClientState.lastSemanticCognitionFailure = nil
    if matchingRequest then
        applyMemoryGossip(id, payload, pending)
        ClientState.pendingSemanticCognition[id] = nil
    end
    return true, changed == true and "updated" or reason
end

return Client
