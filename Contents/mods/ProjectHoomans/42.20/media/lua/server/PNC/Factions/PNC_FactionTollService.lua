-- Stable faction-toll service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FactionTolls = PNC.FactionTolls or {}

require "PNC/Factions/FactionTollService/PNC_FactionTollService_Core"
require "PNC/Factions/FactionTollService/PNC_FactionTollService_Money"
require "PNC/Factions/FactionTollService/PNC_FactionTollService_Relationships"
require "PNC/Factions/FactionTollService/PNC_FactionTollService_Responses"
require "PNC/Factions/FactionTollService/PNC_FactionTollService_Pump"

return PNC.FactionTolls
