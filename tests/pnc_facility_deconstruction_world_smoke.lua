local T = require "tests/support/test"
T.addPackagePaths({ { "ProjectHoomans", "server" } })

local removedObject = false
local object = {
    getSpriteName = function() return "workstation_sprite" end,
    getName = function() return "" end,
    getScriptName = function() return "none" end,
}
local objects = {
    size = function() return 1 end,
    get = function(_, index) return index == 0 and object or nil end,
}
local square = {
    getSpecialObjects = function() return objects end,
    transmitRemoveItemFromSquare = function(_, value, safelyRemove)
        removedObject = value == object and safelyRemove == true
        return 0
    end,
}
getCell = function()
    return { getGridSquare = function() return square end }
end

local facility = {
    id = "facility-1", baseId = "base-1", definitionId = "primitive_furnace",
    componentIds = { component = true },
    workstationPlacement = {
        placed = true, x = 10, y = 12, z = 0,
        sprite = "workstation_sprite", entityScript = "primitive_furnace",
    },
}
local base = { id = "base-1", facilityIds = { [facility.id] = true },
    revision = 4 }
PNC = {
    FacilityService = { Internal = {
        emit = function() end,
        isBuilt = function() return true end,
        removeComponent = function() return true end,
    }, RebuildIndexes = function() end },
    SettlementRepository = {
        State = { facilities = { [facility.id] = facility }, components = {
            component = {},
        } },
        GetFacility = function(id)
            return id == facility.id and facility or nil
        end,
        MarkDirty = function() end,
    },
    BaseService = { Get = function(id)
        return id == base.id and base or nil
    end },
    FacilityReservations = { ReleaseComponent = function() end },
    EventTypes = { FACILITY_DESTROYED = "FacilityDestroyed" },
}
PsychopatzCore = { Events = {} }

local Service = T.load("ProjectHoomans", "server",
    "PNC/Settlement/FacilityService/PNC_FacilityService_Removal.lua")
local ok, reason = Service.FinalizeDestroy(facility)
T.equal(ok, true, "facility deconstruction finalizes")
T.equal(reason, "FacilityDestroyed", "facility deconstruction reason")
T.truthy(removedObject,
    "deconstruction removes the placed workstation from the world")
T.falsy(PNC.SettlementRepository.State.facilities[facility.id],
    "deconstruction removes the facility record")
T.falsy(base.facilityIds[facility.id],
    "deconstruction removes the facility from the base index")

T.finish("pnc_facility_deconstruction_world_smoke")
