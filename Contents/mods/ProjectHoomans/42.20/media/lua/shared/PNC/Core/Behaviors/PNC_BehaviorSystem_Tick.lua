-- Ordered behavior tick provider. The surrounding file remains the
-- composition root for helper ownership and module load order.

PNC = PNC or {}
PNC.BehaviorSystem = PNC.BehaviorSystem or {}

local Behavior = PNC.BehaviorSystem
local H = Behavior.Internal and Behavior.Internal.Tick
if type(H) ~= "table" then return Behavior end

local ScalingDiagnostics = H.ScalingDiagnostics
local ActionPlanOwnership = H.ActionPlanOwnership
local Preflight = H.Preflight
local Ownership = H.Ownership
local Dispatch = H.Dispatch

function Behavior.Tick(record, zombie, now)
    local previousJob = record and record.activeJob or nil

    -- Behavior state, movement leases, and combat targets are authoritative
    -- writes. The server tick owns them in MP; the same authority path is
    -- used by singleplayer/listen-server. Keep a shared-load client from
    -- mutating the decision state if a future hook calls this entry point.
    if PNC.Core and type(PNC.Core.IsAuthority) == "function"
        and PNC.Core.IsAuthority() ~= true
    then
        return false
    end

    if ScalingDiagnostics then
        ScalingDiagnostics.Increment("NPCDecisions.BehaviorTicks")
    end

    if Preflight and Preflight.Run
        and Preflight.Run(record, zombie, now)
    then
        return
    end
    -- Preflight.Run preserves the existing early ownership order:
    -- OrderSystem.RecoverStalled(record, zombie, now)

    -- Ownership.Run preserves the existing lease order:
    -- Combat.TickCommittedAction(record, zombie)
    -- ThreatGuard.Tick(record, zombie, now)
    -- AnimationScenes.InterruptForSafety(
    -- Treatment.Tick(record, zombie, now)
    -- Ordered tactical, presentation, roaming, and treatment leases must
    -- retain their original priority before ordinary job dispatch.
    if Ownership and Ownership.Run
        and Ownership.Run(record, zombie, now)
    then
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

    return Dispatch.Run(record, zombie, now, previousJob)
end

return Behavior
