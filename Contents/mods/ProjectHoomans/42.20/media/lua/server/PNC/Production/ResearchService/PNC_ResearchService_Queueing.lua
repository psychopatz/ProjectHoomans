-- Research queueing, targeting, and duplicate reconciliation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.ResearchService = PNC.ResearchService or {}
local Service = PNC.ResearchService
local Internal = Service.Internal
local Definitions = PNC.ColonyResearchDefinitions

local function queue(context, spec)
    spec.colonyId, spec.factionId, spec.baseId = context.colony.id,
        context.faction.id, context.base.id
    return PNC.WorkService.Commands.Queue(spec)
end

local function researchTarget(order, worker, live)
    local mode = tostring(order and order.payload and order.payload.mode or "")
    local technology = mode == "technology" and Definitions.Get(
        order.payload and order.payload.technologyId) or nil
    -- Blueprint study shares the same physical Log Table as technology
    -- research and book reading, just as workshop salvage shares the craft
    -- station. Keep the mode for UI/policy while reserving one real table.
    local capability = technology and technology.researchCapability
        or "work.research"
    return PNC.FacilityService.AcquireActivity(order.baseId, worker.id,
        capability, { abstract = live == nil, ttlMs = 30000,
            workOrderId = order.id })
end

local function activeTechnologyOrders(colonyId, technologyId)
    local output = {}
    colonyId, technologyId = tostring(colonyId or ""),
        tostring(technologyId or "")
    for _, order in ipairs(PNC.WorkService.Queries.List(colonyId)) do
        local payload = order.payload or {}
        if order.operation == "RESEARCH"
            and order.status ~= "COMPLETED" and order.status ~= "CANCELLED"
            and payload.mode == "technology"
            and tostring(payload.technologyId or "") == technologyId
        then
            output[#output + 1] = order
        end
    end
    table.sort(output, function(left, right)
        local leftProgress = tonumber(left.progress) or 0
        local rightProgress = tonumber(right.progress) or 0
        if leftProgress ~= rightProgress then
            return leftProgress > rightProgress
        end
        local leftCreated = tonumber(left.createdAt) or 0
        local rightCreated = tonumber(right.createdAt) or 0
        if leftCreated ~= rightCreated then return leftCreated < rightCreated end
        return tostring(left.id or "") < tostring(right.id or "")
    end)
    return output
end

function Service.Commands.ReconcileDuplicates()
    local groups = {}
    for _, order in ipairs(PNC.WorkService.Queries.List()) do
        local payload = order.payload or {}
        if order.operation == "RESEARCH"
            and order.status ~= "COMPLETED" and order.status ~= "CANCELLED"
            and payload.mode == "technology"
            and tostring(payload.technologyId or "") ~= ""
        then
            local key = tostring(order.colonyId or "") .. "\31"
                .. tostring(payload.technologyId)
            local bucket = groups[key]
            if not bucket then bucket = {}; groups[key] = bucket end
            bucket[#bucket + 1] = order
        end
    end
    local removed = 0
    for _, bucket in pairs(groups) do
        table.sort(bucket, function(left, right)
            local leftProgress = tonumber(left.progress) or 0
            local rightProgress = tonumber(right.progress) or 0
            if leftProgress ~= rightProgress then
                return leftProgress > rightProgress
            end
            local leftCreated = tonumber(left.createdAt) or 0
            local rightCreated = tonumber(right.createdAt) or 0
            if leftCreated ~= rightCreated then return leftCreated < rightCreated end
            return tostring(left.id or "") < tostring(right.id or "")
        end)
        for index = 2, #bucket do
            local cancelled = PNC.WorkService.Commands.Cancel(
                bucket[index].id, "duplicate_research_order")
            if cancelled then removed = removed + 1 end
        end
    end
    return removed
end

function Service.Commands.ReconcileRemovedReverseEngineering()
    local removed = 0
    for _, order in ipairs(PNC.WorkService.Queries.List()) do
        local payload = order.payload or {}
        if order.operation == "RESEARCH"
            and order.status ~= "COMPLETED"
            and order.status ~= "CANCELLED"
            and payload.mode == "reverse"
        then
            local cancelled = PNC.WorkService.Commands.Cancel(
                order.id, "reverse_engineering_removed")
            if cancelled then removed = removed + 1 end
        end
    end
    return removed
end

function Service.Commands.QueueTechnology(player, technologyId)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    local definition = Definitions.Get(technologyId)
    if not context then return nil, reason end
    if not definition then
        return nil, "TECHNOLOGY_UNKNOWN"
    end
    if Service.Queries.HasTechnology(context.colony.id, technologyId) then
        return nil, "ALREADY_KNOWN"
    end
    if definition.prerequisiteTechnology
        and not Service.Queries.HasTechnology(context.colony.id,
            definition.prerequisiteTechnology)
    then
        return nil, "PREREQUISITE_REQUIRED"
    end
    Service.Commands.ReconcileDuplicates()
    local existing = activeTechnologyOrders(context.colony.id, technologyId)[1]
    if existing then return existing, "ALREADY_QUEUED" end
    return queue(context, { operation = "RESEARCH",
        requiredWork = definition.requiredWork,
        requiredSkills = definition.requiredSkills,
        payload = { mode = "technology", technologyId = technologyId } })
end

Internal.Queue = queue
Internal.ResearchTarget = researchTarget
Internal.ActiveTechnologyOrders = activeTechnologyOrders

return Service
