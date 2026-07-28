--[[
    PNC Client Presence Sync
    Public facade, shared reconciliation state, and client event wiring.
]]

PNC = PNC or {}
PNC.ClientPresenceSync = PNC.ClientPresenceSync or {}

local Sync = PNC.ClientPresenceSync
local Interpolation = PNC.ClientInterpolation

Sync.BodyByID = Sync.BodyByID or {}
Sync.BodyByOnlineID = Sync.BodyByOnlineID or {}
Sync.BodyByInstanceID = Sync.BodyByInstanceID or {}
Sync.BodyByLease = Sync.BodyByLease or {}
Sync.FacingByID = Sync.FacingByID or {}
Sync.UnresolvedLogAtByID = Sync.UnresolvedLogAtByID or {}
Sync.MotionLogByID = Sync.MotionLogByID or {}
Sync.PrunedRevisionByID = Sync.PrunedRevisionByID or {}
Sync.Internal = Sync.Internal or {}
Sync.lastBodyScanAt = Sync.lastBodyScanAt or 0
Sync.lastLocalSnapshotBuildAt = Sync.lastLocalSnapshotBuildAt or 0

require "PNC/PresenceSync/PNC_ClientPresenceRuntime"
require "PNC/PresenceSync/PNC_ClientPresenceFacing"
require "PNC/PresenceSync/PNC_ClientPresenceVisuals"
require "PNC/PresenceSync/PNC_ClientPresenceBodies"
require "PNC/PresenceSync/PNC_ClientPresenceTick"

local function onResetLua()
    Sync.BodyByID = {}
    Sync.BodyByOnlineID = {}
    Sync.BodyByInstanceID = {}
    Sync.BodyByLease = {}
    Sync.FacingByID = {}
    Sync.UnresolvedLogAtByID = {}
    Sync.MotionLogByID = {}
    Sync.PrunedRevisionByID = {}
    Sync.lastBodyScanAt = 0
    if Interpolation and Interpolation.ClearAll then
        Interpolation.ClearAll()
    end
end

if Events and Events.OnTick then
    Events.OnTick.Add(Sync.OnTick)
end

if Events and Events.OnResetLua then
    Events.OnResetLua.Add(onResetLua)
end
