local T = require "tests/support/test"
T.addPackagePaths({ { "PsychopatzCore", "shared" } })

local BOOTSTRAP = "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap"
local RUNTIME = "PsychopatzCore/Profiler/PsychopatzProfilerBootstrap"
local TRANSPORT = "PsychopatzCore/Bridge/PsychopatzBridgeFileTransport"
local BRIDGE = "PsychopatzCore/Bridge/PsychopatzBridge"
local PROFILER_BRIDGE = "PsychopatzCore/Profiler/PsychopatzProfilerBridge"
local originalRequire = require

local cases = {
    { name = "singleplayer", client = false, server = false,
        allowed = true, authority = "singleplayer" },
    { name = "pure_client", client = true, server = false,
        allowed = true, authority = "multiplayer_client" },
    { name = "listen_client", client = true, server = true,
        allowed = true, authority = "multiplayer_client" },
    { name = "dedicated_server", client = false, server = true,
        allowed = false, authority = nil },
}

local function installConfigReader()
    getFileReader = function(name)
        if name ~= "PsychopatzCore_Bridge.txt" then return nil end
        local lines = { "config_version=1", "bridge_enabled=true" }
        local index = 0
        return {
            readLine = function()
                index = index + 1
                return lines[index]
            end,
            close = function() end,
        }
    end
end

local function runCase(case)
    local initialized = false
    local options
    local bridge = {
        Initialize = function(value)
            initialized = true
            options = value
            return true
        end,
    }
    local runtime = {
        GetRuntimeMetadata = function() return { id = case.name } end,
    }
    local transport = {}
    local profilerBridge = { Register = function() return true end }

    PsychopatzCore = {}
    isClient = function() return case.client end
    isServer = function() return case.server end
    getTimeInMillis = function() return 1000 end
    installConfigReader()

    local fakeModules = {
        [RUNTIME] = runtime,
        [TRANSPORT] = transport,
        [BRIDGE] = bridge,
        [PROFILER_BRIDGE] = profilerBridge,
    }
    require = function(name)
        return fakeModules[name] or originalRequire(name)
    end

    local Bootstrap = T.load(
        "PsychopatzCore", "shared",
        "PsychopatzCore/Bridge/PsychopatzBridgeBootstrap.lua"
    )
    T.equal(Bootstrap.Initialize(), case.allowed,
        case.name .. " bridge activation policy")
    T.equal(Bootstrap.IsEnabled(), case.allowed,
        case.name .. " bridge enabled state")
    T.equal(initialized, case.allowed,
        case.name .. " bridge backend initialization")
    if case.allowed then
        T.equal(options.authority, case.authority,
            case.name .. " published bridge authority")
    else
        T.equal(initialized, false,
            case.name .. " loaded the bridge backend")
    end
    require = originalRequire
end

for _, case in ipairs(cases) do runCase(case) end

T.finish("pnc_psychopatz_bridge_runtime_policy")
