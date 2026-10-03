-- Ambient objective refresh and target invalidation.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local H = PNC.MobileGroupDirectorInternal
local Internal = H.Internal
local Constants = PNC.FactionConstants
local Factions = PNC.Factions
local Config = PNC.DirectorConfig or {}
local beginDiagnosticTiming = Internal.AmbientTargets.beginDiagnosticTiming
local endDiagnosticTiming = Internal.AmbientTargets.endDiagnosticTiming
local incrementDiagnostic = Internal.incrementDiagnostic or function() end
local setDiagnosticGauge = Internal.setDiagnosticGauge or function() end
local finite = Internal.AmbientTargets.finite
local shelterTargetIsLocal = Internal.AmbientTargets.shelterTargetIsLocal
local ambientOwnershipSnapshot = Internal.ambientOwnershipSnapshot
local updateMobile = Internal.updateMobile
local memberRecords = Internal.memberRecords

function H.RefreshAmbient(faction, at, context)
    local mobile = faction and faction.mobile or nil
    if not mobile
        or mobile.controlMode ~= Constants.MOBILE_CONTROL_AMBIENT
    then
        return faction, false
    end
    if H.IsPlayerRoamArea and H.IsPlayerRoamArea(mobile) then
        return faction, false
    end
    if mobile.activity
        == Constants.MOBILE_ACTIVITY_TRAVELING_TO_SETTLEMENT
    then
        return faction, false
    end
    local timingName, timingStart = beginDiagnosticTiming(
        "MobileAmbient.RefreshAmbient"
    )
    local phase = H.AmbientPhase(at)
    local ambient = mobile.ambient or {}
    local objective = phase == Constants.MOBILE_AMBIENT_DAY
        and Constants.MOBILE_AMBIENT_ROAD
        or Constants.MOBILE_AMBIENT_SHELTER
    local target = ambient.target
    local staleShelterTarget = ambient.objective
        == Constants.MOBILE_AMBIENT_SHELTER
        and target ~= nil
        and not shelterTargetIsLocal(mobile, target)
    if staleShelterTarget then
        ambient = {
            phase = phase,
            objective = nil,
            target = nil,
            holdForNoShelter = true,
            nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
            nextObjectiveAt = at,
            retryAt = at,
            revision = (tonumber(ambient.revision) or 0) + 1,
        }
        faction = updateMobile(faction, {
            ambient = ambient,
        }, "mobile_ambient_shelter_out_of_range")
        mobile = faction.mobile or mobile
        ambient = mobile.ambient or ambient
        target = nil
    end
    local needsTarget = ambient.phase ~= phase
        or ambient.objective ~= objective
        or not target
        or at >= (tonumber(ambient.nextObjectiveAt) or 0)
    local targetSelectionDue = needsTarget
        and at >= (tonumber(ambient.retryAt) or 0)
    local targetSelectionAllowed = not context
        or context.ambientTargetSelectionBudget == nil
        or context.ambientTargetSelectionBudget > 0
    local checkDue = target and at >= (tonumber(ambient.nextCheckAt) or 0)
    local ownershipSnapshot
    if objective == Constants.MOBILE_AMBIENT_SHELTER
        and ((targetSelectionDue and targetSelectionAllowed) or checkDue)
    then
        ownershipSnapshot = ambientOwnershipSnapshot(context)
    end
    if targetSelectionDue and not targetSelectionAllowed then
        -- Leave the objective due for the next pump. This keeps target
        -- discovery resumable without changing its eventual result.
        incrementDiagnostic("MobileAmbient.TargetSelectionDeferred")
        if staleShelterTarget then H.RepairMobileOrders(faction) end
        endDiagnosticTiming(timingName, timingStart, "selection_deferred")
        return faction, target ~= nil
    end
    if targetSelectionDue then
        incrementDiagnostic("MobileAmbient.TargetSelections")
        if context and context.ambientTargetSelectionBudget ~= nil then
            context.ambientTargetSelectionBudget =
                context.ambientTargetSelectionBudget - 1
            context.ambientTargetSelections =
                (tonumber(context.ambientTargetSelections) or 0) + 1
        end
        local selected
        if objective == Constants.MOBILE_AMBIENT_ROAD then
            incrementDiagnostic("MobileAmbient.RoadSelections")
            selected = H.FindRoadTarget(faction)
        else
            incrementDiagnostic("MobileAmbient.ShelterSelections")
            selected = H.FindShelterTarget(
                faction,
                at,
                ownershipSnapshot
            )
        end
        if type(selected) == "table" then
            target = selected
            ambient = {
                phase = phase,
                objective = objective,
                target = target,
                nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
                nextObjectiveAt = at + Constants.MOBILE_AMBIENT_OBJECTIVE_HOURS,
                retryAt = 0,
                revision = (tonumber(ambient.revision) or 0) + 1,
            }
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_objective")
            H.SyncAbstractObjective(faction, objective, target, at)
        else
            ambient = {
                phase = phase,
                objective = nil,
                target = nil,
                holdForNoShelter = objective
                    == Constants.MOBILE_AMBIENT_SHELTER,
                nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS,
                nextObjectiveAt = at,
                retryAt = at + Constants.MOBILE_AMBIENT_RETRY_HOURS,
                revision = (tonumber(ambient.revision) or 0) + 1,
            }
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_target_retry")
        end
    elseif target and checkDue then
        if objective == Constants.MOBILE_AMBIENT_SHELTER
            and not H.IsValidShelterSite({
                kind = "building",
                home = { x = target.x, y = target.y, z = target.z },
                bounds = target.bounds,
            }, ownershipSnapshot)
        then
            ambient.nextObjectiveAt = at
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_shelter_invalidated")
        else
            ambient.nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_objective_checked")
        end
    end
    if objective ~= Constants.MOBILE_AMBIENT_SHELTER
        and PNC.AmbientVisitService
        and PNC.AmbientVisitService.ReleaseMobileShelter
    then
        for _, record in ipairs(memberRecords(faction)) do
            PNC.AmbientVisitService.ReleaseMobileShelter(
                record,
                "mobile_shelter_day_started",
                at
            )
        end
    end
    H.RepairMobileOrders(faction)
    endDiagnosticTiming(
        timingName,
        timingStart,
        target and "target" or "no_target"
    )
    return faction, target ~= nil
end

return H
