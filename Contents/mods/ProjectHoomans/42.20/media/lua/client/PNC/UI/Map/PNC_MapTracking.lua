-- Client-side state for the player's home-base navigation marker.

require "PsychopatzCore/EventMarkers/PsychopatzEventMarkerHandler"

PNC = PNC or {}
PNC.MapTracking = PNC.MapTracking or {}

local Tracking = PNC.MapTracking
local Target = require "PNC/UI/Map/PNC_MapTrackingTarget"
local MARKER_ID = "pnc_base_track"
local MARKER_ICON = "tent.png"
local MARKER_DURATION = 86400
local MARKER_REFRESH_MS = 250
local ARRIVAL_DISTANCE = 10

Tracking.MarkerID = MARKER_ID
Tracking.ArrivalDistance = ARRIVAL_DISTANCE
Tracking.BaseTracked = Tracking.BaseTracked == true
Tracking.markerCreated = Tracking.markerCreated == true
Tracking.lastMarkerUpdateAt = Tracking.lastMarkerUpdateAt
Tracking.cachedSnapshotSignature = Tracking.cachedSnapshotSignature
Tracking.cachedTarget = Tracking.cachedTarget
Tracking.lastSnapshotRequestAt = Tracking.lastSnapshotRequestAt

local function now()
    if PNC.Core and type(PNC.Core.Now) == "function" then
        return tonumber(PNC.Core.Now()) or 0
    end
    if getTimestampMs then return tonumber(getTimestampMs()) or 0 end
    return 0
end

local function markerHandler()
    return PNC.EventMarkers
        or (PsychopatzCore and PsychopatzCore.EventMarkers) or nil
end

local function markerSet(markerID, icon, duration, x, y, color, desc)
    local markers = markerHandler()
    local setMarker = markers and (markers.Set or markers.set) or nil
    if not setMarker then return nil end
    return setMarker(markerID, icon, duration, x, y, color, desc)
end

local function markerRemove(markerID)
    local markers = markerHandler()
    local remove = markers and (markers.Remove or markers.remove) or nil
    if not remove then return false end
    return remove(markerID)
end

local function markerDescription()
    local key = "UI_PNC_MapTrack_Marker"
    local value = getText and getText(key) or nil
    if value and value ~= "" and value ~= key then return value end
    return key
end

local function readSnapshot()
    local client = PNC.ColonyManagementClient
    if client and type(client.ReadSnapshot) == "function" then
        local update = client.ReadSnapshot()
        if type(update) == "table" then
            return update.snapshot or {}, update.revision
        end
    end

    local network = PNC.Network
    local state = network and network.ClientState or nil
    return state and state.colonyManagement or {},
        state and state.colonyManagementRevision or 0
end

local function requestSnapshot(force)
    local timestamp = now()
    if not force and timestamp > 0
        and timestamp - (tonumber(Tracking.lastSnapshotRequestAt) or 0) < 1000
    then
        return false
    end
    Tracking.lastSnapshotRequestAt = timestamp

    local client = PNC.ColonyManagementClient
    if client and type(client.RequestSnapshot) == "function" then
        return client.RequestSnapshot()
    end
    if PNC.Client and type(PNC.Client.RequestColonyManagement) == "function" then
        return PNC.Client.RequestColonyManagement()
    end
    return false
end

function Tracking.GetBaseTarget()
    local snapshot, revision = readSnapshot()
    local settlement = type(snapshot) == "table" and snapshot.settlement or nil
    local geometry = settlement and settlement.geometry or nil
    local signature = tostring(revision or "") .. ":"
        .. tostring(settlement and settlement.id or "") .. ":"
        .. tostring(settlement and settlement.revision or "") .. ":"
        .. tostring(geometry and geometry.revision or "") .. ":"
        .. tostring(geometry and geometry.region or "") .. ":"
        .. tostring(geometry and geometry.bounds or "")

    if Tracking.cachedSnapshotSignature ~= signature then
        Tracking.cachedSnapshotSignature = signature
        Tracking.cachedTarget = Target.FromSettlement(settlement)
    end
    return Tracking.cachedTarget
end

function Tracking.HasBase()
    return Tracking.GetBaseTarget() ~= nil
end

function Tracking.IsBaseTracked()
    return Tracking.BaseTracked == true
end

local function distanceTo(player, target)
    if not player or not target or type(player.getX) ~= "function"
        or type(player.getY) ~= "function"
    then
        return nil
    end
    local x, y = player:getX(), player:getY()
    if IsoUtils and IsoUtils.DistanceTo then
        return IsoUtils.DistanceTo(target.x, target.y, x, y)
    end
    local dx, dy = target.x - x, target.y - y
    return math.sqrt(dx * dx + dy * dy)
end

function Tracking.ClearBase()
    markerRemove(MARKER_ID)
    Tracking.BaseTracked = false
    Tracking.markerCreated = false
    Tracking.lastMarkerUpdateAt = nil
    if Tracking.instance and Tracking.instance.syncButtons then
        Tracking.instance:syncButtons()
    end
    return true
end

local function updateMarker(target, force)
    local timestamp = now()
    if not force and timestamp > 0
        and timestamp - (tonumber(Tracking.lastMarkerUpdateAt) or 0)
            < MARKER_REFRESH_MS
    then
        return true
    end

    local marker = markerSet(
        MARKER_ID,
        MARKER_ICON,
        MARKER_DURATION,
        target.x,
        target.y,
        { r = 0.20, g = 1.00, b = 0.35 },
        markerDescription()
    )
    if not marker then return false end
    Tracking.markerCreated = true
    Tracking.lastMarkerUpdateAt = timestamp
    return true
end

function Tracking.UpdateBaseMarker(force)
    if not Tracking.BaseTracked then return false end

    local target = Tracking.GetBaseTarget()
    if not target then
        Tracking.ClearBase()
        return false
    end

    local markers = markerHandler()
    local existing = markers and markers.markers
        and markers.markers[MARKER_ID] or nil
    if Tracking.markerCreated and not existing then
        Tracking.ClearBase()
        return false
    end
    if existing and existing.getDuration
        and existing:getDuration() <= 0
    then
        Tracking.ClearBase()
        return false
    end

    local player = getSpecificPlayer and getSpecificPlayer(0) or nil
    local distance = distanceTo(player, target)
    if distance and distance <= ARRIVAL_DISTANCE then
        Tracking.ClearBase()
        return false
    end
    return updateMarker(target, force)
end

function Tracking.ToggleBase()
    if Tracking.BaseTracked then
        Tracking.ClearBase()
        return false
    end

    local target = Tracking.GetBaseTarget()
    if not target then
        requestSnapshot(true)
        return false
    end

    Tracking.BaseTracked = true
    Tracking.markerCreated = false
    Tracking.lastMarkerUpdateAt = nil
    if not Tracking.UpdateBaseMarker(true) then
        Tracking.ClearBase()
        return false
    end
    return true
end

local function updateTracking()
    Tracking.UpdateBaseMarker(false)
end

local function onResetLua()
    if type(Tracking.Close) == "function" then Tracking.Close() end
    Tracking.ClearBase()
    Tracking.cachedSnapshotSignature = nil
    Tracking.cachedTarget = nil
end

if Events and Events.OnResetLua and not Tracking.resetHookRegistered then
    Events.OnResetLua.Add(onResetLua)
    Tracking.resetHookRegistered = true
end
if Events and Events.OnTick and not Tracking.tickHookRegistered then
    Events.OnTick.Add(updateTracking)
    Tracking.tickHookRegistered = true
end

return Tracking
