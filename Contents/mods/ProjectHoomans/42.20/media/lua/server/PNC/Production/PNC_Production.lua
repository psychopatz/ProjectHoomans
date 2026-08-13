if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Production/PNC_KnowledgeRepository"
require "PNC/Production/PNC_ResearchRepository"
require "PNC/Production/PNC_WorkRepository"
require "PNC/Production/PNC_ProductionContext"
require "PNC/Production/PNC_WorkService"
require "PNC/Production/PNC_ResearchService"
require "PNC/Production/PNC_CraftingService"

return true
