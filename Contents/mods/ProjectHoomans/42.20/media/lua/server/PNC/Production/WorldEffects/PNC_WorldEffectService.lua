-- Durable, server-authoritative world mutations that must wait loaded
-- grid square. Providers own persistence; this service owns indexing,
-- bounded retries, and diagnostics.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode()
then return end

PNC = PNC or {}
PNC.WorldEffectService = PNC.WorldEffectService or {}

local Service = PNC.WorldEffectService
local Core = PNC.Core or {}
local Repository = PNC.WorkRepository

Service.SCHEMA_VERSION = 1
Service.PUMP_INTERVAL_MS = 1000
Service.MAX_APPLIES_PER_PUMP = 8
Service.MAX_APPLIES_PER_LOAD = 8
Service.RETRY_BASE_MS = 2000
Service.RETRY_MAX_MS = 30000
Service.Providers = Service.Providers or {}
Service.Handlers = Service.Handlers or {}
Service.Runtime = Service.Runtime or {}
Service.Runtime.entries = Service.Runtime.entries or {}
Service.Runtime.byPoint = Service.Runtime.byPoint or {}
Service.Runtime.byOwner = Service.Runtime.byOwner or {}
Service.Runtime.indexed = Service.Runtime.indexed == true
Service.Runtime.nextPumpAt = tonumber(Service.Runtime.nextPumpAt) or 0
Service.Internal = Service.Internal or {}

local Internal = Service.Internal
Internal.Core = Core
Internal.Repository = Repository

require "PNC/Production/WorldEffects/PNC_WorldEffectService_Context"
require "PNC/Production/WorldEffects/PNC_WorldEffectService_Registry"
require "PNC/Production/WorldEffects/PNC_WorldEffectService_Reconciliation"
require "PNC/Production/WorldEffects/PNC_WorldEffectService_Snapshot"
require "PNC/Production/WorldEffects/PNC_WorldEffectService_Bootstrap"

return Service
