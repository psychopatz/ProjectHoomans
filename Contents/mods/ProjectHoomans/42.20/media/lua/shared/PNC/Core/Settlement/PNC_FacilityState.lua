PNC = PNC or {}
PNC.FacilityState = PNC.FacilityState or {}

local State = PNC.FacilityState

-- constructionState is the durable lifecycle field. Older saves may omit it,
-- which has always meant that the facility is already built. cachedState is a
-- derived operational state and must not replace the lifecycle decision.
function State.ConstructionState(facility)
    local value = facility and facility.constructionState or nil
    if value == nil or tostring(value) == "" then return "BUILT" end
    return tostring(value)
end

function State.IsBuilt(facility)
    return type(facility) == "table"
        and State.ConstructionState(facility) == "BUILT"
end

function State.DisplayState(facility)
    local construction = facility and facility.constructionState or nil
    if construction ~= nil and tostring(construction) ~= "" then
        return tostring(construction)
    end
    return tostring(facility and facility.cachedState or "BUILT")
end

return State
