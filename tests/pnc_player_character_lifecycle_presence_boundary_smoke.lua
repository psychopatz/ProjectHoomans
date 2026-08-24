local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "server", "PNC/")
local entry = T.read(ROOT .. "Player/PNC_PlayerCharacterLifecycle.lua")
local providers = ROOT .. "Player/PlayerCharacterLifecycle/"
local core = T.read(providers .. "PNC_PlayerCharacterLifecycle_Core.lua")
local callbacks = T.read(
    providers .. "PNC_PlayerCharacterLifecycle_Callbacks.lua")
local pump = T.read(providers .. "PNC_PlayerCharacterLifecycle_Pump.lua")
local startup = T.read(
    providers .. "PNC_PlayerCharacterLifecycle_Startup.lua")

T.contains(entry, "PNC.PlayerCharacterLifecycle.Internal",
    "entry owns the internal namespace")
T.contains(core, "function H.EnsureIdentityAndProfile",
    "identity binding stays behind the internal boundary")
T.contains(callbacks, "function Lifecycle.OnPlayerDeath",
    "death callback remains available")
T.contains(pump, "function Lifecycle.Pump",
    "periodic lifecycle validation remains available")
T.contains(startup, "function Lifecycle.OnServerStarted",
    "server startup integration remains available")
T.falsy(string.find(entry, "function Lifecycle.Pump", 1, true),
    "entry contains wiring rather than implementation")
