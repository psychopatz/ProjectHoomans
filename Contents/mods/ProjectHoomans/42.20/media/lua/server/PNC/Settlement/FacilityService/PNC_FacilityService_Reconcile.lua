--[[
    Facility construction-state reconciliation.

    A facility that is not BUILT depends on a live work order to make progress.
    If that order disappears (cancelled elsewhere, dropped on load, completed
    without finalizing) the facility stays in PLANNED / UNDER_CONSTRUCTION /
    RECONSTRUCTING forever, and several of those states are lock-outs:

      * a PLANNED stockpile loses storage access (`GetStockpile(base, true)`),
        which locks the colony out of its own stockpile;
      * the Command Hub hides the stockpile build button once a stockpile record
        exists at all, and the FACILITIES tab never lists the stockpile, so a
        stuck stockpile has no rebuild path in the UI at all;
      * the CANCEL CONSTRUCTION action needs an active order, so with the order
        gone the button silently does nothing.

    This module heals those states from evidence instead of leaving the player
    soft-locked, and reports every repair so the cause is visible in the log.
]]
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityService = PNC.FacilityService or {}
PNC.FacilityService.Internal = PNC.FacilityService.Internal or {}

local Service = PNC.FacilityService
local Repository = PNC.SettlementRepository
local FacilityState = require "PNC/Core/Settlement/PNC_FacilityState"

local TERMINAL = { COMPLETED = true, CANCELLED = true }

local function logInfo(message)
    if PNC.Core and PNC.Core.LogInfo then PNC.Core.LogInfo(message)
    else print("[PNC][INFO] " .. message) end
end

local function logWarn(message)
    if PNC.Core and PNC.Core.LogWarn then PNC.Core.LogWarn(message)
    else print("[PNC][WARN] " .. message) end
end

-- A work order still owns the facility only while it can still finish.
local function orderIsLive(orderId)
    orderId = tostring(orderId or "")
    if orderId == "" then return false end
    local queries = PNC.WorkService and PNC.WorkService.Queries
    local order = queries and type(queries.Get) == "function"
        and queries.Get(orderId) or nil
    if not order then return false end
    return TERMINAL[tostring(order.status or "")] ~= true
end

local function storageForBase(base)
    local repo = PNC.ColonyStorageRepository
    if not repo or type(repo.GetForSettlement) ~= "function" then return nil end
    return repo.GetForSettlement(base and (base.colonyId or base.settlementId)
        or nil)
end

-- Which state, if any, a stuck facility should be restored to. Returns
-- (state, reason); nil means "leave it, it can still be rebuilt from the UI".
local function repairedStateFor(facility, base)
    local state = FacilityState.ConstructionState(facility)
    if state == "BUILT" then return nil end
    if state == "RECONSTRUCTING" then
        -- A reconstruct can only follow a completed build, so the facility was
        -- operational before the order was lost.
        return facility.previousConstructionState or "BUILT",
            "reconstruct_order_missing"
    end
    -- A stockpile with a live storage record that the colony is already using
    -- was completed at some point; leaving it PLANNED locks storage access.
    if tostring(facility.definitionId or "") == "stockpile"
        and storageForBase(base)
    then
        return "BUILT", "stockpile_storage_present"
    end
    return nil
end

local function applyRepair(base, facility, target, reason, fromState)
    facility.constructionState = target
    facility.constructionWorkOrderId = nil
    if Service.RefreshState then Service.RefreshState(facility) end
    local internal = Service.Internal
    if internal and type(internal.touch) == "function" then
        internal.touch(base, facility)
    end
    if internal and type(internal.updateState) == "function" then
        internal.updateState(base, facility)
    end
    Repository.MarkDirty()
    logWarn("facility_state_repaired facility=" .. tostring(facility.id)
        .. " definition=" .. tostring(facility.definitionId)
        .. " from=" .. tostring(fromState) .. " to=" .. tostring(target)
        .. " reason=" .. tostring(reason))
end

--[[
    Heals every facility of a base whose construction can no longer progress.
    Returns the number of repairs and a report table for the caller/UI.
]]
function Service.ReconcileConstructionStates(baseOrId)
    Repository.Load()
    local base = type(baseOrId) == "table" and baseOrId
        or (PNC.BaseService and PNC.BaseService.Get(baseOrId)) or nil
    if not base then return 0, {} end
    local report = {}
    for facilityId in pairs(base.facilityIds or {}) do
        local facility = Repository.GetFacility(facilityId)
        if facility then
            local orderId = facility.constructionWorkOrderId
            local state = FacilityState.ConstructionState(facility)
            if state ~= "BUILT" and not orderIsLive(orderId) then
                local target, reason = repairedStateFor(facility, base)
                if not target and orderId then
                    -- Stale reference with nothing to restore: clear it so the
                    -- facility can be queued again cleanly.
                    facility.constructionWorkOrderId = nil
                    Repository.MarkDirty()
                    report[#report + 1] = { facilityId = facility.id,
                        definitionId = facility.definitionId, state = state,
                        reason = "stale_order_reference_cleared" }
                elseif target then
                    report[#report + 1] = { facilityId = facility.id,
                        definitionId = facility.definitionId, state = state,
                        to = target, reason = reason }
                    applyRepair(base, facility, target, reason, state)
                end
            end
        end
    end
    if #report > 0 and Service.RebuildIndexes then Service.RebuildIndexes() end
    return #report, report
end

--[[
    Every base, once. Used by the load-time heal so an already-broken save
    repairs itself instead of requiring the player to find a button.
]]
function Service.ReconcileAllConstructionStates()
    Repository.Load()
    local total = 0
    for _, base in pairs(Repository.State.bases or {}) do
        local count = Service.ReconcileConstructionStates(base)
        total = total + (tonumber(count) or 0)
    end
    if total > 0 then
        logInfo("facility_state_reconcile_complete repaired=" .. tostring(total))
    end
    return total
end

--[[
    Player-facing repair. This is what the Base window's cancel/repair action
    falls back to when a facility has no live order left to cancel.
]]
function Service.ReconcileAction(player, args)
    args = type(args) == "table" and args or {}
    Repository.Load()
    local facility = args.facilityId
        and Repository.GetFacility(args.facilityId) or nil
    local base = facility and PNC.BaseService
        and PNC.BaseService.Get(facility.baseId) or nil
    if not base and args.baseId and PNC.BaseService then
        base = PNC.BaseService.Get(args.baseId)
    end
    if not base then return { ok = false, reason = "BASE_NOT_FOUND" } end
    if PNC.BaseValidationService
        and not PNC.BaseValidationService.CanUse(player, base)
    then
        return { ok = false, reason = "NO_PERMISSION" }
    end
    local count, report = Service.ReconcileConstructionStates(base)
    return { ok = true,
        reason = count > 0 and "FACILITY_STATE_REPAIRED" or "FACILITY_STATE_OK",
        repaired = count, facilities = report }
end

--[[
    Periodic sweep.

    The load-time heal only runs once per session, but an order can also be lost
    mid-session (a cancel that could not resolve its facility, an order dropped
    by another subsystem). A ten-minute sweep over the few facilities of each
    base is negligible and keeps a lock-out from lasting until the next restart.
]]
if Events and Events.EveryTenMinutes and Events.EveryTenMinutes.Add
    and not Service.ReconcileSweepRegistered
then
    Service.ReconcileSweepRegistered = true
    Events.EveryTenMinutes.Add(function()
        local ok, err = pcall(Service.ReconcileAllConstructionStates)
        if not ok then
            logWarn("facility_state_reconcile_failed reason=" .. tostring(err))
        end
    end)
end

return Service
