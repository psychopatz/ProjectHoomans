if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local WorldLoot = require "PsychopatzCore/WorldLoot/PsychopatzWorldLoot"
local Service = PNC.ScavengeService
local Internal = Service.Internal
local TERMINAL_STATES = Internal.TERMINAL_STATES
local copy = Internal.Copy
local emit = Internal.Emit

local function activity(session, status, entry, reasonOrDetails)
    local details = type(reasonOrDetails) == "table"
        and reasonOrDetails or { reason = reasonOrDetails }
    local npcId = details.npcId and tostring(details.npcId) or nil
    local npc = npcId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    local row = {
        status = tostring(status or ""),
        entryId = entry and entry.entryId or nil,
        fullType = entry and entry.fullType or nil,
        displayName = entry and entry.displayName or nil,
        sourceType = entry and entry.sourceType or nil,
        sourceLabel = details.sourceLabel
            or entry and entry.sourceLabel or nil,
        npcId = npcId,
        npcName = npc and tostring(npc.name or npc.displayName or npc.id)
            or details.npcName and tostring(details.npcName) or npcId,
        quantity = tonumber(details.quantity)
            or entry and tonumber(entry.quantity) or nil,
        itemCount = tonumber(details.itemCount),
        sceneId = details.sceneId and tostring(details.sceneId) or nil,
        reason = details.reason and tostring(details.reason) or nil,
        at = PNC.Core.Now(),
    }
    session.activity[#session.activity + 1] = row
    while #session.activity > 100 do table.remove(session.activity, 1) end
    return row
end

local function touch(session, eventName, details, shouldSend)
    session.revision = (tonumber(session.revision) or 0) + 1
    session.updatedAt = PNC.Core.Now()
    if eventName then emit(eventName, session, details) end
    if shouldSend ~= false then Service.SendSnapshot(session) end
end

local function releaseReservations(session, reason)
    for _, entry in pairs(session.manifestById or {}) do
        if entry.reservationToken then
            WorldLoot.ReleaseReservation(entry.reservationToken, reason)
            entry.reservationToken = nil
        end
    end
end

local function restorePreviousOrder(session, npcId)
    npcId = tostring(npcId or session.npcId or "")
    local record = PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(npcId) or nil
    if not record then return end
    if PNC.PathService and PNC.PathService.Reset then
        local body = PNC.Registry.GetLiveZombie(record.id)
        PNC.PathService.Reset(body, record)
    end
    if PNC.OrderSystem and PNC.OrderSystem.SetOrder then
        local previous = session.previousOrders
            and session.previousOrders[npcId] or session.previousOrder
        PNC.OrderSystem.SetOrder(record, previous)
    end
end


local function forEachWorker(session, callback)
    for _, npcId in ipairs(session.npcIds or { session.npcId }) do
        callback(tostring(npcId))
    end
end

local function removeSession(session, reason)
    if not session then return false end
    releaseReservations(session, reason or "session_released")
    WorldLoot.ReleaseSession(session.worldLootSessionId)
    Service.Sessions[session.id] = nil
    forEachWorker(session, function(npcId)
        if Service.ByNPC[npcId] == session.id then Service.ByNPC[npcId] = nil end
    end)
    return true
end

local function makeSessionRoom()
    local count = 0
    local oldest
    for _, candidate in pairs(Service.Sessions) do
        count = count + 1
        if TERMINAL_STATES[candidate.state]
            and (not oldest or (tonumber(candidate.updatedAt) or 0)
                < (tonumber(oldest.updatedAt) or 0))
        then oldest = candidate end
    end
    while count >= Service.MAX_RUNTIME_SESSIONS and oldest do
        removeSession(oldest, "session_evicted")
        count = count - 1
        oldest = nil
        for _, candidate in pairs(Service.Sessions) do
            if TERMINAL_STATES[candidate.state]
                and (not oldest or (tonumber(candidate.updatedAt) or 0)
                    < (tonumber(oldest.updatedAt) or 0))
            then oldest = candidate end
        end
    end
    return count < Service.MAX_RUNTIME_SESSIONS
end

Internal.Touch = touch
Internal.Activity = activity
Internal.RestorePreviousOrder = restorePreviousOrder
Internal.ReleaseReservations = releaseReservations
Internal.ForEachWorker = forEachWorker
Internal.RemoveSession = removeSession
Internal.MakeSessionRoom = makeSessionRoom

return Service
