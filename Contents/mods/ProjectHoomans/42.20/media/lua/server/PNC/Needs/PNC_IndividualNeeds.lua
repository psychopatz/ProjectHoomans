-- Stable individual-needs service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.IndividualNeeds = PNC.IndividualNeeds or {}
PNC.IndividualNeeds.Commands = PNC.IndividualNeeds.Commands or {}
PNC.IndividualNeeds.Queries = PNC.IndividualNeeds.Queries or {}
PNC.IndividualNeeds.Internal = PNC.IndividualNeeds.Internal or {}

require "PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Core"
require "PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Actions"
require "PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Evolution"
require "PNC/Needs/IndividualNeeds/PNC_IndividualNeeds_Lifecycle"

return PNC.IndividualNeeds
