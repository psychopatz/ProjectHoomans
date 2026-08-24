-- Stable NPC supply service entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}

require "PNC/Supply/NPCSupplyService/PNC_NPCSupplyService_Context"
require "PNC/Supply/NPCSupplyService/PNC_NPCSupplyService_Acquisition"
require "PNC/Supply/NPCSupplyService/PNC_NPCSupplyService_Personal"
require "PNC/Supply/NPCSupplyService/PNC_NPCSupplyService_Process"
require "PNC/Supply/NPCSupplyService/PNC_NPCSupplyService_Queries"

return PNC.NPCSupplyService
