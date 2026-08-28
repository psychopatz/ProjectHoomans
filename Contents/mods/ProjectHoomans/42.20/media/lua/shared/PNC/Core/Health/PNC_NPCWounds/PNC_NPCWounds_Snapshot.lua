PNC = PNC or {}
local Wounds = PNC.NPCWounds
local Core = PNC.Core

function Wounds.BuildSnapshot(record)
    local body = Wounds.Recalculate(record)
    local output = {
        bleedingRate = body.bleedingRate,
        openWoundCount = body.openWoundCount,
        bandagedWoundCount = body.bandagedWoundCount,
        infected = Wounds.HasActiveInfection(record),
        infection = body.infection
            and Core.DeepCopy(body.infection) or nil,
        wholeBodyAilments = Core.DeepCopy(body.wholeBodyAilments or {}),
        wounds = {},
        parts = Core.DeepCopy(body.parts),
        totalPartHealth = body.totalPartHealth,
        totalPartMax = body.totalPartMax,
        overallPercent = body.overallPercent,
    }
    local i
    local partId
    local wound
    for i = 1, #Wounds.PartOrder do
        partId = Wounds.PartOrder[i]
        wound = body.wounds[partId]
        if wound then
            output.wounds[partId] = Core.DeepCopy(wound)
        end
    end
    return output
end

return Wounds
