PNC = PNC or {}
PNC.Persistence = PNC.Persistence or {}
PNC.Persistence.Internal = PNC.Persistence.Internal or {}

local Persistence = PNC.Persistence
local Internal = Persistence.Internal
local Core = PNC.Core
local Const = PNC.Const
local Identity = PNC.Identity
local Types = PNC.Types
local Inventory = PNC.Inventory
local RelationshipTypes = PNC.RelationshipTypes
local RelationshipMath = PNC.RelationshipMath
local FactionTypes = PNC.FactionTypes

function Persistence.RebuildRuntime(record)
    local now = Core.Now()
    local healthState
    if not record then
        return nil
    end
    record.runtime = {
        target = nil,
        pathing = nil,
        abstractTravel = nil,
        roaming = nil,
        roamGoalX = nil,
        roamGoalY = nil,
        roamGoalZ = nil,
        lastPathX = nil,
        lastPathY = nil,
        lastAttackAt = 0,
        lastZombieAttackAt = 0,
        inCombatUntil = 0,
        targetKind = "none",
        combatModeResolved = tostring(record.weaponMode or "melee"),
        weaponStatus = "barehand",
        combatBlockReason = "rehydrated",
        ownerSneaking = false,
        stealthActive = false,
        stealthBroken = false,
        stealthReason = "loaded",
        forceLive = false,
        forceAbstract = false,
        debug = false,
        bodyLease = nil,
        lifecycle = {
            phase = "rehydrated",
            bodyState = "missing",
            lastReason = "rehydrated",
            lastTransitionAt = now,
            lastAuditAt = 0,
            lastError = nil,
            corpseState = record and record.alive == false and "unresolved" or "none",
        },
    }
    record.activeJob = nil
    record.activeBehavior = nil
    record.liveBodyInstanceID = nil
    record.liveBodyOnlineID = nil
    record.lastThinkAt = now
    record.nextThinkAt = now
    record.lastSyncAt = 0
    record.presenceRevision = Internal.normalizeNumber(record.presenceRevision, 0)
    record.ownerOnlineID = nil
    healthState = record.health and tostring(record.health.state or "normal") or "normal"
    if record.health then
        record.health.lastDamageAt = 0
        record.health.recentDamageUntil = 0
        record.health.reviveUntil = 0
        record.health.reviveProtectionUntil = 0
        record.health.downedAt = healthState == "incapacitated" and now or 0
    end
    if record.alive == false or healthState == "corpse" then
        record.presenceState = Const.PRESENCE_CORPSE
    else
        record.presenceState = Const.PRESENCE_ABSTRACT
    end
    if record.stamina then
        record.stamina.lastUpdatedAt = now
    end
    return record
end
