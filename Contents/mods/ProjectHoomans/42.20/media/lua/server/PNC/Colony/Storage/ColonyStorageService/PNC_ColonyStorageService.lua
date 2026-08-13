if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal = PNC.ColonyStorageService.Internal or {}

require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Internal"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_SourceAdapters"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Deposits"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Production"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_DebugApi"

function PNC.ColonyStorageService.RecordActivity(storageOrID, event)
    local storage = type(storageOrID) == "table" and storageOrID
        or PNC.ColonyStorageService.Internal.Repository.Get(storageOrID)
    if not storage then return false, "storage_not_found" end
    local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
    return Journal.Record(storage, event)
end

return PNC.ColonyStorageService
