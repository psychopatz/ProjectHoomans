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
    local state
    if not isSnapshotDebugEnabled(snapshot) or not Core or not Core.Log then
        return
    end
    id = tostring(id or "nil")
    now = Core.Now and Core.Now() or 0
    key = tostring(event or "unknown") .. "|" .. tostring(extra or "")
    state = Sync.MotionLogByID[id]
    if state and state.key == key
        and (now - (tonumber(state.at) or 0)) < 5000
    then
        return
    end
    Sync.MotionLogByID[id] = { key = key, at = now }
    Core.Log("DEBUG", "client_presence npc=" .. tostring(id or "nil") .. " event=" .. tostring(event or "unknown") .. (extra and extra ~= "" and (" " .. tostring(extra)) or ""))
end

Internal.IsWorldReady = isWorldReady
Internal.IsClientVisualReplicaMode = isClientVisualReplicaMode
Internal.CanRequestRemoteSync = canRequestRemoteSync
Internal.IsSnapshotDebugEnabled = isSnapshotDebugEnabled
Internal.LogClientMotionDebug = logClientMotionDebug
