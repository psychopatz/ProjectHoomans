if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

Triggers.HasFacility = HomeRoute.HasFacility

local function resolveAwayRoute(record, definition)
    if not AwayRoutes.IsFollowing(record)
        and HomeRoute.IsAvailable(record, definition)
    then return nil end
    return AwayRoutes.Resolve(record, definition)
end

local function hasRoute(record, definition)
    return not AwayRoutes.IsFollowing(record)
        and HomeRoute.IsAvailable(record, definition)
        or resolveAwayRoute(record, definition) ~= nil
end

local function manuallyDisabled(record, definition)
    return record and record.runtime
        and tostring(record.runtime.manualActivityDisabled or "")
            == tostring(definition and definition.capability or "")
end

function Triggers.PreferFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local actionable = definition and Definitions.Evaluate(
        definition, record, false)
    if manuallyDisabled(record, definition)
        or not actionable or AwayRoutes.IsCombatActive(record)
        or not hasRoute(record, definition)
    then
        return false
    end
    if PNC.Tasking and PNC.Tasking.Commands then
        PNC.Tasking.Commands.MarkDirty(record.id,
            "NEED_FACILITY_" .. string.upper(definition.id))
    end
    return true
end

function Triggers.GetCandidates(npcId)
    local record = recordFor(npcId)
    local candidates = {}
    if not record then return candidates end
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
    if not definition then return false, "TRIGGER_NOT_FOUND" end
    if manuallyDisabled(record, definition) then
        return false, "MANUAL_ACTIVITY_DISABLED"
    end
    if not PNC.CompanionCommands.IsCompanion(record) then
        return false, "NOT_COMPANION"
    end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and (record.runtime.workOrderId
            or record.runtime.attackAction or record.runtime.target)
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
    local definition = Definitions.Get(route and route.needId or lease.sourceRef)
    if not record or record.alive == false or not definition then return false end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and (record.runtime.attackAction
            or record.runtime.target)
    then return false end
    if route then
        return route.CanContinue(record, lease)
            and Definitions.Evaluate(definition, record, true) == true
    end
    return HomeRoute.CanContinue(record, lease)
        and Definitions.Evaluate(definition, record, true) == true
end

local function stop(lease, reason)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity then
        record.runtime.facilityActivity.reservationId = ""
        PNC.FacilityJobs.Stop(record, reason)
    end
    return true
end

function Triggers.Cancel(lease, reason)
    return stop(lease, reason or "task_cancelled")
end

function Triggers.Complete(lease)
    return stop(lease, "need_complete")
end

PNC.Tasking.Commands.RegisterProvider("NeedFacility", Triggers)

if PNC.IndividualNeeds and PNC.IndividualNeeds.RegisterListener then
    PNC.IndividualNeeds.RegisterListener("severity_changed",
        function(record, needType)
            for _, definition in ipairs(Definitions.List()) do
                if definition.needType == needType then
                    PNC.Tasking.Commands.MarkDirty(record.id,
                        "NEED_STATE_CHANGED")
                    return
                end
            end
        end)
end

return Triggers
