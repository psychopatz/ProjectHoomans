local T = require "tests/support/test"

local FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/PNC_ActorOwnership.lua"
)
local BANDITS_FILE = T.path(
    "ProjectHoomans",
    "shared",
    "PNC/Core/Compatibility/Mods/PNC_Compatibility_Bandits.lua"
)

local managed = {}

PNC = {
    Core = {
        IsManagedNPCBody = function(body)
            return managed[body] == true
        end,
    },
}

local function body(modData, bandit)
    return {
        getModData = function() return modData end,
        getVariableBoolean = function(_, name)
            return name == "Bandit" and bandit == true
        end,
    }
end

local human = body({ PNC_NPC = true }, false)
local foreign = body({}, true)
local marked = body({}, false)
local normal = body({}, false)
managed[human] = true

local Ownership = T.load(FILE)
T.load(BANDITS_FILE)

T.truthy(Ownership.IsHoomansOwned(human),
    "managed Hoomans body was not recognized")
T.falsy(Ownership.IsBanditOwned(human),
    "Hoomans ownership did not win over a foreign marker")
T.truthy(Ownership.IsBanditOwned(foreign),
    "Bandits variable was not recognized")
T.equal(Ownership.GetAdapter("Bandits").version, "Bandits2-B42.20",
    "Bandits adapter version was not registered")
T.truthy(Ownership.IsForeignOwned(foreign),
    "Bandits body was not classified as foreign-owned")
T.falsy(Ownership.ShouldHoomansIgnore(normal),
    "ordinary zombie was classified as owned")

T.truthy(Ownership.MarkHoomansOwned(marked),
    "Hoomans ownership marker was not written")
T.equal(marked:getModData().PNC_Owner, "ProjectHoomans",
    "Hoomans ownership marker has the wrong owner")
T.truthy(Ownership.IsHoomansOwned(marked),
    "fresh Hoomans ownership marker was not recognized")

T.truthy(Ownership.RegisterForeignOwner("TestOwner", function(candidate)
    return candidate == normal
end), "custom foreign owner was not registered")
T.equal(Ownership.GetForeignOwner(normal), "TestOwner",
    "custom foreign owner was not detected")

T.finish("pnc_actor_ownership_smoke")
