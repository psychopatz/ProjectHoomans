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
local TraversalQuery = PNC.TraversalQuery
local COMBAT_NAVIGATION = {
    navigationPolicy = "combat",
    navigationProvider = "direct",
}

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

local function requestRetreat(record, threat)
    local state = ensureState(record)
    local dx = record.x - (tonumber(threat and threat.x) or record.x - 1)
    local dy = record.y - (tonumber(threat and threat.y) or record.y)
    local length = math.sqrt(dx * dx + dy * dy)
    local distance = tonumber(Const.SELF_BANDAGE_RETREAT_DISTANCE) or 5
    local baseX
    local baseY
    local angles = { 0, 0.55, -0.55, 1.05, -1.05, 1.55, -1.55 }
    local angle
    local candidateX
    local candidateY
    local rotatedX
    local rotatedY
    local i
    if length <= 0.001 then
        dx = 1
        dy = 0
        length = 1
    end
    baseX = dx / length
    baseY = dy / length
    if TraversalQuery and TraversalQuery.CanStep
        and TraversalQuery.CanOccupy
    then
        for i = 1, #angles do
            angle = angles[i]
            rotatedX = baseX * math.cos(angle) - baseY * math.sin(angle)
            rotatedY = baseX * math.sin(angle) + baseY * math.cos(angle)
            candidateX = record.x + rotatedX * distance
            candidateY = record.y + rotatedY * distance
            if TraversalQuery.CanStep(
                record.x, record.y, record.z,
                record.x + rotatedX * 0.8,
                record.y + rotatedY * 0.8,
                record.z
            ) and TraversalQuery.CanOccupy(candidateX, candidateY, record.z)
            then
                baseX = rotatedX
                baseY = rotatedY
                break
            end
        end
    end
    if MoveIntent and MoveIntent.RequestMove then
        MoveIntent.RequestMove(
            record,
            record.x + baseX * distance,
            record.y + baseY * distance,
            record.z,
            "run",
            tonumber(Const.SELF_BANDAGE_RETREAT_STOP_DISTANCE) or 1,
            "self_treatment_retreat",
            COMBAT_NAVIGATION
        )
    end
    record.activeBehavior = "SelfTreatmentRetreat"
    state.phase = "retreat"
    state.interruptedReason = "threat_nearby"
    record.runtime.tacticalState = "retreat_to_treat"
    record.runtime.target = nil
    record.runtime.attackAction = nil
end

local function startBandage(record, zombie, partId, now)
    local Treatment = PNC.Treatment
    local supply = Treatment and Treatment.FindNPCBandage
        and Treatment.FindNPCBandage(record) or nil
    local state = ensureState(record)
    local emitter
    local modData
    local soundKey
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
    if zombie and Animation and Animation.PlayBump then
        Animation.PlayBump(
            zombie,
            record,
            BANDAGE_ANIM_BY_PART[partId] or "BandageUpperBody"
        )
    end
    emitter = zombie and zombie.getEmitter and zombie:getEmitter() or nil
    if emitter and emitter.playSound then
        emitter:playSound("FirstAidApplyBandage")
        modData = zombie.getModData and zombie:getModData() or nil
        soundKey = tostring(partId) .. ":" .. tostring(state.startedAt)
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
    local interruptRadius
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
        if state.phase ~= "idle" then clearAction(record, zombie, "missing_bandage") end
        return false
    end

    threat = findThreat(record, tonumber(Const.SELF_BANDAGE_THREAT_RADIUS) or 10)
    interruptRadius = tonumber(Const.SELF_BANDAGE_INTERRUPT_RADIUS) or 7
    if state.phase == "bandaging" then
        if threat and (tonumber(threat.distSq) or math.huge)
            <= interruptRadius * interruptRadius
        then
            clearAction(record, zombie, "threat_nearby")
            state.retryAt = now + (tonumber(Const.SELF_BANDAGE_RETRY_MS) or 5000)
            if record.health and record.health.state == "incapacitated" then
                return false
            end
            requestRetreat(record, threat)
            return true
        end
        record.activeBehavior = "SelfBandage"
        if MoveIntent and MoveIntent.Hold then
            MoveIntent.Hold(record, "self_bandage")
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

    if threat then
        if record.health and record.health.state == "incapacitated" then
            return false
        end
        requestRetreat(record, threat)
        return true
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
