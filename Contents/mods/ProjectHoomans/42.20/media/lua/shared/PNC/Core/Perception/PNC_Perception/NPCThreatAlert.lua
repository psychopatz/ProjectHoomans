-- Authority-owned NPC-on-NPC threat propagation.
--
-- A hostile NPC can be targeting one member of a player's group while the
-- other live followers have no direct perception of that target.  This module
-- turns that single authoritative observation into one bounded, expiring
-- alert per recipient.  It deliberately stores the alert on the recipient so
-- consumers do not rescan the NPC spatial index every behavior tick.

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Core = PNC.Core
local Const = PNC.Const or {}
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry
local Diagnostics = PNC.PerformanceScalingDiagnostics

local MAX_PUBLISH_KEYS = 128

local function isAuthority()
    return not Core
        or type(Core.IsAuthority) ~= "function"
        or Core.IsAuthority() == true
end

local function nowValue(value)
    if value ~= nil then return tonumber(value) or 0 end
    return Core and type(Core.Now) == "function" and Core.Now() or 0
end

local function coordinate(object, method, fallback)
    local getter = object and object[method]
    if type(getter) == "function" then
        return tonumber(getter(object)) or 0
    end
    return tonumber(fallback) or 0
end

local function distanceSq(x1, y1, x2, y2)
    if Core and type(Core.DistanceSq) == "function" then
        return Core.DistanceSq(x1, y1, x2, y2)
    end
    local dx = (tonumber(x2) or 0) - (tonumber(x1) or 0)
    local dy = (tonumber(y2) or 0) - (tonumber(y1) or 0)
    return dx * dx + dy * dy
end

local function identityKey(onlineID, username)
    if onlineID ~= nil and tostring(onlineID) ~= "" then
        return "id:" .. tostring(onlineID)
    end
    if username ~= nil and tostring(username) ~= "" then
        return "user:" .. tostring(username)
    end
    return nil
end

local function ownerValue(record, field)
    local value
    local orderSpec
    if not record then return nil end
    value = record[field]
    if value ~= nil and tostring(value) ~= "" then
        return value
    end
    orderSpec = record.orderSpec
    if orderSpec
        and tostring(orderSpec.kind or "")
            == tostring(Const.ORDER_FOLLOW or "follow")
    then
        return orderSpec[field]
    end
    return nil
end

local function ownerMatches(ownerOnlineID, ownerUsername, record)
    local recordOnlineID
    local recordUsername
    local idMatches = false
    if not record then return false end
    recordOnlineID = ownerValue(record, "ownerOnlineID")
    recordUsername = ownerValue(record, "ownerUsername")
    if ownerOnlineID ~= nil and recordOnlineID ~= nil then
        idMatches = tostring(ownerOnlineID) == tostring(recordOnlineID)
        if idMatches then return true end
    end
    -- Online IDs can change across a single-player/MP handoff or a reconnect.
    -- A durable username is the safe fallback when the numeric identity does
    -- not agree or is absent on one side.
    return ownerUsername ~= nil
        and recordUsername ~= nil
        and tostring(ownerUsername) == tostring(recordUsername)
end

local function sameOwner(alert, record)
    return alert
        and ownerMatches(
            alert.ownerOnlineID,
            alert.ownerUsername,
            record
        )
        or false
end

local function liveBody(id)
    if not Registry or type(Registry.GetLiveZombie) ~= "function" then
        return nil
    end
    return Registry.GetLiveZombie(id)
end

local function recordFor(id)
    if not Registry or type(Registry.Get) ~= "function" then
        return nil
    end
    return Registry.Get(id)
end

local function bodyIsAlive(body)
    if not body then return false end
    if type(body.isDead) == "function" and body:isDead() == true then
        return false
    end
    if type(body.isAlive) == "function" and body:isAlive() == false then
        return false
    end
    return true
end

local function resolveIncident(target)
    local player
    local targetRecord
    local targetBody
    local x
    local y
    local z
    local onlineID
    local username
    if not target then return nil end
    if target.kind == "player" then
        player = target.player
        if not player then return nil end
        if type(player.isAlive) == "function" and not player:isAlive() then
            return nil
        end
        x = coordinate(player, "getX", target.x)
        y = coordinate(player, "getY", target.y)
        z = coordinate(player, "getZ", target.z)
        onlineID = type(player.getOnlineID) == "function"
            and player:getOnlineID() or target.onlineID
        username = type(player.getUsername) == "function"
            and player:getUsername() or target.username
        if not identityKey(onlineID, username) then return nil end
        return {
            kind = "player",
            id = onlineID or username,
            x = x,
            y = y,
            z = z,
            ownerOnlineID = onlineID,
            ownerUsername = username,
        }
    end
    if target.kind ~= "npc" then return nil end
    targetRecord = recordFor(target.id)
    if not targetRecord or targetRecord.alive == false then return nil end
    targetBody = liveBody(target.id)
    if targetBody and not bodyIsAlive(targetBody) then return nil end
    x = coordinate(targetBody, "getX", targetRecord.x or target.x)
    y = coordinate(targetBody, "getY", targetRecord.y or target.y)
    z = coordinate(targetBody, "getZ", targetRecord.z or target.z)
    onlineID = ownerValue(targetRecord, "ownerOnlineID")
    username = ownerValue(targetRecord, "ownerUsername")
    if not identityKey(onlineID, username) then return nil end
    return {
        kind = "npc",
        id = targetRecord.id,
        x = x,
        y = y,
        z = z,
        ownerOnlineID = onlineID,
        ownerUsername = username,
    }
end

local function publishKey(sourceID, incident)
    return tostring(sourceID or "") .. "|"
        .. tostring(identityKey(
            incident and incident.ownerOnlineID,
            incident and incident.ownerUsername
        ) or "")
end

local function rememberPublishKey(key)
    local keys = Perception.NPCAttackAlertPublishKeys
    local state = Perception.NPCAttackAlertPublishAt
    local i
    if type(keys) ~= "table" then
        keys = {}
        Perception.NPCAttackAlertPublishKeys = keys
    end
    if type(state) ~= "table" then
        state = {}
        Perception.NPCAttackAlertPublishAt = state
    end
    if state[key] ~= nil then return state end
    if #keys >= MAX_PUBLISH_KEYS then
        state[keys[1]] = nil
        table.remove(keys, 1)
    end
    keys[#keys + 1] = key
    return state
end

local function sourcePosition(record)
    local body = liveBody(record and record.id)
    if body and bodyIsAlive(body) then
        return coordinate(body, "getX", record.x),
            coordinate(body, "getY", record.y),
            coordinate(body, "getZ", record.z)
    end
    return tonumber(record and record.x) or 0,
        tonumber(record and record.y) or 0,
        tonumber(record and record.z) or 0
end

local function publishGroupAlert(record, target, now, radius)
    local incident
    local sourceX
    local sourceY
    local sourceZ
    local publishState
    local key
    local nextAt
    local sequence
    local candidates
    local candidate
    local candidateBody
    local candidateX
    local candidateY
    local candidateZ
    local candidateDistanceSq
    local alert
    local runtime
    local recipients = 0
    local limitSq
    local i
    local auditEnabled
    local candidateCount = 0
    local rejectedSelf = 0
    local rejectedDead = 0
    local rejectedNoBody = 0
    local rejectedOwner = 0
    local rejectedRange = 0
    local liveBodyCount = 0
    local ownerMatchCount = 0
    if not isAuthority()
        or not Spatial
        or type(Spatial.QueryNPCs) ~= "function"
        or not record
        or record.alive == false
    then
        return false
    end
    incident = resolveIncident(target)
    if not incident then return false end
    now = nowValue(now)
    radius = tonumber(radius)
        or tonumber(Const.NPC_GROUP_ALERT_RADIUS)
        or 8
    radius = math.max(1, radius)
    limitSq = radius * radius
    key = publishKey(record.id, incident)
    publishState = rememberPublishKey(key)
    nextAt = tonumber(publishState[key]) or 0
    if now < nextAt then
        if Diagnostics and Diagnostics.Increment then
            Diagnostics.Increment("NPCThreat.NPCGroupAlert.Throttled")
        end
        return false
    end
    -- Check the republish window before resolving the source body or walking
    -- the spatial index.  Combat can call this once per accepted hit, while
    -- recipients only need the bounded alert refresh cadence.
    sourceX, sourceY, sourceZ = sourcePosition(record)
    auditEnabled = Diagnostics
        and Diagnostics.NPCThreatAuditEnabled == true
        and type(Diagnostics.LogNPCThreatAudit) == "function"
    Perception.NPCAttackAlertSequence =
        (tonumber(Perception.NPCAttackAlertSequence) or 0) + 1
    sequence = Perception.NPCAttackAlertSequence
    candidates = Spatial.QueryNPCs(incident.x, incident.y, radius) or {}
    -- The source has already selected or damaged this owner-group target on
    -- the authority. Do not apply the recipient's reverse relationship here:
    -- NPC relationships are directed, and that reverse lookup can discard a
    -- legitimate owner-defense incident for faction-asymmetric records.
    for i = 1, #candidates do
        candidate = candidates[i]
        candidateBody = candidate and liveBody(candidate.id) or nil
        if auditEnabled then candidateCount = candidateCount + 1 end
        if not candidate then
            -- The spatial index should not contain nil entries, but keep the
            -- loop tolerant of a concurrent rebuild.
        elseif tostring(candidate.id or "") == tostring(record.id or "") then
            if auditEnabled then rejectedSelf = rejectedSelf + 1 end
        elseif candidate.alive == false then
            if auditEnabled then rejectedDead = rejectedDead + 1 end
        elseif not bodyIsAlive(candidateBody) then
            if auditEnabled then rejectedNoBody = rejectedNoBody + 1 end
        elseif not ownerMatches(
            incident.ownerOnlineID,
            incident.ownerUsername,
            candidate
        ) then
            if auditEnabled then rejectedOwner = rejectedOwner + 1 end
        else
            if auditEnabled then
                liveBodyCount = liveBodyCount + 1
                ownerMatchCount = ownerMatchCount + 1
            end
            candidateX = coordinate(candidateBody, "getX", candidate.x)
            candidateY = coordinate(candidateBody, "getY", candidate.y)
            candidateZ = coordinate(candidateBody, "getZ", candidate.z)
            candidateDistanceSq = distanceSq(
                candidateX,
                candidateY,
                incident.x,
                incident.y
            )
            if math.abs(candidateZ - incident.z) >= 1
                or candidateDistanceSq > limitSq
            then
                if auditEnabled then rejectedRange = rejectedRange + 1 end
            else
                runtime = candidate.runtime or {}
                candidate.runtime = runtime
                alert = runtime.npcThreatAlert
                if type(alert) ~= "table"
                    or tostring(alert.sourceId or "")
                        ~= tostring(record.id or "")
                    or tostring(alert.ownerOnlineID or "")
                        ~= tostring(incident.ownerOnlineID or "")
                    or tostring(alert.ownerUsername or "")
                        ~= tostring(incident.ownerUsername or "")
                then
                    alert = {}
                    runtime.npcThreatAlert = alert
                end
                if tonumber(alert.sequence) ~= sequence then
                    runtime.npcThreatAlertCheckAt = 0
                    runtime.npcThreatAlertVisible = nil
                    runtime.npcThreatAlertVisibilityKind = nil
                end
                alert.sourceId = record.id
                alert.sourceX = sourceX
                alert.sourceY = sourceY
                alert.sourceZ = sourceZ
                alert.incidentX = incident.x
                alert.incidentY = incident.y
                alert.incidentZ = incident.z
                alert.ownerOnlineID = incident.ownerOnlineID
                alert.ownerUsername = incident.ownerUsername
                alert.targetKind = incident.kind
                alert.targetId = incident.id
                alert.observedAt = now
                alert.expiresAt = now + (
                    tonumber(Const.NPC_ALERT_TTL_MS) or 1800
                )
                alert.sequence = sequence
                alert.alertRadius = radius
                alert.distSq = distanceSq(
                    candidateX,
                    candidateY,
                    sourceX,
                    sourceY
                )
                recipients = recipients + 1
            end
        end
    end
    publishState[key] = now + (
        tonumber(Const.NPC_ALERT_REPUBLISH_MS) or 500
    )
    if Diagnostics and Diagnostics.Increment then
        Diagnostics.Increment("NPCThreat.NPCGroupAlert.Published")
        Diagnostics.Increment(
            "NPCThreat.NPCGroupAlert.Recipients",
            recipients
        )
    end
    if Diagnostics and Diagnostics.NPCThreatAuditEnabled == true
        and Diagnostics.LogNPCThreatAudit
    then
        Diagnostics.LogNPCThreatAudit("npc_group_alert_published", {
            "sourceNpc=" .. tostring(record.id or ""),
            "targetKind=" .. tostring(incident.kind or ""),
            "targetId=" .. tostring(incident.id or ""),
            "sequence=" .. tostring(sequence),
            "recipients=" .. tostring(recipients),
            "radius=" .. tostring(radius),
            "ownerOnlineID=" .. tostring(incident.ownerOnlineID or ""),
            "ownerUsername=" .. tostring(incident.ownerUsername or ""),
            "candidates=" .. tostring(candidateCount),
            "liveBodies=" .. tostring(liveBodyCount),
            "ownerMatches=" .. tostring(ownerMatchCount),
            "rejectedSelf=" .. tostring(rejectedSelf),
            "rejectedDead=" .. tostring(rejectedDead),
            "rejectedNoBody=" .. tostring(rejectedNoBody),
            "rejectedOwner=" .. tostring(rejectedOwner),
            "rejectedRange=" .. tostring(rejectedRange),
        })
    end
    return true
end

function Perception.PublishNPCGroupAlert(record, target, now, radius)
    return publishGroupAlert(record, target, now, radius)
end

local function buildAlertTarget(record, alert, sourceX, sourceY, sourceZ,
        distSq, visible, visibilityKind)
    local target = {
        kind = "npc",
        id = alert.sourceId,
        x = sourceX,
        y = sourceY,
        z = sourceZ,
        distSq = distSq,
        visible = visible == true,
        visibilityKind = visibilityKind or "npc_group_alert",
        lastSeenAt = tonumber(alert.observedAt) or 0,
        threatening = true,
        proximityAlert = true,
        groupAlert = true,
        ownerDefense = true,
        alertOnly = visible ~= true,
        alertSequence = alert.sequence,
        alertRadius = tonumber(alert.alertRadius)
            or tonumber(Const.NPC_GROUP_ALERT_RADIUS)
            or 8,
    }
    return target
end

function Perception.FindNPCGroupAlert(record, radius, allowUnseen)
    local runtime
    local alert
    local sourceRecord
    local sourceBody
    local observerBody
    local observerX
    local observerY
    local sourceX
    local sourceY
    local sourceZ
    local distSq
    local limit
    local visible
    local visibilityKind
    local now
    local checkAt
    local target
    if not isAuthority() or not record or record.alive == false then
        return nil
    end
    runtime = record.runtime or {}
    record.runtime = runtime
    alert = runtime.npcThreatAlert
    if type(alert) ~= "table" then return nil end
    now = nowValue()
    if now >= (tonumber(alert.expiresAt) or 0) then
        runtime.npcThreatAlert = nil
        runtime.npcThreatAlertCheckAt = nil
        runtime.npcThreatAlertVisible = nil
        return nil
    end
    if not sameOwner(alert, record) then
        runtime.npcThreatAlert = nil
        return nil
    end
    sourceRecord = recordFor(alert.sourceId)
    -- Publication is authority-owned and is only reached from a selected
    -- target or an NPC combat-resolution event. The recipient must not repeat
    -- the relationship lookup in the opposite direction; the alert itself is
    -- the bounded owner-defense evidence for this short TTL.
    if not sourceRecord or sourceRecord.alive == false then
        runtime.npcThreatAlert = nil
        return nil
    end
    sourceBody = liveBody(alert.sourceId)
    if sourceBody and not bodyIsAlive(sourceBody) then
        runtime.npcThreatAlert = nil
        return nil
    end
    sourceX = coordinate(sourceBody, "getX", alert.sourceX)
    sourceY = coordinate(sourceBody, "getY", alert.sourceY)
    sourceZ = coordinate(sourceBody, "getZ", alert.sourceZ)
    limit = math.max(
        tonumber(radius) or 0,
        tonumber(alert.alertRadius)
            or tonumber(Const.NPC_GROUP_ALERT_RADIUS)
            or 8
    )
    observerBody = liveBody(record.id)
    observerX = coordinate(observerBody, "getX", record.x)
    observerY = coordinate(observerBody, "getY", record.y)
    distSq = distanceSq(observerX, observerY, sourceX, sourceY)
    if math.abs(sourceZ - (tonumber(record.z) or 0)) >= 1
        or distSq > limit * limit
    then
        return nil
    end
    checkAt = tonumber(runtime.npcThreatAlertCheckAt) or 0
    if now >= checkAt then
        runtime.npcThreatAlertCheckAt = now + (
            tonumber(Const.NPC_ALERT_LOS_RECHECK_MS) or 250
        )
        visible = false
        visibilityKind = "npc_group_alert"
        if sourceBody and Perception.CanSeeWorldObject then
            visible, visibilityKind = Perception.CanSeeWorldObject(
                record,
                sourceBody
            )
        end
        runtime.npcThreatAlertVisible = visible == true
        runtime.npcThreatAlertVisibilityKind = visibilityKind
    else
        visible = runtime.npcThreatAlertVisible == true
        visibilityKind = runtime.npcThreatAlertVisibilityKind
    end
    target = buildAlertTarget(
        record,
        alert,
        sourceX,
        sourceY,
        sourceZ,
        distSq,
        visible,
        visibilityKind
    )
    if visible or allowUnseen ~= false then return target end
    return nil
end

return Perception
