local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Server/PNC_Server.lua")
local pumps = T.read(SERVER .. "Server/Server/PNC_Server_SubsystemPumps.lua")
local tick = T.read(SERVER .. "Server/Server/PNC_Server_Tick.lua")
local safePhase = T.read(
    SERVER .. "Server/Server/PNC_Server_SafePhase.lua"
)

T.contains(entry, "PNC_Server_SafePhase",
    "server entry loads the fault-containment boundary")
T.contains(pumps, "H.SafePhase",
    "subsystem phases use the fault-containment boundary")
T.contains(tick, "server_tick.process_record",
    "record failures are isolated from the tick")
T.contains(safePhase, "function H.SafePhase",
    "safe phase API remains behind the internal boundary")

PNC = {
    Core = {
        Now = function() return 100 end,
        LogWarn = function() end,
    },
    Server = { Internal = {} },
}
local H = T.load(
    "ProjectHoomans",
    "server",
    "PNC/Server/Server/PNC_Server_SafePhase.lua"
)

local failedOK, failedValue, failedReason = H.SafePhase(
    "test.failure",
    function() error("synthetic phase failure") end,
    { npcId = "npc_test" }
)
T.falsy(failedOK, "failed phase was reported")
T.equal(failedValue, nil, "failed phase has no result")
T.contains(failedReason, "synthetic phase failure",
    "failed phase preserves the error reason")
T.equal(H.SafePhaseDiagnostics.totalFailures, 1,
    "failed phase increments diagnostics")

local callbackRan = false
local successOK, result, detail = H.SafePhase(
    "test.success",
    function(value) callbackRan = true; return value, "ok" end,
    nil,
    42
)
T.truthy(successOK, "successful phase was reported")
T.truthy(callbackRan, "successful callback ran")
T.equal(result, 42, "successful phase returns callback result")
T.equal(detail, "ok", "successful phase preserves callback details")

local calls = {}
H.PrepareTick = function()
    calls[#calls + 1] = "prepare"
    return { { id = "npc_bad" }, { id = "npc_good" } }
end
H.ProcessRecord = function(record)
    calls[#calls + 1] = record.id
    if record.id == "npc_bad" then error("synthetic npc failure") end
end
H.FinishTick = function()
    calls[#calls + 1] = "finish"
end
T.load(
    "ProjectHoomans",
    "server",
    "PNC/Server/Server/PNC_Server_Tick.lua"
)
PNC.Server.OnTick()
T.equal(calls[1], "prepare", "tick prepared before records")
T.equal(calls[2], "npc_bad", "first record was attempted")
T.equal(calls[3], "npc_good", "failed record did not abort the queue")
T.equal(calls[4], "finish", "finish phase ran after a record failure")

T.finish("pnc_server_tick_safety_smoke")
