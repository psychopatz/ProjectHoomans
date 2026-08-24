-- Stable colony-storage deposits provider entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal = PNC.ColonyStorageService.Internal or {}

require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Deposits/PNC_ColonyStorageService_Deposits_Player"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Deposits/PNC_ColonyStorageService_Deposits_NPC"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Deposits/PNC_ColonyStorageService_Deposits_Courier"

return PNC.ColonyStorageService
