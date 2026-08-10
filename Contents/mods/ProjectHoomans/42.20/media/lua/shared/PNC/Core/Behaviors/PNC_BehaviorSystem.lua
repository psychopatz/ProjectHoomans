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
require "PNC/Core/Behaviors/PNC_Behavior_Incapacitated"
require "PNC/Core/Behaviors/PNC_Behavior_Treatment"
require "PNC/Core/Behaviors/BehaviorCompanion/PNC_BehaviorCompanion"
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
local AnimationScenes = PNC.AnimationScenes

function Behavior.Tick(record, zombie, now)
    local job

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

    if AnimationScenes and AnimationScenes.Tick
        and AnimationScenes.Tick(record, zombie, now)
    then
        return
    end

    if Treatment and Treatment.Tick and Treatment.Tick(record, zombie, now) then
        return
    end

    job = JobSystem.Select(record)
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
