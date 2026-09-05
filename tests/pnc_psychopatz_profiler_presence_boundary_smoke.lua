local T = require "tests/support/test"

local source = T.read(
    "ProjectHoomans",
    "shared",
    "PNC/Integrations/PNC_PsychopatzProfiler.lua"
)
local prefix = "PNC/Integrations/PNC_PsychopatzProfiler/"
local providers = {
    "PNC_PsychopatzProfiler_Wrapping",
    "PNC_PsychopatzProfiler_Shared",
    "PNC_PsychopatzProfiler_Server",
    "PNC_PsychopatzProfiler_Config",
}
local ownedFunctions = {
    Wrapping = { "Integration.Restore" },
    Shared = { "Internal.InstallSharedPerformance" },
    Server = { "Integration.InstallServer", "Integration.WrapServerTick" },
    Config = { "Integration.ApplyCaptureConfig" },
}

local previous = 0
local i
for i = 1, #providers do
    local provider = providers[i]
    local needle = 'require "' .. prefix .. provider .. '"'
    local position = assert(source:find(needle, 1, true), needle)
    T.truthy(position > previous, provider .. " load order")
    previous = position
end

for role, functions in pairs(ownedFunctions) do
    local providerSource = T.read(
        "ProjectHoomans",
        "shared",
        prefix .. "PNC_PsychopatzProfiler_" .. role .. ".lua"
    )
    for i = 1, #functions do
        T.contains(providerSource, "function " .. functions[i],
            role .. " should own " .. functions[i])
    end
end

-- PZ also auto-executes nested files under media/lua. Providers must be
-- harmless when that loader reaches them outside the aggregator's require
-- window.
for i = 1, #providers do
    local provider = providers[i]
    PNC = { ProfilerIntegration = {} }
    local loaded = T.load(
        "ProjectHoomans",
        "shared",
        prefix .. provider .. ".lua"
    )
    T.equal(loaded, PNC.ProfilerIntegration,
        provider .. " direct auto-load boundary")
end

T.finish("pnc_psychopatz_profiler_presence_boundary_smoke")
