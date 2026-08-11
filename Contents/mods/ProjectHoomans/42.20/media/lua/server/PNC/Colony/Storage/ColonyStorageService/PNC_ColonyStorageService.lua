if isClient and isClient() and (not isServer or not isServer()) then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal = PNC.ColonyStorageService.Internal or {}

require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Internal"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_SourceAdapters"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Deposits"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_DebugApi"

return PNC.ColonyStorageService
