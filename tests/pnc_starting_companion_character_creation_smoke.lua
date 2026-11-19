local T = require "tests/support/test"

T.addPackagePaths()

PNC = { Identity = {} }
T.load(T.path("PsychopatzCore", "shared",
    "PsychopatzCore/Traits/PsychopatzTraitRegistry.lua"))
T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Identity/PNC_Identity.lua"))
T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileConstants.lua"))
T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialProfileTypes.lua"))
T.load(T.path("ProjectHoomans", "shared",
    "PNC/Core/Relationships/PNC_SocialTraits.lua"))

local StartingTraits = require "PNC/Core/Traits/PNC_StartingCompanionTraits"
local SocialConstants = PNC.SocialProfileConstants
local Session = require "PNC/CharacterCreation/PNC_StartingCompanionSession"
local Customization = require
    "PNC/Core/Identity/PNC_StartingCompanionCustomization"

local TID = StartingTraits.IDS

-- The final-screen patch is exercised against the same narrow button/class
-- surface vanilla exposes.  This is a journey test, not a second UI runner.
local function button(x, y, width, height, label, target, callback)
    local value = {
        x = x, y = y, width = width, height = height,
        title = label, target = target, onclick = callback,
        enabled = true,
    }
    function value:getX() return self.x end
    function value:getY() return self.y end
    function value:getWidth() return self.width end
    function value:getHeight() return self.height end
    function value:getRight() return self.x + self.width end
    function value:setX(nextX) self.x = nextX end
    function value:setEnable(nextEnabled) self.enabled = nextEnabled end
    function value:initialise() end
    function value:instantiate() end
    function value:setAnchorLeft() end
    function value:setAnchorRight() end
    function value:setAnchorTop() end
    function value:setAnchorBottom() end
    function value:enableAcceptColor() end
    return value
end

ISButton = {
    new = function(_, x, y, width, height, label, target, callback)
        return button(x, y, width, height, label, target, callback)
    end,
}

ISLabel = {
    new = function(_, x, y, height, label)
        local value = {
            x = x, y = y, height = height, label = label,
            visible = true,
        }
        function value:initialise() end
        function value:instantiate() end
        function value:setName(nextName) self.label = nextName end
        function value:setVisible(nextVisible) self.visible = nextVisible end
        return value
    end,
}

local function finalScreenClass()
    local class = {
        create = function(self)
            self.children = {}
            self.backButton = button(10, 90, 60, 24, "BACK")
            self.presetPanel = {
                getRight = function() return 180 end,
            }
            self.randomButton = button(300, 90, 80, 24, "RANDOM")
            self.playButton = button(500, 90, 80, 24, "PLAY")
            self.playButton.internal = "NEXT"
            self.randomButton.internal = "RANDOM"
            self.backButton.internal = "BACK"
            self.addChild = function(screen, child)
                screen.children[#screen.children + 1] = child
            end
            self.surnameEntry = {
                text = "",
                getText = function(entry) return entry.text end,
            }
            self.forenameEntry = {
                text = "Alex",
                getText = function(entry) return entry.text end,
            }
            return true
        end,
        setVisible = function(self, visible)
            self.visible = visible
            return true
        end,
        prerender = function() return true end,
        onKeyRelease = function(self) self.vanillaKey = true end,
        onOptionMouseDown = function(self, option)
            if option and option.internal == "NEXT" then
                self.vanillaNextCount = (self.vanillaNextCount or 0) + 1
            end
            return "vanilla"
        end,
        initPlayer = function(self)
            self.desc:setForename(self.forenameEntry:getText())
            self.desc:setSurname(self.surnameEntry:getText())
        end,
    }
    class.__index = class
    return class
end

CharacterCreationProfession = {
    repopulateTraitLists = function() end,
    onSelectProf = function() end,
    create = function() end,
    setVisible = function() end,
}
package.preload["OptionScreens/CharacterCreationProfession"] =
    function() return CharacterCreationProfession end

CharacterCreationMain = finalScreenClass()
CoopCharacterCreationMain = {
    onOptionMouseDown = function(self, option)
        if option and option.internal == "NEXT" then
            self.coopVanillaNextCount = (self.coopVanillaNextCount or 0) + 1
        end
        return "coop-vanilla"
    end,
}
setmetatable(CoopCharacterCreationMain, { __index = CharacterCreationMain })
package.preload["OptionScreens/CharacterCreationMain"] =
    function() return CharacterCreationMain end
package.preload["OptionScreens/CoopCharacterCreationMain"] =
    function() return CoopCharacterCreationMain end

local capturedVanillaPlay = CharacterCreationMain.onOptionMouseDown
Events = {
    OnCreatePlayer = { Add = function() end },
    OnGameBoot = { Add = function() end },
    OnGameStart = { Add = function() end },
}

T.load(T.path("PsychopatzCore", "client",
    "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation.lua"))
T.load(T.path("ProjectHoomans", "client",
    "PNC/Patches/PNC_SocialTraitCharacterCreationPatch.lua"))

local Adapter = PNC.StartingCompanionCharacterCreationAdapter
local Patch = PNC.SocialTraitCharacterCreationPatch
local descriptor
local profession
local final

PNC.Identity.GetCharacterAppearance = function(value)
    return value.appearance
end

local function newDescriptor(surname, female, appearance)
    local value = {
        forename = "Alex",
        surname = surname,
        female = female,
        appearance = appearance,
    }
    function value:getForename() return self.forename end
    function value:setForename(nextName) self.forename = nextName end
    function value:getSurname() return self.surname end
    function value:setSurname(nextName) self.surname = nextName end
    function value:isFemale() return self.female end
    return value
end

local function traitEntry(id)
    local trait = {
        getName = function() return id end,
    }
    return {
        item = {
            getType = function() return trait end,
        },
    }
end

local function setTraits(screen, ids)
    screen.listboxTraitSelected = { items = {} }
    for _, id in ipairs(ids or {}) do
        screen.listboxTraitSelected.items[#screen.listboxTraitSelected.items + 1] =
            traitEntry(id)
    end
end

local function startFlow(ids, playerIndex)
    playerIndex = playerIndex or 0
    descriptor = newDescriptor("Reyes", true, {
        skinTexture = "FemaleBody03",
        skinColor = { r = 0.44, g = 0.31, b = 0.22 },
        hairColor = { r = 0.12, g = 0.07, b = 0.03 },
    })
    profession = {
        playerIndex = playerIndex,
        listboxTraitSelected = { items = {} },
    }
    setTraits(profession, ids)
    if playerIndex == 0 then
        MainScreen = {
            instance = {
                desc = descriptor,
                charCreationProfession = profession,
            },
        }
        CoopCharacterCreation = nil
        final = setmetatable({
            playerIndex = 0,
            professionScreen = profession,
            desc = descriptor,
        }, { __index = CharacterCreationMain })
    else
        local coop = {
            playerIndex = playerIndex,
            charCreationProfession = profession,
        }
        CoopCharacterCreation = { instance = coop }
        final = setmetatable({
            playerIndex = playerIndex,
            professionScreen = profession,
            desc = descriptor,
        }, { __index = CoopCharacterCreationMain })
        coop.charCreationMain = final
    end
    final:create()
    final.surnameEntry.text = descriptor.surname
    final.forenameEntry.text = descriptor.forename
    Adapter.HandleEvent(profession, {
        event = "screen_created",
        selectedTraitIDs = ids,
    })
    Adapter.HandleEvent(profession, {
        event = "trait_set_changed",
        selectedTraitIDs = ids,
    })
    Adapter.UpdateFinalActionState(final)
    return final
end

local openCount = 0
local openedSessions = {}
Adapter.OpenComposer = function(screen)
    local session = Adapter.ReconcileFinalScreen(screen, "test_open")
    openCount = openCount + 1
    openedSessions[#openedSessions + 1] = session
    return { session = session }
end

-- 1. No trait: the action is disabled and ordinary Play remains unblocked.
local noTraitFinal = startFlow({}, 0)
T.falsy(noTraitFinal.pncStartingCompanionButton.enabled,
    "no-companion final action is disabled")
noTraitFinal:onOptionMouseDown(noTraitFinal.playButton)
T.equal(noTraitFinal.vanillaNextCount, 1,
    "no-companion Play reaches vanilla transition")
T.falsy(Customization.LocalEnvelope, "no-companion Play stages no envelope")

-- 2. A selected trait alone keeps the canonical default starter path.
local defaultFinal = startFlow({ TID.BROTHER }, 0)
T.truthy(defaultFinal.pncStartingCompanionButton.enabled,
    "selected companion enables final action")
local openCountBeforeVisibility = openCount
Adapter.HandleEvent(profession, {
    event = "screen_shown",
    selectedTraitIDs = { TID.BROTHER },
})
T.equal(openCount, openCountBeforeVisibility,
    "profession visibility never auto-opens the composer")
defaultFinal:onOptionMouseDown(defaultFinal.playButton)
T.equal(defaultFinal.vanillaNextCount, 1,
    "unopened companion Play reaches vanilla transition")
T.falsy(Adapter.LastPreCommit.authored,
    "unopened companion Play remains unmodified")
T.falsy(Customization.LocalEnvelope,
    "unopened companion Play stages no envelope")

local unchangedFinal = startFlow({ TID.BROTHER }, 0)
unchangedFinal:onOptionMouseDown(unchangedFinal.pncStartingCompanionButton)
unchangedFinal:onOptionMouseDown(unchangedFinal.pncStartingCompanionButton)
unchangedFinal:onOptionMouseDown(unchangedFinal.playButton)
T.falsy(Adapter.LastPreCommit.authored,
    "open and close without edits remains unmodified")
T.falsy(Customization.LocalEnvelope,
    "open and close without edits stages no envelope")

-- 3-5. Open, edit, close, then re-open against a changed final player.
local authoredFinal = startFlow({ TID.BROTHER }, 0)
local authoredSession = Adapter.GetSession(authoredFinal)
local originalBlueprintFingerprint
local updatedBlueprintFingerprint
authoredFinal:onOptionMouseDown(authoredFinal.pncStartingCompanionButton)
T.equal(openCount >= 1, true, "final-screen Companions opens the composer")
T.equal(openedSessions[#openedSessions], authoredSession,
    "composer uses the profession-owned logical session")
authoredSession:SetField(TID.BROTHER, "identity.forename", "Riley")
originalBlueprintFingerprint =
    require("PNC/Core/Identity/PNC_NPCAuthoring").Blueprint.Fingerprint(
        authoredSession:GetBlueprint(TID.BROTHER)
    )
authoredFinal:onOptionMouseDown(authoredFinal.pncStartingCompanionButton)
T.equal(authoredSession:GetBlueprint(TID.BROTHER).fields["identity.forename"],
    "Riley", "edit persists after the composer closes and reopens")

descriptor.surname = "Reyes"
descriptor.female = false
descriptor.appearance = {
    skinTexture = "MaleBody05",
    skinColor = { r = 0.2, g = 0.3, b = 0.4 },
    hairColor = { r = 0.5, g = 0.4, b = 0.3 },
}
authoredFinal.surnameEntry.text = "Cruz"
authoredFinal:onOptionMouseDown(authoredFinal.pncStartingCompanionButton)
local resolvedBrother = authoredSession:GetSlot(TID.BROTHER).resolvedDefinition
updatedBlueprintFingerprint =
    require("PNC/Core/Identity/PNC_NPCAuthoring").Blueprint.Fingerprint(
        authoredSession:GetBlueprint(TID.BROTHER)
    )
T.equal(updatedBlueprintFingerprint, originalBlueprintFingerprint,
    "rebinding does not mutate stored blueprint intent")
T.equal(resolvedBrother.identity.survivor.surname, "Cruz",
    "reopen inherits the current player surname")
T.equal(resolvedBrother.identity.survivor.skinTexture, "MaleBody05",
    "reopen inherits the current family appearance")
authoredFinal.playButton.onclick = capturedVanillaPlay
authoredFinal.playButton.target = authoredFinal
authoredFinal:setVisible(true)
local dispatchedBack = false
authoredFinal.backButton.onclick = function() dispatchedBack = true end
authoredFinal:setVisible(true)
PNC.StartingCompanionComposerUI = { IsOpen = function() return true end }
authoredFinal.playButton.onclick(authoredFinal, authoredFinal.playButton)
authoredFinal.backButton.onclick(authoredFinal, authoredFinal.backButton)
authoredFinal:onKeyRelease(1)
T.falsy(authoredFinal.vanillaNextCount, "Play is blocked while composer owns input")
T.falsy(dispatchedBack, "cached native Back callback is blocked")
T.falsy(authoredFinal.vanillaKey, "background key navigation is blocked")
PNC.StartingCompanionComposerUI = nil
local preCommitCalls, preCommit = 0, Adapter.PreCommit
Adapter.PreCommit = function(screen)
    preCommitCalls = preCommitCalls + 1
    return preCommit(screen)
end
authoredFinal.playButton.onclick(authoredFinal.playButton.target, authoredFinal.playButton)
Adapter.PreCommit = preCommit
T.equal(preCommitCalls, 1, "the real Play callback stages once even if it cached the unpatched native method")
T.equal(authoredFinal.vanillaNextCount, 1,
    "authored Play reaches vanilla only after staging")
T.truthy(Adapter.LastPreCommit.authored,
    "meaningful field edit creates authored intent")
T.truthy(Customization.LocalEnvelope,
    "authored Play stages a canonical local envelope")

local mixedFinal = startFlow({ TID.BROTHER, TID.FRIEND }, 0)
local mixed = Adapter.GetSession(mixedFinal)
mixed:SetField(TID.BROTHER, "identity.forename", "Custom")
mixed:SetField(TID.FRIEND, "identity.forename", "Discard me")
mixed:ResetSlot(TID.FRIEND)
mixed:RememberPreview(TID.FRIEND, mixed:GetBlueprint(TID.FRIEND))
T.truthy(Adapter.PreCommit(mixedFinal))
local mixedEnvelope = assert(Customization.DecodeEnvelope(Customization.LocalEnvelope))
T.truthy(mixedEnvelope.blueprints[TID.BROTHER], "custom companion remains in spawn payload")
T.falsy(mixedEnvelope.blueprints[TID.FRIEND], "reset companion is generated through the default server path")

-- 6. Lover sex follows current player sex and social orientation.
local loverFinal = startFlow({
    TID.IS_MARRIED, SocialConstants.TRAIT_IDS.GAY,
}, 0)
loverFinal:onOptionMouseDown(loverFinal.pncStartingCompanionButton)
local loverSession = Adapter.GetSession(loverFinal)
T.equal(loverSession:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale,
    true, "gay female player receives a female lover")
descriptor.female = false
loverFinal:onOptionMouseDown(loverFinal.pncStartingCompanionButton)
T.equal(loverSession:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale,
    false, "gay male player receives a male lover")
setTraits(profession, { TID.IS_MARRIED })
loverFinal:onOptionMouseDown(loverFinal.pncStartingCompanionButton)
T.equal(loverSession:GetSlot(TID.IS_MARRIED).resolvedDefinition.isFemale,
    true, "straight lover follows the current player sex")

-- 7. Back-navigation keeps the same session and removed-slot cache.
local backFinal = startFlow({ TID.BROTHER }, 0)
local backSession = Adapter.GetSession(backFinal)
backSession:SetField(TID.BROTHER, "identity.forename", "Morgan")
setTraits(profession, { TID.SISTER })
Adapter.HandleEvent(profession, {
    event = "trait_set_changed",
    selectedTraitIDs = { TID.SISTER },
})
setTraits(profession, { TID.BROTHER, TID.SISTER })
Adapter.HandleEvent(profession, {
    event = "trait_set_changed",
    selectedTraitIDs = { TID.BROTHER, TID.SISTER },
})
T.equal(Adapter.GetSession(backFinal), backSession,
    "back-navigation does not create a second session")
T.equal(backSession:GetBlueprint(TID.BROTHER).fields["identity.forename"],
    "Morgan", "removed and re-added slot restores its cached blueprint")
T.equal(#backSession:GetActiveSlots(), 2,
    "reconciled session exposes only the selected active slots")

-- 8. Explicit Randomize is authored and stable until used again.
local randomFinal = startFlow({ TID.FRIEND }, 0)
local randomSession = Adapter.GetSession(randomFinal)
local beforeRandomize = randomSession:GetBlueprint(TID.FRIEND).generationSeed
randomSession:RandomizeSlot(TID.FRIEND, 777)
local randomizedSeed = randomSession:GetBlueprint(TID.FRIEND).generationSeed
T.truthy(randomizedSeed ~= beforeRandomize,
    "explicit Randomize changes the generation seed")
T.truthy(randomSession:HasAuthoredIntent(),
    "explicit Randomize creates authored intent")
Adapter.ReconcileFinalScreen(randomFinal, "repeat_preview")
T.equal(randomSession:GetBlueprint(TID.FRIEND).generationSeed, randomizedSeed,
    "repeated preview does not silently reroll")

-- 9. Invalid authored data blocks Play and reports a useful reason.
local invalidFinal = startFlow({ TID.BROTHER }, 0)
local invalidSession = Adapter.GetSession(invalidFinal)
invalidSession:SetField(TID.BROTHER, "identity.forename", "Riley")
invalidSession:GetSlot(TID.BROTHER).blueprint.fields["identity.forename"] =
    string.rep("x", 65)
invalidFinal:onOptionMouseDown(invalidFinal.playButton)
T.equal(invalidFinal.vanillaNextCount, nil,
    "invalid authored customization does not begin vanilla transition")
T.truthy(invalidFinal.pncStartingCompanionError,
    "invalid authored customization surfaces a failure reason")
T.falsy(Customization.LocalEnvelope,
    "invalid authored customization stages no envelope")

-- 10. Co-op uses the same explicit action and pre-commit semantics.
local coopFinal = startFlow({ TID.BROTHER }, 1)
T.truthy(coopFinal.pncStartingCompanionButton.enabled,
    "co-op final screen exposes the Companions action")
coopFinal:onOptionMouseDown(coopFinal.pncStartingCompanionButton)
local coopSession = Adapter.GetSession(coopFinal)
coopSession:SetField(TID.BROTHER, "identity.forename", "Casey")
coopFinal:onOptionMouseDown(coopFinal.playButton)
T.equal(coopFinal.coopVanillaNextCount, 1,
    "co-op authored Play reaches vanilla after pre-commit")
T.truthy(Adapter.LastPreCommit.staged,
    "co-op authored Play stages before accept")

-- 11-12. Remote MP keeps authored intent pending until the player exists.
PNC.Core = PNC.Core or {}
PNC.Core.IsClientOnly = function() return true end
PNC.Const = {
    MODULE = "ProjectHoomans",
    CMD_STARTING_COMPANION_CUSTOMIZATION = "StartingCompanionCustomization",
}
local sent = 0
sendClientCommand = function()
    sent = sent + 1
end
local remoteFinal = startFlow({ TID.BROTHER }, 2)
local remoteSession = Adapter.GetSession(remoteFinal)
remoteFinal:onOptionMouseDown(remoteFinal.pncStartingCompanionButton)
remoteSession:SetField(TID.BROTHER, "identity.forename", "Taylor")
remoteFinal:onOptionMouseDown(remoteFinal.playButton)
T.truthy(Adapter.PendingEnvelopes[2],
    "MP authored Play stages before the player entity exists")
T.equal(sent, 0, "MP does not transmit before player creation")
T.truthy(Adapter.SubmitPending(2, {}),
    "MP submits staged intent when the player exists")
T.equal(sent, 1, "MP sends one authored customization envelope")
T.falsy(Adapter.PendingEnvelopes[2],
    "MP pending envelope is consumed once")

T.finish("pnc_starting_companion_character_creation_smoke")
