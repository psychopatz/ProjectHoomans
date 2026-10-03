-- Public objective refresh and bounded director scheduling.
if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Director = PNC.MobileGroupDirector
local H = PNC.MobileGroupDirectorInternal
local Internal = H.Internal
local Constants = PNC.FactionConstants
local Factions = PNC.Factions
local Config = PNC.DirectorConfig or {}
local Const = PNC.Const
local beginDiagnosticTiming = Internal.AmbientTargets.beginDiagnosticTiming
local endDiagnosticTiming = Internal.AmbientTargets.endDiagnosticTiming
local incrementDiagnostic = Internal.incrementDiagnostic or function() end
local setDiagnosticGauge = Internal.setDiagnosticGauge or function() end
local finite = Internal.AmbientTargets.finite
local shelterTargetIsLocal = Internal.AmbientTargets.shelterTargetIsLocal

-- Re-evaluate one group's objective immediately. The scheduled pump keeps
-- this bounded across the world; debug tools and migration code can use this
-- targeted entry point without scanning every mobile faction.
function H.RefreshFactionObjective(factionID, at)
    if not H.Authority() then return false, "not_authority" end
    local faction = Factions.Get(factionID)
    if not faction then return false, "faction_not_found" end
    if not Factions.IsMobileGroup(faction) then
        return false, "not_mobile_group"
    end
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    local refreshed
    local hasTarget
    if faction.mobile.controlMode
        == Constants.MOBILE_CONTROL_STRATEGIC
    then
        refreshed, hasTarget = H.RefreshStrategic(faction, at)
    else
        refreshed, hasTarget = H.RefreshAmbient(faction, at)
    end
    return true,
        hasTarget and "mobile_objective_refreshed"
            or "mobile_objective_pending",
        refreshed and H.Copy(refreshed.mobile) or nil
end

function H.PumpAmbient(at, budget)
    at = finite(at, H.WorldAge and H.WorldAge() or 0)
    budget = math.max(1, math.floor(tonumber(budget) or 12))
    local pumpTimingName, pumpTimingStart = beginDiagnosticTiming(
        "MobileAmbient.PumpAmbient"
    )
    incrementDiagnostic("MobileAmbient.PumpCalls")
    local selectionBudget = math.max(1, math.floor(
        tonumber(Config.MOBILE_AMBIENT_TARGET_SELECTIONS_PER_PUMP) or 1
    ))
    local context = {
        ambientTargetSelectionBudget = selectionBudget,
        ambientTargetSelections = 0,
    }
    local discoveryTimingName, discoveryTimingStart = beginDiagnosticTiming(
        "MobileAmbient.FactionDiscovery"
    )
    local factionIDs = {}
    for factionID, faction in pairs(
        Factions.Registry and Factions.Registry.byID or {}
    ) do
        if faction.status == "active" and Factions.IsMobileGroup(faction) then
            factionIDs[#factionIDs + 1] = factionID
        end
    end
    table.sort(factionIDs)
    endDiagnosticTiming(
        discoveryTimingName,
        discoveryTimingStart,
        tostring(#factionIDs)
    )
    local cursor = math.max(1, tonumber(Director.AmbientCursor) or 1)
    local processed = 0
    while processed < budget and #factionIDs > 0 do
        if cursor > #factionIDs then cursor = 1 end
        local faction = Factions.Get(factionIDs[cursor])
        local selectionsBefore = context.ambientTargetSelections
        if faction then
            if H.ExpirePlayerRoamArea then
                local roamTimingName, roamTimingStart = beginDiagnosticTiming(
                    "MobileAmbient.ExpirePlayerRoamArea"
                )
                incrementDiagnostic("MobileAmbient.PlayerRoamChecks")
                local expired, _, updated = H.ExpirePlayerRoamArea(
                    faction,
                    at
                )
                endDiagnosticTiming(
                    roamTimingName,
                    roamTimingStart,
                    expired and "expired" or "not_expired"
                )
                if expired then
                    incrementDiagnostic("MobileAmbient.PlayerRoamExpired")
                end
                if expired then faction = updated or Factions.Get(
                    faction.id
                ) or faction end
            end
            if faction.mobile.controlMode
                == Constants.MOBILE_CONTROL_STRATEGIC
            then
                H.RefreshStrategic(faction, at)
            else
                H.RefreshAmbient(faction, at, context)
            end
        end
        local targetSelectionStarted = context.ambientTargetSelections
            > selectionsBefore
        incrementDiagnostic("MobileAmbient.FactionsProcessed")
        cursor = cursor + 1
        processed = processed + 1
        if targetSelectionStarted then
            -- A target lookup may enumerate the meta-grid. Do not run a
            -- second one in the same scheduler callback.
            break
        end
        if processed >= #factionIDs then break end
    end
    Director.AmbientCursor = cursor
    if context.ambientTargetSelections > 0 then
        incrementDiagnostic(
            "MobileAmbient.TargetSelectionsStarted",
            context.ambientTargetSelections
        )
    end
    setDiagnosticGauge("MobileAmbient.LastFactionCount", #factionIDs)
    setDiagnosticGauge("MobileAmbient.LastProcessed", processed)
    setDiagnosticGauge(
        "MobileAmbient.LastTargetSelections",
        context.ambientTargetSelections
    )
    endDiagnosticTiming(
        pumpTimingName,
        pumpTimingStart,
        tostring(processed)
    )
    return processed
end

Internal.AmbientOrders = {
    finite = finite,
    shelterTargetIsLocal = shelterTargetIsLocal,
    beginDiagnosticTiming = beginDiagnosticTiming,
    endDiagnosticTiming = endDiagnosticTiming,
    Const = Const,
}
require "PNC/Director/MobileGroupDirector/PNC_MobileGroupDirector_Ambient_Orders"

return H
