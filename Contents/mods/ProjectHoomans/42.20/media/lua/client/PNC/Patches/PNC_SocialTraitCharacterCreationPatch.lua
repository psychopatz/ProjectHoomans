if not PsychopatzCore or not PsychopatzCore.Traits
    or not PsychopatzCore.Traits.AppendZeroPointTraits
then
    require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"
end

PNC = PNC or {}
PNC.SocialTraitCharacterCreationPatch =
    PNC.SocialTraitCharacterCreationPatch or {}

local Patch = PNC.SocialTraitCharacterCreationPatch

function Patch.AppendZeroPointTraits(screen, list)
    return PsychopatzCore.Traits.AppendZeroPointTraits(screen, list)
end

return Patch
