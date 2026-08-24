local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
    .. "Colony/Storage/ColonyStorageService/"
local entry = T.read(ROOT .. "PNC_ColonyStorageService_Internal.lua")
local providers = ROOT .. "ColonyStorageService_Internal/"
local core = T.read(
    providers .. "PNC_ColonyStorageService_Internal_Core.lua")
local access = T.read(
    providers .. "PNC_ColonyStorageService_Internal_Access.lua")
local transfers = T.read(
    providers .. "PNC_ColonyStorageService_Internal_Transfers.lua")

T.contains(entry, "Internal.Definitions",
    "entry owns shared storage dependencies")
T.contains(core, "function Internal.RecordActivity",
    "storage activity utilities remain available")
T.contains(access, "function Service.ResolveForPlayer",
    "player storage resolution remains available")
T.contains(transfers, "function Internal.TransferIntoStorage",
    "storage transfer mechanics remain available")
T.falsy(string.find(entry, "function Internal.RecordActivity", 1, true),
    "entry contains wiring rather than implementation")
