-- Durable medical-care requests. Runtime leases and live movement state are
-- deliberately not stored here; they are rebuilt by the medical provider.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.MedicalCareRepository = PNC.MedicalCareRepository or {}

local Repository = PNC.MedicalCareRepository
local Core = PNC.Core

Repository.SCHEMA_VERSION = 1
Repository.MODDATA_KEY = "PNC_MedicalCare_V1"
Repository.STATUS = {
    QUEUED = "QUEUED",
    WAITING_FOR_DOCTOR = "WAITING_FOR_DOCTOR",
    WAITING_FOR_SUPPLY = "WAITING_FOR_SUPPLY",
    CLAIMED = "CLAIMED",
    TRAVELING = "TRAVELING",
    AT_PATIENT = "AT_PATIENT",
    TREATING = "TREATING",
    COMPLETED = "COMPLETED",
    CANCELLED = "CANCELLED",
    FAILED = "FAILED",
    QUARANTINED = "QUARANTINED",
}
Repository.TERMINAL = {
    COMPLETED = true,
    CANCELLED = true,
    FAILED = true,
    QUARANTINED = true,
}
Repository.State = Repository.State or {
    schemaVersion = Repository.SCHEMA_VERSION,
    nextId = 1,
    byId = {},
}
Repository.Loaded = Repository.Loaded == true
Repository.Dirty = Repository.Dirty == true

local function copy(value)
    return Core and Core.DeepCopy and Core.DeepCopy(value) or value
end

local function stringOrNil(value)
    if value == nil or value == "" then return nil end
    return tostring(value)
end

local function numberOr(value, fallback)
    local numeric = tonumber(value)
    return numeric == nil and fallback or numeric
end

local function normalizeKind(value)
    value = string.lower(tostring(value or ""))
    if value == "npc" or value == "player" then return value end
    return nil
end

local function normalizeWounds(value)
    local output = {}
    local seen = {}
    if type(value) ~= "table" then return output end
    for index = 1, #value do
        local partId = stringOrNil(value[index])
        if partId and not seen[partId] then
            seen[partId] = true
            output[#output + 1] = partId
        end
    end
    return output
end

local function normalizePolicy(value)
    if type(value) ~= "table" then return nil end
    return {
        allowPlayer = value.allowPlayer ~= false,
        allowNPC = value.allowNPC ~= false,
        requireItem = value.requireItem == true,
        factionOnly = value.factionOnly == true,
    }
end

local function normalize(raw, id)
    if type(raw) ~= "table" then return nil end
    local patientKind = normalizeKind(raw.patientKind)
    local patientId = stringOrNil(raw.patientId)
    if not patientKind or not patientId then return nil end
    local status = tostring(raw.status or Repository.STATUS.QUEUED)
    if not Repository.STATUS[status] then
        status = Repository.STATUS.QUEUED
    end
    local task = {
        schemaVersion = Repository.SCHEMA_VERSION,
        id = tostring(id or raw.id or ""),
        operation = "MEDICAL_CARE",
        requestKey = stringOrNil(raw.requestKey)
            or "medical:" .. patientKind .. ":" .. patientId,
        patientKind = patientKind,
        patientId = patientId,
        factionId = stringOrNil(raw.factionId),
        communityId = stringOrNil(raw.communityId),
        woundParts = normalizeWounds(raw.woundParts),
        currentWoundIndex = math.max(1, math.floor(numberOr(
            raw.currentWoundIndex, 1))),
        severity = math.max(0, math.min(100, numberOr(raw.severity, 0))),
        priority = numberOr(raw.priority, 0),
        source = stringOrNil(raw.source) or "health",
        sourceRef = stringOrNil(raw.sourceRef),
        status = status,
        phase = stringOrNil(raw.phase) or status,
        actorId = stringOrNil(raw.actorId),
        reservationId = stringOrNil(raw.reservationId),
        blockedReason = stringOrNil(raw.blockedReason),
        failureReason = stringOrNil(raw.failureReason),
        completionReason = stringOrNil(raw.completionReason),
        cancellationReason = stringOrNil(raw.cancellationReason),
        retryAt = numberOr(raw.retryAt, 0),
        retryCount = math.max(0, math.floor(numberOr(raw.retryCount, 0))),
        revision = math.max(0, math.floor(numberOr(raw.revision, 0))),
        createdAt = numberOr(raw.createdAt, 0),
        updatedAt = numberOr(raw.updatedAt, 0),
        lastProgressAt = numberOr(raw.lastProgressAt, 0),
        policy = normalizePolicy(raw.policy),
    }
    if task.id == "" then return nil end
    if Repository.TERMINAL[task.status] then
        task.actorId = nil
        task.reservationId = nil
    end
    return task
end

local function recover(task)
    local status = task and task.status or Repository.STATUS.QUEUED
    if not task or Repository.TERMINAL[status] then return task end
    -- A TaskLease is intentionally disposable. Any actor claim from before a
    -- save must be reclaimed instead of leaving a request permanently busy.
    if status == Repository.STATUS.CLAIMED
        or status == Repository.STATUS.TRAVELING
        or status == Repository.STATUS.AT_PATIENT
        or status == Repository.STATUS.TREATING
    then
        task.status = Repository.STATUS.WAITING_FOR_DOCTOR
        task.phase = Repository.STATUS.WAITING_FOR_DOCTOR
        task.actorId = nil
        task.reservationId = nil
        task.blockedReason = "RECOVERED_AFTER_LOAD"
        task.revision = task.revision + 1
    end
    task.updatedAt = math.max(task.updatedAt, task.createdAt)
    task.lastProgressAt = math.max(task.lastProgressAt, task.updatedAt)
    return task
end

function Repository.Import(raw)
    local state = {
        schemaVersion = Repository.SCHEMA_VERSION,
        nextId = 1,
        byId = {},
    }
    if type(raw) == "table"
        and tonumber(raw.schemaVersion) == Repository.SCHEMA_VERSION
    then
        state.nextId = math.max(1, math.floor(numberOr(raw.nextId, 1)))
        for id, value in pairs(raw.byId or {}) do
            local task = normalize(value, id)
            if task then
                state.byId[task.id] = recover(task)
            end
        end
    end
    Repository.State = state
    Repository.Loaded = true
    Repository.Dirty = false
    return state
end

function Repository.Load(force)
    if Repository.Loaded and force ~= true then return Repository.State end
    local raw = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    return Repository.Import(raw)
end

function Repository.NextId()
    Repository.Load()
    local id = "medical:" .. tostring(Repository.State.nextId)
    Repository.State.nextId = Repository.State.nextId + 1
    Repository.Dirty = true
    return id
end

function Repository.Get(id)
    Repository.Load()
    return Repository.State.byId[tostring(id or "")]
end

function Repository.Put(task)
    Repository.Load()
    local normalized = normalize(task, task and task.id)
    if not normalized then return false, "INVALID_MEDICAL_TASK" end
    Repository.State.byId[normalized.id] = normalized
    Repository.Dirty = true
    return normalized
end

function Repository.Remove(id)
    Repository.Load()
    id = tostring(id or "")
    if not Repository.State.byId[id] then return false end
    Repository.State.byId[id] = nil
    Repository.Dirty = true
    return true
end

function Repository.MarkDirty()
    Repository.Dirty = true
end

function Repository.Save()
    Repository.Load()
    if not Repository.Dirty then return false, "not_dirty" end
    local target = ModData and ModData.getOrCreate
        and ModData.getOrCreate(Repository.MODDATA_KEY) or nil
    if not target then return false, "moddata_unavailable" end
    local payload = copy(Repository.State)
    for _, task in pairs(payload.byId or {}) do
        -- Do not persist transient ownership or runtime reservation handles.
        if task.status == Repository.STATUS.CLAIMED
            or task.status == Repository.STATUS.TRAVELING
            or task.status == Repository.STATUS.AT_PATIENT
            or task.status == Repository.STATUS.TREATING
        then
            task.status = Repository.STATUS.WAITING_FOR_DOCTOR
            task.phase = Repository.STATUS.WAITING_FOR_DOCTOR
            task.actorId = nil
            task.reservationId = nil
            task.blockedReason = "RECOVERED_AFTER_LOAD"
        end
    end
    for key, _ in pairs(target) do target[key] = nil end
    for key, value in pairs(payload) do target[key] = value end
    Repository.Dirty = false
    return true, "saved"
end

if Events and Events.OnInitGlobalModData and not Repository.LoadHookRegistered then
    Events.OnInitGlobalModData.Add(function() Repository.Load(true) end)
    Repository.LoadHookRegistered = true
end

return Repository
