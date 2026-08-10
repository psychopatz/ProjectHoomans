-- Central client-side demand set for player-scoped NPC knowledge.
--
-- Presence and UI consumers declare which NPCs they currently need. The
-- networking layer batches the union, while server knowledge remains the
-- authority for which facts have actually been learned.

PNC = PNC or {}
PNC.KnowledgeInterest = PNC.KnowledgeInterest or {}

local Interest = PNC.KnowledgeInterest
local ClientState = PNC.Network.ClientState
local Const = PNC.Const
local Core = PNC.Core

Interest.Pending = Interest.Pending or {}
Interest.FlushQueued = Interest.FlushQueued == true
Interest.FlushDebounceMs = 100

local function isHydrated(npcID)
    return ClientState.npcKnowledge
        and ClientState.npcKnowledge[tostring(npcID)] ~= nil
end

local function addID(ids, seen, npcID, onlyMissing)
    npcID = tostring(npcID or "")
    if npcID == "" or seen[npcID] then return end
    if onlyMissing == true and isHydrated(npcID) then return end
    seen[npcID] = true
    ids[#ids + 1] = npcID
end

function Interest.Require(npcID, source)
    npcID = tostring(npcID or "")
    if npcID == "" then return false, "invalid_npc_id" end
    if isHydrated(npcID) then
        Interest.Pending[npcID] = nil
        return false, "hydrated"
    end
    if Interest.Pending[npcID] ~= nil then
        return false, "pending"
    end
    Interest.Pending[npcID] = tostring(source or "consumer")
    Interest.DirtyAt = Core.Now()
    Interest.FlushQueued = true
    return true, "queued"
end

function Interest.Acknowledge(npcID)
    npcID = tostring(npcID or "")
    if npcID == "" then return false end
    Interest.Pending[npcID] = nil
    return true
end

function Interest.CollectNPCIDs(onlyMissing)
    local ids = {}
    local seen = {}
    local npcID
    local snapshot
    for id, candidate in pairs(ClientState.snapshots or {}) do
        npcID = tostring(id)
        snapshot = candidate
        if snapshot
            and snapshot.alive ~= false
            and snapshot.presenceState == Const.PRESENCE_LIVE
            and snapshot.interestDetailed ~= false
        then
            addID(ids, seen, npcID, onlyMissing)
        end
    end
    for id, _ in pairs(Interest.Pending) do
        npcID = tostring(id)
        if isHydrated(npcID) then
            Interest.Pending[npcID] = nil
        else
            addID(ids, seen, npcID, onlyMissing)
        end
    end
    table.sort(ids)
    return ids
end

function Interest.ConsumeFlush(now)
    if Interest.FlushQueued ~= true then return false end
    now = tonumber(now) or Core.Now()
    if now - (tonumber(Interest.DirtyAt) or now)
        < (tonumber(Interest.FlushDebounceMs) or 100)
    then
        return false
    end
    Interest.FlushQueued = false
    return true
end

function Interest.Reset()
    Interest.Pending = {}
    Interest.DirtyAt = nil
    Interest.FlushQueued = false
end

return Interest
