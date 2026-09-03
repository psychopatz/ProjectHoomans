if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Definitions = PNC.NeedFacilityTriggerDefinitions
local AwayRoutes = PNC.NeedFacilityAwayRoutes
local HomeRoute = PNC.NeedFacilityHomeRoute
local Events = require "PsychopatzCore/Events/PC_EventBus"
local EventTypes = require "PNC/Core/Events/PNC_EventDefinitions"
local TaskEvents = PNC.Tasking and PNC.Tasking.Events
local Recovery = PNC.Tasking and PNC.Tasking.Internal

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

Triggers.HasFacility = HomeRoute.HasFacility

local function resolveAwayRoute(record, definition)
    if not AwayRoutes.IsAwayCompanion(record)
        and HomeRoute.IsAvailable(record, definition)
    then return nil end
    return AwayRoutes.Resolve(record, definition)
end

local function hasRoute(record, definition)
    return not AwayRoutes.IsAwayCompanion(record)
        and HomeRoute.IsAvailable(record, definition)
        or resolveAwayRoute(record, definition) ~= nil
end

local function definitionFor(lease)
    local route = AwayRoutes.Get(lease and lease.sourceRef)
    return Definitions.Get(route and route.needId or lease and lease.sourceRef)
end

local function taskPhaseFor(activity, lease)
    -- Abstract execution does not run the scene state machine, so its lease
    -- phase is the authoritative phase after the provider starts it.
    if lease and tostring(lease.executionMode or "") == "ABSTRACT" then
        return lease.phase == "WORKING" and "WORKING" or "WAITING"
    end
    local phase = tostring(activity and activity.phase or "")
    if phase == "TRAVELLING" then return "TRAVEL" end
    if phase == "QUEUED" or phase == "STARTING"
        or phase == "REPATHING" or phase == "RESEATING"
        or phase == "INTERRUPTED"
    then return "WAITING" end
    return "WORKING"
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
    if not record or record.alive == false or not definition then return false end
    if record.health and record.health.state == "incapacitated"
        or AwayRoutes.IsCombatActive(record)
        or record.runtime and record.runtime.workOrderId
    then return false end
    if route then
        return route.CanContinue(record, lease)
            and Definitions.Evaluate(definition, record, true) == true
    end
    return HomeRoute.CanContinue(record, lease)
        and Definitions.Evaluate(definition, record, true) == true
end

function Triggers.GetRecoveryState(lease)
    local record = recordFor(lease and lease.npcId)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or nil
    local progressAt = activity and activity.lastProgressAt
        or lease and lease.lastProgressAt
    if not record or record.alive == false or not activity
        or tostring(activity.taskLeaseId or "")
            ~= tostring(lease and lease.leaseId or "")
    then
        return {
            invalid = true,
            phase = lease and lease.phase or "WAITING",
            lastProgressAt = progressAt,
        }
    end
    local definition = definitionFor(lease)
    -- Activities without a logical effect (for example a plain living-room
    -- pose) have no truthful progress signal yet. Keep them out of the
    -- effect watchdog until their owner exposes one.
    local activityDefinition = PNC.FacilityJobDefinitions
        and PNC.FacilityJobDefinitions.Get
        and PNC.FacilityJobDefinitions.Get(
            activity.capability or lease and lease.capability)
    if not definition or not activityDefinition
        or not activityDefinition.needEffect
    then
        return { phase = "WAITING", lastProgressAt = progressAt }
    end
    local phase = taskPhaseFor(activity, lease)
    local snapshot = {
        phase = phase,
        lastProgressAt = progressAt,
        watchable = false,
    }
    if phase == "TRAVEL" then
        if Recovery and Recovery.ApplyMovementRecovery then
            snapshot = Recovery.ApplyMovementRecovery(snapshot, lease, record)
        else
            -- Keep isolated provider tests and partial-load diagnostics
            -- compatible with the same PathService observation contract.
            local pathService = PNC.PathService
            local zombie = PNC.Registry and PNC.Registry.GetLiveZombie
                and PNC.Registry.GetLiveZombie(record.id) or nil
            local movement = pathService
                and pathService.GetMovementRecoveryState
                and pathService.GetMovementRecoveryState(record, zombie)
                or nil
            if movement then
                if tonumber(movement.lastProgressAt)
                    and tonumber(movement.lastProgressAt) > 0
                then
                    snapshot.lastProgressAt = movement.lastProgressAt
                end
                snapshot.movement = movement
                if movement.active == true then
                    snapshot.watchable = movement.watchable == true
                    snapshot.forceRecovery = movement.forceRecovery == true
                    snapshot.recoveryReason = movement.forceRecovery == true
                        and "path_traversal_timeout" or nil
                else
                    snapshot.watchable = true
                    snapshot.timeoutMs = 15000
                    snapshot.recoveryReason = "path_lane_inactive"
                end
            else
                snapshot.watchable = true
                snapshot.timeoutMs = 15000
                snapshot.recoveryReason = "path_lane_missing"
            end
        end
    elseif phase == "WORKING" then
        snapshot.watchable = true
    elseif activity.phase == "QUEUED"
        or activity.phase == "STARTING"
        or activity.phase == "INTERRUPTED"
    then
        -- Scene startup and a failed startup retry are preparation, not
        -- effect progress. They still need a short bounded cleanup window so
        -- a stale blocking scene cannot retain the reservation forever.
        snapshot.watchable = true
        snapshot.timeoutMs = 15000
        snapshot.recoveryReason = "facility_scene_start_timeout"
    end
    return snapshot
end

local function stop(lease, reason)
    local record = recordFor(lease.npcId)
    if record and record.runtime and record.runtime.facilityActivity
        and PNC.FacilityJobs and PNC.FacilityJobs.Stop
    then
        local stopped, stopReason = PNC.FacilityJobs.Stop(record, reason)
        return stopped == true, stopReason
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
                    if TaskEvents and TaskEvents.Emit then
                        TaskEvents.Emit("NPC_NEEDS_CHANGED", {
                            npcId = record.id,
                            source = "IndividualNeeds",
                            entityId = needType,
                        })
                    end
                    return
                end
            end
        end)
end

-- Provision pickup changes the personal-supply candidates without changing
-- need severity. Wake tasking on that inventory event so a newly delivered
-- item is consumed immediately instead of waiting for NeedsScheduler.
local function onInventoryChanged(record)
    if record and TaskEvents and TaskEvents.Emit
    then
        TaskEvents.Emit("NPC_INVENTORY_CHANGED", {
            npcId = record.id, source = "InventoryEvent",
            entityId = record.id,
        })
    end
end

Events.subscribe(EventTypes.NPC_INVENTORY_CHANGED, onInventoryChanged, Triggers)

return Triggers
