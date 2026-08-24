local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(ROOT .. "Needs/PNC_GroupNeeds.lua")
local providers = ROOT .. "Needs/GroupNeeds/"
local listeners = T.read(providers .. "PNC_GroupNeeds_Listeners.lua")
local state = T.read(providers .. "PNC_GroupNeeds_State.lua")
local update = T.read(providers .. "PNC_GroupNeeds_Update.lua")
local debugApi = T.read(providers .. "PNC_GroupNeeds_Debug.lua")

T.contains(entry, "PNC.GroupNeeds.Internal",
    "entry owns the internal namespace")
T.contains(listeners, "function Needs.RegisterListener",
    "local listener API remains available")
T.contains(state, "function Needs.Set",
    "need state mutation remains available")
T.contains(update, "function Needs.Update",
    "rate-based updates remain available")
T.contains(debugApi, "function Needs.DebugAbstractScavenge",
    "debug simulation remains available")
T.falsy(string.find(entry, "function Needs.Update", 1, true),
    "entry contains wiring rather than implementation")
