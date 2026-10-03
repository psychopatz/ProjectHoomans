--[[
    PNC Behavior System
    Thin coordinator for live and abstract NPC behavior ticks. Focused job,
    combat, targeting, and common helpers live in separate Lua files so this
    entry point stays small and scalable.
]]

require "PNC/Core/Behaviors/PNC_Behavior_MoveIntent"
require "PNC/Core/Behaviors/PNC_Behavior_ActionPlanOwnership"
require "PNC/Core/Behaviors/PNC_Behavior_Common"
require "PNC/Core/Behaviors/PNC_Behavior_Targeting"
require "PNC/Core/Combat/PNC_Combat_Stance"
require "PNC/Core/Combat/PNC_Combat_Engagement"
require "PNC/Core/Behaviors/PNC_Behavior_Combat"
require "PNC/Core/Behaviors/PNC_BehaviorRegistry"
require "PNC/Core/Behaviors/PNC_Behavior_Travel"
require "PNC/Core/Behaviors/PNC_Behavior_AtHome"
require "PNC/Core/Behaviors/PNC_Behavior_AtCamp"
require "PNC/Core/Behaviors/PNC_Behavior_Lumber"
require "PNC/Core/Behaviors/PNC_Behavior_Fishing"
require "PNC/Core/Behaviors/PNC_Behavior_Incapacitated"
require "PNC/Core/Behaviors/PNC_Behavior_Treatment"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion"
require "PNC/Core/Behaviors/ThreatGuard/PNC_BehaviorThreatGuard"
require "PNC/Core/Behaviors/PNC_Behavior_Hostile"
require "PNC/Core/Behaviors/PNC_Behavior_Roaming"

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local JobSystem = PNC.JobSystem
local Const = PNC.Const
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon
local OrderSystem = PNC.OrderSystem
local Registry = PNC.BehaviorRegistry
local Incapacitated = PNC.BehaviorIncapacitated
local Treatment = PNC.BehaviorTreatment
local Companion = PNC.BehaviorCompanion
local Hostile = PNC.BehaviorHostile
local Combat = PNC.BehaviorCombat
local ThreatGuard = PNC.BehaviorThreatGuard
local AnimationScenes = PNC.AnimationScenes
local LiveBodyControl = PNC.LiveBodyControl
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics
local ActionPlanOwnership = PNC.BehaviorActionPlanOwnership
local ActorControl = PNC.ActorControl

local function tickPendingSleepWake(record, zombie)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local internal = PNC.FacilityJobsBehaviorInternal
    if not activity
        or tostring(activity.capability or "") ~= "sleep"
        or activity.sleepWakePending ~= true
        or not internal
        or type(internal.TickSleepWake) ~= "function"
    then
        return false
    end
    -- A replacement animation scene is allowed to exist while an order
    -- callback is unwinding, but it must not consume the tick that releases
    -- the old sleep carrier. The wake transaction itself enforces authority
    -- and ActorControl checks before any position or reservation write.
    local deadline = tonumber(activity.sleepWakeDeadlineAt)
    local now = PNC.Core and PNC.Core.Now and tonumber(PNC.Core.Now()) or 0
    if deadline
        and now > deadline
            + (tonumber(PNC.Const and PNC.Const.SLEEP_WAKE_HARD_TIMEOUT_MS)
                or 30000)
    then
        -- The transaction could not finish, for example because the record is
        -- abstract and has no body to release. Releasing the gate is safer than
        -- starving every later behavior tick, and the reason stays observable.
        activity.sleepWakePending = nil
        activity.sleepWakeReason = "wake_deadline_exceeded"
        activity.sleepWakeAbandonedAt = now
        runtime.sleepWakePending = nil
        if PNC.Core and PNC.Core.LogWarn then
            PNC.Core.LogWarn(
                "sleep_wake_abandoned npc=" .. tostring(record.id)
                    .. " reason=wake_deadline_exceeded"
                    .. " capability=" .. tostring(activity.capability)
                    .. " phase=" .. tostring(activity.phase)
            )
        end
        return false
    end
    internal.TickSleepWake(record, zombie)
    return true
end

local function puppetOperaOwnsBehavior(record)
    local runtime = record and record.runtime or nil
    local override = runtime and runtime.puppetOperaOverride or nil
    if not override or tostring(override.sessionId or "") == "" then
        return false
    end
    record.activeJob = "PuppetOpera"
    record.activeBehavior = "PuppetOpera:"
        .. tostring(override.sessionId)
    return true
end

local function puppetOperaSafetyBoundary(record, zombie, now)
    if not ActorControl or not ActorControl.IsPuppetOwned
        or not ActorControl.IsPuppetOwned(record)
    then
        return false
    end
    if zombie and zombie.getVehicle and zombie:getVehicle() then
        return true
    end
    if zombie and zombie.isSeatedInVehicle
        and zombie:isSeatedInVehicle()
    then
        return true
    end
    if LiveBodyControl
        and LiveBodyControl.IsPresentationCombatActive
        and LiveBodyControl.IsPresentationCombatActive(record, now)
    then
        return true
    end
    if PNC.PathService and PNC.PathService.IsTraversalActive
        and PNC.PathService.IsTraversalActive(record, zombie)
    then
        return true
    end
    if LiveBodyControl and LiveBodyControl.IsGrounded
        and LiveBodyControl.IsGrounded(zombie)
    then
        return true
    end
    return false
end

local function clearStaleFacilityState(record, zombie)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local orderKind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    local scene = runtime and runtime.animationScene or nil
    local definition

    if orderKind == "facility_activity" then return false end
    -- A valid need activity is authoritative even if a passive order repair
    -- briefly wrote follow/roam back into orderSpec. Explicit commands still
    -- clear this runtime through AbortForOrderChange before reaching here.
    if JobSystem and JobSystem.IsFacilityActivityActive
        and JobSystem.IsFacilityActivityActive(record)
    then
        return false
    end
    if activity and PNC.FacilityJobs
        and PNC.FacilityJobs.AbortForOrderChange
    then
        PNC.FacilityJobs.AbortForOrderChange(
            record, zombie, "stale_facility_activity")
        return true
    end
    if scene and AnimationScenes and AnimationScenes.Get then
        definition = AnimationScenes.Get(scene.id)
        if definition and definition.category == "facility"
            -- The shared ground-sit scene is also used by the transient
            -- roaming-seat service. Its lease is owned by that service, so
            -- do not let facility stale-state repair stop an active sitter.
            and not (runtime and runtime.roamingSeat)
            and AnimationScenes.Stop
        then
            AnimationScenes.Stop(record, zombie, "stale_facility_scene")
            return true
        end
    end
    return false
end

local function isAbstractFollowRecord(record)
    local runtime
    local order
    if not record or record.presenceState ~= Const.PRESENCE_ABSTRACT then
        return false
    end
    runtime = record.runtime or {}
    order = record.orderSpec or {}
    if runtime.vehiclePassenger and runtime.vehiclePassenger.active == true then
        return false
    end
    return tostring(order.kind or "") == tostring(
        Const.ORDER_FOLLOW or "follow"
    )
end

local function finishFollowerReconcile(record, job, handled, now)
    local runtime = record and record.runtime or nil
    local owner
    if not runtime or runtime.followReconcilePending ~= true then
        return
    end
    runtime.followReconcilePending = nil
    if not ScalingDiagnostics
        or not ScalingDiagnostics.IsFollowerPresenceAuditEnabled
        or ScalingDiagnostics.IsFollowerPresenceAuditEnabled() ~= true
        or not ScalingDiagnostics.LogFollowerPresence
    then
        return
    end
    owner = Common.GetOwner(record)
    ScalingDiagnostics.LogFollowerPresence("materialize_follow_reconcile", {
        "npc=" .. tostring(record.id),
        "job=" .. tostring(job or "nil"),
        "handled=" .. tostring(handled == true),
        "owner=" .. tostring(record.ownerUsername or "nil"),
        "ownerOnlineID=" .. tostring(record.ownerOnlineID or "nil"),
        "ownerResolved=" .. tostring(owner ~= nil),
        "activeBehavior=" .. tostring(record.activeBehavior or "nil"),
        "followMode=" .. tostring(runtime.followState
            and runtime.followState.mode or "nil"),
        "moveIntent=" .. tostring(runtime.moveIntent ~= nil),
        "pathPhase=" .. tostring(runtime.pathing
            and runtime.pathing.phase or "nil"),
        "at=" .. tostring(now or "nil"),
    })
end

Behavior.Internal = Behavior.Internal or {}
Behavior.Internal.TickDispatch = {
    JobSystem = JobSystem,
    Animation = Animation,
    Common = Common,
    Registry = Registry,
    Companion = Companion,
    Hostile = Hostile,
    ScalingDiagnostics = ScalingDiagnostics,
    finishFollowerReconcile = finishFollowerReconcile,
}
require "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Dispatch"
Behavior.Internal.TickOwnership = {
    LiveBodyControl = LiveBodyControl,
    Combat = Combat,
    ThreatGuard = ThreatGuard,
    AnimationScenes = AnimationScenes,
    Treatment = Treatment,
    puppetOperaOwnsBehavior = puppetOperaOwnsBehavior,
}
require "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Ownership"
Behavior.Internal.TickPreflight = {
    Animation = Animation,
    Common = Common,
    OrderSystem = OrderSystem,
    Incapacitated = Incapacitated,
    Companion = Companion,
    AnimationScenes = AnimationScenes,
    tickPendingSleepWake = tickPendingSleepWake,
    puppetOperaOwnsBehavior = puppetOperaOwnsBehavior,
    puppetOperaSafetyBoundary = puppetOperaSafetyBoundary,
    clearStaleFacilityState = clearStaleFacilityState,
    isAbstractFollowRecord = isAbstractFollowRecord,
}
require "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick_Preflight"
Behavior.Internal.Tick = {
    ScalingDiagnostics = ScalingDiagnostics,
    ActionPlanOwnership = ActionPlanOwnership,
    Preflight = Behavior.Internal.TickPreflight,
    Dispatch = Behavior.Internal.TickDispatch,
    Ownership = Behavior.Internal.TickOwnership,
}
require "PNC/Core/Behaviors/PNC_BehaviorSystem_Tick"
