-- Project Hoomans owns profiler names and observation points. PsychopatzCore
-- owns the engine, lifecycle, histories, snapshots, and UI.
PNC = PNC or {}
PNC.ProfilerIntegration = PNC.ProfilerIntegration or {}

local Integration = PNC.ProfilerIntegration
local Bootstrap = require "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local BridgeBootstrap = PsychopatzCore and PsychopatzCore.BridgeBootstrap
local liveControlEnabled = BridgeBootstrap and BridgeBootstrap.IsEnabled
    and BridgeBootstrap.IsEnabled() or false

if not Bootstrap.IsEnabled() and not liveControlEnabled then
    return Integration
end

Integration.Internal = Integration.Internal or {}
Integration.Internal.Profiler = PsychopatzCore and PsychopatzCore.Profiler

require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Wrapping"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Shared"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Server"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Config"

return Integration
