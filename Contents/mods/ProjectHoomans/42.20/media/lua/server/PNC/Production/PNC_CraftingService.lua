-- Stable crafting service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}

require "PNC/Production/PNC_WorkInputService"
require "PNC/Production/CraftingService/PNC_CraftingService_Core"
require "PNC/Production/CraftingService/PNC_CraftingService_Commands"
require "PNC/Production/CraftingService/PNC_CraftingService_Completions"
require "PNC/Production/CraftingService/PNC_CraftingService_Lifecycle"
require "PNC/Production/CraftingService/PNC_CraftingService_Queries"

return PNC.CraftingService
