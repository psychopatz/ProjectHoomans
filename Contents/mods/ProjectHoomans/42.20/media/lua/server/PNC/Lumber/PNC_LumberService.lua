-- Server-authoritative lumber zones, tree ledger, and shared job state.
--
-- The service deliberately stores coordinates and scalar progress only. PZ
-- IsoTree and HandWeapon objects are runtime values and must never enter
-- ModData or an NPC record.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberService = PNC.LumberService or {}

local Service = PNC.LumberService
local Const = PNC.Const or {}
local Core = PNC.Core or {}
local GridRegion
local Zones
local CoreInventory

do
    local ok, value = pcall(require, "PsychopatzCore/World/PC_GridRegion")
    if ok then GridRegion = value end
    ok, value = pcall(require, "PsychopatzCore/World/PC_ZoneRegistry")
    if ok then Zones = value end
    ok, value = pcall(require, "PsychopatzCore/Inventory/PsychopatzInventory")
    if ok then CoreInventory = value end
end

Service.MODDATA_KEY = "PNC_LumberWorld_V1"
Service.SCHEMA_VERSION = 1
Service.MAX_ZONE_TILES = tonumber(Const.LUMBER_MAX_ZONE_TILES) or 10000
Service.MAX_WORKERS_PER_ZONE = 16
Service.SCAN_TILES_PER_PUMP = 128
Service.SCAN_ZONES_PER_PUMP = 1
Service.SCAN_INTERVAL_MS = 1000
-- Work orders are created immediately when a worker is assigned. This
-- slower cadence is only for repairing links after load or an interrupted
-- server tick, so large worker populations do not repeatedly copy/query
-- every active lumber order once per scan pass.
Service.WORK_RECONCILE_INTERVAL_MS = 5000
Service.CLAIM_TTL_MS = 30000
Service.HIT_INTERVAL_MS = 1500
Service.ABSTRACT_MAX_ELAPSED_MS = 15000
Service.ABSTRACT_TOOL_HITS_PER_CONDITION = 8

Service.Runtime = Service.Runtime or {
    claims = {},
    previousOrders = {},
    zoneCursor = 0,
    nextPumpAt = 0,
    nextWorkReconcileAt = 0,
}
Service.Data = Service.Data or nil
Service.Loaded = Service.Loaded == true
Service.Dirty = Service.Dirty == true
Service.LastSaveAt = tonumber(Service.LastSaveAt) or 0
Service.Internal = Service.Internal or {}
Service.Internal.CoreInventory = CoreInventory
Service.Internal.Core = Core
Service.Internal.GridRegion = GridRegion
Service.Internal.Zones = Zones
Service.Internal.Const = Const
require "PNC/Lumber/LumberService/PNC_LumberService_State"
require "PNC/Lumber/LumberService/PNC_LumberService_Zones"
require "PNC/Lumber/LumberService/PNC_LumberService_Trees"
require "PNC/Lumber/LumberService/PNC_LumberService_Jobs"

-- Tool discovery and diagnostics are loaded before the execution state
-- machine, which consumes this deliberately small internal contract.
require "PNC/Lumber/LumberService/PNC_LumberService_Tools"
require "PNC/Lumber/LumberService/PNC_LumberService_Execution"
require "PNC/Lumber/LumberService/PNC_LumberService_Runtime"

return Service
