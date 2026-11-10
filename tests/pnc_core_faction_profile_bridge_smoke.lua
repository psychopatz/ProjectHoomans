local T = require "tests/support/test"
T.addPackagePaths()

PNC = {}
local Archetypes = require
    "PNC/Core/Factions/PNC_FactionArchetypes"
local Profiles = require
    "PsychopatzCore/World/SurvivorWorld/PsychopatzSurvivorWorldFactionProfiles"

local trader = Profiles.Get("trader")
T.truthy(trader, "Hoomans built-in profile is registered in Core")
T.equal(trader.sourceMod, "ProjectHoomans",
    "profile source is explicit")
T.equal(trader.defaultRole, Archetypes.GetDefaultRole("trader"),
    "Hoomans facade reads Core default role")
T.equal(trader.capabilities.mobile, true,
    "mobile capability is stored in Core")

local registered, reason = Archetypes.Register("fixture:core_profile", {
    label = "Core Profile Fixture",
    allowedRoles = { leader = true, escort = true },
    defaultRole = "escort",
    behavior = { hostileToOutsiders = false },
    policyDefaults = { aggression = 0.2 },
    mobile = {
        enabled = true,
        roleOrder = { "leader", "escort" },
        npcArchetype = "General",
    },
})
T.truthy(registered, reason)

local fixture = Profiles.Get("fixture:core_profile")
T.truthy(fixture, "custom Hoomans profile is stored in Core")
T.equal(fixture.sourceMod, "ProjectHoomans",
    "custom profile source is explicit")
T.equal(Archetypes.SupportsMobile("fixture:core_profile"), true,
    "Hoomans mobile query uses Core capability")
T.equal(Archetypes.GetMobileRoleOrder("fixture:core_profile")[2],
    "escort", "Hoomans mobile profile reads Core extension")

Archetypes.ResetCustomForTests()
T.falsy(Profiles.Get("fixture:core_profile"),
    "test cleanup removes the Core-owned custom profile")

print("pnc_core_faction_profile_bridge_smoke: PASS")
