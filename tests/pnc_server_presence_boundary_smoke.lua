local T = require "tests/support/test"

local SERVER = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(SERVER .. "Server/PNC_Server.lua")
local records = T.read(
    SERVER .. "Server/Server/PNC_Server_RecordProcessing.lua"
)
local pumps = T.read(
    SERVER .. "Server/Server/PNC_Server_SubsystemPumps.lua"
)
local tick = T.read(SERVER .. "Server/Server/PNC_Server_Tick.lua")
local lifecycle = T.read(
    SERVER .. "Server/Server/PNC_Server_Lifecycle.lua"
)

T.contains(entry, "PNC.Server.Internal",
    "entry owns the internal namespace")
T.contains(entry, "PNC_Server_RecordProcessing",
    "entry loads record processing")
T.contains(entry, "PNC_Server_SubsystemPumps",
    "entry loads subsystem pumps")
T.contains(entry, "PNC_Server_Tick",
    "entry loads tick orchestration")
T.contains(entry, "PNC_Server_Lifecycle",
    "entry loads lifecycle wiring")
T.contains(records, "function H.ProcessRecord",
    "record processing stays behind the internal boundary")
T.contains(pumps, "function H.PrepareTick",
    "frame preparation stays behind the internal boundary")
T.contains(tick, "function Server.OnTick",
    "public tick API remains available")
T.contains(lifecycle, "Events.OnTick.Add(serverTick)",
    "event registration remains in lifecycle wiring")
T.falsy(string.find(entry, "function Server.OnTick", 1, true),
    "entry contains wiring rather than implementation")
