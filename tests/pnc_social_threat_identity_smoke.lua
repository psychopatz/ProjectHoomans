local T = require "tests/support/test"

T.addPackagePaths({ { "ProjectHoomans", "server" } })

T.addPackagePaths({
    { "PsychopatzCore", "common" },
})

PNC = {
    EntityRef = {},
}
isClient = function() return false end
isServer = function() return true end

local Hooks = T.load("ProjectHoomans", "server",
    "PNC/Social/SocialEventHooks/PNC_SocialEventHooks_ThreatAttribution.lua")
local localZombieA = { getOnlineID = function() return -1 end }
local localZombieB = { getOnlineID = function() return -1 end }
local networkZombie = { getOnlineID = function() return 314 end }

T.equal(PNC.SocialEventHooksInternal.ThreatIDFor(networkZombie), "314",
    "network zombies use their online ID")
T.truthy(
    PNC.SocialEventHooksInternal.ThreatIDFor(localZombieA)
        ~= PNC.SocialEventHooksInternal.ThreatIDFor(localZombieB),
    "local zombies receive distinct object identities")

T.finish("pnc_social_threat_identity_smoke")
