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
    ClientState.lastSemanticCognitionRequestAt = {}
    ClientState.lastSemanticCognitionReceiveAt = 0
    ClientState.lastSemanticCognitionFailure = nil
end

function Client.Get(npcID)
    local id = npcKey(npcID)
    return id and ClientState.semanticCognition
        and ClientState.semanticCognition[id] or nil
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
    local id = projection and npcKey(projection.npcID)
        or payload and npcKey(payload.npcID) or nil
    local merged
    local changed
    local reason
    if not id then
        ClientState.lastSemanticCognitionFailure =
            payload and payload.reason or "npc_id_required"
        return false, ClientState.lastSemanticCognitionFailure
    end
    if not projection then
        ClientState.lastSemanticCognitionFailure =
            payload.reason or "cognition_projection_unavailable"
        if payload.requestID and ClientState.pendingSemanticCognition then
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
    if ClientState.pendingSemanticCognition then
        ClientState.pendingSemanticCognition[id] = nil
    end
    return true, changed == true and "updated" or reason
end

return Client
