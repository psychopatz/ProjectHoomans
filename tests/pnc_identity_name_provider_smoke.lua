-- Server truth provider for the identity name.
--
-- The knowledge pipeline only writes `identity.name` if the provider yields a
-- value. This exercises the REAL registered provider (not a stub) against the
-- record shape a runtime-spawned caravan trader has, including the case where
-- its archetype id is not resolvable at spawn time.

local T = require "tests/support/test"

local SHARED = "PNC/Core/"

PsychopatzCore = {
    RuntimeRole = { AllowsServerCode = function() return true end },
}

PNC = {
    Core = {
        DeepCopy = function(value)
            if type(value) ~= "table" then return value end
            local output = {}
            for key, item in pairs(value) do
                output[key] = PNC.Core.DeepCopy(item)
            end
            return output
        end,
    },
}

T.load("ProjectHoomans", "shared", SHARED .. "Knowledge/PNC_KnowledgeRegistry.lua")
T.load("ProjectHoomans", "shared", SHARED .. "Knowledge/PNC_KnowledgeBuiltins.lua")

local Providers = PNC.KnowledgeProviders
local Descriptors = PNC.KnowledgeDescriptors

local nameDescriptor = Descriptors.Get("identity.name")
T.truthy(nameDescriptor ~= nil, "identity.name descriptor is registered")
T.equal(nameDescriptor.presentation.truthField, "displayName",
    "identity.name resolves the canonical display name")
T.equal(nameDescriptor.discovery.minimumFamiliarity, 0,
    "a name introduction is not gated on familiarity")

-- The record shape PH creates for a mobile caravan member.
local caravanRecord = {
    id = "npcDeonByrd_ZUL8",
    archetypeID = "trader",
    identity = { displayName = "Deon Byrd", seed = 17 },
}

local value, reason = Providers.GetTruth(caravanRecord, nameDescriptor)
T.equal(value, "Deon Byrd",
    "the registered provider yields the caravan trader's canonical name")
T.equal(reason, nil, "resolving a real name reports no failure reason")

-- The runtime-spawned failure shape: the identity is real but the archetype id
-- cannot be resolved (helper module absent, unknown id). The name must not be
-- collateral damage, because `identity.name` is the only fact a caravan member
-- ever carries and the whole nameplate depends on it.
local unresolvedRecord = {
    id = "npcDeonByrd_ZUL8",
    archetypeID = "not_a_registered_archetype",
    identity = { displayName = "Deon Byrd", seed = 17 },
}
value, reason = Providers.GetTruth(unresolvedRecord, nameDescriptor)
T.equal(value, "Deon Byrd",
    "an unresolved archetype cannot suppress the canonical name")

-- A record without an identity is still a clean, non-crashing failure.
value, reason = Providers.GetTruth({ id = "npcNameless_0001" }, nameDescriptor)
T.equal(value, nil, "a record without an identity yields no name")
T.truthy(reason ~= nil, "missing truth reports an explicit reason")

T.finish("pnc_identity_name_provider_smoke")
