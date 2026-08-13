if PsychopatzCore and PsychopatzCore.RuntimeRole and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.FacilityWorldValidation = PNC.FacilityWorldValidation or {}

local Validation = PNC.FacilityWorldValidation
local SquareRules = require "PsychopatzCore/World/PsychopatzSquareRules"

local function componentRule(component)
    -- A barracks anchor is a sleep spot, not a mandatory furniture slot.
    -- Runtime target resolution upgrades it to bed sleep when a bed exists.
    if component and component.role == "sleep.bed" then return "" end
    local explicit = tostring(component and component.worldRule
        or component and component.objectTag or "")
    if explicit ~= "" then return explicit end
    local facility = component and PNC.SettlementRepository
        and PNC.SettlementRepository.GetFacility(component.facilityId) or nil
    local level = facility and PNC.FacilityDefinitions.GetLevel(
        facility.definitionId, facility.level) or nil
    local limit = level and level.componentLimits[component.role] or nil
    return tostring(limit and limit.worldRule or "")
end

function Validation.ValidateAnchor(component)
    local rule = componentRule(component)
    if rule == "" then return true end
    local valid, _, reason = SquareRules.MatchAt(
        component.x, component.y, component.z, rule, {
            component = component,
        })
    return valid, reason
end

function Validation.ValidateRegion(component)
    local rule = componentRule(component)
    if rule == "" then return true end
    return SquareRules.ValidateRegion(component.region, rule, {
        component = component,
    })
end

return Validation
