local T = require "tests/support/test"

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")

PNC = {}
T.load(T.path(
    "PsychopatzCore",
    "shared",
    "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"
))
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterConstants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_PlayerCharacterTypes.lua")

local normalized = PNC.PlayerCharacterTypes.NormalizeStartingCompanionState({
    resolved = true,
    grants = {
        PNC_HasBrother = {
            status = "granted",
            traitID = "PNC_HasBrother",
            npcID = "npc_brother",
            enrichmentVersion = 5,
            relationshipKeyVersion = 1,
        },
    },
})

T.equal(
    normalized.grants.PNC_HasBrother.relationshipKeyVersion,
    1,
    "starting-companion normalization preserves relationship key version"
)
T.finish("pnc_starting_companion_state_normalization_smoke")
