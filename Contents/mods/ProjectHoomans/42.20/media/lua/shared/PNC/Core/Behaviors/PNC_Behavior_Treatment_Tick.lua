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

local function returnRecoveredItems(record, zombie, itemsToAdd)
    local inventory = PNC.Inventory
    if not inventory or not inventory.AddItems then return end
    local specs = {}
    for _, fullType in ipairs(itemsToAdd) do
        if type(fullType) == "string" and fullType ~= "" and fullType ~= "PNC.AbstractMedical" then
            specs[#specs + 1] = { type = fullType, stack = 1 }
        end
    end
    if #specs == 0 then return end
    local ok, _, ids = inventory.AddItems(record, specs, "root", "removed_healed_dressing")
    if ok and ids and zombie and inventory.MaterializeItem then
        for _, itemId in ipairs(ids) do inventory.MaterializeItem(record, zombie, itemId) end
    end
end

local function removeHealedDressing(Wounds, Treatment, record, zombie, healedPart, healedKind, now, state)
    local removeFn = healedKind == "splint" and Wounds.RemoveSplint or Wounds.RemoveBandage
    if type(removeFn) ~= "function" then return false end
    local ok, reason, itemA, itemB = removeFn(record, healedPart)
    if not ok then return false end
    if not Treatment.RequiresNPCMedicalItem or Treatment.RequiresNPCMedicalItem(record) then
        returnRecoveredItems(record, zombie, { itemA, itemB })
    end
    state.retryAt = now + 750
    state.lastResult = reason
    record.runtime.forceSyncEvent = reason
    if PNC.Network and PNC.Network.BroadcastRecord then PNC.Network.BroadcastRecord(record, reason) end
    return true
end

function Behavior.Tick(record, zombie, now)
    local Wounds = PNC.NPCWounds
    local Treatment = PNC.Treatment
    local state
    local partId, healedPart, healedKind
    local threat
    local groupAlert
    local safetyRadius
    local baseSafetyRadius
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
        if Wounds.FindRemovableHealedDressing then
            healedPart, _, healedKind = Wounds.FindRemovableHealedDressing(record)
        end
        if not healedPart then
            if state.phase ~= "idle" then
                clearAction(record, zombie, "no_treatable_wound")
            end
            return false
        end
    end
    if not partId and healedPart and (record.presenceState ~= Const.PRESENCE_LIVE or not zombie) then
        if now < (tonumber(state.retryAt) or 0) then return false end
        return removeHealedDressing(Wounds, Treatment, record, nil, healedPart, healedKind, now, state)
    end
    if record.presenceState ~= Const.PRESENCE_LIVE or not zombie then
        return tickAbstract(record, now, partId)
    end
    local onFire = zombie.isOnFire and zombie:isOnFire() == true or false
    local bodySquare = zombie.getSquare and zombie:getSquare() or nil
    local onHazardFire = PNC.BehaviorFireSafety
        and PNC.BehaviorFireSafety.IsHazardFireSquare
        and PNC.BehaviorFireSafety.IsHazardFireSquare(bodySquare) == true
        or false
    if onFire or onHazardFire then
        if state.phase ~= "idle" then
            clearAction(record, zombie, "fire_hazard")
        end
        return false
    end
    if partId and requiresMedicalItem(Treatment, record)
        and not Treatment.HasNPCBandage(record)
        and not (Treatment.GetNPCSplintPlan and Treatment.GetNPCSplintPlan(record, partId))
    then
        if PNC.NeedSupplyBridge and PNC.NeedSupplyBridge.EnsureMedical then
            PNC.NeedSupplyBridge.EnsureMedical(record, "BANDAGE", partId, false)
        end
        if PNC.ProvisionScheduler and PNC.ProvisionScheduler.MarkDirty then
            PNC.ProvisionScheduler.MarkDirty(record, "bandage", 0)
        end
        if PNC.WorldItemService and PNC.WorldItemService.RequestBandageRip then
            PNC.WorldItemService.RequestBandageRip(record, {
                urgent = true,
                targetCount = 1,
                source = "wounded_no_bandage",
            })
        end
        if state.phase ~= "idle" then
            clearAction(record, zombie, "missing_bandage")
        end
        return false
    end

    safetyRadius = tonumber(Const.NPC_ZOMBIE_DEFENSE_RADIUS)
        or tonumber(Const.SELF_BANDAGE_INTERRUPT_RADIUS)
        or 2.2
    baseSafetyRadius = safetyRadius
    if Perception and Perception.FindNPCGroupAlert then
        groupAlert = Perception.FindNPCGroupAlert(
            record,
            tonumber(Const.NPC_GROUP_ALERT_RADIUS) or safetyRadius,
            true
        )
        if groupAlert then
            safetyRadius = math.max(
                safetyRadius,
                tonumber(groupAlert.alertRadius)
                    or tonumber(Const.NPC_GROUP_ALERT_RADIUS)
                    or safetyRadius
            )
        end
    end
    threat = Perception and Perception.ResolveRecentAttacker
        and Perception.ResolveRecentAttacker(record, now) or nil
    if not insideSafetyRadius(threat, baseSafetyRadius) then
        threat = nil
    end
    if not threat and Perception and Perception.FindImmediateZombieThreat then
        threat = Perception.FindImmediateZombieThreat(
            record,
            baseSafetyRadius
        )
    end
    if not threat then
        threat = findThreat(record, baseSafetyRadius)
    end
    if not threat then
        threat = groupAlert
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
        local usingSplint = state.useSplint
        if usingSplint then
            applied, label = Treatment.TryNPCSplint(record, state.partId)
        else
            applied, label = Treatment.TryNPCBandage(record, state.partId, { bandageType = state.bandageType })
        end
        if zombie and Animation and Animation.FinishBump then
            Animation.FinishBump(zombie, true)
        end
        state.phase = "idle"
        state.partId = nil
        state.bandageType = nil
        state.useSplint = nil
        state.bandageName = nil
        state.finishAt = 0
        state.retryAt = now + (applied and 750
            or (tonumber(Const.SELF_BANDAGE_RETRY_MS) or 5000))
        state.lastResult = applied and (usingSplint and "splinted" or "bandaged") or tostring(label or "failed")
        record.runtime.tacticalState = nil
        if applied then
            record.runtime.forceSyncEvent = usingSplint and "splinted" or "self_bandaged"
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
    if not partId and healedPart then
        return removeHealedDressing(Wounds, Treatment, record, zombie, healedPart, healedKind, now, state)
    end
    return startBandage(record, zombie, partId, now)
end

return Behavior
