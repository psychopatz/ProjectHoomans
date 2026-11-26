-- Shared per-evaluation NPC context snapshot for Tasking, Needs, and Autonomy.
--
-- Computed once per dirty NPC inside Tasking.Internal.Collect so Needs,
-- Autonomy, Work, and Reaction providers all read the same consistent facts
-- (scope, camp placement lock, combat state, home base, sleep need, lease)
-- without duplicating lookups or making conflicting eligibility decisions.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.Tasking = PNC.Tasking or {}
PNC.Tasking.NPCContext = PNC.Tasking.NPCContext or {}

local Context = PNC.Tasking.NPCContext
local ActorControl = PNC.ActorControl
    or require "PNC/Core/ActorControl/PNC_ActorControl"

Context.VERSION = 1
Context._active = Context._active or {}

local function computeSleepActionable(record)
    local needs = PNC.IndividualNeeds
    local queries = needs and needs.Queries
    if queries and type(queries.GetSleepIntent) == "function" then
        return queries.GetSleepIntent(record) ~= nil
    end
    local definitions = PNC.NeedsDefinitions
    local policy = definitions and definitions.SLEEP_TASK
    local fatigue = needs and type(needs.Get) == "function"
        and tonumber(needs.Get(record, "fatigue")) or nil
    return fatigue ~= nil and policy ~= nil
        and fatigue >= (tonumber(policy.actionable) or 0.70)
end

local function computeCampPlacementLocked(record, isCamp, placementState)
    local coordinator = PNC.CampMovementCoordinator
    if coordinator and type(coordinator.IsPlacementLocked) == "function" then
        return coordinator.IsPlacementLocked(record) == true
    end
    if not isCamp then return false end
    return placementState == "queued" or placementState == "moving"
end

function Context.Build(record, now)
    if type(record) ~= "table" then return nil end
    local npcId = tostring(record.id or "")
    local runtime = record.runtime
    local order = record.orderSpec
    local orderKind = tostring(order and order.kind or "")
    local campOrderKind = tostring(PNC.Const and PNC.Const.ORDER_CAMP or "camp")
    local isCamp = orderKind == campOrderKind
    local placementState = isCamp
        and string.lower(tostring(order and order.placementState or "arrived"))
        or nil
    local campPlacementLocked = computeCampPlacementLocked(
        record, isCamp, placementState)
    local homeBase = not isCamp
        and PNC.HomeDutyService and PNC.HomeDutyService.GetBase
        and PNC.HomeDutyService.GetBase(record) or nil
    local isHome = homeBase ~= nil
        and PNC.HomeDutyService and PNC.HomeDutyService.IsAtHome
        and PNC.HomeDutyService.IsAtHome(record, homeBase.id) == true or false
    local scope = isCamp and "camp" or (isHome and "home" or "roam")
    local live = PNC.Registry and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(record.id) or nil
    local isCompanion = PNC.CompanionCommands
        and type(PNC.CompanionCommands.IsCompanion) == "function"
        and PNC.CompanionCommands.IsCompanion(record) == true or false
    local puppetOwned = ActorControl
        and type(ActorControl.IsPuppetOwned) == "function"
        and ActorControl.IsPuppetOwned(record) == true
        and not (type(ActorControl.IsLocomotiveCarrier) == "function"
            and ActorControl.IsLocomotiveCarrier(record) == true)
        or false
    local currentLease = PNC.TaskLeaseService
        and type(PNC.TaskLeaseService.ForNPC) == "function"
        and PNC.TaskLeaseService.ForNPC(record.id) or nil
    local combatActive = (runtime and runtime.target ~= nil)
        or (PNC.NeedFacilityAwayRoutes
            and type(PNC.NeedFacilityAwayRoutes.IsCombatActive) == "function"
            and PNC.NeedFacilityAwayRoutes.IsCombatActive(record) == true)
        or false
    local sleepActionable = computeSleepActionable(record)

    return {
        npcId = npcId,
        record = record,
        live = live,
        at = tonumber(now) or (PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0),
        alive = record.alive ~= false,
        isCompanion = isCompanion,
        puppetOwned = puppetOwned,
        orderKind = orderKind,
        isCamp = isCamp,
        campPlacementState = placementState,
        campPlacementLocked = campPlacementLocked,
        homeBase = homeBase,
        isHome = isHome,
        scope = scope,
        combatActive = combatActive,
        currentLease = currentLease,
        hasWorkOrder = runtime ~= nil and runtime.workOrderId ~= nil,
        hasFacilityActivity = runtime ~= nil and runtime.facilityActivity ~= nil,
        sleepActionable = sleepActionable,
    }
end

function Context.BeginEvaluation(record, now)
    if type(record) ~= "table" or record.id == nil then return nil end
    local snapshot = Context.Build(record, now)
    Context._active[tostring(record.id)] = snapshot
    return snapshot
end

function Context.EndEvaluation(record)
    if type(record) ~= "table" or record.id == nil then return end
    Context._active[tostring(record.id)] = nil
end

function Context.GetActive(recordOrId)
    local id = type(recordOrId) == "table" and recordOrId.id or recordOrId
    if id == nil then return nil end
    return Context._active[tostring(id)]
end

function Context.For(record, now)
    if type(record) ~= "table" then return nil end
    local active = record.id ~= nil and Context._active[tostring(record.id)] or nil
    if active and active.record == record then return active end
    return Context.Build(record, now)
end

return Context
