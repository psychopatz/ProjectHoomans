-- Domain registration: Needs. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Needs/PNC_GroupNeeds"
require "PNC/Needs/PNC_NeedHealthConsequences"
require "PNC/Needs/PNC_NeedSupplyBridge"
