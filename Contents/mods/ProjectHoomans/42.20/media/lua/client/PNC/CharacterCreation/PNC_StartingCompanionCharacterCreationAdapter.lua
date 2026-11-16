require "PNC/Core/Traits/PNC_StartingCompanionTraits"
require "PsychopatzCore/Traits/PsychopatzTraitCharacterCreation"

PNC = PNC or {}
PNC.StartingCompanionCharacterCreationAdapter =
    PNC.StartingCompanionCharacterCreationAdapter or {}

local Adapter = PNC.StartingCompanionCharacterCreationAdapter
local StartingTraits = PNC.StartingCompanionTraits
local Extension = PsychopatzCore.CharacterCreationExtension
local CoreTraits = PsychopatzCore.Traits

Adapter.PROVIDER_ID = "ProjectHoomans.StartingCompanions"
Adapter.MAX_CACHED_EVENTS = 8
Adapter.Session = Adapter.Session or nil
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

function Adapter.GetLastEvent()
    return Adapter.EventCache[#Adapter.EventCache]
end

function Adapter.HandleEvent(screen, payload)
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
    if Adapter.Session then
        return Adapter.Session:HandleCharacterCreationEvent(snapshot)
    end
    return true
end

Adapter.Provider = Adapter.Provider or {
    onEvent = function(screen, payload)
        return Adapter.HandleEvent(screen, payload)
    end,
}

Extension.Register(Adapter.PROVIDER_ID, Adapter.Provider)

return Adapter
