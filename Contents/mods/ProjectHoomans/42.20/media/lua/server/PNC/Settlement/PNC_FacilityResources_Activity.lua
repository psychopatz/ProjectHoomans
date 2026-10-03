-- Facility activity target resolution and live materialization.
--
-- This provider owns the bridge from durable facility activity descriptors
-- to interaction targets and authoritative live-body placement.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources

function Resources.ResolveActivityTarget(record)
    local activity = record and record.runtime
        and record.runtime.facilityActivity or record and record.orderSpec or nil
    local facilityId = activity and activity.facilityId or nil
    local facility = PNC.SettlementRepository and PNC.SettlementRepository
        .GetFacility(facilityId) or nil
    local resourceKey = tostring(activity and activity.resourceKey or "")
    if not facility or resourceKey == "" then return nil end
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local function findResource(resources)
        for index = 1, #resources do
            local resource = resources[index]
            if tostring(resource.resourceKey) == resourceKey then
                local targets = PNC.FacilityInteractionTargets
                    and PNC.FacilityInteractionTargets.ResolveResource
                    and PNC.FacilityInteractionTargets.ResolveResource(resource, {
                        abstract = live == nil, character = live,
                    }) or {}
                if targets[1]
                    and (tostring(activity.capability or "") ~= "sleep"
                        or Resources.IsValidSleepTarget(resource, targets[1]))
                then
                    return targets[1], resource
                end
            end
        end
        return nil
    end
    local resources = Resources.GetResources(facility)
    local target, resource = findResource(resources)
    if target then return target, resource end
    -- A saved resource can outlive the current chunk. Force one refresh only
    -- after the cached descriptor failed, preserving the cached bed for the
    -- normal unloaded-chunk handoff path.
    resources = Resources.GetResources(facility, nil, true)
    target, resource = findResource(resources)
    if target then return target, resource end
    local level = PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level)
    local internal = Resources.Internal or {}
    local makeVirtualResource = internal.VirtualResource
    local makeVirtualTarget = internal.VirtualTarget
    for _, capabilityBinding in pairs(level and level.resourceBindings or {}) do
        if capabilityBinding.virtual
            and tostring(capabilityBinding.virtual.resourceKind or "")
                == tostring(activity.resourceKind or "")
            and type(makeVirtualResource) == "function"
            and type(makeVirtualTarget) == "function"
        then
            local virtual = makeVirtualResource(facility, capabilityBinding,
                record.id)
            if virtual and virtual.resourceKey == resourceKey then
                local target = makeVirtualTarget(virtual, capabilityBinding)[1]
                if tostring(activity.capability or "") ~= "sleep"
                    or Resources.IsValidSleepTarget(virtual, target)
                then
                    return target, virtual
                end
            end
        end
    end
    return nil
end

function Resources.ApplyMaterializationTarget(record, zombie, target)
    if not record or not zombie or type(target) ~= "table" then return false end
    if target.interactionX and target.interactionY
        and PNC.LiveBodyControl
        and PNC.LiveBodyControl.SetAuthoritativePosition
    then
        local z = target.interactionZ or target.z
        PNC.LiveBodyControl.SetAuthoritativePosition(
            zombie, target.interactionX, target.interactionY, z)
        record.x, record.y, record.z = target.interactionX,
            target.interactionY, z
    end
    local directionName = tostring(target.interactionFacing or "")
    if directionName == "" and target.interactionAxis == "x" then
        directionName = "E"
    elseif directionName == "" and target.interactionAxis == "y" then
        directionName = "S"
    end
    if directionName ~= "" and IsoDirections
        and zombie.setForwardIsoDirection
    then
        local direction = IsoDirections[directionName]
        if direction then
            zombie:setForwardIsoDirection(direction)
        end
    end
    return target.interactionX ~= nil and target.interactionY ~= nil
end



return Resources

