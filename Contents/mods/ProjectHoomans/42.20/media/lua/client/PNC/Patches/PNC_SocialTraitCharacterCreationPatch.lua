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

local function text(key, fallback)
    if PNC.Translation and PNC.Translation.GetKey then
        return PNC.Translation.GetKey(key, fallback)
    end
    if type(getText) == "function" then
        local value = getText(key)
        if type(value) == "string" and value ~= "" and value ~= key then
            return value
        end
    end
    return fallback or key
end

local function measuredWidth(label)
    local width
    if type(getTextManager) == "function"
        and UIFont and UIFont.Small
    then
        local manager = getTextManager()
        if manager and type(manager.MeasureStringX) == "function" then
            width = manager:MeasureStringX(UIFont.Small, label)
        end
    end
    return math.max(112, (tonumber(width) or 64) + 52)
end

local function errorText(reason)
    local detail = tostring(reason or "unknown")
    return text(
        "UI_PNC_StartingCompanion_ValidationFailed",
        "Starting companion customization could not be applied: "
            .. detail
    ) .. " [" .. detail .. "]"
end

function Patch.ClearFinalError(screen)
    if not screen then return end
    screen.pncStartingCompanionError = nil
    if screen.pncStartingCompanionErrorLabel then
        screen.pncStartingCompanionErrorLabel:setName("")
        screen.pncStartingCompanionErrorLabel:setVisible(false)
    end
end

function Patch.ShowFinalError(screen, reason)
    local message = errorText(reason)
    if not screen then return message end
    screen.pncStartingCompanionError = reason
    if screen.pncStartingCompanionErrorLabel then
        screen.pncStartingCompanionErrorLabel:setName(message)
        screen.pncStartingCompanionErrorLabel:setVisible(true)
    end
    return message
end

function Patch.HandleFinalAction(screen, button, x, y)
    local window
    local reason
    if not button or button.internal ~= "COMPANIONS" then
        return false, "unsupported_final_action"
    end
    window, reason = Adapter.OpenComposer(screen)
    if not window then
        Patch.ShowFinalError(screen, reason)
        return false, reason
    end
    Patch.ClearFinalError(screen)
    return true, "opened"
end

local function installClassMethod(class, methodName, marker, handler)
    local original
    if not class or type(class[methodName]) ~= "function"
        or class[marker]
    then
        return false
    end
    original = class[methodName]
    class[marker] = true
    class[methodName] = function(self, ...)
        return handler(original, self, ...)
    end
    return true
end

local function createFinalCompanionButton(screen)
    local button
    local label
    local width
    local x
    if not screen or screen.pncStartingCompanionButton
        or not screen.playButton or not ISButton
    then
        return screen and screen.pncStartingCompanionButton
    end
    label = text("UI_PNC_StartingCompanion_Companions", "COMPANIONS")
    width = measuredWidth(label)
    x = screen.playButton:getX() - 10 - width
    button = ISButton:new(
        x,
        screen.playButton:getY(),
        width,
        screen.playButton:getHeight(),
        label,
        screen,
        Patch.HandleFinalAction
    )
    button.internal = "COMPANIONS"
    button:initialise()
    button:instantiate()
    button:setAnchorLeft(false)
    button:setAnchorRight(true)
    button:setAnchorTop(false)
    button:setAnchorBottom(true)
    if type(button.enableAcceptColor) == "function" then
        button:enableAcceptColor()
    end
    screen:addChild(button)
    screen.pncStartingCompanionButton = button

    if ISLabel then
        local labelX = screen.presetPanel and screen.presetPanel:getRight()
            or screen.backButton:getRight()
        local status = ISLabel:new(
            labelX + 10,
            screen.backButton:getY(),
            screen.backButton:getHeight(),
            "",
            1,
            0.35,
            0.35,
            1,
            UIFont and UIFont.Small or nil,
            true
        )
        status:initialise()
        status:instantiate()
        status:setVisible(false)
        screen:addChild(status)
        screen.pncStartingCompanionErrorLabel = status
    end

    -- Make room for the new action while retaining vanilla RANDOM/PLAY order.
    if screen.randomButton and type(screen.randomButton.getWidth) == "function" then
        screen.randomButton:setX(
            button:getX() - 10 - screen.randomButton:getWidth()
        )
    end
    Adapter.UpdateFinalActionState(screen)
    return button
end

local function installFinalScreenHooks()
    local loadedCoop
    -- The composition root may load before the final-screen Lua classes.  A
    -- later game-boot/start callback retries this installation once vanilla
    -- has loaded them; isolated headless tests may intentionally omit them.
    if not CharacterCreationMain then return false end
    if not CoopCharacterCreationMain then
        loadedCoop = require "OptionScreens/CoopCharacterCreationMain"
        CoopCharacterCreationMain = CoopCharacterCreationMain
            or (type(loadedCoop) == "table" and loadedCoop or nil)
    end
    if not CoopCharacterCreationMain then return false end

    installClassMethod(
        CharacterCreationMain,
        "create",
        "_pncStartingCompanionFinalCreatePatched",
        function(original, screen, ...)
            local result = original(screen, ...)
            createFinalCompanionButton(screen)
            return result
        end
    )
    installClassMethod(
        CharacterCreationMain,
        "setVisible",
        "_pncStartingCompanionFinalVisibilityPatched",
        function(original, screen, visible, ...)
            local result = original(screen, visible, ...)
            if visible == true then Adapter.UpdateFinalActionState(screen) end
            return result
        end
    )
    installClassMethod(
        CharacterCreationMain,
        "prerender",
        "_pncStartingCompanionFinalPrerenderPatched",
        function(original, screen, ...)
            local result = original(screen, ...)
            Adapter.UpdateFinalActionState(screen)
            return result
        end
    )

    local function finalAction(original, screen, button, ...)
        local ok
        local reason
        if button and button.internal == "COMPANIONS" then
            return Patch.HandleFinalAction(screen, button, ...)
        end
        if button and button.internal == "NEXT" then
            ok, reason = Adapter.PreCommit(screen)
            if not ok then
                Patch.ShowFinalError(screen, reason)
                return false, reason
            end
            Patch.ClearFinalError(screen)
        end
        return original(screen, button, ...)
    end

    installClassMethod(
        CharacterCreationMain,
        "onOptionMouseDown",
        "_pncStartingCompanionFinalActionPatched",
        finalAction
    )
    installClassMethod(
        CoopCharacterCreationMain,
        "onOptionMouseDown",
        "_pncStartingCompanionCoopFinalActionPatched",
        finalAction
    )

    createFinalCompanionButton(CharacterCreationMain.instance)
    if CoopCharacterCreationMain.instance
        and CoopCharacterCreationMain.instance ~= CharacterCreationMain.instance
    then
        createFinalCompanionButton(CoopCharacterCreationMain.instance)
    end
    return true
end

installFinalScreenHooks()

if Events and Events.OnGameBoot and Events.OnGameBoot.Add then
    Events.OnGameBoot.Add(installFinalScreenHooks)
end
if Events and Events.OnGameStart and Events.OnGameStart.Add then
    Events.OnGameStart.Add(installFinalScreenHooks)
end

return Patch
