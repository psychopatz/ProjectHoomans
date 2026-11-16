require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"
require "PNC/CharacterCreation/PNC_StartingCompanionSession"

PNC = PNC or {}
PNC.StartingCompanionCharacterCreationAdapter =
    PNC.StartingCompanionCharacterCreationAdapter or {}

local Adapter = PNC.StartingCompanionCharacterCreationAdapter
local StartingTraits = PNC.StartingCompanionTraits
local Extension = PsychopatzCore.CharacterCreationExtension
local CoreTraits = PsychopatzCore.Traits

Adapter.PROVIDER_ID = "ProjectHoomans.StartingCompanions"
Adapter.MAX_CACHED_EVENTS = 8
Adapter.MAX_SESSIONS = 4
Adapter.Session = Adapter.Session or nil
Adapter.Sessions = Adapter.Sessions or {}
Adapter.SessionOrder = Adapter.SessionOrder or {}
Adapter.EventCache = Adapter.EventCache or {}

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
    local result = session:HandleCharacterCreationEvent(snapshot)
    if snapshot.event == "screen_shown" then
        Adapter.OpenComposer(screen)
    end
    return result
end

Adapter.Provider = Adapter.Provider or {
    onEvent = function(screen, payload)
        return Adapter.HandleEvent(screen, payload)
    end,
}

Extension.Register(Adapter.PROVIDER_ID, Adapter.Provider)

return Adapter
