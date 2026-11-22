PNC = PNC or {}
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_Projection"
require "PNC/Core/Health/PNC_NPCWounds/PNC_NPCWounds_BiteConflictPolicy"

local Wounds = PNC.NPCWounds
local Core = PNC.Core

function Wounds.ClassifyCombatInjuryState(record, preferredPartId, preferredWoundType)
    if type(record) ~= "table" or record.alive == false then return nil end
    local proj = Wounds.GetOrBuildProjection(record, {
        preferredPartId = preferredPartId,
        preferredWoundType = preferredWoundType,
    })
    if not proj or proj.injured ~= true then return nil end
    return proj
end

function Wounds.BuildStatusSummary(record)
    local body = (type(Wounds.Recalculate) == "function" and Wounds.Recalculate(record))
        or (record and record.health and record.health.body)
        or {}
    local bleedingRate = tonumber(body.bleedingRate) or 0
    local openCount = tonumber(body.openWoundCount) or 0
    local bandagedCount = tonumber(body.bandagedWoundCount) or 0
    local patchedCount = tonumber(body.patchedWoundCount) or bandagedCount
    local proj = (record and record.health) and Wounds.GetOrBuildProjection(record) or nil
    local patchState = (openCount > 0 or bleedingRate > 0 or (proj and proj.hasDirtyBandage)) and "with_wounds"
        or (patchedCount > 0 and "patched_up" or "none")
    return {
        bleeding = bleedingRate > 0,
        openWoundCount = openCount,
        bandagedWoundCount = bandagedCount,
        patchedWoundCount = patchedCount,
        patchState = patchState,
        physicalSeverityBand = proj and proj.physicalSeverityBand or "none",
        knoxExposure = proj and proj.knoxExposure or "impossible",
        treatmentState = proj and proj.treatmentState or "uninjured",
    }
end

function Wounds.BuildSnapshot(record)
    local body = Wounds.Recalculate(record)
    local output = {
        bleedingRate = body.bleedingRate,
        openWoundCount = body.openWoundCount,
        bandagedWoundCount = body.bandagedWoundCount,
        infected = Wounds.HasActiveInfection(record),
        infection = body.infection and Core.DeepCopy(body.infection) or nil,
        physiology = body.physiology and Core.DeepCopy(body.physiology) or nil,
        wholeBodyAilments = Core.DeepCopy(body.wholeBodyAilments or {}),
        wounds = {},
        parts = Core.DeepCopy(body.parts),
        totalPartHealth = body.totalPartHealth,
        totalPartMax = body.totalPartMax,
        overallPercent = body.overallPercent,
    }
    for i = 1, #Wounds.PartOrder do
        local partId = Wounds.PartOrder[i]
        local wound = body.wounds[partId]
        if wound then output.wounds[partId] = Core.DeepCopy(wound) end
    end
    return output
end

return Wounds
