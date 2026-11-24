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
T.equal(Names.ResolveNickname("Adrienne", 17), "Adrienne",
    "unlisted forenames fall back to first name instead of 3-letter slices")
T.equal(Names.ResolveNickname("Faustino", 17), "Faustino",
    "unlisted forenames never synthesize 3-letter fragments")
T.equal(Names.ResolveNickname("Raymond", 17), "Ray",
    "authored nicknames resolve from catalog")
T.equal(Names.FormatDisplayName("Clay Prentice", "Clay"), "Clay Prentice",
    "display name omits redundant (FirstName) suffix")
T.equal(Names.FormatDisplayName("Raymond Coker", "Ray"), "Raymond Coker (Ray)",
    "display name includes distinct authored nickname")
T.truthy(Names.NicknameCatalog.Register("Faustino", { "Tino" }, "male"),
    "catalog supports registering gender-specific authored nicknames")
T.equal(Names.ResolveNickname("Faustino", 17, { isFemale = false }), "Tino",
    "registered male authored nickname takes effect for male actors")
T.equal(Names.ResolveNickname("Faustino", 17, { isFemale = true }), "Faustino",
    "male-only registered nickname does not leak to female actors")

local maleAlex = Names.ResolveNickname("Alex", 42, { isFemale = false })
local femaleAlex = Names.ResolveNickname("Alex", 42, { isFemale = true })
T.truthy(maleAlex == "Al" or maleAlex == "Lex",
    "male Alex resolves to male nickname pool")
T.truthy(femaleAlex == "Lexi" or femaleAlex == "Lexy",
    "female Alex resolves to female nickname pool")

T.finish("pnc_identity_nickname_smoke")
