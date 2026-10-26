-- Client-local, presentation-only daily What's Up suppression state.
--
-- This is deliberately not conversation history, semantic memory, ModData,
-- or network state. It only controls which already-valid hub rows are shown
-- to this player for this NPC during the current world day.
PNC = PNC or {}
PNC.Semantics = PNC.Semantics or {}

local State = {}
local HUB_ID = "whats_up"
local MAX_NPC_ENTRIES = 128

local function clientState()
    return PNC.Network and PNC.Network.ClientState or nil
end

local function store()
    local state = clientState()
    if not state then return nil end
    state.semanticHubPresentation = state.semanticHubPresentation or {}
    return state.semanticHubPresentation
end

local function worldAgeHours(context)
    local world = type(context) == "table"
        and context.worldContext or nil
    local hours = world and world.worldAgeHours or nil
    if hours ~= nil then return tonumber(hours) or 0 end

    local gameTime = type(getGameTime) == "function"
        and getGameTime() or nil
    if gameTime and type(gameTime.getWorldAgeHours) == "function" then
        local ok, value = pcall(gameTime.getWorldAgeHours, gameTime)
        if ok then return tonumber(value) or 0 end
    end
    return 0
end

function State.DayIndex(context)
    local world = type(context) == "table"
        and context.worldContext or nil
    local gameDay = world and tonumber(world.gameDay) or nil
    if gameDay ~= nil then return math.floor(gameDay) end
    return math.floor(math.max(0, worldAgeHours(context)) / 24)
end

local function npcIDFrom(context, view)
    local id = type(context) == "table" and context.npcID or nil
    local actor = type(context) == "table"
        and context.actorConversationContext or nil
    if id == nil and type(actor) == "table" then
        id = actor.npcID or actor.id
    end
    if id == nil and type(context) == "table" then
        local entry = context.entry
        id = type(entry) == "table" and (entry.id or entry.npcID) or nil
    end
    if id == nil and view and view.spec then id = view.spec.npcID end
    id = tostring(id or "")
    return id ~= "" and id or nil
end

local function entryFor(npcID, dayIndex, create)
    local entries = store()
    if not entries or not npcID then return nil end
    local entry = entries[npcID]
    if type(entry) == "table"
        and tonumber(entry.dayIndex) ~= dayIndex
    then
        entries[npcID] = nil
        entry = nil
    end
    if not entry and create ~= true then return nil end
    if not entry then
        entry = {
            dayIndex = dayIndex,
            suppressedChoices = {},
        }
        entries[npcID] = entry
    elseif type(entry.suppressedChoices) ~= "table" then
        entry.suppressedChoices = {}
    end
    local state = clientState()
    if state then
        state.semanticHubPresentationSerial =
            (tonumber(state.semanticHubPresentationSerial) or 0) + 1
        entry.lastAccess = state.semanticHubPresentationSerial
        local count = 0
        local oldestID
        local oldestAccess
        for id, candidateEntry in pairs(entries) do
            count = count + 1
            local access = tonumber(candidateEntry.lastAccess) or 0
            if oldestAccess == nil or access < oldestAccess then
                oldestID = id
                oldestAccess = access
            end
        end
        if count > MAX_NPC_ENTRIES and oldestID then
            entries[oldestID] = nil
        end
    end
    return entry
end

function State.Snapshot(context, view)
    local dayIndex = State.DayIndex(context)
    local npcID = npcIDFrom(context, view)
    local entry = entryFor(npcID, dayIndex, false)
    local suppressed = {}
    if entry then
        for candidateID, used in pairs(entry.suppressedChoices) do
            if used == true then suppressed[candidateID] = true end
        end
    end
    return {
        dayIndex = dayIndex,
        suppressedChoices = suppressed,
    }
end

function State.AttachContext(context, view)
    context = type(context) == "table" and context or {}
    context.semanticHubPresentation = State.Snapshot(context, view)
    return context
end

function State.Mark(view, context, frame)
    if view and view.groupConversation then return false end
    if type(frame) ~= "table" or type(frame.extensions) ~= "table" then
        return false
    end
    local extensions = frame.extensions
    if tostring(extensions.hubID or "") ~= HUB_ID
        or extensions.hubAvenue ~= true
    then
        return false
    end
    local candidateID = tostring(frame.candidateID or "")
    if candidateID == "" then return false end

    context = type(context) == "table" and context or {}
    local npcID = npcIDFrom(context, view)
    local entry = entryFor(npcID, State.DayIndex(context), true)
    if not entry then return false end
    entry.suppressedChoices[candidateID] = true
    return true
end

function State.Reset()
    local state = clientState()
    if state then state.semanticHubPresentation = {} end
end

PNC.Semantics.SemanticHubPresentationState = State
return State
