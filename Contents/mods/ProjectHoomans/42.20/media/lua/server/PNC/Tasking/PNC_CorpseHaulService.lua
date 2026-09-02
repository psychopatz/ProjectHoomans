-- Server-authoritative physical corpse hauling.
--
-- Corpses are deliberately not put into ColonyStorageRepository: a corpse is
-- an engine world object. Discovery is read-only; only a selected corpse gets
-- a short-lived reservation token, so the handoff remains valid in multiplayer.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CorpseHaulService = PNC.CorpseHaulService or {}
PNC.CorpseHaulService.Internal = PNC.CorpseHaulService.Internal or {}

local Service = PNC.CorpseHaulService
local Internal = Service.Internal
local Core = PNC.Core

Service.SCAN_INTERVAL_MS = 2000
Service.INTERACTION_TIMEOUT_MS = 10000
Service.CORPSE_COUNT_CACHE_MS = 2000
Service.MAX_PENDING_CORPSE_ORDERS_PER_BASE = 1
-- Visible carry is simulated with the real IsoDeadBody object. Keep the
-- cadence deliberately coarse: movement remains owned by PathService while
-- this presentation layer only follows the worker's position.
Service.CORPSE_CARRY_ENABLED = Service.CORPSE_CARRY_ENABLED ~= false
Service.CORPSE_CARRY_OFFSET = tonumber(Service.CORPSE_CARRY_OFFSET) or 0.65
Service.CORPSE_CARRY_UPDATE_MS = tonumber(Service.CORPSE_CARRY_UPDATE_MS) or 100
Service.CORPSE_CARRY_PERSIST_MS = tonumber(Service.CORPSE_CARRY_PERSIST_MS) or 500
Service.CORPSE_CARRY_RECOVERY_TIMEOUT_MS = tonumber(
    Service.CORPSE_CARRY_RECOVERY_TIMEOUT_MS) or 15000
Service.Runtime = Service.Runtime or {
    byTask = {}, byToken = {}, byDrop = {}, countsByBase = {}, nextScanAt = 0,
}
Service.Runtime.byTask = Service.Runtime.byTask or {}
Service.Runtime.byToken = Service.Runtime.byToken or {}
Service.Runtime.byDrop = Service.Runtime.byDrop or {}
Service.Runtime.countsByBase = Service.Runtime.countsByBase or {}
Service.MAX_CONFIGURED_REGION_TILES = 100000

require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Configuration"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_World"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Carry"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_WorkAdapter"
require "PNC/Tasking/CorpseHaulService/PNC_CorpseHaulService_Dispatch"

Internal.bindWorkService()

function Service.Pump(now)
    now = tonumber(now) or Core.Now()
    if now < (tonumber(Service.Runtime.nextScanAt) or 0) then return end
    Service.Runtime.nextScanAt = now + Service.SCAN_INTERVAL_MS
    Internal.pruneTerminalCorpseOrders()
    Internal.queuePendingOrders()
end

if Events and Events.OnTick and not Service.TickHookRegistered then
    Events.OnTick.Add(function() Service.Pump() end)
    Service.TickHookRegistered = true
end

return Service
