-- Domain registration: Scavenge. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Scavenge/PNC_ScavengePolicy"
require "PNC/Scavenge/PNC_ScavengeService"
require "PNC/Scavenge/PNC_ScavengeExecutor"
