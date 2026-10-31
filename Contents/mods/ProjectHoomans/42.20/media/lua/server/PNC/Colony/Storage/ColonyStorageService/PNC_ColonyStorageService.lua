if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ColonyStorageService = PNC.ColonyStorageService or {}
PNC.ColonyStorageService.Internal = PNC.ColonyStorageService.Internal or {}

require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Internal"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_SourceAdapters"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Deposits"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_Production"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_DebugApi"
require "PNC/Colony/Storage/ColonyStorageService/PNC_ColonyStorageService_JobRequirements"

function PNC.ColonyStorageService.RecordActivity(storageOrID, event, actor,
    items, reason)
    if actor ~= nil or items ~= nil or reason ~= nil then
        return PNC.ColonyStorageService.Internal.RecordActivity(
            storageOrID, event, actor, items, reason)
    end
    local storage = type(storageOrID) == "table" and storageOrID
        or PNC.ColonyStorageService.Internal.Repository.Get(storageOrID)
    if not storage then return false, "storage_not_found" end
    local Journal = require "PNC/Core/Colony/Storage/PNC_ColonyStorageJournal"
    return Journal.Record(storage, event)
end

PNC.ColonyStorageService.GetStorageRevision =
    PNC.ColonyStorageService.Internal.GetStorageRevision
PNC.ColonyStorageService.HasStorageChanged =
    PNC.ColonyStorageService.Internal.HasStorageChanged
PNC.ColonyStorageService.Preflight =
    PNC.ColonyStorageService.Internal.Preflight
PNC.ColonyStorageService.ReserveOutputCapacity =
    PNC.ColonyStorageService.Internal.ReserveOutputCapacity
PNC.ColonyStorageService.ReleaseOutputCapacity =
    PNC.ColonyStorageService.Internal.ReleaseOutputCapacity
PNC.ColonyStorageService.CommitStorage =
    PNC.ColonyStorageService.Internal.CommitStorage
PNC.ColonyStorageService.TransferIntoStorage =
    PNC.ColonyStorageService.Internal.TransferIntoStorage
PNC.ColonyStorageService.LiveNPCSource =
    PNC.ColonyStorageService.Internal.LiveNPCSource

return PNC.ColonyStorageService
