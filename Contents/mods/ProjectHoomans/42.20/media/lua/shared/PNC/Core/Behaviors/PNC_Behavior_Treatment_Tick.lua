-- Treatment behavior tick coordinator.

PNC = PNC or {}
PNC.BehaviorTreatment = PNC.BehaviorTreatment or {}

local Behavior = PNC.BehaviorTreatment
local H = Behavior.Internal and Behavior.Internal.Tick
if type(H) ~= "table" then return Behavior end

local Core = H.Core
local Const = H.Const
local Perception = H.Perception
local Animation = H.Animation
local MoveIntent = H.MoveIntent
local CombatTactics = H.CombatTactics
local ensureState = H.ensureState
local findThreat = H.findThreat
local insideSafetyRadius = H.insideSafetyRadius
local clearAction = H.clearAction
local yieldToCombat = H.yieldToCombat
local startBandage = H.startBandage
local tickAbstract = H.tickAbstract
local requiresMedicalItem = H.requiresMedicalItem

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
        if state.phase ~= "idle" then
            clearAction(record, zombie, "no_treatable_wound")
        end
        return false
    end
    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        return tickAbstract(record, now, partId)
    end
    if requiresMedicalItem(Treatment, record)
        and not Treatment.HasNPCBandage(record)
    then
        if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.EnsureMedical then
            PNC.NeedSupplyBridge.EnsureMedical(record, "BANDAGE", partId, false)
        end
        if state.phase ~= "idle" then
            clearAction(record, zombie, "missing_bandage")
        end
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
        threat = findThreat(record, safetyRadius)
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

return Behavior
