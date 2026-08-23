--[[
    PNC Perception
    Owns nearby hostile resolution, zombie target scanning, and helper queries
    used by behavior, combat, and zombie aggro bridge systems.
]]

PNC = PNC or {}
PNC.Perception = PNC.Perception or {}

local Perception = PNC.Perception
Perception.Internal = Perception.Internal or {}

local Internal = Perception.Internal
local Core = PNC.Core
local Const = PNC.Const
local Spatial = PNC.SpatialIndex
local Stealth = PNC.Stealth
local Registry = PNC.Registry
local Relationships = PNC.Relationships
Perception.OwnerThreatCache = Perception.OwnerThreatCache or {}

function Internal.IsImmediateThreat(target)
    local radius = tonumber(Const.TARGET_IMMEDIATE_THREAT_RADIUS) or 6
    return target and target.threatening == true
        and (tonumber(target.distSq) or math.huge) <= (radius * radius)
end

function Internal.PickNearest(firstTarget, secondTarget)
    local firstThreat
    local secondThreat
    if not firstTarget then
        return secondTarget
    end
    if not secondTarget then
        return firstTarget
    end
    firstThreat = Internal.IsImmediateThreat(firstTarget)
    secondThreat = Internal.IsImmediateThreat(secondTarget)
    if firstThreat ~= secondThreat then
        return firstThreat and firstTarget or secondTarget
    end
    if (tonumber(firstTarget.distSq) or math.huge) <= (tonumber(secondTarget.distSq) or math.huge) then
        return firstTarget
    end
    return secondTarget
end

local function sameTarget(target, kind, id, onlineID, username)
    if not target or tostring(target.kind or "") ~= tostring(kind or "") then
        return false
    end
    if kind == "npc" then
        return tostring(target.id or "") == tostring(id or "")
    end
    if kind == "zombie" then
        return tostring(target.zombieId or "") == tostring(id or "")
    end
    if kind == "player" then
        if onlineID ~= nil and target.onlineID ~= nil then
            return tonumber(target.onlineID) == tonumber(onlineID)
        end
        return username ~= nil and tostring(target.username or "") == tostring(username)
    end
    return false
end

local function targetPointsAtRecord(target, record)
    if not target or not record then return false end
    return tostring(target.kind or "") == "npc"
        and tostring(target.id or "") == tostring(record.id or "")
end

function Perception.RememberAttacker(record, damageEvent, now)
    local kind
    local id
    if not record or type(damageEvent) ~= "table" then return false end
    kind = tostring(damageEvent.attackerKind or "")
    if kind ~= "npc" and kind ~= "player" and kind ~= "zombie" then
        return false
    end
    if kind == "npc" then
        id = damageEvent.attackerID
    elseif kind == "zombie" then
        id = damageEvent.attackerZombieId or damageEvent.zombieId
    end
    if (kind == "npc" or kind == "zombie") and (id == nil or id == "") then
        return false
    end
    if kind == "player"
        and damageEvent.attackerOnlineID == nil
        and (damageEvent.attackerUsername == nil or damageEvent.attackerUsername == "")
    then
        return false
    end
    record.runtime = record.runtime or {}
    record.runtime.recentThreat = {
        kind = kind,
        id = id,
        onlineID = damageEvent.attackerOnlineID,
        username = damageEvent.attackerUsername,
        expiresAt = (tonumber(now) or Core.Now())
            + (tonumber(Const.TARGET_RECENT_ATTACKER_MS) or 5000),
    }
    if Perception.InvalidateFrame then
        Perception.InvalidateFrame(record)
    end
    return true
end

function Perception.ResolveRecentAttacker(record, now)
    local recent
    local kind
    local targetRecord
    local worldObject
    local x
    local y
    local z
    local target
    if not record or not record.runtime then
        return nil
    end
    recent = record.runtime.recentThreat
    now = tonumber(now) or Core.Now()
    if not recent or now > (tonumber(recent.expiresAt) or 0) then
        record.runtime.recentThreat = nil
        return nil
    end
    kind = tostring(recent.kind or "")
    if kind == "npc" then
        targetRecord = Registry
            and Registry.Get
            and Registry.Get(recent.id)
            or nil
        if not targetRecord or targetRecord.alive == false then
            return nil
        end
        if Relationships
            and Relationships.AreNPCsEnemies
            and not Relationships.AreNPCsEnemies(record, targetRecord)
        then
            return nil
        end
        worldObject = Registry
            and Registry.GetLiveZombie
            and Registry.GetLiveZombie(recent.id)
            or nil
        if not worldObject or (worldObject.isDead and worldObject:isDead()) then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "npc",
            id = recent.id,
        }
    elseif kind == "player" then
        worldObject = Core.ResolvePlayerByOnlineID(recent.onlineID)
            or Core.ResolvePlayerByUsername(recent.username)
        if not worldObject
            or (worldObject.isDead and worldObject:isDead())
            or (worldObject.isAlive and not worldObject:isAlive())
        then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "player",
            player = worldObject,
            onlineID = recent.onlineID,
            username = recent.username,
        }
    elseif kind == "zombie" then
        worldObject = Perception.FindZombieByID
            and Perception.FindZombieByID(recent.id)
            or nil
        if not worldObject or (worldObject.isDead and worldObject:isDead()) then
            return nil
        end
        x = worldObject:getX()
        y = worldObject:getY()
        z = worldObject:getZ()
        target = {
            kind = "zombie",
            zombieId = recent.id,
            worldObject = worldObject,
        }
    else
        return nil
    end
    target.x = x
    target.y = y
    target.z = z
    target.distSq = Core.DistanceSq(record.x, record.y, x, y)
    target.visible = true
    target.visibilityKind = "recent_attacker"
    target.lastSeenAt = now
    target.threatening = true
    target.immediateSelfDefense = true
    return target
end

function Perception.IsTargetThreatening(record, target)
    local recent
    local targetRecord
    local targetBody
    local observerBody
    local engineTarget
    if not record or not target then return false end
    recent = record.runtime and record.runtime.recentThreat or nil
    if recent and Core.Now() <= (tonumber(recent.expiresAt) or 0)
        and sameTarget(
            target,
            recent.kind,
            recent.id,
            recent.onlineID,
            recent.username
        )
    then
        return true
    end
    if target.kind == "npc" then
        targetRecord = Registry and Registry.Get and Registry.Get(target.id) or nil
        return targetRecord ~= nil
            and targetPointsAtRecord(targetRecord.runtime and targetRecord.runtime.target, record)
    end
    if target.kind == "zombie" then
        targetBody = target.zombie
            or (Perception.FindZombieByID and Perception.FindZombieByID(target.zombieId))
        observerBody = Registry and Registry.GetLiveZombie
            and Registry.GetLiveZombie(record.id)
            or nil
        if targetBody and observerBody and targetBody.getTarget then
            engineTarget = targetBody:getTarget()
            return engineTarget == observerBody
        end
    end
    return false
end

function Perception.SelectPreferredTarget(firstTarget, secondTarget)
    return Internal.PickNearest(firstTarget, secondTarget)
end
