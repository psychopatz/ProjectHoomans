--[[
    PNC self-treatment behavior.

    The authority owns this state machine. Live NPCs retreat, perform a
    body-part-specific bandage animation, and cancel when danger closes in.
    Abstract NPCs use the same inventory and wound APIs on a coarse cadence.
]]

PNC = PNC or {}
PNC.BehaviorTreatment = PNC.BehaviorTreatment or {}

local Behavior = PNC.BehaviorTreatment
local Core = PNC.Core
local Const = PNC.Const
local Perception = PNC.Perception
local Animation = PNC.Animation
local MoveIntent = PNC.BehaviorMoveIntent
local CombatTactics = PNC.CombatTactics

local BANDAGE_ANIM_BY_PART = {
    Head = "BandageHead",
    Neck = "BandageHead",
    Torso_Upper = "BandageUpperBody",
    Torso_Lower = "BandageLowerBody",
    Groin = "BandageLowerBody",
    UpperArm_L = "BandageLeftArm",
    ForeArm_L = "BandageLeftArm",
    Hand_L = "BandageLeftArm",
    UpperArm_R = "BandageRightArm",
    ForeArm_R = "BandageRightArm",
    Hand_R = "BandageRightArm",
    UpperLeg_L = "BandageLeftLeg",
    LowerLeg_L = "BandageLeftLeg",
    Foot_L = "BandageLeftLeg",
    UpperLeg_R = "BandageRightLeg",
    LowerLeg_R = "BandageRightLeg",
    Foot_R = "BandageRightLeg",
}

function Behavior.ResolveBandageAnimation(partId)
    return BANDAGE_ANIM_BY_PART[tostring(partId or "")]
        or "BandageUpperBody"
end

local function ensureState(record)
    record.runtime = record.runtime or {}
    record.runtime.selfTreatment = record.runtime.selfTreatment or {
        phase = "idle",
        retryAt = 0,
        nextAbstractAt = 0,
    }
    return record.runtime.selfTreatment
end

local function nearest(left, right)
    if not left then return right end
    if not right then return left end
    return (tonumber(right.distSq) or math.huge)
        < (tonumber(left.distSq) or math.huge) and right or left
end

local function findThreat(record, radius)
    local threat
    local hostility = record and record.hostility or {}
    if hostility.attackNPCs ~= false and Perception and Perception.FindNearestEnemyNPC then
        threat = nearest(threat, Perception.FindNearestEnemyNPC(record, radius))
    end
    if hostility.attackZombies ~= false and Perception and Perception.FindNearestEnemyZombie then
        threat = nearest(threat, Perception.FindNearestEnemyZombie(record, radius))
    end
    if (record.faction == Const.FACTION_HOSTILE or hostility.attackPlayers == true)
        and Perception and Perception.FindNearestEnemyPlayer
    then
        threat = nearest(threat, Perception.FindNearestEnemyPlayer(record, radius))
    end
    return threat
end

local function insideSafetyRadius(threat, radius)
    return threat ~= nil
        and (tonumber(threat.distSq) or math.huge)
            <= radius * radius
end

local function clearAction(record, zombie, reason)
    local state = ensureState(record)
    if state.phase == "bandaging" and zombie and Animation and Animation.FinishBump then
        Animation.FinishBump(zombie, true)
    end
    state.phase = "idle"
    state.partId = nil
    state.bandageType = nil
    state.bandageName = nil
    state.startedAt = 0
    state.finishAt = 0
    state.interruptedReason = reason
    record.runtime.tacticalState = nil
end

local function yieldToCombat(record, zombie, threat, now)
    local state = ensureState(record)
    if state.phase == "bandaging" then
        clearAction(record, zombie, "threat_nearby")
    else
        state.phase = "idle"
        state.interruptedReason = "threat_nearby"
        record.runtime.tacticalState = nil
    end
    state.retryAt = now + (tonumber(Const.SELF_BANDAGE_RETRY_MS) or 5000)
    record.runtime.target = threat
    -- Treatment must never choose movement while an enemy owns the tactical
    -- lane. The combat layer decides whether to counter, shove, or retreat.
    -- Returning false lets that decision happen in this same behavior tick.
    if CombatTactics and CombatTactics.ClearRetreatState then
        CombatTactics.ClearRetreatState(record)
    end
    return false
end

local function startBandage(record, zombie, partId, now)
    local Treatment = PNC.Treatment
    local supply = Treatment and Treatment.FindNPCBandage
        and Treatment.FindNPCBandage(record) or nil
    local state = ensureState(record)
    local emitter
    local modData
    local soundKey
    local bandageAnim
    if not supply then return false end
    state.phase = "bandaging"
    state.partId = partId
    state.bandageType = supply.fullType
    state.bandageName = supply.displayName
    state.startedAt = now
    state.finishAt = now + Treatment.GetNPCBandageDuration(record)
    state.interruptedReason = nil
    record.activeBehavior = "SelfBandage"
    record.runtime.tacticalState = "self_bandage"
    record.runtime.target = nil
    record.runtime.attackAction = nil
    if MoveIntent and MoveIntent.Hold then
        MoveIntent.Hold(record, "self_bandage")
    end
    bandageAnim = Behavior.ResolveBandageAnimation(partId)
    if zombie and Animation and Animation.PlayBump then
        Animation.PlayBump(
            zombie,
            record,
            bandageAnim,
            {
                leaseUntil = state.finishAt,
            }
        )
    end
    modData = zombie and zombie.getModData
        and zombie:getModData() or nil
    soundKey = tostring(partId) .. ":" .. tostring(state.startedAt)
    if modData then
        -- The local client sees the same body in SP/listen-host worlds. Mark
        -- the authority-started action so snapshot presentation maintains it
        -- instead of selecting the same node a second time.
        modData.PNC_ClientTreatmentAnimKey = soundKey
    end
    emitter = zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        if modData then
            -- Local-authority worlds use the same snapshot presentation path.
            -- Seed its dedupe key so the replicated SFX is not played twice.
            modData.PNC_ClientTreatmentSoundKey = soundKey
        end
    end
    return true
end

local function tickAbstract(record, now, partId)
    local state = ensureState(record)
    local Treatment = PNC.Treatment
    if now < (tonumber(state.nextAbstractAt) or 0) then return false end
    if record.runtime.target ~= nil
        or now < (tonumber(record.runtime.inCombatUntil) or 0)
    then
        state.nextAbstractAt = now
            + (tonumber(Const.ABSTRACT_SELF_BANDAGE_INTERVAL_MS) or 30000)
        return false
    end
    if not Treatment or not Treatment.HasNPCBandage
        or not Treatment.HasNPCBandage(record)
    then
        if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.EnsureMedical then
            PNC.NeedSupplyBridge.EnsureMedical(record, "BANDAGE", partId, false)
        end
        return false
    end
    state.nextAbstractAt = now
        + (tonumber(Const.ABSTRACT_SELF_BANDAGE_INTERVAL_MS) or 30000)
    if Treatment.TryNPCBandage(record, partId) then
        state.phase = "abstract"
        state.partId = partId
        state.bandageName = nil
        record.activeBehavior = "AbstractSelfTreatment"
        return true
    end
    return false
end

function Behavior.Tick(record, zombie, now)
    local Wounds = PNC.NPCWounds
    local Treatment = PNC.Treatment
    local state
    local partId
    local threat
    local safetyRadius
    local applied
    local label
    if not record or record.alive == false or not Wounds
        or not Wounds.FindTreatableWound or not Treatment
    then
        return false
    end
    partId = Wounds.FindTreatableWound(record)
    state = ensureState(record)
    now = tonumber(now) or Core.Now()
    if not partId then
        if state.phase ~= "idle" then clearAction(record, zombie, "no_treatable_wound") end
        return false
    end
    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        return tickAbstract(record, now, partId)
    end
    if not Treatment.HasNPCBandage(record) then
        if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.EnsureMedical then
            PNC.NeedSupplyBridge.EnsureMedical(record, "BANDAGE", partId, false)
        end
        if state.phase ~= "idle" then clearAction(record, zombie, "missing_bandage") end
        return false
    end

    safetyRadius = tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS)
        or tonumber(Const.SELF_BANDAGE_INTERRUPT_RADIUS)
        or 2.2
    threat = Perception and Perception.ResolveRecentAttacker
        and Perception.ResolveRecentAttacker(record, now) or nil
    if not insideSafetyRadius(threat, safetyRadius) then
        threat = nil
    end
    if not threat and Perception and Perception.FindImmediateZombieThreat then
        threat = Perception.FindImmediateZombieThreat(
            record,
            safetyRadius
        )
    end
    if not threat then
        threat = findThreat(
            record,
            safetyRadius
        )
    end
    if state.phase == "bandaging" then
        if insideSafetyRadius(threat, safetyRadius) then
            if record.health and record.health.state == "incapacitated" then
                clearAction(record, zombie, "threat_nearby")
                return false
            end
            return yieldToCombat(record, zombie, threat, now)
        end
        record.activeBehavior = "SelfBandage"
        if MoveIntent and MoveIntent.Hold then
            MoveIntent.Hold(record, "self_bandage")
        end
        if Animation and Animation.MaintainBump then
            Animation.MaintainBump(
                zombie,
                record,
                Behavior.ResolveBandageAnimation(state.partId),
                state.finishAt
            )
        end
        if now < (tonumber(state.finishAt) or 0) then return true end
        applied, label = Treatment.TryNPCBandage(record, state.partId)
        if zombie and Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        state.phase = "idle"
        state.partId = nil
        state.bandageType = nil
        state.bandageName = nil
        state.finishAt = 0
        state.retryAt = now + (applied and 750
            or (tonumber(Const.SELF_BANDAGE_RETRY_MS) or 5000))
        state.lastResult = applied and "bandaged" or tostring(label or "failed")
        record.runtime.tacticalState = nil
        if applied then
            record.runtime.forceSyncEvent = "self_bandaged"
        end
        return true
    end

    if insideSafetyRadius(threat, safetyRadius) then
        if record.health and record.health.state == "incapacitated" then
            return false
        end
        return yieldToCombat(record, zombie, threat, now)
    end
    if state.phase == "retreat"
        and CombatTactics
        and CombatTactics.ClearRetreatState
    then
        CombatTactics.ClearRetreatState(record)
        state.phase = "idle"
        record.runtime.tacticalState = nil
    end
    if now < (tonumber(state.retryAt) or 0) then return false end
    return startBandage(record, zombie, partId, now)
end

function Behavior.BuildSnapshot(record)
    local state = record and record.runtime and record.runtime.selfTreatment or nil
    if not state then return nil end
    return {
        phase = state.phase,
        partId = state.partId,
        bandageType = state.bandageType,
        bandageName = state.bandageName,
        startedAt = state.startedAt,
        finishAt = state.finishAt,
        interruptedReason = state.interruptedReason,
        lastResult = state.lastResult,
    }
end

return Behavior
