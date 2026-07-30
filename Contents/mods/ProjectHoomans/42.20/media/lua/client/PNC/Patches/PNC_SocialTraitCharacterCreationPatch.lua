require "OptionScreens/CharacterCreationProfession"

PNC = PNC or {}
PNC.SocialTraitCharacterCreationPatch =
    PNC.SocialTraitCharacterCreationPatch or {}

local Patch = PNC.SocialTraitCharacterCreationPatch

local function isAvailable(screen, traitDefinition)
    if screen.isTraitEnabled
        and not screen:isTraitEnabled(traitDefinition)
    then
        return false
    end
    if screen.isTraitExcluded
        and screen:isTraitExcluded(traitDefinition)
    then
        return false
    end
    return true
end

function Patch.AppendZeroPointTraits(screen, list)
    local constants = PNC.SocialProfileConstants
    local socialTraits = PNC.SocialTraits
    local added = 0
    local index
    local spec
    local trait
    local traitDefinition
    if not list
        or not constants
        or not socialTraits
        or not CharacterTraitDefinition
        or not CharacterTraitDefinition.getCharacterTraitDefinition
    then
        return 0
    end
    for index = 1, #constants.TRAIT_DEFINITIONS do
        spec = constants.TRAIT_DEFINITIONS[index]
        if spec.cost == 0 then
            trait = socialTraits.EngineTraits[spec.id]
            traitDefinition = trait
                and CharacterTraitDefinition
                    .getCharacterTraitDefinition(trait) or nil
            if traitDefinition
                and isAvailable(screen, traitDefinition)
            then
                if list.addUniqueItem then
                    list:addUniqueItem(
                        traitDefinition:getLabel(),
                        traitDefinition,
                        traitDefinition:getDescription()
                    )
                elseif list.addItem then
                    list:addItem(
                        traitDefinition:getLabel(),
                        traitDefinition,
                        traitDefinition:getDescription()
                    )
                end
                added = added + 1
            end
        end
    end
    return added
end

-- Build 42.20's vanilla screen only populates traits whose cost is strictly
-- positive or negative. Keep the standard screen and standard point logic,
-- but make PNC's intentionally zero-point identity/preferences selectable.
if CharacterCreationProfession
    and CharacterCreationProfession.populateTraitList
    and not CharacterCreationProfession
        ._pncZeroPointSocialTraitsPatched
then
    CharacterCreationProfession
        ._pncZeroPointSocialTraitsPatched = true
    local originalPopulateTraitList =
        CharacterCreationProfession.populateTraitList

    function CharacterCreationProfession:populateTraitList(list)
        local result = originalPopulateTraitList(self, list)
        Patch.AppendZeroPointTraits(self, list)
        return result
    end
end

return Patch
