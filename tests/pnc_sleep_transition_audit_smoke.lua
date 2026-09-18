local T = require "tests/support/test"

T.addPackagePaths()

local logs = {}
local now = 1000

PNC = {
    Core = {
        Now = function() return now end,
        LogInfo = function(message)
            logs[#logs + 1] = tostring(message)
        end,
    },
    LiveBodyControl = {
        GetActionContextStateName = function()
            return "bumped"
        end,
    },
    FacilityJobsBehaviorInternal = {},
}

local Diagnostics = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Diagnostics/PNC_PerformanceScalingDiagnostics.lua"
)
Diagnostics.SetSleepAuditEnabled(true)
logs = {}

local object = { satChair = false }
function object:setSatChair(value) self.satChair = value == true end
function object:isFurnitureOccupied() return false end

local body = {
    x = 11.5,
    y = 20.5,
    z = 0,
    bed = nil,
    modData = {
        PNC_BumpRequestedType = "PNC_SleepBed",
        PNC_BumpActionLease = true,
    },
    variables = {
        OnBed = false,
        SittingOnFurniture = false,
    },
}
function body:getX() return self.x end
function body:getY() return self.y end
function body:getZ() return self.z end
function body:getModData() return self.modData end
function body:getActionStateName() return "bumped" end
function body:getBumpType() return "PNC_SleepBed" end
function body:getBed() return self.bed end
function body:getVariableBoolean(name) return self.variables[name] == true end
function body:setOnFloor() end
function body:setSitOnGround() end
function body:setSitOnFurnitureObject(value) self.furniture = value end
function body:setSitOnFurnitureDirection(value) self.direction = value end
function body:reportEvent(eventName) self.lastEvent = eventName end
function body:setIsResting(value) self.resting = value == true end
function body:setBed(value) self.bed = value end
function body:clearVariable(name) self.variables[name] = nil end

local record = {
    id = "sleep-audit-npc",
    x = body.x,
    y = body.y,
    z = body.z,
    runtime = {
        capability = "sleep",
        sleepSurface = "bed",
        resourceKey = "bed:11:20:0",
        phase = "STARTING",
        arrivalSettled = true,
        positioned = true,
        sleepSurfaceEntered = false,
        animationScene = {
            id = "facility.sleep.bed",
            bump = "SleepBed",
        },
    },
}

local Internal = PNC.FacilityJobsBehaviorInternal
Internal.LiveSleepObject = function() return object end
IsoDirections = { S = "S" }

local Surfaces = T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Facilities/FacilityJobsBehavior/PNC_FacilityJobsBehavior_Surfaces.lua"
)

local prepared, prepareReason = Surfaces.PrepareSleepSurface(
    record,
    body,
    record.runtime,
    { sleepSurface = "bed", sleepFacing = "S" }
)
T.truthy(prepared and prepareReason == nil,
    "sleep surface preparation failed in the audit seam")
T.truthy(record.runtime.sleepSurfaceEntered,
    "sleep surface entry did not latch")
T.truthy(body.bed == object,
    "sleep surface entry did not assign the bed object")
T.contains(logs[1], "event=sleep_surface_entry_attempt",
    "sleep entry attempt was not logged")
T.contains(logs[2], "event=sleep_surface_entry_complete",
    "sleep entry completion was not logged")
T.contains(logs[2], "surface=bed",
    "sleep audit omitted the selected surface")
T.contains(logs[2], "scene=facility.sleep.bed",
    "sleep audit omitted the active scene")
T.contains(logs[2], "requestedBump=PNC_SleepBed",
    "sleep audit omitted the requested bump")

Surfaces.ClearSleepSurface(record, body, record.runtime)
T.falsy(record.runtime.sleepSurfaceEntered,
    "sleep surface cleanup did not clear the entry latch")
T.truthy(body.bed == nil,
    "sleep surface cleanup did not clear the bed object")
T.contains(logs[3], "event=sleep_surface_clear_begin",
    "sleep cleanup start was not logged")
T.contains(logs[4], "event=sleep_surface_clear_complete",
    "sleep cleanup completion was not logged")

Diagnostics.SetSleepAuditEnabled(false)
T.falsy(Diagnostics.LogSleepState(
    "disabled",
    record,
    body,
    record.runtime.animationScene,
    "disabled"
), "disabled sleep audit still emitted an event")

T.finish("pnc_sleep_transition_audit_smoke")
