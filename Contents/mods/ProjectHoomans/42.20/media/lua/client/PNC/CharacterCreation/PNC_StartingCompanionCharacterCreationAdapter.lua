require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PNC/Core/Identity/PNC_StartingCompanionCustomization"
require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"
require "PNC/CharacterCreation/PNC_StartingCompanionSession"

PNC = PNC or {}
PNC.StartingCompanionCharacterCreationAdapter =
    PNC.StartingCompanionCharacterCreationAdapter or {}

local Adapter = PNC.StartingCompanionCharacterCreationAdapter
local StartingTraits = PNC.StartingCompanionTraits
local Customization = PNC.StartingCompanionCustomization
local Extension = PsychopatzCore.CharacterCreationExtension
local CoreTraits = PsychopatzCore.Traits

Adapter.PROVIDER_ID = "ProjectHoomans.StartingCompanions"
Adapter.MAX_CACHED_EVENTS = 8
Adapter.MAX_SESSIONS = 4
Adapter.Session = Adapter.Session or nil
Adapter.Sessions = Adapter.Sessions or {}
Adapter.SessionsByPlayerIndex = Adapter.SessionsByPlayerIndex or {}
Adapter.SessionOrder = Adapter.SessionOrder or {}
Adapter.EventCache = Adapter.EventCache or {}
Adapter.PendingEnvelopes = Adapter.PendingEnvelopes or {}
Adapter.LastPreCommit = Adapter.LastPreCommit or nil
Adapter.LastOpen = Adapter.LastOpen or nil

local function copyList(source)
    local output = {}
    for index = 1, #(source or {}) do
        output[index] = source[index]
    end
    return output
end

local function companionTraitIDs(source)
    local found = {}
    local output = {}
    local id
    local spec
    local selectedID

    for index = 1, #(source or {}) do
        selectedID = source[index]
        id = CoreTraits.NormalizeID(selectedID, StartingTraits.OWNER)
        spec = id and StartingTraits.GetDefinition(id) or nil
        if spec then found[id] = true end
    end

    for index = 1, #StartingTraits.DEFINITIONS do
        id = StartingTraits.DEFINITIONS[index].id
        if found[id] then output[#output + 1] = id end
    end
    return output
end

local function cacheEvent(snapshot)
    Adapter.EventCache[#Adapter.EventCache + 1] = snapshot
    while #Adapter.EventCache > Adapter.MAX_CACHED_EVENTS do
        table.remove(Adapter.EventCache, 1)
    end
end

local function playerIndexFor(screen)
    if screen and screen.playerIndex ~= nil then
        return tonumber(screen.playerIndex) or 0
    end
    if CoopCharacterCreation and CoopCharacterCreation.instance then
        local instance = CoopCharacterCreation.instance
        if screen == instance.charCreationProfession
            or screen == instance.charCreationMain
        then
            return tonumber(instance.playerIndex) or 0
        end
    end
    return 0
end

local function rememberSession(index, session)
    Adapter.SessionsByPlayerIndex[index] = session
    Adapter.Session = session
    Adapter.SessionOrder[#Adapter.SessionOrder + 1] = index
    while #Adapter.SessionOrder > Adapter.MAX_SESSIONS do
        local oldest = table.remove(Adapter.SessionOrder, 1)
        if oldest ~= index then Adapter.SessionsByPlayerIndex[oldest] = nil end
    end
    return session
end

local function clearStaged(index)
    Adapter.PendingEnvelopes[index] = nil
    if Customization.ClearLocalEnvelope then
        Customization.ClearLocalEnvelope()
    end
end

local function professionScreen(screen)
    if screen and screen.listboxTraitSelected then return screen end
    if screen and screen.professionScreen then return screen.professionScreen end
    if CoopCharacterCreation and CoopCharacterCreation.instance
        and CoopCharacterCreation.instance.charCreationProfession
    then
        return CoopCharacterCreation.instance.charCreationProfession
    end
    if MainScreen and MainScreen.instance then
        return MainScreen.instance.charCreationProfession
    end
    return nil
end

local function selectedTraitIDs(screen)
    local profession = professionScreen(screen)
    if not profession then return {}, nil end
    return Extension.ReadSelectedTraitIDs(profession), profession
end

local function isRemoteClient()
    if PNC.Core and PNC.Core.IsClientOnly then
        return PNC.Core.IsClientOnly() == true
    end
    return isClient and isClient()
        and (not isServer or not isServer()) or false
end

local function refreshSessionFromFinalScreen(screen, reason)
    local selected
    local profession
    local ids
    local session
    local result

    if screen and type(screen.initPlayer) == "function" then
        -- Vanilla keeps name/voice text-entry state in the final-screen
        -- widgets until initPlayer is called. Rebind before preview or
        -- pre-commit so surname changes are not one click behind.
        screen:initPlayer()
    end
    selected, profession = selectedTraitIDs(screen)
    ids = companionTraitIDs(selected)
    session = Adapter.GetSession(screen or profession)
    result = session:HandleCharacterCreationEvent({
        event = "final_screen_context",
        reason = reason or "final_screen",
        screen = screen or profession,
        selectedTraitIDs = selected,
        selectedCompanionTraitIDs = ids,
    })
    return session, selected, ids, result, profession
end

function Adapter.GetPlayerIndex(screen)
    return playerIndexFor(screen)
end

function Adapter.AttachSession(session)
    if session ~= nil
        and type(session.HandleCharacterCreationEvent) ~= "function"
    then
        return false, "invalid_session"
    end
    Adapter.Session = session
    if session then
        Adapter.SessionsByPlayerIndex[0] = session
    end
    return true
end

function Adapter.ResetSession(screenOrIndex)
    local index = type(screenOrIndex) == "number"
        and screenOrIndex or playerIndexFor(screenOrIndex)
    Adapter.SessionsByPlayerIndex[index] = nil
    Adapter.Session = nil
    clearStaged(index)
    return true
end

function Adapter.GetSession(screen)
    local index = playerIndexFor(screen)
    local session = Adapter.SessionsByPlayerIndex[index]
    if not session then
        session = PNC.StartingCompanionSession.New({
            playerIndex = index,
            seedText = "starting-companion-player:" .. tostring(index),
        })
        rememberSession(index, session)
    else
        Adapter.Session = session
    end
    return session
end

function Adapter.SetSession(screen, session)
    local index
    if session ~= nil
        and type(session.HandleCharacterCreationEvent) ~= "function"
    then
        return false, "invalid_session"
    end
    index = playerIndexFor(screen)
    if session then
        rememberSession(index, session)
    else
        Adapter.SessionsByPlayerIndex[index] = nil
        Adapter.Session = nil
    end
    return true
end

function Adapter.GetLastEvent()
    return Adapter.EventCache[#Adapter.EventCache]
end

function Adapter.CanOpenCompanions(screen)
    local selected = selectedTraitIDs(screen)
    return #companionTraitIDs(selected) > 0
end

function Adapter.UpdateFinalActionState(screen)
    local enabled = Adapter.CanOpenCompanions(screen)
    local button = screen and screen.pncStartingCompanionButton
    if button and type(button.setEnable) == "function" then
        button:setEnable(enabled)
    end
    return enabled
end

function Adapter.ReconcileFinalScreen(screen, reason)
    return refreshSessionFromFinalScreen(screen, reason)
end

function Adapter.OpenComposer(screen)
    local session
    local selected
    local companionIDs
    local reconciliation
    local UIState
    local window

    session, selected, companionIDs, reconciliation =
        refreshSessionFromFinalScreen(screen, "companions_open")
    if #companionIDs == 0 then return nil, "no_active_companions" end
    if not PsychopatzCore or not PsychopatzCore.UI then
        return nil, "ui_unavailable"
    end
    UIState = require
        "PNC/UI/StartingCompanions/PNC_StartingCompanionComposerWindow"
    if not UIState or type(UIState.Open) ~= "function" then
        return nil, "ui_unavailable"
    end
    window = UIState.Open(session)
    Adapter.LastOpen = {
        screen = screen,
        selectedTraitIDs = copyList(selected),
        companionTraitIDs = copyList(companionIDs),
        reconciliation = reconciliation,
        session = session,
        window = window,
    }
    return window
end

function Adapter.HandleEvent(screen, payload)
    local event = payload and payload.event or ""
    local index = playerIndexFor(screen)
    local session
    local snapshot
    local result

    if event == "screen_created" then
        Adapter.ResetSession(index)
        clearStaged(index)
    end
    session = Adapter.GetSession(screen)
    snapshot = {
        event = event,
        reason = payload and payload.reason or "",
        screen = screen,
        selectedTraitIDs = copyList(payload and payload.selectedTraitIDs),
        selectedCompanionTraitIDs = companionTraitIDs(
            payload and payload.selectedTraitIDs
        ),
    }
    cacheEvent(snapshot)
    result = session:HandleCharacterCreationEvent(snapshot)
    if event == "trait_set_changed"
        or event == "build_loaded"
        or event == "build_reset"
        or event == "randomized"
    then
        -- A staged envelope belongs to the exact selected-set/context snapshot
        -- that was pre-committed. Any later build mutation invalidates it.
        clearStaged(index)
    end
    -- screen_shown and screen_hidden only reconcile the session. Navigation
    -- is an explicit final-screen action, never a visibility side effect.
    return result
end

function Adapter.PreCommit(screen)
    local session
    local selected
    local companionIDs
    local reconciliation
    local index = playerIndexFor(screen)
    local authored
    local valid
    local reason
    local envelope
    local decoded
    local setResult

    session, selected, companionIDs, reconciliation =
        refreshSessionFromFinalScreen(screen, "character_creation_commit")
    authored = session:HasAuthoredIntent()
    clearStaged(index)
    Adapter.LastPreCommit = {
        screen = screen,
        selectedTraitIDs = copyList(selected),
        companionTraitIDs = copyList(companionIDs),
        reconciliation = reconciliation,
        authored = authored,
        staged = false,
    }
    if #companionIDs == 0 or not authored then
        Adapter.LastPreCommit.reason = "default"
        return true, "default"
    end

    valid, reason = session:ValidateActive()
    if not valid then
        Adapter.LastPreCommit.reason = reason
        return false, reason
    end
    envelope, reason = Customization.BuildEnvelope(session, companionIDs)
    if not envelope then
        Adapter.LastPreCommit.reason = reason
        return false, reason
    end
    decoded, reason = Customization.DecodeEnvelope(envelope)
    if not decoded then
        Adapter.LastPreCommit.reason = reason
        return false, reason
    end
    if isRemoteClient() then
        Adapter.PendingEnvelopes[index] = envelope
    else
        setResult, reason = Customization.SetLocalEnvelope(envelope)
        if not setResult then
            Adapter.LastPreCommit.reason = reason
            return false, reason
        end
        Adapter.PendingEnvelopes[index] = nil
    end
    Adapter.LastPreCommit.envelope = envelope
    Adapter.LastPreCommit.staged = true
    Adapter.LastPreCommit.reason = "staged"
    return true, "staged"
end

-- Keep the old public name as a semantic alias for integrations that already
-- called the adapter, but make it obey the final-screen pre-commit boundary.
function Adapter.Submit(screen)
    return Adapter.PreCommit(screen)
end

function Adapter.SubmitPending(playerIndex, player)
    local index = tonumber(playerIndex) or 0
    local envelope = Adapter.PendingEnvelopes[index]
    if not envelope or not isRemoteClient() then return false end
    player = player or (getSpecificPlayer and getSpecificPlayer(index) or nil)
    if not player or not sendClientCommand then return false end
    sendClientCommand(
        player,
        PNC.Const.MODULE,
        PNC.Const.CMD_STARTING_COMPANION_CUSTOMIZATION,
        envelope
    )
    Adapter.PendingEnvelopes[index] = nil
    return true
end

function Adapter.OnCreatePlayer(first, second)
    local index = type(first) == "number" and first or 0
    local player = second
    if not player and type(first) == "table" then player = first end
    return Adapter.SubmitPending(index, player)
end

Adapter.Provider = Adapter.Provider or {
    onEvent = function(screen, payload)
        return Adapter.HandleEvent(screen, payload)
    end,
}

Extension.Register(Adapter.PROVIDER_ID, Adapter.Provider)

if Events and Events.OnCreatePlayer and Events.OnCreatePlayer.Add then
    Events.OnCreatePlayer.Add(Adapter.OnCreatePlayer)
end

return Adapter
