-- Project Hoomans owns profiler names and observation points. PsychopatzCore
-- owns the engine, lifecycle, histories, snapshots, and UI.
PNC = PNC or {}
PNC.ProfilerIntegration = PNC.ProfilerIntegration or {}

local Integration = PNC.ProfilerIntegration
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local BridgeBootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
local liveControlEnabled = BridgeBootstrap and BridgeBootstrap.IsEnabled
    and BridgeBootstrap.IsEnabled() or false

-- Project Zomboid executes every Lua file below media/lua, including the
-- provider files in the profiler subdirectory.  The providers are also
-- required here, so mark the explicit composition window and keep direct
-- engine loads from running them a second time.
Integration._loadingProviders = nil

if not Bootstrap.IsEnabled() and not liveControlEnabled then
    return Integration
end

if type(Integration.Internal) ~= "table" then
    Integration.Internal = {}
end
Integration.Internal.Profiler = PsychopatzCore and PsychopatzCore.Profiler

Integration._loadingProviders = true
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Wrapping"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Shared"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Server"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Config"
Integration._loadingProviders = nil

return Integration
