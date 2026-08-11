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
    provisionPolicyRevision = 0,
    provisionDirtyNPCs = 0,
    provisionEvaluations = 0,
    provisionRulesEvaluated = 0,
    provisionRulesSatisfied = 0,
    provisionRulesDeficient = 0,
    provisionRequestsCreated = 0,
    provisionRequestsSucceeded = 0,
    provisionRequestsFailed = 0,
    provisionRequestsSuppressedByIncoming = 0,
    provisionRequestsSuppressedByNeedRequest = 0,
    provisionSchedulerQueueSize = 0,
    provisionSchedulerProcessed = 0,
    provisionStorageShortages = 0,
}

local Metrics = PNC.SupplyMetrics

function Metrics.Increment(name, amount)
    if Metrics[name] == nil then return false end
    Metrics[name] = Metrics[name] + (tonumber(amount) or 1)
    return true
end

function Metrics.Set(name, value)
    if Metrics[name] == nil then return false end
    Metrics[name] = tonumber(value) or 0
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
