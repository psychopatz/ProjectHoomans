PNC = PNC or {}
PNC.SupplyMetrics = PNC.SupplyMetrics or {
    supplyRequests = 0,
    supplyRequestsSatisfiedFromPersonalInventory = 0,
    supplyRequestsSentToStorage = 0,
    supplyRequestsSucceeded = 0,
    supplyRequestsFailed = 0,
    foodRequests = 0,
    hydrationRequests = 0,
    medicalRequests = 0,
    reservationsCreated = 0,
    reservationFailures = 0,
    instantAcquisitions = 0,
    acquisitionFailures = 0,
    candidateQueries = 0,
    candidateItemsEvaluated = 0,
    supplyRetriesSuppressed = 0,
    deltaInventoryMutations = 0,
    deltaInventoryCompactions = 0,
    deltaToFullPromotions = 0,
}

local Metrics = PNC.SupplyMetrics

function Metrics.Increment(name, amount)
    if Metrics[name] == nil then return false end
    Metrics[name] = Metrics[name] + (tonumber(amount) or 1)
    return true
end

function Metrics.Snapshot()
    local output = {}
    for key, value in pairs(Metrics) do
        if type(value) == "number" then output[key] = value end
    end
    return output
end

return Metrics
