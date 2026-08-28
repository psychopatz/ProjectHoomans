PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Core = PNC.Core
local Repairs = Persistence.Repairs or {}

Persistence.Repairs = Repairs
Repairs.Entries = Repairs.Entries or {}
Repairs.ByKey = Repairs.ByKey or {}
Repairs.Diagnostics = Repairs.Diagnostics or {
    runs = 0,
    applied = 0,
    changed = 0,
    failures = 0,
    pending = 0,
    recentApplications = {},
    recentFailures = {},
}
Repairs.Diagnostics.recentApplications =
    Repairs.Diagnostics.recentApplications or {}
Repairs.Diagnostics.recentFailures =
    Repairs.Diagnostics.recentFailures or {}

local function copyVersions(source)
    local output = {}
    local key
    local value
    if type(source) ~= "table" then return output end
    for key, value in pairs(source) do
        value = tonumber(value)
        if type(key) == "string" and value ~= nil then
            output[key] = math.max(0, math.floor(value))
        end
    end
    return output
end

local function entryKey(scope, id, revision)
    return tostring(scope) .. "|" .. tostring(id) .. "|"
        .. tostring(revision)
end

local function recordFailure(entry, context, reason)
    local diagnostics = Repairs.Diagnostics
    local failure = {
        scope = entry.scope,
        id = entry.id,
        revision = entry.revision,
        reason = tostring(reason or "REPAIR_FAILED"),
        objectId = context and context.objectId,
    }
    diagnostics.failures = diagnostics.failures + 1
    diagnostics.lastFailure = failure
    diagnostics.recentFailures[#diagnostics.recentFailures + 1] = failure
    while #diagnostics.recentFailures > 32 do
        table.remove(diagnostics.recentFailures, 1)
    end
    if Core and Core.LogWarn then
        Core.LogWarn("PNC persistence repair failed scope="
            .. tostring(entry.scope) .. " id=" .. tostring(entry.id)
            .. " revision=" .. tostring(entry.revision)
            .. " object=" .. tostring(context and context.objectId)
            .. " reason=" .. tostring(reason or "REPAIR_FAILED"))
    end
end

local function recordApplication(entry, context, didChange, reason)
    local diagnostics = Repairs.Diagnostics
    local application = {
        scope = entry.scope,
        id = entry.id,
        revision = entry.revision,
        changed = didChange == true,
        reason = tostring(reason or "REPAIR_APPLIED"),
        objectId = context and context.objectId,
    }
    diagnostics.lastApplication = application
    diagnostics.recentApplications[#diagnostics.recentApplications + 1] =
        application
    while #diagnostics.recentApplications > 32 do
        table.remove(diagnostics.recentApplications, 1)
    end
end

local function sortEntries()
    table.sort(Repairs.Entries, function(left, right)
        if left.scope ~= right.scope then return left.scope < right.scope end
        if left.id ~= right.id then return left.id < right.id end
        return left.revision < right.revision
    end)
end

function Repairs.Register(scope, id, revision, handler)
    scope = tostring(scope or "")
    id = tostring(id or "")
    revision = tonumber(revision)
    if scope == "" or id == "" or revision == nil
        or revision < 1 or type(handler) ~= "function"
    then
        return false, "INVALID_PERSISTENCE_REPAIR"
    end
    revision = math.floor(revision)
    local key = entryKey(scope, id, revision)
    local existing = Repairs.ByKey[key]
    if existing then
        existing.handler = handler
        return true, existing
    end
    local entry = {
        scope = scope,
        id = id,
        revision = revision,
        handler = handler,
    }
    Repairs.ByKey[key] = entry
    Repairs.Entries[#Repairs.Entries + 1] = entry
    sortEntries()
    return true, entry
end

function Repairs.NormalizeVersions(source)
    return copyVersions(source)
end

function Repairs.CopyVersions(source)
    local output = copyVersions(source)
    for key, value in pairs(output) do
        if value <= 0 then output[key] = nil end
    end
    return output
end

function Repairs.GetDefinitions()
    local output = {}
    for index, entry in ipairs(Repairs.Entries) do
        output[index] = {
            scope = entry.scope,
            id = entry.id,
            revision = entry.revision,
        }
    end
    return output
end

function Repairs.Apply(scope, object, context)
    local applied
    local changed = 0
    local appliedCount = 0
    local failureCount = 0
    local pending = 0
    local entry
    local key
    local version
    local ok
    local didChange
    local reason
    if type(object) ~= "table" then
        return false, 0, 0
    end
    context = type(context) == "table" and context or {}
    context.scope = tostring(scope or "")
    applied = copyVersions(object.persistenceRepairVersions
        or object.repairVersions)
    Repairs.Diagnostics.runs = Repairs.Diagnostics.runs + 1
    for _, candidate in ipairs(Repairs.Entries) do
        if candidate.scope == context.scope then
            key = candidate.id
            version = tonumber(applied[key]) or 0
            if version < candidate.revision then
                pending = pending + 1
                ok, didChange, reason = pcall(candidate.handler,
                    object, context, version)
                if not ok then
                    failureCount = failureCount + 1
                    recordFailure(candidate, context, didChange)
                elseif didChange == nil then
                    failureCount = failureCount + 1
                    recordFailure(candidate, context,
                        "INVALID_REPAIR_RESULT")
                else
                    applied[key] = candidate.revision
                    appliedCount = appliedCount + 1
                    Repairs.Diagnostics.applied =
                        Repairs.Diagnostics.applied + 1
                    recordApplication(candidate, context, didChange, reason)
                    if didChange == true and Core and Core.LogInfo then
                        Core.LogInfo("PNC persistence repair applied scope="
                            .. tostring(candidate.scope) .. " id="
                            .. tostring(candidate.id) .. " revision="
                            .. tostring(candidate.revision) .. " object="
                            .. tostring(context.objectId) .. " reason="
                            .. tostring(reason or "changed"))
                    end
                    if didChange == true then
                        changed = changed + 1
                        Repairs.Diagnostics.changed =
                            Repairs.Diagnostics.changed + 1
                    end
                end
            end
        end
    end
    object.persistenceRepairVersions = applied
    object.persistenceRepairChanged = changed > 0
    object.persistenceRepairApplied = appliedCount > 0
    object.persistenceRepairPending = failureCount > 0
    Repairs.Diagnostics.pending = Repairs.Diagnostics.pending
        + math.max(0, pending - appliedCount)
    return changed > 0, appliedCount, failureCount
end

function Repairs.GetDiagnostics()
    local diagnostics = Repairs.Diagnostics
    return {
        runs = diagnostics.runs,
        applied = diagnostics.applied,
        changed = diagnostics.changed,
        failures = diagnostics.failures,
        pending = diagnostics.pending,
        definitions = Repairs.GetDefinitions(),
        lastApplication = Core and Core.DeepCopy
            and Core.DeepCopy(diagnostics.lastApplication)
            or diagnostics.lastApplication,
        recentApplications = Core and Core.DeepCopy
            and Core.DeepCopy(diagnostics.recentApplications)
            or diagnostics.recentApplications,
        lastFailure = Core and Core.DeepCopy
            and Core.DeepCopy(diagnostics.lastFailure)
            or diagnostics.lastFailure,
        recentFailures = Core and Core.DeepCopy
            and Core.DeepCopy(diagnostics.recentFailures)
            or diagnostics.recentFailures,
    }
end

-- Facility activity is runtime-owned. Its order can be persisted as a
-- breadcrumb, but its reservation, animation, path, and task lease cannot be
-- safely resumed after a process restart. Clear that breadcrumb on load so
-- tasking can choose a fresh intent instead of inheriting a dead lease.
Repairs.Register("npc_record", "facility_activity_runtime", 1,
    function(record)
        local order = record.orderSpec
        if type(order) ~= "table"
            or tostring(order.kind or "") ~= "facility_activity"
        then
            return false, "NO_FACILITY_ACTIVITY"
        end
        record.orderSpec = nil
        record.activeJob = nil
        record.activeBehavior = nil
        if type(record.runtime) == "table" then
            record.runtime.facilityActivity = nil
            record.runtime.facilityDebugWork = nil
        end
        return true, "FACILITY_ACTIVITY_RESET_AFTER_RELOAD"
    end)

return Repairs
