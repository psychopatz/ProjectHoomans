if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Validation = PNC.FacilityValidationService
local Repository = PNC.SettlementRepository
local Definitions = PNC.FacilityDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"
local Farming = PNC.Farming
local H = Validation.Internal

function Validation.CalculateOperationalState(base, facility)
    if facility.disabled == true then return "DISABLED" end
    local levelData = H.LevelDefinition(facility)
    if not levelData or base.hqLevel < levelData.requiredHQLevel then return "INVALID_COMPONENT" end
    local counts, tiles = H.ComponentStats(facility)
    for role, limit in pairs(levelData.componentLimits or {}) do
        if limit.minCount and (counts[role] or 0) < limit.minCount then
            return "NEEDS_ASSIGNMENT"
        end
        if limit.minTotalTiles and (tiles[role] or 0) < limit.minTotalTiles then
            return "UNDERSIZED"
        end
        if limit.maxCount and (counts[role] or 0) > limit.maxCount then
            return "INVALID_COMPONENT"
        end
        if limit.maxTotalTiles and (tiles[role] or 0) > limit.maxTotalTiles then
            return "INVALID_COMPONENT"
        end
    end
    return "OPERATIONAL"
end

return Validation

