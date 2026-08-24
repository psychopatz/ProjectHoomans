-- Stable colony-storage source-adapter entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal =
    PNC.ColonyStorageService.Internal or {}

require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_Player"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_Storage"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_Physical"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_AbstractNPC"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_LiveNPC"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_SourceAdapters/PNC_ColonyStorageService_SourceAdapters_NPCBulk"

return PNC.ColonyStorageService.Internal
