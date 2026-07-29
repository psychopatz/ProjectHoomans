--[[
    PNC Client Presence Runtime
    Owns replica-mode policy and deduplicated client diagnostics.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}
PNC.ClientPresenceSync.Internal =
    PNC.ClientPresenceSync.Internal or {}

local Sync = PNC.ClientPresenceSync
local Internal = Sync.Internal
local Core = PNC.Core

local function isWorldReady()
    return (not isIngameState) or isIngameState()
end

local function isClientVisualReplicaMode()
    return Core and Core.IsClientOnly and Core.IsClientOnly()
end

local function canRequestRemoteSync()
    return isClientVisualReplicaMode()
end

local function isSnapshotDebugEnabled(snapshot)
    if snapshot and snapshot.debugState and snapshot.debugState.debugEnabled == true then
        return true
    end
    return false
end

local function logClientMotionDebug(snapshot, id, event, extra)
    local now
    local key
    local eventKey
    local state
    local states
    if not isSnapshotDebugEnabled(snapshot) or not Core or not Core.Log then
        return
    end
    id = tostring(id or "nil")
    now = Core.Now and Core.Now() or 0
    eventKey = tostring(event or "unknown")
    key = eventKey .. "|" .. tostring(extra or "")
    states = Sync.MotionLogByID[id]
    if type(states) ~= "table" or states.key ~= nil then
        states = {}
        Sync.MotionLogByID[id] = states
    end
    state = states[eventKey]
    if state then
        local elapsed = now - (tonumber(state.at) or 0)
        if elapsed < 1500
            or (state.key == key and elapsed < 5000)
        then
            return
        end
    end
    states[eventKey] = { key = key, at = now }
    Core.Log("DEBUG", "client_presence npc=" .. tostring(id or "nil") .. " event=" .. tostring(event or "unknown") .. (extra and extra ~= "" and (" " .. tostring(extra)) or ""))
end

Internal.IsWorldReady = isWorldReady
Internal.IsClientVisualReplicaMode = isClientVisualReplicaMode
Internal.CanRequestRemoteSync = canRequestRemoteSync
Internal.IsSnapshotDebugEnabled = isSnapshotDebugEnabled
Internal.LogClientMotionDebug = logClientMotionDebug
