-- Canonical current-activity pipeline for networking and presentation.
-- Providers are ordered so specific runtime ownership wins over generic jobs.
PNC = PNC or {}
PNC.ActivityStatus = PNC.ActivityStatus or {}

local Status = PNC.ActivityStatus
local Core = PNC.Core

Status.Providers = Status.Providers or {}
Status.Ordered = Status.Ordered or {}

local function rebuildOrder()
    Status.Ordered = {}
    for _, provider in pairs(Status.Providers) do
        Status.Ordered[#Status.Ordered + 1] = provider
    end
    table.sort(Status.Ordered, function(a, b)
        if a.priority ~= b.priority then return a.priority > b.priority end
        return a.id < b.id
    end)
end

function Status.Register(id, priority, resolver)
    id = tostring(id or "")
    if id == "" or type(resolver) ~= "function" then
        return false, "INVALID_ACTIVITY_PROVIDER"
    end
    Status.Providers[id] = {
        id = id,
        priority = tonumber(priority) or 0,
        Resolve = resolver,
    }
    rebuildOrder()
    return true, Status.Providers[id]
end

function Status.Unregister(id)
    id = tostring(id or "")
    if not Status.Providers[id] then return false end
    Status.Providers[id] = nil
    rebuildOrder()
    return true
end

function Status.Build(record)
    if not record then return nil end
    for index = 1, #Status.Ordered do
        local ok, information = pcall(
            Status.Ordered[index].Resolve, record)
        if ok and type(information) == "table" then
            information.providerId = Status.Ordered[index].id
            return information
        end
    end
    return nil
end

local function humanize(value)
    value = tostring(value or "")
    value = string.gsub(value, "([a-z])([A-Z])", "%1 %2")
    value = string.gsub(value, "[_%.:]+", " ")
    return value
end

local function activity(id, labelKey, fallback, extra)
    local output = type(extra) == "table" and extra or {}
    output.kind = "activity"
    output.activityId = tostring(id or "")
    output.labelKey = labelKey
    output.fallback = tostring(fallback or humanize(id))
    return output
end

local function fullTypeFromItem(item)
    if not item or type(item.getFullType) ~= "function" then return nil end
    local ok, fullType = pcall(item.getFullType, item)
    fullType = ok and tostring(fullType or "") or ""
    return fullType ~= "" and fullType or nil
end

local function supplyItemFullType(record, kind)
    local supply = record.runtime and record.runtime.supply or nil
    local state = supply and supply.byKind and supply.byKind[kind] or nil
    local used = state and state.lastUsedItem or nil
    if used and used.fullType then return tostring(used.fullType) end
    local candidate = state and state.personalCandidates
        and state.personalCandidates[1] or nil
    return candidate and candidate.fullType
        and tostring(candidate.fullType) or nil
end

local function facilityItem(record, runtime, capability)
    if capability == "food.dine"
        or capability == "survival.eat.inventory"
        or runtime.resourceKind == "personal_food"
    then
        local selected = tostring(runtime.activityItemFullType
            or record.orderSpec and record.orderSpec.activityItemFullType
            or "")
        if selected ~= "" then
            return selected, "UI_PNC_Action_FoodTarget"
        end
        return supplyItemFullType(record, "FOOD"),
            "UI_PNC_Action_FoodTarget"
    end
    if capability == "water.nearby"
        or runtime.resourceKind == "nearby_water"
    then
        local resource = runtime.resource
        return fullTypeFromItem(resource and resource.item),
            "UI_PNC_Action_WaterTarget"
    end
    if capability == "water.drink" then
        return nil, "UI_PNC_Action_WaterTarget"
    end
end

Status.Register("survival_state", 100, function(record)
    if record.alive == false then
        return activity("dead", "UI_PNC_Activity_Dead", "Dead")
    end
    if record.health and record.health.state == "incapacitated" then
        return activity("incapacitated",
            "UI_PNC_Activity_Incapacitated", "Incapacitated")
    end
end)

Status.Register("combat", 90, function(record)
    local runtime = record.runtime or {}
    local treatment = runtime.selfTreatment
    if treatment and treatment.phase == "bandaging" then
        -- Bandaging is an active tactical owner. The combat lease can be a
        -- stale presentation hold from the attack that preceded treatment.
        return nil
    end
    local attackActive = runtime.attackAction ~= nil
        and Core.Now() < (tonumber(runtime.attackAction.finishAt) or 0)
    local combatActive = runtime.target ~= nil or attackActive
        or Core.Now() < (tonumber(runtime.inCombatUntil) or 0)
    if combatActive then
        return activity("combat", "UI_PNC_Activity_Fighting", "Fighting")
    end
end)

Status.Register("treatment", 85, function(record)
    local treatment = PNC.BehaviorTreatment
        and PNC.BehaviorTreatment.BuildSnapshot
        and PNC.BehaviorTreatment.BuildSnapshot(record) or nil
    local phase = tostring(treatment and treatment.phase or "")
    if phase ~= "" and phase ~= "idle" and phase ~= "complete" then
        return { kind = "treatment", phase = phase }
    end
end)

Status.Register("facility_activity", 80, function(record)
    local runtime = record.runtime and record.runtime.facilityActivity or nil
    if not runtime then return nil end
    local capability = tostring(runtime.capability or "")
    local definition = PNC.FacilityJobDefinitions
        and PNC.FacilityJobDefinitions.Get(capability) or nil
    local facility = runtime.facilityId and PNC.SettlementRepository
        and PNC.SettlementRepository.GetFacility(runtime.facilityId) or nil
    local itemFullType, itemLabelKey = facilityItem(
        record, runtime, capability)
    return activity("facility:" .. capability,
        definition and definition.activityLabelKey,
        definition and definition.activityText
            or capability ~= "" and humanize(capability)
            or humanize(record.activeJob or capability), {
            capability = capability,
            phase = tostring(runtime.phase or ""),
            facilityId = runtime.facilityId,
            facilityDefinitionId = facility and facility.definitionId or nil,
            activityItemFullType = itemFullType,
            activityItemLabelKey = itemLabelKey,
        })
end)

Status.Register("work_and_home", 70, function(record)
    return PNC.WorkService and PNC.WorkService.BuildActionInformation
        and PNC.WorkService.BuildActionInformation(record) or nil
end)

Status.Register("current_job", 10, function(record)
    local runtime = record.runtime or {}
    if runtime.vehiclePassenger and runtime.vehiclePassenger.active == true then
        return activity("vehicle_passenger",
            "UI_PNC_Activity_InVehicle", "In Vehicle")
    end
    local current = tostring(record.activeBehavior
        or record.activeJob or record.orderSpec and record.orderSpec.kind or "")
    if current == "" then return nil end
    if current == "FacilityActivity" then
        local order = record.orderSpec or {}
        local facilityRuntime = runtime.facilityActivity or order
        local capability = tostring(facilityRuntime.capability or "")
        if capability ~= "" then
            local definition = PNC.FacilityJobDefinitions
                and PNC.FacilityJobDefinitions.Get(capability) or nil
            local facilityId = facilityRuntime.facilityId
            local facility = facilityId and PNC.SettlementRepository
                and PNC.SettlementRepository.GetFacility(facilityId) or nil
            local itemFullType, itemLabelKey = facilityItem(
                record, facilityRuntime, capability)
            return activity("facility:" .. capability,
                definition and definition.activityLabelKey,
                definition and definition.activityText
                    or humanize(capability), {
                    capability = capability,
                    phase = tostring(facilityRuntime.phase or ""),
                    facilityId = facilityId,
                    facilityDefinitionId = facility
                        and facility.definitionId or nil,
                    activityItemFullType = itemFullType,
                    activityItemLabelKey = itemLabelKey,
                })
        end
    end
    local information = {
        job = tostring(record.activeJob or ""),
        behavior = tostring(record.activeBehavior or ""),
        orderKind = tostring(record.orderSpec and record.orderSpec.kind or ""),
    }
    local lumber = runtime.lumber
    if tostring(record.activeJob or "") == "Lumber" and lumber then
        information.phase = tostring(lumber.phase or "")
        information.waitingFor = lumber.waitingFor
        information.waitingReason = lumber.waitingReason
        information.toolDiagnostic = Core and Core.DeepCopy
            and Core.DeepCopy(lumber.tool) or nil
    end
    return activity("job:" .. current, nil, humanize(current), information)
end)

return Status
