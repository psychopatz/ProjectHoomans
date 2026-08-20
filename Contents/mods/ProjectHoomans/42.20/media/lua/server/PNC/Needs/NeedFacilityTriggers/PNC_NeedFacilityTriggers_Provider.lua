if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Triggers = PNC.NeedFacilityTriggers
local Definitions = PNC.NeedFacilityTriggerDefinitions

local function recordFor(id)
    return PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(id) or nil
end

local function baseFor(record)
    return PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
end

function Triggers.HasFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local base = record and baseFor(record)
    if not definition or not base or not PNC.FacilityService
        or not PNC.FacilityService.ListByCapability
    then return false end
    local facilities = PNC.FacilityService.ListByCapability(
        base.id, definition.capability)
    for index = 1, #facilities do
        if not PNC.FacilityReservations
            or not PNC.FacilityReservations.HasCapacity
            or PNC.FacilityReservations.HasCapacity(
                facilities[index], definition.capability)
        then return true end
    end
    return false
end

local function hasNearbyWater(record)
    return PNC.NearbyWaterService and PNC.NearbyWaterService.Find
        and PNC.NearbyWaterService.Find(record) ~= nil
end

local function hasRoute(record, definition)
    if Triggers.HasFacility(record, definition.id) then return true end
    return definition.id == "hydration" and hasNearbyWater(record)
end

function Triggers.PreferFacility(record, triggerId)
    local definition = Definitions.Get(triggerId)
    local actionable = definition and Definitions.Evaluate(
        definition, record, false)
    if not actionable or not hasRoute(record, definition) then
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
        local available = actionable and hasRoute(record, definition)
        if available then
            local nearby = definition.id == "hydration"
                and not Triggers.HasFacility(record, definition.id)
            local sourceRef = nearby and "nearby_water" or definition.id
            local capability = nearby and "water.nearby"
                or definition.capability
            local suffix = nearby and PNC.NearbyWaterService.Find(record)
                or nil
            candidates[#candidates + 1] = {
                taskId = nearby and "nearby_water:" .. tostring(suffix
                    and suffix.key or "unknown") .. ":" .. tostring(record.id)
                    or "need_facility:" .. definition.id .. ":"
                        .. tostring(record.id),
                npcId = tostring(record.id), kind = definition.kind,
                sourceDomain = "NeedFacility", sourceRef = sourceRef,
                precedence = metadata.precedence,
                urgency = metadata.urgency,
                capability = capability,
                interruptPolicy = "NORMAL", revision = 1,
            }
        end
    end
    return candidates
end

function Triggers.Validate(intent)
    local record = recordFor(intent.npcId)
    local definition = Definitions.Get(intent.sourceRef == "nearby_water"
        and "hydration" or intent.sourceRef)
    if not record or record.alive == false then return false, "NPC_UNAVAILABLE" end
    if not definition then return false, "TRIGGER_NOT_FOUND" end
    if not PNC.CompanionCommands.IsCompanion(record) then
        return false, "NOT_COMPANION"
    end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and (record.runtime.workOrderId
            or record.runtime.attackAction)
    then return false, "NPC_BUSY" end
    local activity = record.runtime and record.runtime.facilityActivity
    local activityLease = PNC.TaskLeaseService.ForNPC(record.id)
    if activity and not activityLease and activity.automatic ~= true then
        return false, "FACILITY_ACTIVITY_BUSY"
    end
    if intent.sourceRef == "nearby_water" then
        if not hasNearbyWater(record) then
            return false, "NEARBY_WATER_NOT_FOUND"
        end
        local actionable, metadata = Definitions.Evaluate(
            definition, record, false)
        if not actionable then return false, "NEED_ROUTE_NOT_ACTIONABLE" end
        intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
        return true
    end
    local base = baseFor(record)
    if not base or not PNC.HomeDutyService.IsAtHome(record, base.id) then
        return false, "NOT_AT_HOME"
    end
    local actionable, metadata = Definitions.Evaluate(
        definition, record, false)
    if not actionable or not Triggers.HasFacility(record, definition.id) then
        return false, "NEED_ROUTE_NOT_ACTIONABLE"
    end
    intent.precedence, intent.urgency = metadata.precedence, metadata.urgency
    return true
end

function Triggers.Assign(intent)
    local record = recordFor(intent.npcId)
    if intent.sourceRef == "nearby_water" then
        local source = PNC.NearbyWaterService
            and PNC.NearbyWaterService.Find(record) or nil
        if not source then return nil, "NEARBY_WATER_NOT_FOUND" end
        local live = PNC.Registry and PNC.Registry.GetLiveZombie
            and PNC.Registry.GetLiveZombie(record.id) or nil
        return {
            ok = true, facilityId = "nearby_water:" .. tostring(source.key),
            componentId = "", reservationId = "",
            target = { x = source.x, y = source.y, z = source.z },
            resource = source, resourceKey = source.key,
            executionMode = live and "LIVE" or "ABSTRACT",
        }
    end
    local base = record and baseFor(record) or nil
    if not base then return nil, "BASE_NOT_FOUND" end
    if record.runtime and record.runtime.facilityActivity
        and record.runtime.facilityActivity.automatic == true
        and PNC.FacilityJobs
    then
        PNC.FacilityJobs.Stop(record,
            "need_trigger_" .. tostring(intent.sourceRef))
    end
    local live = PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    PNC.Tasking.Diagnostics.counters.facilityLookups =
        PNC.Tasking.Diagnostics.counters.facilityLookups + 1
    local acquired = PNC.FacilityService.AcquireActivity(base.id, record.id,
        intent.capability, { ttlMs = 30000, abstract = live == nil })
    if not acquired.ok or not acquired.target then
        return nil, acquired.reason or "NO_ACTIVITY_CAPACITY"
    end
    acquired.executionMode = live and "LIVE" or "ABSTRACT"
    return acquired
end

function Triggers.Start(lease, assignment)
    local record = recordFor(lease.npcId)
    if not record then return false, "NPC_UNAVAILABLE" end
    if lease.sourceRef == "nearby_water" then
        local source = PNC.NearbyWaterService
            and PNC.NearbyWaterService.Resolve(record, assignment.resourceKey)
            or nil
        if not source then return false, "NEARBY_WATER_NOT_FOUND" end
        return PNC.FacilityJobs.Start(record, {
            id = assignment.facilityId, baseId = "", definitionId = "nearby_water",
        }, "water.nearby", {
            automatic = true, acquired = assignment, resource = source,
            resourceKey = source.key, resourceKind = "nearby_water",
            taskLeaseId = lease.leaseId, nearby = true,
            abstract = lease.executionMode == "ABSTRACT",
        })
    end
    local ok, reason = PNC.FacilityJobs.Start(record, assignment.facilityId,
        lease.capability, { automatic = true, acquired = assignment,
            taskLeaseId = lease.leaseId,
            abstract = lease.executionMode == "ABSTRACT" })
    if ok then
        PNC.TaskLeaseService.SetPhase(lease.leaseId,
            lease.executionMode == "LIVE" and "TRAVEL" or "WORKING")
    end
    return ok, reason
end

function Triggers.CanContinue(lease)
    local record = recordFor(lease.npcId)
    local definition = Definitions.Get(lease.sourceRef == "nearby_water"
        and "hydration" or lease.sourceRef)
    if not record or record.alive == false or not definition then return false end
    if record.health and record.health.state == "incapacitated"
        or record.runtime and record.runtime.attackAction
    then return false end
    if lease.sourceRef == "nearby_water" then
        return PNC.NearbyWaterService
            and PNC.NearbyWaterService.Resolve
            and PNC.NearbyWaterService.Resolve(record, lease.resourceKey) ~= nil
            and Definitions.Evaluate(definition, record, true) == true
    end
    return PNC.SettlementRepository.GetFacility(lease.facilityId) ~= nil
        and PNC.FacilityReservations.ByID[lease.reservationId] ~= nil
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
