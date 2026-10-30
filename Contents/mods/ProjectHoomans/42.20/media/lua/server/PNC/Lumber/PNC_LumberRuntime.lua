-- Domain registration: Activities. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Lumber/PNC_LumberService"
require "PNC/Lumber/PNC_LumberWorkAdapter"
require "PNC/Lumber/PNC_LumberExecutor"
