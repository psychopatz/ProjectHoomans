-- Domain registration: Tasking. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Tasking/PNC_WorkTaskProvider"
require "PNC/Tasking/PNC_CorpseHaulService"
require "PNC/Tasking/PNC_TaskRequestService"
require "PNC/Tasking/Autonomy/PNC_AutonomyScorer"
require "PNC/Tasking/Autonomy/PNC_CoPresenceService"
require "PNC/Tasking/Autonomy/PNC_AutonomyTaskProvider"
