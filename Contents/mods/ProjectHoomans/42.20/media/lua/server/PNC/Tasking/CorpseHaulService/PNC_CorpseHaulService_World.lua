if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CorpseHaulService = PNC.CorpseHaulService or {}
PNC.CorpseHaulService.Internal = PNC.CorpseHaulService.Internal or {}

local Service = PNC.CorpseHaulService
local Internal = Service.Internal

require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World_Helpers"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World_Corpses"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World_Destinations"

return Service
