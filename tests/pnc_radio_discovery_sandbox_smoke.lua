local T = require "tests/support/test"

local ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/Base/")
PNC = { Core = { Now = function() return 0 end } }
SandboxVars = nil
T.load(ROOT .. "PNC_Sandbox.lua")

T.equal(PNC.Sandbox.RadioDiscoveryEnabled(), true,
    "radio discovery is enabled by default")
T.equal(PNC.Sandbox.RadioDiscoveryCooldownHours(), 0.5,
    "radio discovery defaults to a thirty-minute cooldown")
T.equal(PNC.Sandbox.RadioDiscoverySignalChance(), 100,
    "radio signal detection defaults to guaranteed candidate resolution")
T.equal(PNC.Sandbox.RadioDiscoveryLineSpacingSeconds(), 2,
    "radio lines default to two seconds apart")

SandboxVars = { ProjectHoomans = {
    RadioDiscoveryEnabled = false,
    RadioDiscoveryCooldownMinutes = 90,
    RadioDiscoverySignalChance = 25,
    RadioDiscoveryLineSpacingSeconds = 6,
} }
T.equal(PNC.Sandbox.RadioDiscoveryEnabled(), false,
    "sandbox can disable radio discovery")
T.equal(PNC.Sandbox.RadioDiscoveryCooldownHours(), 1.5,
    "sandbox cooldown is exposed in game-hour units")
T.equal(PNC.Sandbox.RadioDiscoverySignalChance(), 25,
    "sandbox controls signal detection chance")
T.equal(PNC.Sandbox.RadioDiscoveryLineSpacingSeconds(), 6,
    "sandbox controls radio line spacing")

T.finish("pnc_radio_discovery_sandbox_smoke")
