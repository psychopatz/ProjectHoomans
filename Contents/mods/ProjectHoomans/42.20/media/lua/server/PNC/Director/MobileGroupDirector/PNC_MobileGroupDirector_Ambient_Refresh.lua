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
    local rainShelter = H.IsRainShelterActive
        and H.IsRainShelterActive(context) == true or false
    local chopperShelter = H.IsHelicopterShelterActive
        and H.IsHelicopterShelterActive(context) == true or false
    local ambient = mobile.ambient or {}
    local prevObjective = ambient.objective
    local prevRainShelter = ambient.rainShelter == true
    local prevChopperShelter = ambient.chopperShelter == true
    local objective = (phase == Constants.MOBILE_AMBIENT_DAY and not rainShelter and not chopperShelter)
        and Constants.MOBILE_AMBIENT_ROAD
        or Constants.MOBILE_AMBIENT_SHELTER
    local target = ambient.target
    local staleShelterTarget = ambient.objective
        == Constants.MOBILE_AMBIENT_SHELTER
        and target ~= nil
        and not shelterTargetIsLocal(mobile, target)
    local ambientMutated = staleShelterTarget
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
                rainShelter = rainShelter and objective == Constants.MOBILE_AMBIENT_SHELTER or false,
                chopperShelter = chopperShelter and objective == Constants.MOBILE_AMBIENT_SHELTER or false,
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
            ambientMutated = true
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
            ambientMutated = true
        end
    elseif target and checkDue then
        if objective == Constants.MOBILE_AMBIENT_SHELTER
            and not H.IsValidShelterSite({
                kind = "building",
                home = { x = target.x, y = target.y, z = target.z },
                bounds = target.bounds,
            }, ownershipSnapshot)
        then
            ambient = {
                phase = ambient.phase,
                objective = ambient.objective,
                target = ambient.target,
                holdForNoShelter = ambient.holdForNoShelter,
                nextCheckAt = ambient.nextCheckAt,
                nextObjectiveAt = at,
                retryAt = ambient.retryAt,
                revision = ambient.revision,
            }
            faction = updateMobile(faction, {
                ambient = ambient,
            }, "mobile_ambient_shelter_invalidated")
            ambientMutated = true
        else
            local nextCheckAt = at + Constants.MOBILE_AMBIENT_CHECK_HOURS
            if Factions and type(Factions.TouchMobileAmbientCheck) == "function" then
                Factions.TouchMobileAmbientCheck(faction.id, nextCheckAt)
            else
                ambient.nextCheckAt = nextCheckAt
                faction = updateMobile(faction, {
                    ambient = ambient,
                }, "mobile_ambient_objective_checked")
            end
        end
    end
    if objective ~= Constants.MOBILE_AMBIENT_SHELTER
        and PNC.AmbientVisitService
        and PNC.AmbientVisitService.ReleaseMobileShelter
    then
        local weatherClearedBeatEmitted = false
        for npcID in pairs(faction and faction.memberIDs or {}) do
            local record = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(npcID) or nil
            if record and record.alive ~= false
                and (ambientMutated
                    or prevObjective == Constants.MOBILE_AMBIENT_SHELTER
                    or (PNC.AmbientVisitService.IsActive
                        and PNC.AmbientVisitService.IsActive(record, at)))
            then
                local releaseReason = prevChopperShelter
                    and "mobile_shelter_chopper_cleared"
                    or (prevRainShelter
                        and "mobile_shelter_weather_cleared"
                        or "mobile_shelter_day_started")
                PNC.AmbientVisitService.ReleaseMobileShelter(
                    record,
                    releaseReason,
                    at
                )
                if (prevChopperShelter or prevRainShelter) and not weatherClearedBeatEmitted then
                    weatherClearedBeatEmitted = true
                    local beats = PNC and PNC.Semantics and PNC.Semantics.DialogueBeats or nil
                    if beats and type(beats.Emit) == "function" then
                        beats.Emit(
                            prevChopperShelter and "ambient.chopper_shelter.clear"
                                or "ambient.rain_shelter.clear",
                            {
                                speaker = record,
                                factionID = faction and faction.id or nil,
                            }
                        )
                    end
                end
            end
        end
    end
    local latestMobile = faction and faction.mobile or mobile
    local latestAmb = latestMobile and latestMobile.ambient or ambient
    local revKey = tostring((latestMobile and latestMobile.revision) or 0)
        .. ":" .. tostring((latestAmb and latestAmb.revision) or 0)
    local prevKey = H.LastRepairedAmbientRevision
        and H.LastRepairedAmbientRevision[faction.id] or nil
    H.AmbientRepairCounters = H.AmbientRepairCounters or {}
    local cycleCount = (H.AmbientRepairCounters[faction.id] or 0) + 1
    if ambientMutated or prevKey ~= revKey or cycleCount >= 10 then
        H.AmbientRepairCounters[faction.id] = 0
        H.RepairMobileOrders(faction)
    else
        H.AmbientRepairCounters[faction.id] = cycleCount
    end
    endDiagnosticTiming(
        timingName,
        timingStart,
        target and "target" or "no_target"
    )
    return faction, target ~= nil
end

return H
