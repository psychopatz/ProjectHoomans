if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Internal = Service.Internal
local Repository = PNC.SettlementRepository
local emit = Internal.emit
local touch = Internal.touch
local updateState = Internal.updateState
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

local function isBuilt(facility)
    return FacilityState.IsBuilt(facility)
end

local function normalizeCapacity(value)
    if PNC.FacilityResources
        and PNC.FacilityResources.NormalizeCapacity
    then
        return PNC.FacilityResources.NormalizeCapacity(value)
    end
    if value == nil or value == "" or value == "auto" then return nil end
    local capacity = tonumber(value)
    if not capacity or capacity ~= math.floor(capacity)
        or capacity < 1 or capacity > 999
    then
        return nil, "INVALID_ROOM_CAPACITY"
    end
    return capacity
end

function Service.SetCapacity(player, args)
    args = type(args) == "table" and args or {}
    local facility = Repository.GetFacility(args.facilityId)
    local base = facility and PNC.BaseService.Get(facility.baseId) or nil
    if not base then
        return { ok = false,
            reason = facility and "BASE_NOT_FOUND" or "FACILITY_NOT_FOUND" }
    end
    if not PNC.BaseValidationService.CanUse(player, base) then
        return { ok = false, reason = "NO_PERMISSION" }
    end
    if not isBuilt(facility) then
        return { ok = false, reason = "FACILITY_NOT_BUILT" }
    end
    if args.expectedRevision ~= nil
        and tonumber(args.expectedRevision) ~= facility.revision
    then
        return { ok = false, reason = "REVISION_CONFLICT",
            revision = facility.revision }
    end
    local capacity, reason = normalizeCapacity(args.capacity)
    if reason then return { ok = false, reason = reason } end
    if facility.capacity == capacity then
        return { ok = true, facility = facility, capacity = capacity,
            event = "FacilityCapacityUnchanged" }
    end
    facility.capacity = capacity
    touch(base, facility)
    updateState(base, facility)
    Service.RebuildIndexes()
    if PNC.EventTypes and PNC.EventTypes.FACILITY_SETTINGS_CHANGED then
        emit(PNC.EventTypes.FACILITY_SETTINGS_CHANGED, {
            facilityId = facility.id, setting = "capacity",
            capacity = capacity, revision = facility.revision,
        })
    end
    return { ok = true, facility = facility, capacity = capacity,
        event = "FacilityCapacityChanged" }
end

return Service
