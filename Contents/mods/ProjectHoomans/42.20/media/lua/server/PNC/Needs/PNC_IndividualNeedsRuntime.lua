-- Domain registration: Needs. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Needs/PNC_NeedsRepository"
require "PNC/Needs/PNC_NeedsEvaluator"
require "PNC/Needs/PNC_IndividualNeeds"
