local ROOT = "Contents/mods/ProjectHoomans/42.20/media/lua/"

local function assertEqual(actual, expected, label)
    if actual ~= expected then
        error((label or "assertEqual") .. ": expected=" .. tostring(expected)
            .. " actual=" .. tostring(actual))
    end
end

local function capture(path, setup)
    local calls = {}
    local originalRequire = require
    require = function(name)
        calls[#calls + 1] = name
        return true
    end
    if setup then setup(calls) end
    dofile(path)
    require = originalRequire
    return calls
end

local anchorCases = {
    {
        path = ROOT .. "shared/PNC/00_PNC_Init.lua",
        composition = "PNC/Composition/PNC_SharedComposition",
    },
    {
        path = ROOT .. "server/PNC/00_PNC_Server_Init.lua",
        composition = "PNC/Composition/PNC_ServerComposition",
    },
    {
        path = ROOT .. "client/PNC/00_PNC_Client_Init.lua",
        composition = "PNC/Composition/PNC_ClientComposition",
    },
}

for _, case in ipairs(anchorCases) do
    local calls = capture(case.path)
    assertEqual(#calls, 1, case.path .. " must remain thin")
    assertEqual(calls[1], case.composition,
        case.path .. " composition delegation")
end

PNC = {}
local sharedCalls = capture(
    ROOT .. "shared/PNC/Composition/PNC_SharedComposition.lua"
)
assertEqual(sharedCalls[1], "PNC/Core/Base/PNC_Core",
    "shared composition first dependency")
assertEqual(sharedCalls[#sharedCalls], "PNC/Integrations/PNC_PsychopatzProfiler",
    "shared composition final dependency")

PNC = {}
local serverCalls = capture(
    ROOT .. "server/PNC/Composition/PNC_ServerComposition.lua",
    function(calls)
        PNC.ProfilerIntegration = {
            InstallServer = function()
                calls[#calls + 1] = "<install-server-profiler>"
            end,
        }
    end
)
assertEqual(serverCalls[1], "PNC/00_PNC_Init",
    "server composition begins with shared anchor")
assertEqual(serverCalls[#serverCalls - 1], "<install-server-profiler>",
    "server profiler installation timing")
assertEqual(serverCalls[#serverCalls], "PNC/PNC_Server",
    "server runtime starts after dependencies")

local eventMarkers = {}
PNC = {}
PsychopatzCore = { EventMarkers = eventMarkers }
local clientCalls = capture(
    ROOT .. "client/PNC/Composition/PNC_ClientComposition.lua"
)
assertEqual(clientCalls[1], "PNC/00_PNC_Init",
    "client composition begins with shared anchor")
assertEqual(clientCalls[#clientCalls], "PNC/Integrations/PNC_PsychopatzCoreDebug",
    "client composition final dependency")
assertEqual(PNC.EventMarkers, eventMarkers,
    "client EventMarkers assignment timing")

print("pnc_composition_bootstrap_smoke: OK")
