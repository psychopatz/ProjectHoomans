local T = require "tests/support/test"

local SHARED = T.path("ProjectHoomans", "shared", "")
T.addPackagePaths()

PNC = {
    Translation = {
        GetKey = function(_, _, fallback) return fallback end,
    },
    Semantics = {},
}

T.load(SHARED .. "PNC/Semantics/PNC_SemanticAddressResolver.lua")
local Resolver = PNC.Semantics.AddressResolver

local unknown = Resolver.Resolve({
    identityKnown = false,
    knownName = "Unknown survivor",
    npcID = "npc-unknown",
})
T.equal(unknown.known, false, "unknown identity became a known name")
T.equal(unknown.id, "stranger", "neutral unknown address is not constrained")
T.equal(unknown.address, "stranger", "unknown address text")
T.falsy(Resolver.IsPlaceholder(unknown.address),
    "valid unknown address was classified as a placeholder")

local varied = Resolver.Resolve({
    identityKnown = false,
    npcID = "npc-unknown",
    recentAddresses = { "stranger" },
})
T.equal(varied.id, "mate", "bounded anti-repeat did not advance safely")

local friendlyMale = Resolver.Resolve({
    identityKnown = false,
    npcID = "npc-companion",
    isMale = true,
    relationshipKind = "companion",
    persona = "slang",
})
T.equal(friendlyMale.id, "bro", "slang male companion address")

local friendlyMaleAfterBro = Resolver.Resolve({
    identityKnown = false,
    npcID = "npc-companion",
    isMale = true,
    relationshipKind = "companion",
    persona = "slang",
    recentAddresses = { "bro" },
})
T.equal(friendlyMaleAfterBro.id, "mate",
    "anti-repeat left the constrained friendly style")

local formalMale = Resolver.Resolve({
    identityKnown = false,
    isMale = true,
    tone = "formal",
})
T.equal(formalMale.id, "mister", "formal male address")

local formalFemale = Resolver.Resolve({
    identityKnown = false,
    isFemale = true,
    tone = "formal",
})
T.equal(formalFemale.id, "miss", "formal female address")

local unavailableGender = Resolver.Resolve({
    identityKnown = false,
    tone = "formal",
})
T.equal(unavailableGender.id, "stranger",
    "unavailable gender did not use a neutral address")

local known = Resolver.Resolve({
    identityKnown = true,
    knownName = "Mara",
    recentAddresses = { "Mara" },
})
T.equal(known.known, true, "authoritative known name was not preserved")
T.equal(known.address, "Mara", "known name was replaced by a nickname")

local leaked = Resolver.Resolve({
    target = { displayName = "Unknown survivor" },
})
T.falsy(leaked.address == "Unknown survivor",
    "internal Unknown survivor placeholder leaked")

local context = {}
local applied, resolved = Resolver.Apply(context, {
    identityKnown = false,
    relationshipKind = "hostile",
})
T.equal(applied.addressKind, "term", "applied address kind")
T.equal(applied.semanticAddress, resolved.address,
    "applied semantic address was not returned")
T.equal(applied.identityKnown, false,
    "applied address invented identity knowledge")

T.finish("pnc_semantic_address_resolver_smoke")
