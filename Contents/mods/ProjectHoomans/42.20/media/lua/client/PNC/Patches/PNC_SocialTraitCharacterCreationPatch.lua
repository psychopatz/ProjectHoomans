require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"
require "PNC/CharacterCreation/PNC_StartingCompanionCharacterCreationAdapter"

PNC = PNC or {}
PNC.SocialTraitCharacterCreationPatch =
    PNC.SocialTraitCharacterCreationPatch or {}

local Patch = PNC.SocialTraitCharacterCreationPatch

function Patch.AppendZeroPointTraits(screen, list)
    return PsychopatzCore.Traits.AppendZeroPointTraits(screen, list)
end

return Patch
