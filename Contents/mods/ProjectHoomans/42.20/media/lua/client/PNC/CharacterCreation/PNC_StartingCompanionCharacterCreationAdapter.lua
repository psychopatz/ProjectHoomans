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
Adapter.SessionOrder = Adapter.SessionOrder or {}
Adapter.EventCache = Adapter.EventCache or {}
Adapter.PendingEnvelopes = Adapter.PendingEnvelopes or {}

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
        id = CoreTraits.NormalizeID(
            selectedID, StartingTraits.OWNER
        )
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

function Adapter.AttachSession(session)
    if session ~= nil and type(session.HandleCharacterCreationEvent) ~= "function" then
        return false, "invalid_session"
    end
    Adapter.Session = session
    return true
end

local function rememberSession(screen, session)
    if not screen then
        Adapter.Session = session
        return session
    end
    Adapter.Sessions[screen] = session
    Adapter.SessionOrder[#Adapter.SessionOrder + 1] = screen
    while #Adapter.SessionOrder > Adapter.MAX_SESSIONS do
        local oldest = table.remove(Adapter.SessionOrder, 1)
        if oldest ~= screen then Adapter.Sessions[oldest] = nil end
    end
    return session
end

function Adapter.GetSession(screen)
    local session
    if screen and Adapter.Sessions[screen] then
        return Adapter.Sessions[screen]
    end
    if screen and Adapter.Session then
        session = Adapter.Session
        Adapter.Session = nil
        return rememberSession(screen, session)
    end
    if not screen and Adapter.Session then return Adapter.Session end
    session = PNC.StartingCompanionSession.New({ screen = screen })
    return rememberSession(screen, session)
end

function Adapter.SetSession(screen, session)
    if session ~= nil
        and type(session.HandleCharacterCreationEvent) ~= "function"
    then
        return false, "invalid_session"
    end
    if screen then
        if session then rememberSession(screen, session) end
    else
        Adapter.Session = session
    end
    return true
end

function Adapter.GetLastEvent()
    return Adapter.EventCache[#Adapter.EventCache]
end

function Adapter.OpenComposer(screen)
    local session = Adapter.GetSession(screen)
    local selected = session and session.GetActiveSlots
        and session:GetActiveSlots() or {}
    if #selected == 0 then return nil, "no_active_companions" end
    if not PsychopatzCore or not PsychopatzCore.UI
        or not PsychopatzWindow
    then
        return nil, "ui_unavailable"
    end
    local UIState = require
        "PNC/UI/StartingCompanions/PNC_StartingCompanionComposerWindow"
    return UIState.Open(session)
end

function Adapter.HandleEvent(screen, payload)
    local session = Adapter.GetSession(screen)
    local snapshot = {
        event = payload and payload.event or "",
        reason = payload and payload.reason or "",
        screen = screen,
        selectedTraitIDs = copyList(payload and payload.selectedTraitIDs),
        selectedCompanionTraitIDs = companionTraitIDs(
            payload and payload.selectedTraitIDs
        ),
    }
    cacheEvent(snapshot)
    if snapshot.event == "screen_created"
        and Customization.ClearLocalEnvelope
    then
        local index = tonumber(screen and screen.playerIndex)
        if index == nil
            and CoopCharacterCreation and CoopCharacterCreation.instance
            and CoopCharacterCreation.instance.charCreationProfession == screen
        then
            index = tonumber(CoopCharacterCreation.instance.playerIndex) or 0
        end
        Customization.ClearLocalEnvelope()
        Adapter.PendingEnvelopes[index or 0] = nil
    end
    local result = session:HandleCharacterCreationEvent(snapshot)
    if snapshot.event == "screen_shown" then
        Adapter.OpenComposer(screen)
    elseif snapshot.event == "screen_hidden" then
        -- The base profession seam is also used by the co-op profession
        -- screen.  Queue the latest selected-set snapshot here; final player
        -- identity and server trait state are still resolved authoritatively
        -- after OnCreatePlayer.
        Adapter.Submit(screen, { defer = true })
    end
    return result
end

local function isRemoteClient()
    if PNC.Core and PNC.Core.IsClientOnly then
        return PNC.Core.IsClientOnly() == true
    end
    return isClient and isClient()
        and (not isServer or not isServer()) or false
end

local function playerIndexFor(screen)
    if screen and screen.playerIndex ~= nil then
        return tonumber(screen.playerIndex) or 0
    end
    if CoopCharacterCreation and CoopCharacterCreation.instance
        and CoopCharacterCreation.instance.charCreationProfession == screen
    then
        return tonumber(CoopCharacterCreation.instance.playerIndex) or 0
    end
    return 0
end

local function professionScreen(screen)
    if screen and screen.listboxTraitSelected then return screen end
    if MainScreen and MainScreen.instance then
        return MainScreen.instance.charCreationProfession
    end
    return screen
end

function Adapter.Submit(screen, options)
    local profession = professionScreen(screen)
    local selected
    local companionIDs
    local session
    local envelope
    local reason
    local index
    local player
    options = type(options) == "table" and options or {}
    if not profession then return false, "profession_screen_unavailable" end
    selected = Extension.ReadSelectedTraitIDs(profession)
    companionIDs = companionTraitIDs(selected)
    session = Adapter.GetSession(profession)
    session:HandleCharacterCreationEvent({
        event = "submission",
        reason = "character_creation_commit",
        screen = profession,
        selectedTraitIDs = selected,
        selectedCompanionTraitIDs = companionIDs,
    })
    envelope, reason = Customization.BuildEnvelope(session, companionIDs)
    if not envelope then return false, reason end
    index = playerIndexFor(profession)
    Adapter.PendingEnvelopes[index] = envelope
    if not isRemoteClient() then
        return Customization.SetLocalEnvelope(envelope)
    end
    if options.defer == true then return true, "queued" end
    player = getSpecificPlayer and getSpecificPlayer(index) or nil
    if player and sendClientCommand then
        sendClientCommand(
            player,
            PNC.Const.MODULE,
            PNC.Const.CMD_STARTING_COMPANION_CUSTOMIZATION,
            envelope
        )
        Adapter.PendingEnvelopes[index] = nil
        return true, "sent"
    end
    return true, "queued"
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
