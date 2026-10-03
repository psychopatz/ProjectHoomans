-- Client voice death, explicit emit, and reset provider.

PNC = PNC or {}
PNC.NPCVoice = PNC.NPCVoice or {}
PNC.NPCVoice.Triggers = PNC.NPCVoice.Triggers or {}
local Voice = PNC.NPCVoice
local Catalog = Voice.Catalog
local Triggers = Voice.Triggers
local Internal = Triggers.Internal or {}
Triggers.Internal = Internal
local isServerRuntime = Internal.IsServerRuntime
local nowMillis = Internal.NowMillis
local stateFor = Internal.StateFor
local playEvent = Internal.PlayEvent
local passesChance = Internal.PassesChance

local function resolveBodyForID(id)
    local sync = PNC.ClientPresenceSync
    local body
    local cell
    local zombieList
    local i
    local candidate
    local modData
    if sync and sync.BodyByID then
        body = sync.BodyByID[tostring(id)]
        if body and body ~= false then return body end
    end
    if not getCell then return nil end
    cell = getCell()
    zombieList = cell and cell.getZombieList and cell:getZombieList() or nil
    if not zombieList then return nil end
    for i = 0, zombieList:size() - 1 do
        candidate = zombieList:get(i)
        modData = candidate and candidate.getModData
            and candidate:getModData() or nil
        if modData and modData.PNC_NPC == true
            and tostring(modData.PNC_UUID or "") == tostring(id)
        then
            return candidate
        end
    end
    return nil
end

function Triggers.ObserveDeath(snapshot, body, now)
    local state
    local previous
    local clientState
    local previousSnapshot
    if isServerRuntime() or type(snapshot) ~= "table" then
        return false
    end
    body = body or resolveBodyForID(snapshot.id)
    clientState = PNC.Network and PNC.Network.ClientState or nil
    previousSnapshot = clientState and clientState.snapshots
        and clientState.snapshots[tostring(snapshot.id or "")] or nil
    previous = previousSnapshot
    if previous then
        -- Death-marker snapshots are intentionally compact. Reuse identity
        -- fields from the last live snapshot so position-only playback still
        -- selects the NPC's established voice profile.
        if snapshot.identitySeed == nil then
            snapshot.identitySeed = previous.identitySeed
        end
        if snapshot.isFemale == nil then
            snapshot.isFemale = previous.isFemale
        end
        if snapshot.identity == nil then
            snapshot.identity = previous.identity
        end
    end
    state = stateFor(snapshot, body)
    if state and state.terminalPlayed then
        return false
    end
    if playEvent(snapshot, body, "death.alone", nowMillis(now)) then
        if state then
            state.terminalPlayed = true
            state.lastAlive = false
            state.lastDeathAt = nowMillis(now)
        end
        return true
    end
    return false
end

function Triggers.Emit(body, eventID, snapshot, options)
    local policy
    local now
    local occurrenceKey
    if isServerRuntime() or not body then return false end
    policy = Catalog and Catalog.Get and Catalog.Get(eventID) or nil
    if not policy then return false end
    options = options or {}
    now = nowMillis(options.now)
    occurrenceKey = options.occurrenceKey
        or tostring(eventID) .. ":" .. tostring(now)
    if not passesChance(snapshot, body, occurrenceKey, policy) then
        return false
    end
    return playEvent(snapshot, body, eventID, now)
end

function Triggers.Reset()
    if Internal.ResetState then Internal.ResetState() end
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(Triggers.Reset)
end

return Triggers
