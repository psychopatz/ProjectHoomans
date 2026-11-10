local T = require "tests/support/test"

PNC = { Identity = {} }
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity.lua")
T.load("ProjectHoomans", "shared", "PNC/Core/Identity/PNC_Identity_Names.lua")

local Names = PNC.IdentityNames
local seen = {}
for seed = 1, 64 do
    local first = Names.ResolveNickname("Patrick", seed)
    local second = Names.ResolveNickname("Patrick", seed)
    T.equal(first, second, "nickname resolution is deterministic for a seed")
    seen[first] = true
end

T.truthy(seen.Pat, "Patrick has the expected Pat alias available")
T.equal(Names.ResolveNickname("Patrick", 17, { nickname = "Patch" }),
    "Patch", "authored nickname overrides generated aliases")
T.equal(Names.ResolveNickname("Ben", 17), "Ben",
    "short forenames remain valid public nicknames")

T.finish("pnc_identity_nickname_smoke")
