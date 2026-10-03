if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}
local emit = Internal.emit
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local markAssignmentDirty = Internal.markAssignmentDirty

function Internal.Queue(spec)
    spec = type(spec) == "table" and spec or {}
    local operation = tostring(spec.operation or "")
    if not Definitions.CAPABILITY_BY_OPERATION[operation]
        and not Service.TargetProviders[operation]
    then
        return nil, "UNKNOWN_OPERATION"
    end
    -- Fall back to the operation's default policy when the caller does not
    -- state one. Research-family work defaults to ANYWHERE/REMOTE/STAY so an
    -- away colonist keeps the order instead of the scheduler releasing and
    -- re-claiming it every pass.
    local policySpec = type(spec.locationPolicy) == "table" and spec
        or { locationPolicy = Definitions.LocationPolicy
            and Definitions.LocationPolicy(operation) or nil }
    local locationPolicy = Internal.locationPolicy(policySpec)
    local order = {
        schemaVersion = Repository.SCHEMA_VERSION,
        id = Repository.NextId(), operation = operation,
        colonyId = tostring(spec.colonyId or ""),
        factionId = tostring(spec.factionId or ""),
        baseId = tostring(spec.baseId or ""),
        recipeId = tonumber(spec.recipeId),
        recipeRevision = tonumber(spec.recipeRevision),
        requiredStationId = spec.requiredStationId
            and tostring(spec.requiredStationId) or nil,
        requiredWorkerId = spec.requiredWorkerId
            and tostring(spec.requiredWorkerId) or nil,
        productionSkillId = spec.productionSkillId
            and tostring(spec.productionSkillId) or nil,
        funded = spec.funded == true,
        projectLifecycle = spec.projectLifecycle,
        quantity = math.max(1, math.floor(tonumber(spec.quantity) or 1)),
        requiredWork = math.max(1, tonumber(spec.requiredWork) or 100),
        progress = math.max(0, tonumber(spec.progress) or 0),
        requiredSkills = copy(spec.requiredSkills or {}),
        locationPolicy = locationPolicy,
        manual = spec.manual == true,
        payload = copy(spec.payload or {}),
        phase = spec.phase,
        status = Status.QUEUED, priority = tonumber(spec.priority) or 0,
        revision = 0, createdAt = now(), updatedAt = now(),
        lastProgressAt = now(),
    }
    Repository.Put(order)
    markAssignmentDirty(order, "WORK_REQUEST_QUEUED")
    emit(EventTypes.WORK_ORDER_QUEUED, { workOrderId = order.id,
        colonyId = order.colonyId, operation = order.operation })
    return copy(order)
end

return Service
