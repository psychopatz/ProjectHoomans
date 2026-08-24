if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

require "PNC/Production/PNC_KnowledgeRepository"
require "PNC/Production/PNC_ResearchRepository"
require "PNC/Production/PNC_WorkRepository"
require "PNC/Production/PNC_ProductionContext"
require "PNC/Production/PNC_WorkInputService"
require "PNC/Production/PNC_HomeDutyService"
require "PNC/Production/PNC_WorkService"
require "PNC/Production/PNC_ResearchService"
require "PNC/Production/PNC_CraftingService"
require "PNC/Production/PNC_RecipeBookService"
require "PNC/Production/ConstructionService/PNC_ConstructionService"
require "PNC/Production/PNC_BuildingService"

return true
