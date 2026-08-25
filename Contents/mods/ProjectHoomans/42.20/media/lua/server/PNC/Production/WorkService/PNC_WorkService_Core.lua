if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.WorkService = PNC.WorkService or {}
PNC.WorkService.Internal = PNC.WorkService.Internal or {}

local Service = PNC.WorkService
local Internal = Service.Internal
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Status = Definitions.STATUS
local EventsBus = PsychopatzCore and PsychopatzCore.Events
local EventTypes = PNC.EventTypes or {}



local function emit(eventType, payload)
    if eventType and EventsBus and EventsBus.emit then
        EventsBus.emit(eventType, payload)
    end
end

Service.CompletionHandlers = Service.CompletionHandlers or {}
Service.PreparationHandlers = Service.PreparationHandlers or {}
Service.CollectionHandlers = Service.CollectionHandlers or {}
Service.TargetProviders = Service.TargetProviders or {}
Service.ReconcileHandlers = Service.ReconcileHandlers or {}
Service.ClaimsByStation = Service.ClaimsByStation or {}
Service.ClaimsByWorker = Service.ClaimsByWorker or {}
Service.NextPassAt = Service.NextPassAt or 0
Service.NextPruneAt = Service.NextPruneAt or 0
Service.MAX_TERMINAL_HISTORY = 512
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

local function now() return PNC.Core and PNC.Core.Now and PNC.Core.Now() or 0 end

local function terminal(order)
    return order.status == Status.CANCELLED or order.status == Status.COMPLETED
        or order.status == Status.FAILED
end

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function requirementsMet(record, requirements)
    local rate, reason = Definitions.WorkRate(record, requirements, 1, 1)
    return rate > 0, reason, rate
end

local function requiresHome(order)
    if not order then return true end
    -- Provision pickup is home-only. This also migrates orders written by the
    -- previous world-space pickup behavior, even if they persisted
    -- requiresHome=false.
    if order.operation == "PROVISION_PICKUP" then return true end
    if order.requiresHome ~= nil then return order.requiresHome ~= false end
    return true
end

local function autoReturnHome(order)
    if not order then return true end
    -- A hungry/following NPC must wait for an explicit home command instead
    -- of having provision work silently take over its current behavior.
    if order.operation == "PROVISION_PICKUP" then return false end
    return order.autoReturnHome ~= false
end

local function specializationScore(record, order)
    local skillId = order and order.productionSkillId
    if not skillId then return 0 end
    if PNC.Skills and PNC.Skills.GetLevel then
        return tonumber(PNC.Skills.GetLevel(record, skillId)) or 0
    end
    return 0
end

local function recipeKnowledgeMet(record, order)
    if not order or order.operation ~= "CRAFT" then return true end
    if PNC.ResearchService and PNC.ResearchService.Queries
        and PNC.ResearchService.Queries.HasRecipe
        and PNC.ResearchService.Queries.HasRecipe(order.colonyId, order.recipeId)
    then
        return true
    end
    if PNC.RecipeKnowledge and PNC.RecipeKnowledge.Queries
        and PNC.RecipeKnowledge.Queries.CanCraft
    then
        return PNC.RecipeKnowledge.Queries.CanCraft(record, order.recipeId)
    end
    return true
end

local function belongsToOrder(record, order)
    local affiliation = record and record.affiliation or {}
    local factionId = tostring(affiliation.factionID or affiliation.factionId
        or record and record.factionId or "")
    local colonyId = tostring(affiliation.communityID or affiliation.communityId
        or record and record.communityId or "")
    if colonyId == "" and PNC.HomeDutyService
        and PNC.HomeDutyService.GetColonyId
    then
        colonyId = PNC.HomeDutyService.GetColonyId(record)
    end
    return (order.factionId == "" or factionId == order.factionId)
        and (order.colonyId == "" or colonyId == order.colonyId)
end

local function markAssignmentDirty(order, cause)
    if not order or not PNC.Tasking or not PNC.Tasking.Commands
        or not PNC.Tasking.Commands.MarkDirty or not PNC.Registry
    then return 0 end
    local marked = 0
    local function consider(record)
        if record and record.alive ~= false and belongsToOrder(record, order) then
            PNC.Tasking.Commands.MarkDirty(record.id,
                cause or "WORK_REQUEST_CHANGED")
            marked = marked + 1
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    return marked
end

local function workerAvailable(record, order)
    if not record or record.alive == false or not belongsToOrder(record, order) then
        return false
    end
    if Service.ClaimsByWorker[tostring(record.id)] then return false end
    local runtime = record.runtime
    if runtime and runtime.workOrderId then return false end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsReturningHome
        and PNC.HomeDutyService.IsReturningHome(record, order.baseId)
    then
        return false
    end
    local job = Definitions.JOB_BY_OPERATION[order.operation]
    local allowed = record.allowedJobs
    -- Colony jobs are opt-out. Archetype tables predate colony production and
    -- therefore missing keys must mean allowed, not disabled.
    if type(allowed) == "table" and allowed[job] == false then return false end
    if requiresHome(order) and PNC.HomeDutyService
        and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(record, order.baseId)
    then
        return false
    end
    if not recipeKnowledgeMet(record, order) then return false end
    return requirementsMet(record, order.requiredSkills)
end

local function findWorker(order)
    local selected
    local selectedScore = -1
    local selectedId = ""
    local away
    if not PNC.Registry then return nil end
    local function consider(record)
        if not record or record.alive == false
            or not belongsToOrder(record, order)
        then
            return
        end
        local job = Definitions.JOB_BY_OPERATION[order.operation]
        local allowed = record.allowedJobs
        local eligible = not Service.ClaimsByWorker[tostring(record.id)]
            and not (record.runtime and record.runtime.workOrderId)
            and not (type(allowed) == "table" and allowed[job] == false)
            and recipeKnowledgeMet(record, order)
            and requirementsMet(record, order.requiredSkills)
        if not eligible then return end
        if workerAvailable(record, order) then
            local score = specializationScore(record, order)
            local recordId = tostring(record.id or "")
            if not selected or score > selectedScore
                or score == selectedScore and recordId < selectedId
            then
                selected, selectedScore, selectedId = record, score, recordId
            end
        elseif not away then
            away = record
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    if not selected and away and autoReturnHome(order)
        and PNC.HomeDutyService
        and PNC.HomeDutyService.SendHome
    then
        PNC.HomeDutyService.SendHome(away, order.baseId, "work_waiting")
        return nil, "WORKER_RETURNING_HOME"
    end
    return selected, selected and nil
        or (autoReturnHome(order) and "NO_QUALIFIED_WORKER"
            or "NO_HOME_WORKER")
end

function Service.RegisterCompletion(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CompletionHandlers[operation] = handler
    return true
end

function Service.RegisterPreparation(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.PreparationHandlers[operation] = handler
    return true
end

function Service.RegisterCollection(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.CollectionHandlers[operation] = handler
    return true
end

function Service.RegisterTargetProvider(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.TargetProviders[operation] = handler
    return true
end

function Service.RegisterReconciler(id, handler)
    id = tostring(id or "")
    if id == "" or type(handler) ~= "function" then return false end
    Service.ReconcileHandlers[id] = handler
    return true
end


Internal.emit = emit
Internal.now = now
Internal.terminal = terminal
Internal.copy = copy
Internal.requirementsMet = requirementsMet
Internal.requiresHome = requiresHome
Internal.autoReturnHome = autoReturnHome
Internal.belongsToOrder = belongsToOrder
Internal.markAssignmentDirty = markAssignmentDirty
Internal.workerAvailable = workerAvailable
Internal.findWorker = findWorker

return Service
