-- Authoritative colonist departure composition root.
-- Context and policy helpers load before departure execution and the pump.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.ColonistDeparture = PNC.ColonistDeparture or {}

local Service = PNC.ColonistDeparture
Service.Internal = Service.Internal or {}

require "PNC/Colonists/PNC_ColonistDepartureService_Core"
require "PNC/Colonists/PNC_ColonistDepartureService_Destination"
require "PNC/Colonists/PNC_ColonistDepartureService_Depart"
require "PNC/Colonists/PNC_ColonistDepartureService_Pump"

return Service
