-- Atomic server-owned JointSceneLease (2-4 participants) integrated with PNC.Tasking.Claims & SecondaryChannel.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.JointSceneLease = PNC.JointSceneLease or {}

local LeaseService = PNC.JointSceneLease

LeaseService.VERSION = 1
LeaseService.MIN_PARTICIPANTS = 2
LeaseService.MAX_PARTICIPANTS = 4
LeaseService.DEFAULT_TTL_MS = 18000
LeaseService.CLAIM_DOMAIN = "joint_scene"

LeaseService.LeasesById = LeaseService.LeasesById or {}
LeaseService.LeaseByNPC = LeaseService.LeaseByNPC or {}
LeaseService.Sequence = LeaseService.Sequence or 0
LeaseService.Stats = LeaseService.Stats or {
    acquired = 0,
    released = 0,
    aborted = 0,
    expired = 0,
    lastAbortReason = nil,
}

local function nowMs(at)
    if at ~= nil then return tonumber(at) or 0 end
    return PNC.Core and type(PNC.Core.Now) == "function" and PNC.Core.Now() or 0
end

local function isCombatLocked(record, current)
    local rt = type(record) == "table" and type(record.runtime) == "table" and record.runtime or nil
    if not rt then return false end
    if rt.combatTarget ~= nil or rt.attackAction ~= nil or rt.medicalCare ~= nil or rt.treatment ~= nil then
        return true
    end
    return current < (tonumber(rt.inCombatUntil) or 0)
end

local function getRecord(participant)
    if type(participant) == "table" and participant.id ~= nil then
        return participant
    end
    if type(participant) == "table" and type(participant.actor) == "table" then
        return participant.actor
    end
    local id = type(participant) == "table" and participant.id or participant
    if id ~= nil and PNC.Registry and type(PNC.Registry.Get) == "function" then
        return PNC.Registry.Get(tostring(id))
    end
    return nil
end

local function participantIdOf(participant)
    if type(participant) == "table" then
        if participant.id ~= nil then return tostring(participant.id) end
        if type(participant.actor) == "table" and participant.actor.id ~= nil then
            return tostring(participant.actor.id)
        end
    elseif participant ~= nil then
        return tostring(participant)
    end
    return ""
end

local function isPlayerParticipant(participant)
    if type(participant) ~= "table" then return false end
    return participant.isPlayer == true or tostring(participant.kind or "") == "player"
end

local function applySecondaryParticipation(record, role, targetRecord, at)
    local sc = PNC.SecondaryChannel
    if not sc or type(record) ~= "table" then return end
    if targetRecord and targetRecord.x ~= nil and targetRecord.y ~= nil
        and type(sc.RequestGaze) == "function"
    then
        sc.RequestGaze(record, targetRecord.x, targetRecord.y, 4000, at)
    end
    if type(sc.SetPosture) == "function" then
        sc.SetPosture(record, "conversing")
    end
    if type(sc.SetSecondaryState) == "function" then
        sc.SetSecondaryState(record, role == "speaker" and "speaking" or "listening", nil, 4000, at)
    end
end

local function clearSecondaryParticipation(record)
    local sc = PNC.SecondaryChannel
    if not sc or type(record) ~= "table" then return end
    if type(sc.SetSecondaryState) == "function" then
        sc.SetSecondaryState(record, "")
    end
    if type(sc.SetPosture) == "function" then
        sc.SetPosture(record, sc.DEFAULT_POSTURE or "relaxed")
    end
end

---Atomically acquires a 2-4 participant JointSceneLease with Claims rollback on failure.
function LeaseService.Acquire(spec, at)
    spec = type(spec) == "table" and spec or {}
    local current = nowMs(at)
    LeaseService.SweepExpired(current)

    local rawParticipants = type(spec.participants) == "table" and spec.participants or {}
    if #rawParticipants < LeaseService.MIN_PARTICIPANTS then
        return false, "JOINT_SCENE_TOO_FEW_PARTICIPANTS"
    end
    if #rawParticipants > LeaseService.MAX_PARTICIPANTS then
        return false, "JOINT_SCENE_TOO_MANY_PARTICIPANTS"
    end

    local seen = {}
    local npcRecords = {}
    local entries = {}
    local speakerId = spec.speakerId and tostring(spec.speakerId) or participantIdOf(rawParticipants[1])
    local responderId = spec.responderId and tostring(spec.responderId) or participantIdOf(rawParticipants[2])

    for i = 1, #rawParticipants do
        local p = rawParticipants[i]
        local pid = participantIdOf(p)
        if pid == "" then
            return false, "JOINT_SCENE_INVALID_PARTICIPANT"
        end
        if seen[pid] then
            return false, "JOINT_SCENE_DUPLICATE_PARTICIPANT"
        end
        seen[pid] = true

        local isPlayer = isPlayerParticipant(p)
        local rec = not isPlayer and getRecord(p) or nil
        if not isPlayer then
            if type(rec) ~= "table" or rec.alive == false then
                return false, "JOINT_SCENE_PARTICIPANT_UNAVAILABLE"
            end
            if isCombatLocked(rec, current) then
                return false, "JOINT_SCENE_PARTICIPANT_IN_COMBAT"
            end
            local existingId = LeaseService.LeaseByNPC[pid]
            if existingId and LeaseService.LeasesById[existingId] then
                return false, "JOINT_SCENE_PARTICIPANT_BUSY"
            end
            npcRecords[pid] = rec
        end

        local role = (pid == speakerId and "speaker")
            or (pid == responderId and "responder")
            or "listener"
        entries[#entries + 1] = {
            id = pid,
            isPlayer = isPlayer,
            role = role,
            record = rec or p,
        }
    end

    LeaseService.Sequence = LeaseService.Sequence + 1
    local leaseId = tostring(spec.leaseId or ("joint_scene:" .. tostring(LeaseService.Sequence)))
    local ttlMs = math.max(1000, tonumber(spec.ttlMs) or LeaseService.DEFAULT_TTL_MS)
    local sceneId = tostring(spec.sceneId or leaseId)
    local claims = PNC.Tasking and PNC.Tasking.Claims or nil

    if claims and type(claims.Acquire) == "function" then
        for i = 1, #entries do
            local entry = entries[i]
            if not entry.isPlayer then
                local claimKey = "joint_scene:npc:" .. entry.id
                local ok, reason = claims.Acquire(claimKey, entry.id, {
                    leaseId = leaseId,
                    domain = LeaseService.CLAIM_DOMAIN,
                    ttlMs = ttlMs,
                    at = current,
                    metadata = { sceneId = sceneId, role = entry.role },
                })
                if not ok then
                    claims.ReleaseByLease(leaseId, "joint_scene_atomic_rollback")
                    return false, reason or "JOINT_SCENE_CLAIM_FAILED"
                end
            end
        end
    end

    local listenerIds = {}
    local participantIds = {}
    for i = 1, #entries do
        local entry = entries[i]
        participantIds[#participantIds + 1] = entry.id
        if not entry.isPlayer then
            LeaseService.LeaseByNPC[entry.id] = leaseId
        end
        if entry.role == "listener" then
            listenerIds[#listenerIds + 1] = entry.id
        end
    end

    local lease = {
        leaseId = leaseId,
        sceneId = sceneId,
        participants = entries,
        participantIds = participantIds,
        speakerId = speakerId,
        responderId = responderId,
        listenerIds = listenerIds,
        createdAt = current,
        expiresAt = current + ttlMs,
        ttlMs = ttlMs,
        active = true,
        onAbort = type(spec.onAbort) == "function" and spec.onAbort or nil,
    }
    LeaseService.LeasesById[leaseId] = lease
    LeaseService.Stats.acquired = LeaseService.Stats.acquired + 1

    local speakerEntry = nil
    for i = 1, #entries do
        if entries[i].id == speakerId then
            speakerEntry = entries[i]
            break
        end
    end
    local responderEntry = nil
    for i = 1, #entries do
        if entries[i].id == responderId then
            responderEntry = entries[i]
            break
        end
    end
    for i = 1, #entries do
        local entry = entries[i]
        if not entry.isPlayer and npcRecords[entry.id] then
            local lookAt = (entry.id == speakerId and responderEntry and responderEntry.record)
                or (speakerEntry and speakerEntry.record)
                or nil
            applySecondaryParticipation(npcRecords[entry.id], entry.role, lookAt, current)
        end
    end

    return true, lease
end

function LeaseService.UpdateSpeaker(leaseId, speakerId, targetId, at)
    local lease = LeaseService.LeasesById[tostring(leaseId or "")]
    if not lease or not lease.active then return false, "JOINT_LEASE_NOT_FOUND" end
    local current = nowMs(at)
    lease.speakerId = tostring(speakerId or lease.speakerId or "")
    if targetId ~= nil then
        lease.responderId = tostring(targetId)
    end

    local byId = {}
    for i = 1, #lease.participants do
        local entry = lease.participants[i]
        byId[entry.id] = entry
    end
    local speakerEntry = byId[lease.speakerId]
    local targetEntry = byId[lease.responderId]

    for i = 1, #lease.participants do
        local entry = lease.participants[i]
        if entry.id == lease.speakerId then
            entry.role = "speaker"
        elseif entry.id == lease.responderId then
            entry.role = "responder"
        else
            entry.role = "listener"
        end
        if not entry.isPlayer and type(entry.record) == "table" then
            local lookAt = (entry.id == lease.speakerId and targetEntry and targetEntry.record)
                or (speakerEntry and speakerEntry.record)
                or nil
            applySecondaryParticipation(entry.record, entry.role, lookAt, current)
        end
    end
    return true, lease
end

local function closeLease(leaseId, reason, aborted, at)
    local id = tostring(leaseId or "")
    local lease = LeaseService.LeasesById[id]
    if not lease then return false, "JOINT_LEASE_NOT_FOUND" end
    lease.active = false
    lease.closedAt = nowMs(at)
    lease.closeReason = tostring(reason or (aborted and "aborted" or "released"))

    local claims = PNC.Tasking and PNC.Tasking.Claims or nil
    if claims and type(claims.ReleaseByLease) == "function" then
        claims.ReleaseByLease(id, lease.closeReason)
    end

    for i = 1, #lease.participants do
        local entry = lease.participants[i]
        if not entry.isPlayer then
            if LeaseService.LeaseByNPC[entry.id] == id then
                LeaseService.LeaseByNPC[entry.id] = nil
            end
            clearSecondaryParticipation(getRecord(entry) or entry.record)
        end
    end
    LeaseService.LeasesById[id] = nil

    if aborted then
        LeaseService.Stats.aborted = LeaseService.Stats.aborted + 1
        LeaseService.Stats.lastAbortReason = lease.closeReason
        if type(lease.onAbort) == "function" then
            lease.onAbort(lease, lease.closeReason)
        end
    else
        LeaseService.Stats.released = LeaseService.Stats.released + 1
    end
    return true, lease
end

function LeaseService.Release(leaseId, reason, at)
    return closeLease(leaseId, reason or "released", false, at)
end

function LeaseService.AbortLease(leaseId, reason, at)
    return closeLease(leaseId, reason or "aborted", true, at)
end

function LeaseService.OnParticipantUnavailable(npcId, reason, at)
    local key = tostring(npcId or "")
    if key == "" then return false end
    local leaseId = LeaseService.LeaseByNPC[key]
    if not leaseId then return false end
    return closeLease(leaseId, reason or ("participant_unavailable:" .. key), true, at)
end

function LeaseService.Get(leaseId)
    return LeaseService.LeasesById[tostring(leaseId or "")]
end

function LeaseService.GetForNPC(npcId)
    local leaseId = LeaseService.LeaseByNPC[tostring(npcId or "")]
    if not leaseId then return nil end
    return LeaseService.LeasesById[leaseId]
end

function LeaseService.SweepExpired(at)
    local hasAny = false
    for _ in pairs(LeaseService.LeasesById) do
        hasAny = true
        break
    end
    if not hasAny then return 0 end
    local current = nowMs(at)
    local expiredIds = {}
    for id, lease in pairs(LeaseService.LeasesById) do
        if lease.expiresAt and lease.expiresAt <= current then
            expiredIds[#expiredIds + 1] = id
        end
    end
    table.sort(expiredIds)
    for i = 1, #expiredIds do
        LeaseService.Stats.expired = LeaseService.Stats.expired + 1
        closeLease(expiredIds[i], "lease_expired", true, current)
    end
    return #expiredIds
end

local function onTaskLeaseCreated(first, second)
    local ev = (type(second) == "table" and second) or (type(first) == "table" and first) or nil
    if type(ev) ~= "table" or ev.npcId == nil then return end
    local npcId = tostring(ev.npcId)
    if not LeaseService.LeaseByNPC[npcId] then return end

    local taskLease = PNC.TaskLeaseService and type(PNC.TaskLeaseService.ForNPC) == "function"
        and PNC.TaskLeaseService.ForNPC(npcId) or nil
    local payload = type(ev.payload) == "table" and ev.payload or {}
    local domain = tostring((taskLease and taskLease.sourceDomain) or payload.sourceDomain or "")
    local prec = tostring((taskLease and taskLease.precedence) or payload.precedence or ev.precedence or "")

    if prec == "HARD_EMERGENCY"
        or prec == "CRITICAL_NEED"
        or domain == "combat"
        or domain == "reaction"
        or domain == "medical"
    then
        LeaseService.OnParticipantUnavailable(npcId, "task_preemption:" .. (prec ~= "" and prec or domain), ev.at)
    end
end

function LeaseService.EnsureSubscribed()
    local events = PNC.Tasking and PNC.Tasking.Events or nil
    if events and type(events.Subscribe) == "function" then
        events.Subscribe("TASK_LEASE_CREATED", onTaskLeaseCreated, "PNC.JointSceneLease")
    end
end

function LeaseService.Reset()
    local ids = {}
    for id in pairs(LeaseService.LeasesById) do
        ids[#ids + 1] = id
    end
    table.sort(ids)
    for i = 1, #ids do
        closeLease(ids[i], "reset", false, 0)
    end
    LeaseService.LeasesById = {}
    LeaseService.LeaseByNPC = {}
    LeaseService.Sequence = 0
    LeaseService.EnsureSubscribed()
end

LeaseService.EnsureSubscribed()

return LeaseService
