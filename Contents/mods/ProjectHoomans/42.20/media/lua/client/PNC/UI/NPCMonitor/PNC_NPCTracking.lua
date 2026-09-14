-- Shared client-side NPC locate-marker tracking.

require "PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"
require "PNC/UI/NPCMonitor/PNC_NPCMonitorSupport"

PNC = PNC or {}
PNC.NPCTracking = PNC.NPCTracking or {}

local Tracking = PNC.NPCTracking
local ClientState = PNC.Network.ClientState
local Support = PNC.NPCMonitorSupport

local TRACK_MARKER_PREFIX = "pnc_npc_track:"
local TRACK_MARKER_DURATION = 86400
local MARKER_REFRESH_MS = 250

local function markerHandler()
    return PNC.EventMarkers
        or (PsychopatzCore and PsychopatzCore.EventMarkers) or nil
end

local function markerID(npcID)
    return TRACK_MARKER_PREFIX .. tostring(npcID or "")
end

local function markerStyle(item)
    local tacticalClass = tostring(item and item.tacticalClass or "")
    if tacticalClass == "hostile" then
        return "thief.png", { r = 1, g = 0.25, b = 0.2 }
    end
    if tacticalClass == "neutral" then
        return "crew.png", { r = 0.95, g = 0.75, b = 0.2 }
    end
    return "friend.png", { r = 0.15, g = 0.85, b = 1 }
end

local function copyTarget(target)
    local output = {}
    if type(target) ~= "table" then return output end
    for key, value in pairs(target) do output[key] = value end
    return output
end

local function normalTarget(npcID)
    for _, item in ipairs(ClientState.debugRoster or {}) do
        if tostring(item.id or "") == tostring(npcID or "") then
            return item
        end
    end
    return nil
end

local function uniqueTarget(npcID)
    local runtime
    for _, item in ipairs(
        ClientState.uniqueNPCDebug
            and ClientState.uniqueNPCDebug.entries or {}
    ) do
        runtime = item.runtime or {}
        if tostring(runtime.runtimeNpcId or item.runtimeNpcId or "")
            == tostring(npcID or "")
        then
            return {
                id = tostring(npcID),
                name = runtime.name or item.displayName or npcID,
                tacticalClass = runtime.tacticalClass or "neutral",
                presenceState = runtime.presenceState,
                bodyLease = runtime.bodyLease,
                x = runtime.x,
                y = runtime.y,
                z = runtime.z,
            }
        end
    end
    return nil
end

local function sourceTarget(npcID)
    return normalTarget(npcID) or uniqueTarget(npcID)
end

local function now()
    return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0
end

local function markerSet(id, icon, duration, x, y, color, description)
    local markers = markerHandler()
    local setMarker = markers and (markers.Set or markers.set) or nil
    if not setMarker then return nil end
    return setMarker(id, icon, duration, x, y, color, description)
end

local function markerRemove(id)
    local markers = markerHandler()
    local remove = markers and (markers.Remove or markers.remove) or nil
    if not remove then return false end
    return remove(id)
end

local function refreshTarget()
    local target = Tracking.target
    local fresh
    if not target or not Tracking.trackedId then return target end
    fresh = sourceTarget(Tracking.trackedId)
    if fresh then
        fresh.id = target.id
        fresh.markerIcon = target.markerIcon
        fresh.markerColor = target.markerColor
        Tracking.target = fresh
        return fresh
    end
    Tracking.Clear()
    return nil
end

function Tracking.Clear()
    if Tracking.trackedId then
        markerRemove(markerID(Tracking.trackedId))
    end
    Tracking.trackedId = nil
    Tracking.target = nil
    Tracking.trackSignature = nil
    Tracking.trackUpdatedAt = nil
    return true
end

function Tracking.GetTrackedID()
    return Tracking.trackedId
end

function Tracking.IsTracked(npcID)
    return Tracking.trackedId ~= nil
        and tostring(Tracking.trackedId) == tostring(npcID or "")
end

function Tracking.UpdateTarget(target)
    if type(target) ~= "table" or not target.id then return false end
    if not Tracking.IsTracked(target.id) then return false end
    Tracking.target = copyTarget(target)
    return true
end

function Tracking.Update(force)
    local target = refreshTarget()
    local markers
    local existing
    local body
    local x
    local y
    local z
    local timestamp
    local signature
    local icon
    local color
    if not Tracking.trackedId or not target then return false end
    markers = markerHandler()
    existing = markers and markers.markers
        and markers.markers[markerID(Tracking.trackedId)] or nil
    if existing and existing.getDuration and existing:getDuration() <= 0 then
        Tracking.Clear()
        return false
    end
    body = Support and Support.FindBody and Support.FindBody(target) or nil
    x = body and body.getX and body:getX() or tonumber(target.x)
    y = body and body.getY and body:getY() or tonumber(target.y)
    z = body and body.getZ and body:getZ() or tonumber(target.z) or 0
    if x == nil or y == nil then return false end
    timestamp = now()
    signature = string.format("%s:%.2f:%.2f:%.0f",
        tostring(Tracking.trackedId), x, y, z)
    if force ~= true then
        if signature == Tracking.trackSignature then return true end
        if timestamp - (tonumber(Tracking.trackUpdatedAt) or 0)
            < MARKER_REFRESH_MS
        then
            return true
        end
    end
    icon, color = markerStyle(target)
    markerSet(
        markerID(Tracking.trackedId),
        target.markerIcon or icon,
        TRACK_MARKER_DURATION,
        x,
        y,
        target.markerColor or color,
        tostring(target.name or target.id)
    )
    Tracking.trackSignature = signature
    Tracking.trackUpdatedAt = timestamp
    return true
end

function Tracking.Track(target)
    local id = target and target.id
    if not id then return false end
    Tracking.Clear()
    Tracking.trackedId = tostring(id)
    Tracking.target = copyTarget(target)
    return Tracking.Update(true)
end

return Tracking
