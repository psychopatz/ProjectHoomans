--[[
    PNC Behavior System
    Thin coordinator for live and abstract NPC behavior ticks. Focused job,
    combat, targeting, and common helpers live in separate Lua files so this
    entry point stays small and scalable.
]]

require "PNC/Core/Behaviors/PNC_Behavior_MoveIntent"
require "PNC/Core/Behaviors/PNC_Behavior_Common"
require "PNC/Core/Behaviors/PNC_Behavior_Targeting"
require "PNC/Core/Combat/PNC_Combat_Engagement"
require "PNC/Core/Behaviors/PNC_Behavior_Combat"
require "PNC/Core/Behaviors/PNC_BehaviorRegistry"
require "PNC/Core/Behaviors/PNC_Behavior_Travel"
require "PNC/Core/Behaviors/PNC_Behavior_AtHome"
require "PNC/Core/Behaviors/PNC_Behavior_AtCamp"
require "PNC/Core/Behaviors/PNC_Behavior_CorpseHaul"
require "PNC/Core/Behaviors/PNC_Behavior_Lumber"
require "PNC/Core/Behaviors/PNC_Behavior_Fishing"
require "PNC/Core/Behaviors/PNC_Behavior_Incapacitated"
require "PNC/Core/Behaviors/PNC_Behavior_Treatment"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion"
require "PNC/Core/Behaviors/PNC_Behavior_SeatedThreat"
require "PNC/Core/Behaviors/PNC_Behavior_Hostile"
require "PNC/Core/Behaviors/PNC_Behavior_Roaming"

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local JobSystem = PNC.JobSystem
local Animation = PNC.Animation
local Common = PNC.BehaviorCommon
local Registry = PNC.BehaviorRegistry
local Incapacitated = PNC.BehaviorIncapacitated
local Treatment = PNC.BehaviorTreatment
local Companion = PNC.BehaviorCompanion
local Hostile = PNC.BehaviorHostile
local Combat = PNC.BehaviorCombat
local SeatedThreat = PNC.BehaviorSeatedThreat
local AnimationScenes = PNC.AnimationScenes
local LiveBodyControl = PNC.LiveBodyControl
local ScalingDiagnostics = PNC.PerformanceScalingDiagnostics

local function clearStaleFacilityState(record, zombie)
    local runtime = record and record.runtime or nil
    local activity = runtime and runtime.facilityActivity or nil
    local orderKind = tostring(record and record.orderSpec
        and record.orderSpec.kind or "")
    local scene = runtime and runtime.animationScene or nil
    local definition

    if orderKind == "facility_activity" then return false end
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
            and AnimationScenes.Stop
        then
            AnimationScenes.Stop(record, zombie, "stale_facility_scene")
            return true
        end
    end
    return false
end

function Behavior.Tick(record, zombie, now)
    local job
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

    -- Knockdown owns the actor before scenes, attacks, movement, or ordinary
    -- jobs. This guarantees a grounded NPC cannot start an attack lease that
    -- prevents its get-up recovery.
    if LiveBodyControl and LiveBodyControl.TickGroundedRecovery
        and LiveBodyControl.TickGroundedRecovery(record, zombie, now)
    then
        return
    end

    -- Scenes are presentation leases, never tactical locks. Cancel an
    -- interruptible sequence before committed combat, treatment, or movement
    -- gets its turn so an ambient pose cannot delay a survival response.
    if AnimationScenes and AnimationScenes.InterruptForSafety then
        AnimationScenes.InterruptForSafety(
            record,
            zombie,
            now
        )
    end

    -- A committed windup owns the actor until its delayed hit/finish frame.
    -- Perception may legitimately return no fresh target for one frame, but
    -- that must not holster the weapon or abandon the animation in progress.
    if Combat and Combat.TickCommittedAction
        and Combat.TickCommittedAction(record, zombie)
    then
        return
    end

    -- Automatic ambient seating is a blocking presentation scene. Give it a
    -- narrow perception/combat handoff before the scene can consume the tick;
    -- the arbiter keeps the facility activity alive for later resumption.
    if SeatedThreat and SeatedThreat.Tick
        and SeatedThreat.Tick(record, zombie, now)
    then
        return
    end

    if AnimationScenes and AnimationScenes.Tick
        and AnimationScenes.Tick(record, zombie, now)
    then
        return
    end

    if Treatment and Treatment.Tick and Treatment.Tick(record, zombie, now) then
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

    if Companion.Tick(record, zombie, job) then
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
