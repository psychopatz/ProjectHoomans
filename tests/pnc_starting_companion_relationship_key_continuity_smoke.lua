local T = require "tests/support/test"

local SHARED_ROOT = T.path("ProjectHoomans", "shared", "PNC/Core/")
local SERVER_ROOT = T.path("ProjectHoomans", "server", "PNC/")

T.load(T.path(
    "PsychopatzCore",
    "shared",
    "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"
))
PNC = {}
T.load(SHARED_ROOT .. "Base/PNC_Core.lua")
T.load(SHARED_ROOT .. "Base/PNC_Constants.lua")
T.load(SHARED_ROOT .. "Identity/PNC_Identity.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_EntityRef.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileConstants.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileGenerator.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialTraits.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_SocialProfileMath.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductConstants.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductTypes.lua")
T.load(SHARED_ROOT .. "Conduct/PNC_ConductMath.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionConstants.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionArchetypes.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionEmblems.lua")
T.load(SHARED_ROOT .. "Factions/PNC_FactionTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipConstants.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipStates.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipTypes.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_RelationshipMath.lua")
T.load(SHARED_ROOT .. "Base/PNC_Types.lua")
T.load(SHARED_ROOT .. "Relationships/PNC_Relationships.lua")

PNC.Core.IsAuthority = function() return true end
PNC.Registry = {
    Data = {},
    MarkDirty = function() return true end,
}
PNC.Registry.Get = function(id)
    return PNC.Registry.Data[tostring(id)]
end
T.load(SERVER_ROOT .. "Social/PNC_RelationshipService.lua")

PNC.StartingCompanions = {}
PNC.StartingCompanionServiceInternal = {}
PNC.StartingCompanionTraits = {}
PNC.PlayerCharacters = {}
PNC.PlayerCharacters.GetEntityKey = function(_, context)
    return PNC.EntityRef.ForPlayerIdentity(
        "sp_slot_0",
        context and context.characterUUID or "char_player"
    )
end
T.load(SERVER_ROOT ..
    "Companions/StartingCompanionService/PNC_StartingCompanionService_Core.lua")
T.load(SERVER_ROOT ..
    "Companions/StartingCompanionService/PNC_StartingCompanionService_Assignment.lua")

local player = {}
local character = {
    uuid = "char_player",
    accountIdentity = "Bob",
    accountKey = "sp_slot_0",
}
local playerKey = PNC.EntityRef.ForPlayerIdentity(
    "sp_slot_0",
    character.uuid
)
local legacyKey = PNC.EntityRef.ForPlayerIdentity(
    character.accountIdentity,
    character.uuid
)

local function newNPC(id)
    local record = {
        id = id,
        alive = true,
        social = PNC.RelationshipTypes.NewSocialState(),
    }
    PNC.Registry.Data[id] = record
    return record
end

local newNPCRecord = newNPC("npc_new_companion")
local H = PNC.StartingCompanionServiceInternal
H.ApplyLifelongKnowledge(
    player,
    character,
    newNPCRecord.id,
    { id = "PNC_HasBrother", relationshipKind = "brother" },
    12
)
local newRelationship = PNC.Relationships.Get(
    newNPCRecord.id,
    playerKey
)
T.truthy(newRelationship, "new companion uses the canonical player key")
T.equal(newRelationship.approval, 85,
    "new companion relationship is visible through canonical lookup")
T.equal(newRelationship.respect, 70,
    "new companion respect is visible through canonical lookup")
T.equal(newRelationship.familiarity, 100,
    "new companion familiarity is visible through canonical lookup")
T.equal(PNC.Relationships.Get(newNPCRecord.id, legacyKey), nil,
    "new companion does not write the legacy player key")

T.finish("pnc_starting_companion_relationship_key_continuity_smoke")
