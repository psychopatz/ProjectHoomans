PNC = PNC or {}
PNC.Perception = PNC.Perception or {}
PNC.Perception.Internal = PNC.Perception.Internal or {}

local Perception = PNC.Perception
local Internal = Perception.Internal
local Const = PNC.Const
local Core = PNC.Core
local Spatial = PNC.SpatialIndex
local Registry = PNC.Registry
local Diagnostics = PNC.PerformanceScalingDiagnostics

local function isAuthority()
    return not Core
        or type(Core.IsAuthority) ~= "function"
        or Core.IsAuthority() == true
end

local function alertId(zombie)
    local modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    return modData and modData.PNC_ZombieID or nil
end

local function publishGroupAlert(record, zombie, now, radius)
    local zombieId
    local publishState
    local candidates
    local candidate
    local body
    local runtime
    local distanceSq
    local limitSq
    local sequence
    local recipients = 0
    if not isAuthority() or not Spatial or not Spatial.QueryNPCs
        or not record or not zombie
    then
        return false
    end
    zombieId = alertId(zombie)
    if not zombieId then return false end
    Perception.ZombieAlertPublishAt = Perception.ZombieAlertPublishAt
        or setmetatable({}, { __mode = "k" })
    publishState = Perception.ZombieAlertPublishAt[zombie]
    if publishState and now < (tonumber(publishState.nextAt) or 0) then
        return false
    end
    Perception.ZombieAlertSequence =
        (tonumber(Perception.ZombieAlertSequence) or 0) + 1
    sequence = Perception.ZombieAlertSequence
    radius = tonumber(radius)
        or tonumber(Const.ZOMBIE_GROUP_ALERT_RADIUS)
        or 8
    limitSq = radius * radius
    candidates = Spatial.QueryNPCs(zombie:getX(), zombie:getY(), radius)
    for i = 1, #candidates do
        candidate = candidates[i]
        body = candidate and Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(candidate.id) or nil
        if candidate and body and candidate.alive ~= false
            and candidate.presenceState == Const.PRESENCE_LIVE
            and math.abs(body:getZ() - zombie:getZ()) < 1
        then
            distanceSq = Core.DistanceSq(
                body:getX(), body:getY(), zombie:getX(), zombie:getY()
            )
            if distanceSq <= limitSq then
                runtime = candidate.runtime or {}
                candidate.runtime = runtime
                runtime.zombieAlert = {
                    zombieId = zombieId,
                    x = zombie:getX(),
                    y = zombie:getY(),
                    z = zombie:getZ(),
                    observedAt = now,
                    expiresAt = now + (
                        tonumber(Const.ZOMBIE_ALERT_TTL_MS) or 1800
                    ),
                    sequence = sequence,
                    sourceId = record.id,
                    distSq = distanceSq,
                }
                recipients = recipients + 1
            end
        end
    end
    Perception.ZombieAlertPublishAt[zombie] = {
        nextAt = now + (tonumber(Const.ZOMBIE_ALERT_REPUBLISH_MS) or 350),
        sequence = sequence,
    }
    if Diagnostics and Diagnostics.NPCThreatAuditEnabled == true
        and Diagnostics.LogNPCThreatAudit
    then
        Diagnostics.LogNPCThreatAudit("group_alert_published", {
            "sourceNpc=" .. tostring(record.id or ""),
            "zombieId=" .. tostring(zombieId),
            "sequence=" .. tostring(sequence),
            "recipients=" .. tostring(recipients),
            "radius=" .. tostring(radius),
        })
    end
    return true
end

-- Keep group-alert publication behind one shared authority-aware boundary so
-- existing immediate-threat paths can refresh nearby NPCs even when the
-- source NPC already has an active zombie target and therefore does not enter
-- FindProximityZombieAlert on this tick.
function Perception.PublishZombieGroupAlert(record, zombie, now, radius)
    if not record or not zombie then return false end
    return publishGroupAlert(
        record,
        zombie,
        tonumber(now) or (Core and Core.Now and Core.Now() or 0),
        radius
    )
end

local function buildAlertOnlyTarget(alert)
    return {
        kind = "zombie",
        zombieId = alert.zombieId,
        x = tonumber(alert.x) or 0,
        y = tonumber(alert.y) or 0,
        z = tonumber(alert.z) or 0,
        distSq = tonumber(alert.distSq) or math.huge,
        visible = false,
        visibilityKind = "group_alert",
        lastSeenAt = tonumber(alert.observedAt) or 0,
        proximityAlert = true,
        alertOnly = true,
        alertSequence = alert.sequence,
    }
end

-- A proximity alert wakes nearby NPCs even when the zombie is using Hoomans'
-- multiplayer coordinate pursuit and therefore has no native engine target.
-- The local observer still has to pass LOS before the target becomes an attack
-- target. Group recipients receive an alert-only target and remain stationary
-- until they can confirm the threat themselves.
function Perception.FindProximityZombieAlert(record, radius)
    local now
    local runtime
    local alert
    local zombie
    local visible
    local visibilityKind
    local entries
    local entry
    local target
    local limit
    if not record or not Perception.GetVisibleZombieEntries then return nil end
    if Core and type(Core.IsAuthority) == "function"
        and Core.IsAuthority() ~= true
    then
        return nil
    end
    now = Core and Core.Now and Core.Now() or 0
    runtime = record.runtime or {}
    record.runtime = runtime
    alert = runtime.zombieAlert
    if alert and now < (tonumber(alert.expiresAt) or 0) then
        zombie = Perception.FindZombieByID
            and Perception.FindZombieByID(alert.zombieId) or nil
        if zombie and not zombie:isDead() then
            visible, visibilityKind = Perception.CanSeeWorldObject(
                record, zombie
            )
            if visible then
                target = Internal.BuildZombieTarget(
                    record,
                    zombie,
                    Core.DistanceSq(record.x, record.y, zombie:getX(), zombie:getY()),
                    visibilityKind or "group_alert",
                    alert.zombieId
                )
                if target then
                    target.proximityAlert = true
                    target.alertSequence = alert.sequence
                    return target
                end
            end
            return buildAlertOnlyTarget(alert)
        end
    elseif alert then
        runtime.zombieAlert = nil
    end
    limit = tonumber(radius)
        or tonumber(Const.ZOMBIE_PROXIMITY_ALERT_RADIUS)
        or tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS)
        or 6
    entries = Perception.GetVisibleZombieEntries(record, limit)
    for i = 1, #(entries or {}) do
        entry = entries[i]
        if entry and entry.zombie then
            target = Internal.BuildZombieTarget(
                record,
                entry.zombie,
                entry.distSq,
                entry.visibilityKind or "proximity"
            )
            if target then
                target.proximityAlert = true
                publishGroupAlert(record, entry.zombie, now)
                return target
            end
        end
    end
    return nil
end

-- Immediate proximity does not override walls. Treating every nearby spatial
-- candidate as actionable made NPCs stare at zombies in the next room while
-- scripted bite damage continued through the shared wall.
function Perception.FindImmediateEnemyZombie(record, radius)
    local frame
    local entries
    local entry
    local visible
    local visibilityKind
    local i
    local limit = tonumber(radius)
        or tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS)
        or 4
    local limitSq = limit * limit
    if not record
        or record.hostility and record.hostility.attackZombies == false
        or not Perception.GetZombieFrame
    then
        return nil
    end
    frame = Perception.GetZombieFrame(record, limit)
    entries = frame and frame.entries or nil
    for i = 1, #(entries or {}) do
        entry = entries[i]
        if entry and entry.zombie and entry.distSq <= limitSq then
            visible, visibilityKind =
                Perception.CanSeeWorldObject(
                    record,
                    entry.zombie
                )
            if visible then
                return Internal.BuildZombieTarget(
                    record,
                    entry.zombie,
                    entry.distSq,
                    visibilityKind or "proximity"
                )
            end
        end
    end
    return nil
end
