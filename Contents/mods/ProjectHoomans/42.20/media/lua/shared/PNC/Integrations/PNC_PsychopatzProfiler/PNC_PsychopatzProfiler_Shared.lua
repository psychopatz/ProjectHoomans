local Integration = PNC and PNC.ProfilerIntegration or nil
if not Integration or Integration._loadingProviders ~= true then
    return Integration
end

local Internal = Integration.Internal
if type(Internal) ~= "table" then return Integration end

require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Shared_Wrappers"
require "PNC/Integrations/PNC_PsychopatzProfiler/PNC_PsychopatzProfiler_Shared_Sampler"

function Internal.InstallSharedPerformance()
    Internal.InstallSharedPerformanceWrappers()
    Internal.InstallSharedPerformanceSampler()
end

return Integration
