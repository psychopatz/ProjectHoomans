local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Vehicles/PNC_CompanionVehicle.lua"
)
local providers = {
    "PNC_CompanionVehicle_Utilities",
    "PNC_CompanionVehicle_ReservationData",
    "PNC_CompanionVehicle_SeatSelection",
    "PNC_CompanionVehicle_ReservationMarker",
    "PNC_CompanionVehicle_Boarding",
    "PNC_CompanionVehicle_Tick",
    "PNC_CompanionVehicle_Audit",
}
local publicFunctions = {
    "IsReservationItem",
    "GetSeatReservation",
    "IsPassenger",
    "Tick",
    "Release",
    "AuditLoadedReservations",
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle =
        'require "PNC/Core/Vehicles/PNC_CompanionVehicle/'
            .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

PNC = {
    Core = {},
    Const = {},
    Registry = {},
}
T.load(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Vehicles/PNC_CompanionVehicle.lua"
)
for i = 1, #publicFunctions do
    local functionName = publicFunctions[i]
    T.equal(
        type(PNC.CompanionVehicle[functionName]),
        "function",
        "entry point should preserve CompanionVehicle." .. functionName
    )
end

T.finish("pnc_companion_vehicle_presence_boundary_smoke")
