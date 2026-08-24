-- Stable facility-reservation entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityReservations = PNC.FacilityReservations or {}
PNC.FacilityReservations.Internal =
    PNC.FacilityReservations.Internal or {}

local Reservations = PNC.FacilityReservations
Reservations.ByID = Reservations.ByID or {}
Reservations.ByComponent = Reservations.ByComponent or {}
Reservations.ByNPC = Reservations.ByNPC or {}
Reservations.ByActivity = Reservations.ByActivity or {}
Reservations.DEFAULT_TTL_MS = 30000

require "PNC/Settlement/FacilityReservations/PNC_FacilityReservations_Core"
require "PNC/Settlement/FacilityReservations/PNC_FacilityReservations_Capabilities"
require "PNC/Settlement/FacilityReservations/PNC_FacilityReservations_Acquisition"

return Reservations
