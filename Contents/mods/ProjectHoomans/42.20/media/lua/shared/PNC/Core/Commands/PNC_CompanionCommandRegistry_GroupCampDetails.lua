-- Bounded group-camp response details.
-- This provider serializes primitive diagnostics without owning camp effects.

PNC = PNC or {}
PNC.CompanionCommands = PNC.CompanionCommands or {}

local Commands = PNC.CompanionCommands
if type(Commands) ~= "table" then return false end

Commands.Internal = Commands.Internal or {}

local function detailText(value, maximum)
    local valueType = type(value)
    local result
    if value == nil then return nil end
    if valueType ~= "string" and valueType ~= "number"
        and valueType ~= "boolean"
    then
        return nil
    end
    result = tostring(value)
    if maximum then result = string.sub(result, 1, maximum) end
    return result ~= "" and result or nil
end

local function detailNumber(value)
    value = tonumber(value)
    if value ~= nil and value == value then return value end
    return nil
end

local function compactCampSite(site)
    local output
    local bounds
    if type(site) ~= "table" then return nil end
    output = {
        kind = detailText(site.kind, 32),
        scope = detailText(site.scope or site.siteScope, 32),
        siteID = detailText(site.siteID, 128),
        roomID = detailText(site.roomID, 128),
        buildingID = detailText(site.buildingID, 128),
        roomType = detailText(site.roomType, 48),
        roomName = detailText(site.roomName, 64),
        campfireID = detailText(site.campfireID, 128),
        label = detailText(site.label, 64),
        risk = detailText(site.risk, 32),
        x = detailNumber(site.x),
        y = detailNumber(site.y),
        z = detailNumber(site.z),
        radius = detailNumber(site.radius),
        resourceRadius = detailNumber(site.resourceRadius),
        stopDistance = detailNumber(site.stopDistance),
    }
    bounds = site.roomBounds
    if type(bounds) == "table" then
        output.roomBounds = {
            minX = detailNumber(bounds.minX or bounds.x),
            minY = detailNumber(bounds.minY or bounds.y),
            maxX = detailNumber(bounds.maxX or bounds.x2),
            maxY = detailNumber(bounds.maxY or bounds.y2),
            z = detailNumber(bounds.z),
        }
    end
    return output
end

local function campLeaseFor(record)
    local leases = PNC.TaskLeaseService
    local ok
    local lease
    if not leases or type(leases.ForNPC) ~= "function" then return nil end
    ok, lease = pcall(leases.ForNPC, record and record.id)
    return ok and type(lease) == "table" and lease or nil
end

local function campCommandDetails(campID, site, records, route,
    acceptedCount)
    local output = {
        version = 1,
        route = detailText(route, 32) or "command",
        campID = detailText(campID, 128),
        placementMode = "root_only",
        site = compactCampSite(site),
        targetCount = 0,
        acceptedCount = tonumber(acceptedCount) or 0,
        targets = {},
    }
    local maximum = math.min(type(records) == "table" and #records or 0, 32)
    for index = 1, maximum do
        local record = records[index]
        if record and record.id ~= nil then
            local runtime = record.runtime or {}
            local placement = runtime.campPlacement or {}
            local order = record.orderSpec or {}
            local lease = campLeaseFor(record)
            local activity = runtime.facilityActivity or {}
            local assignment = runtime.campZoneAssignment or {}
            local state = detailText(placement.state, 24)
                or detailText(order.placementState, 24)
                or "arrived"
            local target = {
                npcID = detailText(record.id, 128),
                state = state,
                reason = detailText(placement.reason, 64)
                    or detailText(order.zoneReason, 64),
                orderKind = detailText(order.kind, 32),
                activeJob = detailText(record.activeJob, 64),
                activeBehavior = detailText(record.activeBehavior, 96),
                taskLeaseID = detailText(lease and lease.leaseId, 128)
                    or detailText(activity.taskLeaseId, 128),
                leaseDomain = detailText(lease and lease.sourceDomain, 48),
                leasePhase = detailText(lease and lease.phase, 32),
                facilityCapability = detailText(activity.capability, 48),
                facilityPhase = detailText(activity.phase, 32),
                sleepWakePending = activity.sleepWakePending == true,
                zoneID = detailText(assignment.zoneID or order.zoneID, 128),
                zoneLabel = detailText(
                    assignment.zoneLabel or order.zoneLabel, 64),
                zoneNeedKind = detailText(
                    assignment.needKind or order.zoneNeedKind, 32),
            }
            output.targets[#output.targets + 1] = target
            output.targetCount = output.targetCount + 1
            if output.placementState == nil then
                output.placementState = state
            end
            if state == "moving" and output.activeNPCID == nil then
                output.activeNPCID = target.npcID
            end
        end
    end
    return output
end

Commands.Internal.CampCommandDetails = campCommandDetails

return true
