-- Authority-side durable medical request lifecycle.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MedicalCareService = PNC.MedicalCareService or {}

local Service = PNC.MedicalCareService
local Repository = PNC.MedicalCareRepository
local Status = Repository.STATUS
local Core = PNC.Core

Service.STATUS = Status
Service.TERMINAL = Repository.TERMINAL

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function now()
    return Core and Core.Now and Core.Now() or 0
end

local function emit(eventType, task, cause)
    local tasking = PNC.Tasking
    if not tasking or not tasking.Events
        or type(tasking.Events.Emit) ~= "function"
    then
        return
    end
    tasking.Events.Emit(eventType, {
        npcId = task.patientKind == "npc" and task.patientId or nil,
        source = "MedicalCareService",
        entityId = task.id,
        payload = {
            taskId = task.id,
            patientKind = task.patientKind,
            patientId = task.patientId,
            factionId = task.factionId,
            cause = cause,
        },
    })
    -- The patient wound event wakes the patient, not a doctor. Wake only
    -- actual medical-capable actors when a request first appears or is
    -- requeued; phase updates remain lease-local and do not fan out.
    if eventType == "MEDICAL_CARE_REQUESTED" or cause == "requeued" then
        local executor = PNC.MedicalCareExecutor
        local registry = PNC.Registry
        local isDoctor = executor and executor.Internal
            and executor.Internal.IsDoctor
        if registry and registry.ForEach and isDoctor then
            registry.ForEach(function(record)
                if record and record.alive ~= false
                    and isDoctor(record)
                    and tostring(record.id) ~= tostring(task.patientId)
                then
                    tasking.Events.Emit(eventType, {
                        npcId = record.id,
                        source = "MedicalCareService",
                        entityId = task.id,
                        payload = {
                            taskId = task.id,
                            patientKind = task.patientKind,
                            patientId = task.patientId,
                            cause = "medical_request_available",
                        },
                    })
                end
            end)
        end
    end
end

local function patientFromSpec(spec)
    if type(spec) ~= "table" then return nil, nil end
    local patient = type(spec.patient) == "table" and spec.patient or spec
    local kind = string.lower(tostring(
        patient.patientKind or patient.kind or ""))
    local id = patient.patientId or patient.id or patient.key
    if kind ~= "npc" and kind ~= "player" then return nil, nil end
    if id == nil or tostring(id) == "" then return nil, nil end
    return kind, tostring(id)
end

local function priorityFor(spec)
    if spec.priority ~= nil then return tonumber(spec.priority) or 0 end
    if spec.incapacitated == true then return 100 end
    return tonumber(spec.severity) or 0
end

local function normalizeParts(spec)
    local output = {}
    local seen = {}
    local source = spec.woundParts or spec.parts
    if type(source) ~= "table" then return output end
    for index = 1, #source do
        local partId = tostring(source[index] or "")
        if partId ~= "" and not seen[partId] then
            seen[partId] = true
            output[#output + 1] = partId
        end
    end
    return output
end

local function activeForKey(requestKey)
    for _, task in pairs(Repository.State.byId or {}) do
        if task.requestKey == requestKey and not Service.TERMINAL[task.status] then
            return task
        end
    end
    return nil
end

local function updateExisting(task, spec, at)
    local parts = normalizeParts(spec)
    local seen = {}
    for index = 1, #(task.woundParts or {}) do
        seen[task.woundParts[index]] = true
    end
    for index = 1, #parts do
        if not seen[parts[index]] then
            task.woundParts[#task.woundParts + 1] = parts[index]
        end
    end
    task.severity = math.max(task.severity or 0,
        tonumber(spec.severity) or 0)
    task.priority = math.max(task.priority or 0, priorityFor(spec))
    task.updatedAt = at
    task.lastProgressAt = at
    task.revision = task.revision + 1
    if task.status == Status.WAITING_FOR_DOCTOR
        and task.retryAt > at
    then
        task.retryAt = at
    end
    return task
end

function Service.CreateRequest(spec)
    local kind
    local patientId
    local at
    local requestKey
    local existing
    local task
    spec = type(spec) == "table" and spec or {}
    kind, patientId = patientFromSpec(spec)
    if not kind then return nil, "PATIENT_REQUIRED" end
    Repository.Load()
    at = now()
    requestKey = tostring(spec.requestKey or (
        "medical:" .. kind .. ":" .. patientId))
    existing = activeForKey(requestKey)
    if existing then
        updateExisting(existing, spec, at)
        Repository.Put(existing)
        emit("MEDICAL_CARE_REQUEST_CHANGED", existing, "coalesced")
        return copy(existing), "coalesced"
    end
    task = {
        id = Repository.NextId(),
        operation = "MEDICAL_CARE",
        requestKey = requestKey,
        patientKind = kind,
        patientId = patientId,
        factionId = spec.factionId and tostring(spec.factionId) or nil,
        communityId = spec.communityId and tostring(spec.communityId) or nil,
        woundParts = normalizeParts(spec),
        currentWoundIndex = 1,
        severity = math.max(0, math.min(100,
            tonumber(spec.severity) or 0)),
        priority = priorityFor(spec),
        source = tostring(spec.source or "health"),
        sourceRef = spec.sourceRef and tostring(spec.sourceRef) or nil,
        status = Status.QUEUED,
        phase = Status.WAITING_FOR_DOCTOR,
        actorId = nil,
        reservationId = nil,
        blockedReason = nil,
        retryAt = at,
        retryCount = 0,
        revision = 0,
        createdAt = at,
        updatedAt = at,
        lastProgressAt = at,
        policy = type(spec.policy) == "table" and copy(spec.policy) or nil,
    }
    task = Repository.Put(task)
    if not task then return nil, "MEDICAL_TASK_PERSIST_FAILED" end
    emit("MEDICAL_CARE_REQUESTED", task, "created")
    return copy(task), "created"
end

function Service.RequestNPC(record, options)
    options = type(options) == "table" and options or {}
    if not record or not record.id then return nil, "NPC_REQUIRED" end
    options.patientKind = "npc"
    options.patientId = record.id
    options.factionId = options.factionId
        or record.affiliation and record.affiliation.factionID
    options.communityId = options.communityId
        or record.affiliation and record.affiliation.communityID
    if not options.woundParts and PNC.NPCWounds
        and PNC.NPCWounds.GetTreatableWounds
    then
        options.woundParts = {}
        for _, entry in ipairs(PNC.NPCWounds.GetTreatableWounds(record)) do
            options.woundParts[#options.woundParts + 1] = entry.partId
        end
    end
    if options.incapacitated == nil then
        options.incapacitated = record.health
            and record.health.state == "incapacitated"
    end
    return Service.CreateRequest(options)
end

function Service.RequestPlayer(playerKey, options)
    options = type(options) == "table" and options or {}
    options.patientKind = "player"
    options.patientId = playerKey
    return Service.CreateRequest(options)
end

function Service.Get(id)
    return copy(Repository.Get(id))
end

function Service.List(includeTerminal)
    Repository.Load()
    local output = {}
    for _, task in pairs(Repository.State.byId or {}) do
        if includeTerminal == true or not Service.TERMINAL[task.status] then
            output[#output + 1] = copy(task)
        end
    end
    table.sort(output, function(left, right)
        if left.priority ~= right.priority then
            return left.priority > right.priority
        end
        return tostring(left.id) < tostring(right.id)
    end)
    return output
end

function Service.FindForPatient(patientKind, patientId)
    patientKind = string.lower(tostring(patientKind or ""))
    patientId = tostring(patientId or "")
    for _, task in pairs(Repository.State.byId or {}) do
        if task.patientKind == patientKind and task.patientId == patientId
            and not Service.TERMINAL[task.status]
        then
            return copy(task)
        end
    end
    return nil
end

function Service.ResolveForPatient(patientKind, patientId, reason)
    local task = Service.FindForPatient(patientKind, patientId)
    if not task then return false, "MEDICAL_TASK_NOT_FOUND" end
    if string.lower(tostring(patientKind or "")) == "npc" then
        local record = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(patientId) or nil
        local wounds = record and PNC.NPCWounds
            and PNC.NPCWounds.GetTreatableWounds
            and PNC.NPCWounds.GetTreatableWounds(record) or nil
        if wounds and #wounds > 0 then
            return false, "PATIENT_STILL_REQUIRES_CARE"
        end
    end
    return Service.Complete(task.id, reason or "patient_resolved")
end

function Service.SetPhase(id, phase, options)
    local task = Repository.Get(id)
    local at = now()
    options = type(options) == "table" and options or {}
    phase = tostring(phase or "")
    if not task then return false, "MEDICAL_TASK_NOT_FOUND" end
    if not Repository.STATUS[phase] then
        return false, "INVALID_MEDICAL_PHASE"
    end
    if Service.TERMINAL[task.status] then
        return false, "MEDICAL_TASK_TERMINAL"
    end
    task.status = phase
    task.phase = phase
    if options.actorId ~= nil then task.actorId = tostring(options.actorId) end
    if options.clearActor == true then task.actorId = nil end
    if options.reservationId ~= nil then
        task.reservationId = tostring(options.reservationId)
    end
    if options.clearReservation == true then task.reservationId = nil end
    if options.clearBlockedReason == true then task.blockedReason = nil end
    task.blockedReason = options.blockedReason
        and tostring(options.blockedReason) or task.blockedReason
    task.updatedAt = at
    task.lastProgressAt = at
    task.revision = task.revision + 1
    Repository.Put(task)
    emit("MEDICAL_CARE_PHASE_CHANGED", task, "phase_changed")
    return true, copy(task)
end

function Service.MarkProgress(id, options)
    local task = Repository.Get(id)
    if not task or Service.TERMINAL[task.status] then
        return false, "MEDICAL_TASK_NOT_ACTIVE"
    end
    options = type(options) == "table" and options or {}
    task.updatedAt = now()
    task.lastProgressAt = task.updatedAt
    task.blockedReason = options.blockedReason
        and tostring(options.blockedReason) or nil
    task.revision = task.revision + 1
    Repository.Put(task)
    return true, copy(task)
end

function Service.Complete(id, reason)
    local task = Repository.Get(id)
    if not task then return false, "MEDICAL_TASK_NOT_FOUND" end
    if Service.TERMINAL[task.status] then return false, "MEDICAL_TASK_TERMINAL" end
    task.status = Status.COMPLETED
    task.phase = Status.COMPLETED
    task.actorId = nil
    task.reservationId = nil
    task.updatedAt = now()
    task.lastProgressAt = task.updatedAt
    task.completionReason = reason and tostring(reason) or nil
    task.revision = task.revision + 1
    Repository.Put(task)
    emit("MEDICAL_CARE_COMPLETED", task, reason or "completed")
    return true, copy(task)
end

function Service.Cancel(id, reason)
    local task = Repository.Get(id)
    if not task then return false, "MEDICAL_TASK_NOT_FOUND" end
    if Service.TERMINAL[task.status] then return false, "MEDICAL_TASK_TERMINAL" end
    task.status = Status.CANCELLED
    task.phase = Status.CANCELLED
    task.actorId = nil
    task.reservationId = nil
    task.cancellationReason = tostring(reason or "cancelled")
    task.updatedAt = now()
    task.lastProgressAt = task.updatedAt
    task.revision = task.revision + 1
    Repository.Put(task)
    emit("MEDICAL_CARE_CANCELLED", task, task.cancellationReason)
    return true, copy(task)
end

function Service.Requeue(id, reason)
    local task = Repository.Get(id)
    if not task or Service.TERMINAL[task.status] then
        return false, "MEDICAL_TASK_NOT_REQUEUEABLE"
    end
    task.status = Status.WAITING_FOR_DOCTOR
    task.phase = Status.WAITING_FOR_DOCTOR
    task.actorId = nil
    task.reservationId = nil
    task.blockedReason = reason and tostring(reason) or nil
    task.retryCount = task.retryCount + 1
    task.retryAt = now()
    task.updatedAt = task.retryAt
    task.lastProgressAt = task.retryAt
    task.revision = task.revision + 1
    Repository.Put(task)
    emit("MEDICAL_CARE_REQUEST_CHANGED", task, "requeued")
    return true, copy(task)
end

return Service
