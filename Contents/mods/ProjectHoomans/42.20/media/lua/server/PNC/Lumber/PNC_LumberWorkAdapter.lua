-- Lumber WorkService adapter composition root.
--
-- The adapter keeps the stable PNC.LumberWorkAdapter namespace while its
-- target/execution lifecycle, order bridge, and world-effect registrations
-- load in the same order as the former monolith.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.LumberWorkAdapter = PNC.LumberWorkAdapter or {}

local Adapter = PNC.LumberWorkAdapter
local Internal = Adapter.Internal or {}
Adapter.Internal = Internal
Internal.Work = PNC.WorkService
Internal.Service = PNC.LumberService
Internal.Status = PNC.WorkDefinitions and PNC.WorkDefinitions.STATUS or {}
Internal.WorldEffects = PNC.WorldEffectService
Internal.Repository = PNC.WorkRepository

require "PNC/Lumber/PNC_LumberWorkAdapter_Lifecycle"
require "PNC/Lumber/PNC_LumberWorkAdapter_OrderBridge"
require "PNC/Lumber/PNC_LumberWorkAdapter_WorldEffects"

return Adapter
