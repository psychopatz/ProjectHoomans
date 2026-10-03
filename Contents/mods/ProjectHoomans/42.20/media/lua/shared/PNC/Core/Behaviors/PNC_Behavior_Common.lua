--[[
    PNC Behavior Common
    Shared behavior helpers for combat debug state, owner resolution, and
    movement intent routing. Focused modules call through here instead of
    reimplementing the same record mutations.
]]

PNC = PNC or {}
PNC.BehaviorCommon = PNC.BehaviorCommon or {}

local Common = PNC.BehaviorCommon
local Core = PNC.Core
local Const = PNC.Const
local PathService = PNC.PathService
local Equipment = PNC.Equipment
local Combat = PNC.Combat
local NavigationRouter = PNC.NavigationRouter
local Diagnostics = PNC.PerformanceScalingDiagnostics
local ActorControl = PNC.ActorControl

local function resolveMoveIntent()
    return PNC.BehaviorMoveIntent
end

function Common.SetCombatDebug(record, target, reason, modeResolved, weaponStatus)
    record.runtime = record.runtime or {}
    record.runtime.targetKind = target and target.kind or "none"
    record.runtime.combatModeResolved = modeResolved or tostring(record.weaponMode or "melee")
    record.runtime.weaponStatus = weaponStatus or record.runtime.weaponStatus or "unknown"
    record.runtime.combatBlockReason = reason or "idle"
end

-- The runtime target is a combat lease, never a movement destination. Keep
-- every producer on one write path so a passive presentation can distinguish
-- an owned combat handoff from stale or foreign state.
function Common.SetCombatTarget(record, target, source)
    local runtime
    if not record or type(target) ~= "table" or target.kind == nil then
        return false
    end
    record.runtime = record.runtime or {}
    runtime = record.runtime
    runtime.target = target
    runtime.targetSource = tostring(source or "combat")
    runtime.targetAt = Core and Core.Now and Core.Now() or nil
    -- Acquiring a target is the instant fighting mode begins.  Start the
    -- weapon-drawn hold here so presentation never depends on the next
    -- engagement tick having already run.
    if PNC.CombatStance and PNC.CombatStance.Maintain then
        PNC.CombatStance.Maintain(record, runtime.targetAt)
    end
    if Diagnostics and Diagnostics.NPCThreatAuditEnabled == true
        and Diagnostics.LogNPCThreatAudit
    then
        Diagnostics.LogNPCThreatAudit("combat_target_set", {
            "npc=" .. tostring(record.id or ""),
            "targetKind=" .. tostring(target.kind or ""),
            "targetId=" .. tostring(target.zombieId or target.id or ""),
            "source=" .. tostring(source or "combat"),
            "proximityAlert=" .. tostring(target.proximityAlert == true),
            "alertOnly=" .. tostring(target.alertOnly == true),
        })
    end
    return true
end

function Common.ClearCombatTarget(record, reason, zombie)
    local equipmentInfo = Equipment.Describe(record)
    local combatTactics = PNC.CombatTactics
    local committedAttack
    local previousTarget = record and record.runtime
        and record.runtime.target or nil
    record.runtime = record.runtime or {}
    record.runtime.target = nil
    record.runtime.targetSource = nil
    record.runtime.targetAt = nil
    if Diagnostics and Diagnostics.NPCThreatAuditEnabled == true
        and Diagnostics.LogNPCThreatAudit
    then
        Diagnostics.LogNPCThreatAudit("combat_target_clear", {
            "npc=" .. tostring(record and record.id or ""),
            "targetKind=" .. tostring(previousTarget
                and previousTarget.kind or ""),
            "targetId=" .. tostring(previousTarget
                and (previousTarget.zombieId or previousTarget.id) or ""),
            "reason=" .. tostring(reason or "no_target"),
            "behavior=" .. tostring(record and record.activeBehavior or ""),
        })
    end
    if combatTactics and combatTactics.EndStaminaRecovery then
        combatTactics.EndStaminaRecovery(record)
    end
    committedAttack = Combat and Combat.HasActiveAttack
        and Combat.HasActiveAttack(record, Core.Now())
        or false
    if not committedAttack then
        -- A combat hold is useful while a target is being reassessed, but an
        -- explicit disengage is authoritative. Leaving the old lease alive
        -- kept both the activity label and weapon presentation in Fighting
        -- after ordinary movement had already resumed.
        record.runtime.inCombatUntil = 0
    end
    if not zombie and PNC.Registry and PNC.Registry.GetLiveZombie then
        zombie = PNC.Registry.GetLiveZombie(record.id)
    end
    if Equipment.ApplyCombatState and zombie then
        Equipment.ApplyCombatState(zombie, record, committedAttack)
    end
    Common.SetCombatDebug(
        record,
        nil,
        reason or "no_target",
        equipmentInfo.combatModeResolved or tostring(record.weaponMode or "melee"),
        equipmentInfo.weaponStatus or record.runtime.weaponStatus
    )
end

function Common.GetOwner(record)
    if not record then return nil end
    local username = record.ownerUsername
    local owner = Core.ResolvePlayerByOnlineID(record.ownerOnlineID)
    if owner then
        if username == nil
            or not owner.getUsername
            or owner:getUsername() == username
        then
            return owner
        end
    end
    return Core.ResolvePlayerByUsername(username)
end

-- Returns the already-selected hostile target only while a follow-order
-- companion still has an active combat lane.  This is deliberately a pure
-- state check: callers must not use it as a reason to start a perception
-- scan.  Presence and social systems use this same predicate so an abstract
-- transition cannot disagree with the abandonment attribution.
function Common.IsActiveFollowCombatTarget(record, now)
    local orderSpec = record and record.orderSpec or nil
    local runtime = record and record.runtime or nil
    local target = runtime and runtime.target or nil
    local followState = runtime and runtime.followState or nil
    local mode = followState and tostring(followState.mode or "") or ""
    local attack = runtime and runtime.attackAction or nil
    local attackActive = false
    local modeActive = mode == "combat"
        or mode == "combat_self_defense"
        or mode == "combat_retreat"
    local kind
    if not orderSpec
        or tostring(orderSpec.kind or "") ~= tostring(Const.ORDER_FOLLOW or "follow")
        or type(target) ~= "table"
    then
        return nil
    end
    kind = tostring(target.kind or "")
    if kind ~= "zombie" and kind ~= "npc" then return nil end
    now = tonumber(now)
    if now == nil and Core and Core.Now then now = Core.Now() end
    if type(attack) == "table" and now ~= nil then
        attackActive = tonumber(attack.finishAt) ~= nil
            and now < tonumber(attack.finishAt)
    end
    if not modeActive and not attackActive then return nil end
    return target, kind, modeActive and "follow_combat_mode"
        or "follow_attack_action"
end


function Common.ResolveCombatApproachMode(dist, preferredMode)
    if preferredMode == "run" and tonumber(dist) and tonumber(dist) <= 3.5 then
        return "walk"
    end
    return preferredMode
end

Common.Internal = Common.Internal or {}
Common.Internal.MovementHalt = {
    Const = Const,
    PathService = PathService,
    ActorControl = ActorControl,
    resolveMoveIntent = resolveMoveIntent,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_MovementHalt"
Common.Internal.StationaryMovementHold = {
    Core = Core,
    Diagnostics = Diagnostics,
    HaltMovement = Common.HaltMovement,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_StationaryMovementHold"
Common.Internal.MovementRouting = {
    NavigationRouter = NavigationRouter,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_MovementRouting"
Common.Internal.MovementDispatch = {
    Const = Const,
    PathService = PathService,
    resolveMoveIntent = resolveMoveIntent,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_MovementDispatch"
Common.Internal.MoveRecordSeatingAudit = {
    Diagnostics = Diagnostics,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_MoveRecord_SeatingAudit"
Common.Internal.MoveRecord = {
    Const = Const,
    PathService = PathService,
    ActorControl = ActorControl,
    SeatingAudit = Common.Internal.MoveRecordSeatingAudit,
}
require "PNC/Core/Behaviors/PNC_Behavior_Common_MoveRecord"
