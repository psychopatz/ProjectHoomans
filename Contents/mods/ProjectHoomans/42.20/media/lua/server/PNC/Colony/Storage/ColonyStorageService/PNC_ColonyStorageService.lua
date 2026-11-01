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

function PNC.ColonyStorageService.GetStorageRevision(...)
    return PNC.ColonyStorageService.Internal.GetStorageRevision(...)
end

function PNC.ColonyStorageService.HasStorageChanged(...)
    return PNC.ColonyStorageService.Internal.HasStorageChanged(...)
end

function PNC.ColonyStorageService.Preflight(...)
    return PNC.ColonyStorageService.Internal.Preflight(...)
end

function PNC.ColonyStorageService.ReserveOutputCapacity(...)
    return PNC.ColonyStorageService.Internal.ReserveOutputCapacity(...)
end

function PNC.ColonyStorageService.ReleaseOutputCapacity(...)
    return PNC.ColonyStorageService.Internal.ReleaseOutputCapacity(...)
end

function PNC.ColonyStorageService.CommitStorage(...)
    return PNC.ColonyStorageService.Internal.CommitStorage(...)
end

function PNC.ColonyStorageService.TransferIntoStorage(...)
    return PNC.ColonyStorageService.Internal.TransferIntoStorage(...)
end

function PNC.ColonyStorageService.LiveNPCSource(...)
    return PNC.ColonyStorageService.Internal.LiveNPCSource(...)
end

return PNC.ColonyStorageService
