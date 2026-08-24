-- Stable colony-storage internal entry point.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Service = PNC.ColonyStorageService
local Internal = Service.Internal

Service.Metrics = Service.Metrics or {
    deposits = 0,
    withdrawals = 0,
    transferFailures = 0,
    capacityRejects = 0,
    compactions = 0,
    validationFailures = 0,
}
Service.ProcessedRequests = Service.ProcessedRequests or {}

Internal.Definitions =
    require "PNC/Core/Colony/Storage/PNC_ColonyStorageDefinitions"
Internal.Repository =
    require "PNC/Colony/Storage/PNC_ColonyStorageRepository"
Internal.CoreInventory =
    require "PsychopatzCore/Inventory/PsychopatzInventory"
Internal.Constants =
    require "PsychopatzCore/Inventory/PsychopatzInventoryConstants"

require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Internal/PNC_ColonyStorageService_Internal_Core"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Internal/PNC_ColonyStorageService_Internal_Access"
require "PNC/Colony/Storage/ColonyStorageService/ColonyStorageService_Internal/PNC_ColonyStorageService_Internal_Transfers"

return Internal
