local T = require "tests/support/test"
T.addPackagePaths()

local originalCore = PsychopatzCore
local originalPNC = PNC
local originalReader = getFileReader
local originalClock = getTimeInMillis

local files = {}
PsychopatzCore = {
    Bridge = {
        GetRuntimeInfo = function()
            return { runtime_id = "runtime-current" }
        end,
    },
    BridgeBootstrap = {
        IsEnabled = function() return true end,
    },
}
PNC = { HoomansLLM = {} }
getTimeInMillis = function() return 5000 end
getFileReader = function(path)
    local content = files[path]
    if not content then return nil end
    local lines = {}
    for line in string.gmatch(content, "[^\n]*") do
        lines[#lines + 1] = line
    end
    local index = 0
    return {
        readLine = function(self)
            index = index + 1
            return lines[index]
        end,
        close = function() end,
    }
end

local Runtime = T.load(
    "ProjectHoomans",
    "client",
    "PNC/Integrations/HoomansLLM/PNC_HoomansLLM_Runtime.lua"
)
local statePath = "PsychopatzBridge/state/provider_state.json"
local markerPath = "PsychopatzBridge/state/provider_state.ready.txt"
files[statePath] = "{\"runtime_id\":\"runtime-current\",\"status\":\"ready\",\"ready\":true,\"heartbeat_ms\":4000}"
files[markerPath] = "runtime-current"

local ready = Runtime.GetProviderStatus()
T.equal(ready.ready, true, "fresh matching worker heartbeat is ready")
T.equal(Runtime.IsProviderAvailable(), true,
    "runtime exposes the provider availability gate")

files[statePath] = "{\"runtime_id\":\"runtime-current\",\"status\":\"ready\",\"ready\":true,\"heartbeat_ms\":0}"
local stale = Runtime.GetProviderStatus()
T.equal(stale.ready, false, "stale heartbeat disables the remote route")
T.equal(stale.reason, "heartbeat_stale", "stale heartbeat is diagnosable")

files[statePath] = "{\"runtime_id\":\"runtime-old\",\"status\":\"ready\",\"ready\":true,\"heartbeat_ms\":4000}"
files[markerPath] = "runtime-old"
local oldRuntime = Runtime.GetProviderStatus()
T.equal(oldRuntime.ready, false, "old game runtime cannot enable the provider")
T.equal(oldRuntime.reason, "stale_runtime", "runtime mismatch is diagnosable")

files[statePath] = nil
files[markerPath] = nil
local stopped = Runtime.GetProviderStatus()
T.equal(stopped.ready, false, "missing worker heartbeat disables the provider")

PsychopatzCore = originalCore
PNC = originalPNC
getFileReader = originalReader
getTimeInMillis = originalClock

T.finish("pnc_hoomans_llm_provider_availability_smoke")
