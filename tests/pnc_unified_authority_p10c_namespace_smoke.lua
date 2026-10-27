-- P10C namespace and addressing-authority regression.

local T = require "tests/support/test"

T.addPackagePaths({
    { "ProjectHoomans", "shared" },
    { "ProjectHoomans", "client" },
    { "ProjectHoomans", "server" },
    { "PsychopatzCore", "common" },
})

PNC = { Semantics = {} }
getText = function(key) return key end

local SocialContext = require "PNC/Core/Social/PNC_SemanticSocialContext"
local AddressResolver = require "PNC/Semantics/PNC_SemanticAddressResolver"
local Constants = PNC.Semantics.SocialContextConstants

T.equal(PNC.FlavorText, nil, "retired FlavorText namespace is absent")
T.equal(PNC.FlavorTextConst, nil, "retired FlavorText constants are absent")
T.equal(PNC.FlavorAddress, nil, "retired FlavorAddress namespace is absent")
T.equal(PNC.Semantics.SocialContext, SocialContext,
    "social facts use the canonical semantic context provider")
T.equal(PNC.Semantics.AddressResolver, AddressResolver,
    "identity terms and name disclosure use one semantic address resolver")

T.equal(SocialContext.ClassifyThreat({ kind = "bandit" }),
    Constants.Threat.FOREIGN_NPC,
    "compatibility threat facts retain foreign-NPC classification")
T.equal(SocialContext.ClassifyGrief({ relationshipState = "lover" }),
    Constants.Grief.DEVOTED,
    "grief facts retain relationship-sensitive classification")

local friendly = AddressResolver.Resolve({
    relationshipKind = "companion",
    persona = "casual",
    gender = "male",
})
T.equal(friendly.id, "bro", "friendly casual male address preserves bro term")
local formal = AddressResolver.Resolve({
    relationshipKind = "stranger",
    tone = "formal",
    gender = "female",
})
T.equal(formal.id, "miss", "formal female stranger preserves miss term")
local known = AddressResolver.Resolve({
    identityKnown = true,
    name = "Alex Mercer",
})
T.equal(known.kind, "name", "known identity disclosure uses the authoritative name")
T.equal(known.address, "Alex Mercer", "known identity is not replaced by a nickname")
local firstAddress = AddressResolver.Resolve({
    relationshipKind = "companion",
    gender = "male",
})
local addressHistory = {}
AddressResolver.Remember(addressHistory, firstAddress)
local nextAddress = AddressResolver.Resolve({
    relationshipKind = "companion",
    recentAddresses = addressHistory,
    gender = "male",
})
T.falsy(nextAddress.id == firstAddress.id,
    "bounded address history avoids an immediate repeated term")

local deleted = {
    "PNC_FlavorAddress.lua",
    "PNC_FlavorAddress_Names.lua",
    "PNC_FlavorAddress_Nicknames.lua",
    "PNC_FlavorTextResolver.lua",
    "PNC_FlavorTextResolver_Constants.lua",
}
for _, name in ipairs(deleted) do
    local path = T.path("ProjectHoomans", "shared", "PNC/Core/Identity/" .. name)
    if string.find(name, "FlavorText", 1, true) then
        path = T.path("ProjectHoomans", "shared", "PNC/Core/Social/" .. name)
    end
    local handle = io.open(path, "rb")
    T.falsy(handle, "retired legacy namespace file still exists: " .. name)
    if handle then handle:close() end
end

T.finish("pnc_unified_authority_p10c_namespace_smoke")
