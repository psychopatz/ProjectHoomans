local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Settlement/"
local entry = T.read(ROOT .. "PNC_FacilityReservations.lua")
local providers = ROOT .. "FacilityReservations/"
local core = T.read(providers .. "PNC_FacilityReservations_Core.lua")
local capabilities = T.read(
    providers .. "PNC_FacilityReservations_Capabilities.lua"
)
local acquisition = T.read(
    providers .. "PNC_FacilityReservations_Acquisition.lua"
)

T.contains(entry, "PNC.FacilityReservations.Internal",
    "entry owns the internal namespace")
T.contains(core, "function Reservations.Reserve",
    "reservation lifecycle remains available")
T.contains(capabilities, "function Reservations.HasCapacity",
    "capability capacity remains available")
T.contains(acquisition, "function PNC.FacilityService.AcquireActivity",
    "activity acquisition remains available")
T.falsy(string.find(entry, "function Reservations.Reserve", 1, true),
    "entry contains wiring rather than implementation")
