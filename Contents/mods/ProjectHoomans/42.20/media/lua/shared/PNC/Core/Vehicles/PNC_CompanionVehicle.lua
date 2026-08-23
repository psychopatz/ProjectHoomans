--[[
    PNC Companion Vehicle Travel

    Stable entry point. Companions reserve an installed vehicle seat, travel
    abstractly, and rematerialize through the normal presence recovery path.
]]

PNC = PNC or {}
PNC.CompanionVehicle = PNC.CompanionVehicle or {}
PNC.CompanionVehicle.Internal = PNC.CompanionVehicle.Internal or {}

require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_Utilities"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_ReservationData"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_SeatSelection"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_ReservationMarker"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_Boarding"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_Tick"
require "PNC/Core/Vehicles/PNC_CompanionVehicle/PNC_CompanionVehicle_Audit"

return PNC.CompanionVehicle
