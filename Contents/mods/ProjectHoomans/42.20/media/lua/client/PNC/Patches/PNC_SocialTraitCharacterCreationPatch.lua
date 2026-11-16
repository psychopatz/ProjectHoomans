require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"
require "PNC/CharacterCreation/PNC_StartingCompanionCharacterCreationAdapter"

PNC = PNC or {}
PNC.SocialTraitCharacterCreationPatch =
    PNC.SocialTraitCharacterCreationPatch or {}

local Patch = PNC.SocialTraitCharacterCreationPatch
local Adapter = PNC.StartingCompanionCharacterCreationAdapter

function Patch.AppendZeroPointTraits(screen, list)
    return PsychopatzCore.Traits.AppendZeroPointTraits(screen, list)
end

local function installSubmissionHooks()
    if CharacterCreationMain
        and type(CharacterCreationMain.onOptionMouseDown) == "function"
        and not CharacterCreationMain
            ._pncStartingCompanionSubmissionPatched
    then
        local original = CharacterCreationMain.onOptionMouseDown
        CharacterCreationMain
            ._pncStartingCompanionSubmissionPatched = true
        CharacterCreationMain.onOptionMouseDown = function(self, button, ...)
            local result = original(self, button, ...)
            if button and button.internal == "NEXT"
                and Adapter and Adapter.Submit
            then
                Adapter.Submit(
                    MainScreen and MainScreen.instance
                        and MainScreen.instance.charCreationProfession
                        or nil
                )
            end
            return result
        end
    end

    if CoopCharacterCreation
        and type(CoopCharacterCreation.accept1) == "function"
        and not CoopCharacterCreation._pncStartingCompanionSubmissionPatched
    then
        local original = CoopCharacterCreation.accept1
        CoopCharacterCreation._pncStartingCompanionSubmissionPatched = true
        CoopCharacterCreation.accept1 = function(self, ...)
            local result = original(self, ...)
            if result and Adapter and Adapter.Submit then
                Adapter.Submit(self.charCreationProfession)
            end
            return result
        end
    end
end

installSubmissionHooks()
if Events and Events.OnGameBoot and Events.OnGameBoot.Add then
    Events.OnGameBoot.Add(installSubmissionHooks)
end
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(installSubmissionHooks)
end

return Patch
