local T = require "tests/support/test"
T.addPackagePaths()

local facility = {
    id = "bedroom:1", baseId = "base:1", definitionId = "bedroom",
    level = 1, constructionState = "BUILT", revision = 4,
}
local base = { id = "base:1" }
local emitted

PNC = {
    SettlementRepository = {
        GetFacility = function(id)
            return tostring(id) == facility.id and facility or nil
        end,
    },
    BaseService = {
        Get = function(id) return tostring(id) == base.id and base or nil end,
    },
    BaseValidationService = {
        CanUse = function() return true end,
    },
    FacilityResources = {
        NormalizeCapacity = function(value)
            if value == nil or value == "" or value == "auto" then
                return nil
            end
            local capacity = tonumber(value)
            if not capacity or capacity ~= math.floor(capacity)
                or capacity < 1 or capacity > 999
            then
                return nil, "INVALID_ROOM_CAPACITY"
            end
            return capacity
        end,
    },
    EventTypes = { FACILITY_SETTINGS_CHANGED = "settings_changed" },
    FacilityService = {
        Internal = {
            touch = function(_, value)
                value.revision = (tonumber(value.revision) or 0) + 1
            end,
            updateState = function() end,
            emit = function(_, value) emitted = value end,
        },
        RebuildIndexes = function() end,
    },
}

local Service = require
    "PNC/Settlement/FacilityService/PNC_FacilityService_Settings"

local result = Service.SetCapacity({}, {
    facilityId = facility.id, expectedRevision = 4, capacity = 5,
})
T.truthy(result.ok, "room capacity override saves")
T.equal(facility.capacity, 5, "room capacity is stored on the facility")
T.equal(facility.revision, 5, "capacity update advances facility revision")
T.equal(emitted.setting, "capacity", "capacity update emits setting metadata")

local invalid = Service.SetCapacity({}, {
    facilityId = facility.id, expectedRevision = 5, capacity = 0,
})
T.falsy(invalid.ok, "zero room capacity is rejected")
T.equal(invalid.reason, "INVALID_ROOM_CAPACITY",
    "invalid room capacity returns a stable reason")
T.equal(facility.capacity, 5, "invalid capacity does not mutate the room")

local automatic = Service.SetCapacity({}, {
    facilityId = facility.id, expectedRevision = 5, capacity = "auto",
})
T.truthy(automatic.ok, "automatic capacity can be restored")
T.equal(facility.capacity, nil, "automatic capacity clears the override")
T.finish("pnc_facility_capacity_smoke")
