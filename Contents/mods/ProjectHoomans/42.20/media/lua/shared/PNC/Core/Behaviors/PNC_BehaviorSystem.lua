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

function Behavior.Tick(record, zombie, now)
    local job
    local companionHandled
    local previousJob = record and record.activeJob or nil

    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.BehaviorTicks")
    end

    if record.alive == false then
        if AnimationScenes and AnimationScenes.Stop then
            AnimationScenes.Stop(
                record,
                zombie,
                "npc_dead"
            )
        end
        record.activeJob = "Dead"
        record.activeBehavior = "Dead"
        Common.ClearCombatTarget(record, "dead")
        if zombie then
            Animation.Apply(zombie, record, "Idle")
        end
        return
    end

    -- Sleep teardown owns the actor until native bump release, valid exit
    -- placement, surface cleanup, and reservation release have completed.
    -- This must run before Puppet/scene/job ownership, otherwise a newly
    -- requested presentation scene can leave the NPC visibly stuck in the
    -- old sleep state.
    if tickPendingSleepWake(record, zombie) then
        return
    end

    -- The Puppet lease suspends every ordinary behavior before recovery,
    -- stale-provider repair, or job selection can issue a competing write.
    -- Safety boundaries deliberately fall through so combat, vehicles,
    -- traversal, and grounded recovery can abort the scene and take control.
    if puppetOperaOwnsBehavior(record)
        and not puppetOperaSafetyBoundary(record, zombie, now)
    then
        return
    end

    -- Direct follow/guard/patrol/roam/travel orders do not own a Tasking
    -- lease, so give them the same bounded liveness boundary. The recovery
    -- probe observes PathService and re-issues the order only after a real
    -- movement/action timeout; legitimate holds and traversal passages pass
    -- through untouched.
    if OrderSystem and OrderSystem.RecoverStalled
        and OrderSystem.RecoverStalled(record, zombie, now)
    then
        return
    end

    -- An order command can arrive after a scene callback has already failed
    -- or after an older build left only the runtime activity behind. Repair
    -- that stale presentation lease before it can consume this tick again.
    clearStaleFacilityState(record, zombie)

    if record.health and record.health.state == "incapacitated" then
        if AnimationScenes and AnimationScenes.Stop then
            AnimationScenes.Stop(
                record,
                zombie,
                "npc_incapacitated"
            )
        end
        Incapacitated.Tick(record, zombie)
        return
    end

    -- Abstract followers have no IsoZombie and therefore must not pass
    -- through live-only seating, perception, animation, or engine-pathing
    -- gates. Their durable follow order is advanced by a bounded lightweight
    -- controller until presence reconciliation materializes them again.
    if isAbstractFollowRecord(record)
        and Companion
        and Companion.Internal
        and Companion.Internal.TickAbstractFollowOwner
    then
        Companion.Internal.TickAbstractFollowOwner(record, now)
        return
    end

    -- Knockdown owns the actor before scenes, attacks, movement, or ordinary
    -- jobs. This guarantees a grounded NPC cannot start an attack lease that
    -- prevents its get-up recovery.
    if LiveBodyControl and LiveBodyControl.TickGroundedRecovery
        and LiveBodyControl.TickGroundedRecovery(record, zombie, now)
    then
        return
    end

    -- A committed windup owns the actor until its delayed hit/finish frame.
    -- Perception may legitimately return no fresh target for one frame, but
    -- that must not holster the weapon or abandon the animation in progress.
    if Combat and Combat.TickCommittedAction
        and Combat.TickCommittedAction(record, zombie)
    then
        return
    end

    -- ThreatGuard is the single tactical owner for passive orders and
    -- presentation leases. It runs before any job or scene can clear its
    -- target, while the original order remains available for resumption.
    if ThreatGuard and ThreatGuard.Tick
        and ThreatGuard.Tick(record, zombie, now)
    then
        return
    end

    -- Scenes are presentation leases, never tactical locks. ThreatGuard must
    -- validate or claim a passive threat before this safety check runs; if it
    -- rejects a stale target it also clears the combat lease, allowing the
    -- original seat/sleep activity to continue without a restart loop.
    if AnimationScenes and AnimationScenes.InterruptForSafety then
        AnimationScenes.InterruptForSafety(
            record,
            zombie,
            now
        )
    end

    -- Puppet Opera is a temporary presentation lease. ThreatGuard and the
    -- committed-combat fence above still win; once they yield, do not let a
    -- normal job/ambient/scene tick overwrite the session's movement lane.
    -- The server-side lease owns the corresponding restore handoff.
    if puppetOperaOwnsBehavior(record) then
        return
    end

    -- Roaming ambience is a transient presentation lease. It is evaluated
    -- before seating so a night-time bed choice wins over a chair, while the
    -- service itself remains server-loaded and dynamically resolved here.
    local roamingAmbient = PNC.RoamAmbient
    if roamingAmbient and roamingAmbient.Tick
        and roamingAmbient.Tick(record, zombie, now)
    then
        return
    end

    -- A roaming seat is a transient presentation lease. It owns only the
    -- live route/scene while active; the durable roam order remains intact.
    -- The server service is loaded after this shared coordinator, so resolve
    -- it dynamically instead of capturing a nil module at load time.
    local roamingSeat = PNC.RoamingSeat
    if roamingSeat and roamingSeat.Tick
        and roamingSeat.Tick(record, zombie, now)
    then
        return
    end

    if AnimationScenes and AnimationScenes.Tick
        and AnimationScenes.Tick(record, zombie, now)
    then
        return
    end

    -- A doctor lease owns the actor before self-treatment and job selection.
    -- Without this fence a wounded doctor could start self-bandaging while
    -- the server medical executor was walking it to another patient.
    if record.runtime and record.runtime.medicalCare then
        return
    end

    if Treatment and Treatment.Tick and Treatment.Tick(record, zombie, now) then
        return
    end

    -- Semantic action plans are an exclusive, resumable execution lease for
    -- ordinary behavior. Safety/combat gates above retain priority; once they
    -- yield, the plan provider owns the actor until its current step changes.
    -- This prevents the normal job selector from overwriting a provider's
    -- movement intent between the Tasking pump and PathService.Pump.
    local planOwner = ActionPlanOwnership
        and ActionPlanOwnership.Get
        and ActionPlanOwnership.Get(record) or nil
    if planOwner then
        record.activeJob = "SemanticActionPlan"
        record.activeBehavior = "SemanticActionPlan:"
            .. tostring(planOwner.action or "unknown")
        return
    end

    job = JobSystem.Select(record)
    if ScalingDiagnostics then
        if previousJob == job then
            ScalingDiagnostics.Increment(
                "NPCDecisions.BehaviorSameJobReselections"
            )
        elseif previousJob ~= nil then
            ScalingDiagnostics.Increment(
                "NPCDecisions.BehaviorJobSwitches"
            )
        end
    end
    record.activeJob = job
    record.activeBehavior = job

    if Registry.Tick(record, zombie, job, now) then
        return
    end

    companionHandled = Companion.Tick(record, zombie, job)
    finishFollowerReconcile(record, job, companionHandled, now)
    if companionHandled then
        return
    end

    if Hostile.Tick(record, zombie, job) then
        return
    end

    Common.ClearCombatTarget(record, "idle")
    if zombie then
        Animation.Apply(zombie, record, "Idle")
    end
end
