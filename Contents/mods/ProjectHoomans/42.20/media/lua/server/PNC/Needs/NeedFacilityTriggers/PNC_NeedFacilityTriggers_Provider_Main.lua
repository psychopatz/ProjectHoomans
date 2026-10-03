if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Internal = Triggers.Internal
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute

local recordFor = Internal.RecordFor
local resolveAwayRoute = Internal.ResolveAwayRoute
local hasRoute = Internal.HasRoute
local definitionFor = Internal.DefinitionFor
local manuallyDisabled = Internal.ManuallyDisabled
local campPlacementLocked = Internal.CampPlacementLocked
local TaskEvents = PNC.Tasking and PNC.Tasking.Events

function Triggers.PreferFacility(record, triggerId)
    if campPlacementLocked(record) then return false end
    local definition = Definitions.Get(triggerId)
    local actionable = definition and Definitions.Evaluate(
        definition, record, false)
    if manuallyDisabled(record, definition)
        or not actionable or AwayRoutes.IsCombatActive(record)
        or not hasRoute(record, definition)
    then
        return false
    end
    if TaskEvents and TaskEvents.Emit then
        TaskEvents.Emit("NEED_FACILITY_CHANGED", {
            npcId = record.id, source = "NeedFacilityTriggers",
            entityId = definition.id,
            cause = "NEED_FACILITY_" .. string.upper(definition.id),
        })
    end
    return true
end

-- The passive needs scheduler is also the periodic safety net for needs whose
-- severity did not change while the NPC was travelling. Check every
-- definition once and emit one coalesced wake-up for the NPC; the task inbox
-- deduplicates repeated scheduler ticks while preserving the best cause.
function Triggers.WakeActionable(record)
    if not record then return false end
    if campPlacementLocked(record) then return false end
    for _, definition in ipairs(Definitions.List()) do
        local actionable = Definitions.Evaluate(definition, record, false)
        if not manuallyDisabled(record, definition)
            and actionable and hasRoute(record, definition)
        then
            if TaskEvents and TaskEvents.Emit then
                TaskEvents.Emit("NPC_NEEDS_CHANGED", {
                    npcId = record.id, source = "NeedsScheduler",
                    entityId = definition.id,
                    cause = "NEED_FACILITY_REFRESH",
                })
            end
            return true
        end
    end
    return false
end

function Triggers.GetCandidates(npcId)
    local record = recordFor(npcId)
    local candidates = {}
    if not record then return candidates end
    if campPlacementLocked(record) then return candidates end
    for _, definition in ipairs(Definitions.List()) do
        local actionable, metadata = Definitions.Evaluate(
            definition, record, false)
        local available = not manuallyDisabled(record, definition)
            and actionable and hasRoute(record, definition)
        if available then
            local route = resolveAwayRoute(record, definition)
            candidates[#candidates + 1] = route
                and AwayRoutes.BuildCandidate(
                    route, record, definition, metadata)
                or {
                    taskId = "need_facility:" .. definition.id .. ":"
                        .. tostring(record.id),
                    npcId = tostring(record.id), kind = definition.kind,
                    sourceDomain = "NeedFacility", sourceRef = definition.id,
                    precedence = metadata.precedence,
                    urgency = metadata.urgency,
                    capability = definition.capability,
                    interruptPolicy = "NORMAL", revision = 1,
                }
        end
    end
    return candidates
end

function Triggers.Validate(intent)
    local record = recordFor(intent.npcId)
    local route = AwayRoutes.Get(intent.sourceRef)
    local definition = Definitions.Get(route and route.needId or intent.sourceRef)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if campPlacementLocked(record) then
        return false, "CAMP_PLACEMENT_ACTIVE"
    end
    if not definition then return false, "TRIGGER_NOT_FOUND" end
    if manuallyDisabled(record, definition) then
        return false, "MANUAL_ACTIVITY_DISABLED"
    end
    if not PNC.CompanionCommands.IsCompanion(record) then
        return false, "NOT_COMPANION"
    end
    if record.health and record.health.state == "incapacitated"
        or AwayRoutes.IsCombatActive(record)
        or record.runtime and record.runtime.workOrderId
    then return false, "NPC_BUSY" end
    local activity = record.runtime and record.runtime.facilityActivity
    local activityLease = PNC.TaskLeaseService.ForNPC(record.id)
    if activity and not activityLease and activity.automatic ~= true then
        return false, "FACILITY_ACTIVITY_BUSY"
    end
    if route then
        local valid, reason = route.Validate(record, intent)
        if not valid then return false, reason end
        local actionable, metadata = Definitions.Evaluate(
            definition, record, false)
        if not actionable then return false, "NEED_ROUTE_NOT_ACTIONABLE" end
        intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
        return true
    end
    local valid, reason = HomeRoute.Validate(record, definition)
    if not valid then return false, reason end
    local actionable, metadata = Definitions.Evaluate(
        definition, record, false)
    if not actionable then
        return false, "NEED_ROUTE_NOT_ACTIONABLE"
    end
    intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
    return true
end

function Triggers.Assign(intent)
    local record = recordFor(intent.npcId)
    local route = AwayRoutes.Get(intent.sourceRef)
    if route then return route.Assign(record, intent) end
    return HomeRoute.Assign(record, intent)
end

function Triggers.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    local route = AwayRoutes.Get(lease.sourceRef)
    if route then return route.Start(record, lease, assignment) end
    return HomeRoute.Start(record, lease, assignment)
end

function Triggers.CanContinue(lease)
    local record = recordFor(lease.npcId)
    local route = AwayRoutes.Get(lease.sourceRef)
    local definition = definitionFor(lease)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    if not record or record.alive == false or not definition then return false end
    if campPlacementLocked(record) then return false end
    if record.health and record.health.state == "incapacitated"
        or AwayRoutes.IsCombatActive(record)
        or record.runtime and record.runtime.workOrderId
    then return false end
    local activityOwnsLease = activity
        and tostring(activity.taskLeaseId or "")
            == tostring(lease and lease.leaseId or "")
        and tostring(lease and lease.leaseId or "") ~= ""
    if activityOwnsLease
        and (activity.failedReason ~= nil
            or activity.failureRequested == true)
    then
        return false
    end
    if route then
        if not route.CanContinue(record, lease) then return false end
        if activity and activity.completionRequested == true then return true end
        return Definitions.Evaluate(definition, record, true) == true
    end
    if not HomeRoute.CanContinue(record, lease) then return false end
    if activity and activity.completionRequested == true then return true end
    return Definitions.Evaluate(definition, record, true) == true
end

