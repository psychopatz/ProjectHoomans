local T = require "tests/support/test"

local OWNERSHIP_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_ActorOwnership.lua"
)
local POLICY_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/Necroa/PNC_Necroa_Policy.lua"
)

local managed = {}

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return managed[body] == true
        end,
    },
}

local liveBody = {
    getModData = function()
        return {
            PNC_Owner = "ProjectHoomans",
            PNC_UUID = "npc-1",
        }
    end,
}
managed[liveBody] = true

local corpse = {
    getModData = function()
        return {
            PNC_DeathMarkerID = "npc-1",
            PNC_CorpseToken = "corpse-1",
        }
    end,
}

local ordinaryZombie = {
    getModData = function() return {} end,
}

T.load(OWNERSHIP_FILE)
local policy = T.load(POLICY_FILE)

T.truthy(policy.IsHoomansOwned(liveBody),
    "Necroa policy did not recognize a live Hoomans body")
T.truthy(policy.IsHoomansCorpse(corpse),
    "Necroa policy did not recognize a Hoomans corpse")
T.falsy(policy.IsHoomansManagedObject(ordinaryZombie),
    "Necroa policy misidentified an ordinary zombie")

T.truthy(policy.ShouldSkipFeature(liveBody, "speech"),
    "Necroa speech was not excluded for Hoomans")
T.truthy(policy.ShouldSkipFeature(liveBody, "contact_infection"),
    "Necroa contact infection was not excluded for Hoomans")
T.truthy(policy.ShouldSkipFeature(corpse, "corpse_reanimation"),
    "Necroa corpse reanimation was not excluded for Hoomans")
T.truthy(policy.ShouldSkipFeature(corpse, "corpse_infection"),
    "Necroa corpse infection was not excluded for Hoomans")
T.falsy(policy.ShouldSkipFeature(liveBody, "explosion_aoe"),
    "Necroa explosion was incorrectly discarded instead of routed")
T.truthy(policy.ShouldRouteIncomingDamage(liveBody),
    "Necroa damage was not routed to Hoomans")
T.falsy(policy.CanNecroaInfect(liveBody),
    "Necroa infection was allowed for a Hoomans body")
T.truthy(policy.CanNecroaInfect(ordinaryZombie),
    "ordinary zombie infection policy was changed")

T.finish("pnc_compatibility_necroa_smoke")
