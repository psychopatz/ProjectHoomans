local BodyBinding = require "PNC/PresenceSync/PNC_MultiplayerBodyBinding_Runtime"
--[[
    PNC Client Roster Commands
    Applies roster synchronization, record deltas, and removal commands.
]]

PNC = PNC or {}
PNC.Client = PNC.Client or {}
PNC.Client.Internal = PNC.Client.Internal or {}

local Client = PNC.Client
local Internal = Client.Internal
local Const = PNC.Const
local ClientState = PNC.Network.ClientState
local Network = PNC.Network
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function normalizeSnapshotID(value)
    local valueType = type(value)
    local normalized
    if valueType ~= "string" and valueType ~= "number" then
        return nil
    end
    normalized = tostring(value)
    if normalized == "" then return nil end
    return normalized
end

local function isSnapshotRecord(snapshot)
    local visualState
    if type(snapshot) ~= "table"
        or normalizeSnapshotID(snapshot.id) == nil
    then
        return false
    end
    visualState = snapshot.visualState
    return visualState == nil
        or visualState == false
        or type(visualState) == "table"
end

local function refreshClientBodyIdentityIndex()
    if Network and Network.RefreshClientBodyIdentityIndex then
        Network.RefreshClientBodyIdentityIndex()
    end
end

local function clearPendingRoster()
    ClientState.pendingRoster = nil
    ClientState.pendingRosterRevision = nil
    ClientState.pendingRosterExpectedChunks = nil
    ClientState.pendingRosterExpectedTotal = nil
    ClientState.pendingRosterSyncID = nil
    ClientState.pendingRosterPortraitProtocol = nil
    ClientState.pendingRosterChunks = nil
    ClientState.pendingRosterChunkRecords = nil
    ClientState.pendingRosterReceivedTotal = nil
end

local function rosterSyncID(args)
    return args and (args.syncID or args.requestID) or nil
end

local function requestRosterRetry()
    clearPendingRoster()
    if Client.RequestFullSync then
        Client.RequestFullSync()
    end
end

local function logClientPresenceTransition(current, incoming, eventName)
    local fromState
    local toState
    local orderKind
    if not Diagnostics
        or not Diagnostics.IsFollowerPresenceAuditEnabled
        or Diagnostics.IsFollowerPresenceAuditEnabled() ~= true
        or not Diagnostics.LogFollowerPresence
        or type(current) ~= "table"
        or type(incoming) ~= "table"
    then
        return
    end
    fromState = current.presenceState
    toState = incoming.presenceState
    if fromState == nil or toState == nil or fromState == toState then
        return
    end
    orderKind = incoming.orderKind or current.orderKind
    if tostring(orderKind or "") ~= tostring(Const.ORDER_FOLLOW or "follow") then
        return
    end
    Diagnostics.LogFollowerPresence("client_presence_transition", {
        "npc=" .. tostring(incoming.id or current.id),
        "source=client",
        "event=" .. tostring(eventName or "snapshot"),
        "from=" .. tostring(fromState),
        "to=" .. tostring(toState),
        "order=" .. tostring(orderKind),
        "owner=" .. tostring(incoming.ownerUsername
            or current.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(incoming.ownerOnlineID
            or current.ownerOnlineID or "nil"),
        "position=" .. tostring(incoming.x or current.x)
            .. "," .. tostring(incoming.y or current.y)
            .. "," .. tostring(incoming.z or current.z),
        "presenceRevision=" .. tostring(incoming.presenceRevision or "nil"),
    })
end

local function logClientPresencePosition(current, incoming, eventName)
    local orderKind
    local oldX
    local oldY
    local newX
    local newY
    if not Diagnostics
        or not Diagnostics.IsFollowerPresenceAuditEnabled
        or Diagnostics.IsFollowerPresenceAuditEnabled() ~= true
        or not Diagnostics.LogFollowerPresence
        or type(incoming) ~= "table"
    then
        return
    end
    orderKind = incoming.orderKind
        or type(current) == "table" and current.orderKind or nil
    if tostring(orderKind or "") ~= tostring(Const.ORDER_FOLLOW or "follow")
    then
        return
    end
    oldX = type(current) == "table" and tonumber(current.x) or nil
    oldY = type(current) == "table" and tonumber(current.y) or nil
    newX = tonumber(incoming.x)
    newY = tonumber(incoming.y)
    if newX == nil or newY == nil
        or oldX == nil or oldY == nil
        or oldX == newX and oldY == newY
    then
        return
    end
    Diagnostics.LogFollowerPresence("client_presence_position", {
        "npc=" .. tostring(incoming.id or ""),
        "source=client",
        "event=" .. tostring(eventName or "snapshot"),
        "from=" .. tostring(oldX) .. "," .. tostring(oldY),
        "to=" .. tostring(newX) .. "," .. tostring(newY),
        "presence=" .. tostring(incoming.presenceState or "nil"),
        "owner=" .. tostring(incoming.ownerUsername or "nil"),
    })
end

local function logClientPresenceRemoval(current, id, reason, eventName)
    if not Diagnostics
        or Diagnostics.FollowerPresenceAuditEnabled ~= true
        or not Diagnostics.LogFollowerPresence
        or type(current) ~= "table"
        or current.presenceState ~= Const.PRESENCE_LIVE
        or tostring(current.orderKind or "") ~= tostring(
            Const.ORDER_FOLLOW or "follow"
        )
    then
        return
    end
    Diagnostics.LogFollowerPresence("client_presence_removed", {
        "npc=" .. tostring(id),
        "source=client",
        "event=" .. tostring(eventName or "remove_record"),
        "from=" .. tostring(current.presenceState),
        "to=abstract_or_unavailable",
        "reason=" .. tostring(reason or "unknown"),
        "order=" .. tostring(current.orderKind),
        "owner=" .. tostring(current.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(current.ownerOnlineID or "nil"),
    })
end

local function compareIncarnationStrings(currentInc, incomingInc)
    if type(currentInc) ~= "string" or type(incomingInc) ~= "string"
        or currentInc == incomingInc
    then
        return 0
    end
    local curPrefix, curEpoch, curSerial =
        string.match(currentInc, "^(.-)(%d+):(%d+)$")
    local incPrefix, incEpoch, incSerial =
        string.match(incomingInc, "^(.-)(%d+):(%d+)$")
    if curEpoch and incEpoch and curPrefix == incPrefix then
        if tonumber(curEpoch) ~= tonumber(incEpoch) then
            return tonumber(incEpoch) > tonumber(curEpoch) and 1 or -1
        end
        return tonumber(incSerial) > tonumber(curSerial) and 1 or -1
    end
    return -1
end

local function compareLifetimes(current, incoming)
    if type(current) ~= "table" or type(incoming) ~= "table" then
        return 0
    end
    return compareIncarnationStrings(current.incarnation, incoming.incarnation)
end

local function isStaleSnapshot(current, incoming)
    local currentSequence
    local incomingSequence
    local currentPresenceRevision
    local incomingPresenceRevision
    if type(current) ~= "table" or type(incoming) ~= "table" then
        return false
    end
    local lifetimeOrder = compareLifetimes(current.portraitRef, incoming.portraitRef)
    if lifetimeOrder ~= 0 then return lifetimeOrder < 0 end
    currentSequence = tonumber(current.replicaSequence)
    incomingSequence = tonumber(incoming.replicaSequence)
    if currentSequence ~= nil then
        return incomingSequence == nil or incomingSequence < currentSequence
    end
    currentPresenceRevision = tonumber(current.presenceRevision)
    incomingPresenceRevision = tonumber(incoming.presenceRevision)
    if currentPresenceRevision ~= nil then
        return incomingPresenceRevision == nil
            or incomingPresenceRevision < currentPresenceRevision
    end
    if incomingSequence ~= nil or incomingPresenceRevision ~= nil then
        return false
    end
    return false
end

local function mergeSnapshot(current, incoming)
    local key
    if type(current) ~= "table" then
        return incoming
    end
    -- Periodic roster deltas in singleplayer/same-cell carry interestDetailed = false
    -- so they don't overwrite a live detailed local snapshot into rebuilding full
    -- snapshots on every client tick.
    local preserveDetailed = current.interestDetailed == true
        and type(incoming) == "table"
        and incoming.interestDetailed == false
        and incoming.deathMarker ~= true
        and (incoming.presenceState == nil or incoming.presenceState == current.presenceState)
    if type(incoming) == "table"
        and type(incoming.travel) == "table"
        and incoming.travel.route == nil
        and type(current.travel) == "table"
        and current.travel.route ~= nil
    then
        incoming.travel.route = current.travel.route
    end
    for key, _ in pairs(incoming or {}) do
        current[key] = incoming[key]
    end
    if preserveDetailed then
        current.interestDetailed = true
    end
    return current
end

local function ensureTrackedDomains(id, incarnation)
    ClientState.domainRevisions = ClientState.domainRevisions or {}
    local tracked = ClientState.domainRevisions[id]
    if not tracked then
        tracked = { incarnation = incarnation, domains = {} }
        ClientState.domainRevisions[id] = tracked
    elseif not tracked.incarnation and incarnation then
        tracked.incarnation = incarnation
    end
    return tracked
end

local function isSupportedDelta(deltaKind, protocol)
    if deltaKind == nil or deltaKind == "full" then
        return true
    end
    local supported = (Network and Network.SUPPORTED_DELTA_KINDS) or {
        presence = true,
        combat_damage = true,
        combat_state = true,
        health_wounds = true,
        equipment = true,
        full = true,
    }
    if not supported[deltaKind] then
        return false
    end
    if protocol ~= nil
        and Const.DOMAIN_DELTA_PROTOCOL ~= nil
        and tonumber(protocol) ~= tonumber(Const.DOMAIN_DELTA_PROTOCOL)
    then
        return false
    end
    return true
end

local function storeSnapshot(
    incoming,
    replace,
    suppressIdentityRefresh,
    eventName
)
    local id
    local current
    if not isSnapshotRecord(incoming) then
        return nil
    end
    id = normalizeSnapshotID(incoming.id)
    current = ClientState.snapshots[id]

    local deltaKind = incoming.deltaKind ~= nil
        and tostring(incoming.deltaKind) or nil
    if not isSupportedDelta(deltaKind, incoming.deltaProtocol) then
        ClientState.unsupportedDeltas =
            (tonumber(ClientState.unsupportedDeltas) or 0) + 1
        if Client.RequestRecordRepair then
            Client.RequestRecordRepair(id, "unsupported_delta", {
                deltaKind = deltaKind,
            })
        end
        return current
    end

    ClientState.domainRevisions = ClientState.domainRevisions or {}
    local tracked = ClientState.domainRevisions[id]
    if tracked and tracked.incarnation and incoming.replicaIncarnation
        and tracked.incarnation ~= incoming.replicaIncarnation
    then
        local order = compareIncarnationStrings(
            tracked.incarnation,
            incoming.replicaIncarnation
        )
        if deltaKind == "full" or replace == true then
            if order < 0 and replace ~= true then
                return current
            end
        elseif order > 0 then
            if Client.RequestRecordRepair then
                Client.RequestRecordRepair(id, "incarnation_mismatch", {
                    deltaKind = deltaKind,
                })
            end
            return current
        else
            return current
        end
    end

    if current and type(incoming.portraitRef) == "table"
        and type(current.portraitRef) == "table"
        and current.portraitRef.incarnation == incoming.portraitRef.incarnation
    then
        local previous = tonumber(current.portraitRef.revision) or 0
        local updated = tonumber(incoming.portraitRef.revision) or 0
        if updated < previous then
            incoming.portraitRef = current.portraitRef
        elseif updated > previous then
            current.portraitRef = incoming.portraitRef
            current.portrait = nil
        end
    end
    if incoming.deathMarker ~= true
        and isStaleSnapshot(current, incoming)
    then
        return current
    end

    if deltaKind ~= nil and deltaKind ~= "full" then
        if current == nil
            and deltaKind ~= "presence"
            and incoming.deathMarker ~= true
        then
            if Client.RequestRecordRepair then
                Client.RequestRecordRepair(id, "missing_baseline", {
                    deltaKind = deltaKind,
                })
            end
        end
        local incomingRev = tonumber(incoming.domainRevision)
        if incomingRev ~= nil then
            tracked = ensureTrackedDomains(id, incoming.replicaIncarnation)
            local lastRev = tonumber(tracked.domains[deltaKind]) or 0
            if incomingRev <= lastRev then
                return current
            end
            local baseRev = tonumber(incoming.baseDomainRevision)
            if baseRev ~= nil and lastRev > 0 and baseRev > lastRev then
                ClientState.revisionGapsDetected =
                    (tonumber(ClientState.revisionGapsDetected) or 0) + 1
                if Client.RequestRecordRepair then
                    Client.RequestRecordRepair(id, "gap_repair", {
                        deltaKind = deltaKind,
                        expectedRevision = lastRev + 1,
                        receivedRevision = incomingRev,
                    })
                end
            end
            tracked.domains[deltaKind] = incomingRev
        end
    end

    if current and type(current.portraitRef) == "table"
        and type(incoming.portraitRef) == "table"
        and current.portraitRef.incarnation ~= incoming.portraitRef.incarnation
    then
        BodyBinding.Forget(id)
        if PNC.Client.ForgetRosterPortrait then PNC.Client.ForgetRosterPortrait(id) end
        if ClientState.characterPayloads then ClientState.characterPayloads[id] = nil end
        replace = true
    end
    if incoming.portraitRef then
        incoming.portrait = nil
        if current then current.portrait = nil end
    end
    BodyBinding.AcceptSnapshot(incoming)
    if Diagnostics and Diagnostics.FollowerPresenceAuditEnabled == true then
        logClientPresenceTransition(current, incoming, eventName)
        logClientPresencePosition(current, incoming, eventName)
    end
    if deltaKind == "full" or replace == true or incoming.deathMarker == true then
        if incoming.deathMarker == true then
            ClientState.domainRevisions[id] = nil
        else
            local nextDomains = {}
            if type(incoming.domainRevisions) == "table" then
                for dk, dv in pairs(incoming.domainRevisions) do
                    nextDomains[dk] = tonumber(dv) or 0
                end
            end
            ClientState.domainRevisions[id] = {
                incarnation = incoming.replicaIncarnation
                    or (incoming.portraitRef and incoming.portraitRef.incarnation)
                    or nil,
                domains = nextDomains,
            }
        end
    end
    if replace == true or incoming.deathMarker == true then
        ClientState.snapshots[id] = incoming
    else
        ClientState.snapshots[id] = mergeSnapshot(
            ClientState.snapshots[id],
            incoming
        )
    end
    if incoming.deathMarker == true then
        if ClientState.characterPayloads then
            ClientState.characterPayloads[id] = nil
        end
    elseif ClientState.characterPayloads
        and ClientState.characterPayloads[id]
    then
        ClientState.characterPayloads[id].snapshot =
            ClientState.snapshots[id]
    end
    if suppressIdentityRefresh ~= true then
        refreshClientBodyIdentityIndex()
    end
    return ClientState.snapshots[id]
end

Internal.StoreSnapshot = storeSnapshot
Internal.IsStaleSnapshot = isStaleSnapshot
Internal.NormalizeSnapshotID = normalizeSnapshotID
Internal.IsSnapshotRecord = isSnapshotRecord
Internal.RequestRosterRetry = requestRosterRetry
Internal.RosterSyncID = rosterSyncID
Internal.ClearPendingRoster = clearPendingRoster
Internal.LogClientPresenceRemoval = logClientPresenceRemoval
Internal.RefreshClientBodyIdentityIndex = refreshClientBodyIdentityIndex
