-- Domain registration: Quests. Ordered startup only; no gameplay policy.
if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end
require "PNC/Quests/PNC_QuestDefinitions"
require "PNC/Quests/PNC_QuestRepository"
require "PNC/Quests/PNC_QuestService"
