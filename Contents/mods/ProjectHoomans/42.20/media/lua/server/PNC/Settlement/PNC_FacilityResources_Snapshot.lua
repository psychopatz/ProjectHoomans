-- Facility resource snapshot construction.
--
-- This provider converts live scan descriptors into read-only facility
-- components and capacity profiles without exposing Java world objects.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityResources = PNC.FacilityResources or {}

local Resources = PNC.FacilityResources
local copyDescriptor = Resources.CopyDescriptor

function Resources.BuildSnapshot(facility)
    local scan = Resources.GetScan(facility)
    local resources = {}
    local components = {}
    local counts = {}
    local sleepSurfaceCount = 0
    for index = 1, #(scan.resources or {}) do
        local resource = scan.resources[index]
        local copy = copyDescriptor(resource)
        resources[#resources + 1] = copy
        local role = tostring(copy.role or copy.detectorId or "resource")
        counts[role] = (counts[role] or 0) + 1
        copy.kind = "discovered"
        copy.readOnly = true
        components[#components + 1] = copy
        if tostring(copy.resourceKind or "") == "sleep_surface" then
            sleepSurfaceCount = sleepSurfaceCount + 1
        end
    end
    local bedCount = tonumber(counts["sleep.bed"]) or 0
    local sofaCount = tonumber(counts["sleep.sofa"]) or 0
    if not Resources.GetBinding(facility, "sleep") then
        return { resources = resources, components = components }
    end
    local capacity, capacityMode = Resources.GetCapacity(
        facility, "sleep", scan)
    local configuredCapacity = Resources.NormalizeCapacity(facility.capacity)
    local profile = {
        scanStatus = scan.status,
        resourceCounts = counts,
        bedCount = bedCount,
        sofaCount = sofaCount,
        sleepSurfaceCount = sleepSurfaceCount,
        capacity = capacity,
        capacityOverride = configuredCapacity,
        capacityMode = configuredCapacity and "configured" or capacityMode,
        classification = (configuredCapacity or sleepSurfaceCount) > 1
            and "barracks" or "bedroom",
        roomLabelKey = (configuredCapacity or sleepSurfaceCount) > 1
            and "UI_PNC_Facility_Barracks"
            or "UI_PNC_Facility_Bedroom",
    }
    if sleepSurfaceCount == 0 then profile.sleepSurface = "floor" end
    return { resources = resources, components = components, profile = profile }
end
return Resources
