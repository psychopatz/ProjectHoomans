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
local WorkPolicy = PNC.WorkPolicy
    or require "PNC/Core/Production/WorkDefinition/PNC_WorkPolicy"
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
Service.ExecutionHandlers = Service.ExecutionHandlers or {}
Service.AbstractExecutionHandlers = Service.AbstractExecutionHandlers or {}
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

local startsAtHome = Internal.startsAtHome
local returnsHome = Internal.returnsHome

local function isFollowing(record)
    if PNC.HomeDutyService and PNC.HomeDutyService.IsFollowing then
        return PNC.HomeDutyService.IsFollowing(record) == true
    end
    local order = record and record.orderSpec or nil
    return tostring(order and order.kind or "") == tostring(
        PNC.Const and PNC.Const.ORDER_FOLLOW or "follow")
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
    local factionId = tostring(affiliation.factionID or "")
    local colonyId = tostring(affiliation.communityID or "")
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
        or not PNC.Tasking.Events or not PNC.Tasking.Events.Emit
        or not PNC.Registry
    then return 0 end
    local marked = 0
    local function consider(record)
        if record and record.alive ~= false and belongsToOrder(record, order) then
            PNC.Tasking.Events.Emit(cause or "WORK_REQUEST_CHANGED", {
                npcId = record.id, source = "WorkService",
                entityId = order.id,
            })
            marked = marked + 1
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    return marked
end

local function workerAvailable(record, order)
    if not record then return false, "WORKER_NOT_FOUND" end
    if record.alive == false then return false, "WORKER_DEAD" end
    if not belongsToOrder(record, order) then
        return false, "ORDER_OWNERSHIP_MISMATCH"
    end
    if order.operation == "PROVISION_PICKUP" and isFollowing(record) then
        return false, "FOLLOWING_DURING_PROVISION"
    end
    -- Follow is a direct player order. Automatic colony work must not steal a
    -- follower, even when the player happens to be inside the home zone. A
    -- manually forced order is explicit and may still override follow.
    if order.manual ~= true and isFollowing(record) then
        return false, "FOLLOWING_ACTIVE"
    end
    if order.requiredWorkerId
        and tostring(order.requiredWorkerId) ~= tostring(record.id)
    then
        return false, "REQUIRED_WORKER_MISMATCH"
    end
    if Service.ClaimsByWorker[tostring(record.id)] then
        return false, "WORKER_ALREADY_CLAIMED"
    end
    local runtime = record.runtime
    if runtime and runtime.workOrderId then
        return false, "WORKER_ALREADY_HAS_ORDER"
    end
    if PNC.HomeDutyService and PNC.HomeDutyService.IsReturningHome
        and PNC.HomeDutyService.IsReturningHome(record, order.baseId)
    then
        return false, "WORKER_RETURNING_HOME"
    end
    local job = Definitions.JOB_BY_OPERATION[order.operation]
    -- Colony jobs are opt-out. Archetype tables predate colony production and
    -- therefore missing keys must mean allowed, not disabled.
    if job and order.manual ~= true
        and not WorkPolicy.CanAutoClaim(record, job)
    then return false, "JOB_DISABLED" end
    if startsAtHome(order) and PNC.HomeDutyService
        and PNC.HomeDutyService.IsAtHome
        and not PNC.HomeDutyService.IsAtHome(record, order.baseId)
    then
        return false, "WORKER_NOT_AT_HOME"
    end
    local executionPolicy = Definitions.ExecutionPolicy
        and Definitions.ExecutionPolicy(order.operation)
        or Definitions.REQUIRES_LIVE and Definitions.REQUIRES_LIVE[order.operation]
            and "LIVE_ONLY" or "ABSTRACT_SAFE"
    if executionPolicy == "LIVE_ONLY"
        and (not PNC.Registry or not PNC.Registry.GetLiveZombie
            or not PNC.Registry.GetLiveZombie(record.id))
    then
        return false, "LIVE_BODY_REQUIRED"
    end
    if not recipeKnowledgeMet(record, order) then
        return false, "RECIPE_KNOWLEDGE_MISSING"
    end
    local requirementsOK, requirementsReason = requirementsMet(
        record, order.requiredSkills)
    if not requirementsOK then
        return false, requirementsReason or "REQUIRED_SKILL_MISSING"
    end
    return true
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
        local eligible = not Service.ClaimsByWorker[tostring(record.id)]
            and not (record.runtime and record.runtime.workOrderId)
            and not (order.requiredWorkerId
                and tostring(order.requiredWorkerId) ~= tostring(record.id))
            and (not job or order.manual == true
                or WorkPolicy.CanAutoClaim(record, job))
            and recipeKnowledgeMet(record, order)
            and requirementsMet(record, order.requiredSkills)
        if not eligible then return end
        local available, availableReason = workerAvailable(record, order)
        if available then
            local score = specializationScore(record, order)
            local recordId = tostring(record.id or "")
            if not selected or score > selectedScore
                or score == selectedScore and recordId < selectedId
            then
                selected, selectedScore, selectedId = record, score, recordId
            end
        elseif availableReason ~= "FOLLOWING_ACTIVE"
            and availableReason ~= "FOLLOWING_DURING_PROVISION"
            and not away
        then
            away = record
        end
    end
    if PNC.Registry.ForEach then PNC.Registry.ForEach(consider)
    else for _, record in pairs(PNC.Registry.Data or {}) do consider(record) end end
    if not selected and away and returnsHome(order)
        and PNC.HomeDutyService
        and PNC.HomeDutyService.SendHome
    then
        PNC.HomeDutyService.SendHome(away, order.baseId, "work_waiting")
        return nil, "WORKER_RETURNING_HOME"
    end
    return selected, selected and nil
        or (returnsHome(order) and "NO_QUALIFIED_WORKER"
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

function Service.RegisterExecution(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.ExecutionHandlers[operation] = handler
    return true
end

function Service.RegisterAbstractExecution(operation, handler)
    operation = tostring(operation or "")
    if operation == "" or type(handler) ~= "function" then return false end
    Service.AbstractExecutionHandlers[operation] = handler
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
Internal.startsAtHome = startsAtHome
Internal.returnsHome = returnsHome
Internal.isFollowing = isFollowing
Internal.belongsToOrder = belongsToOrder
Internal.markAssignmentDirty = markAssignmentDirty
Internal.workerAvailable = workerAvailable
Internal.findWorker = findWorker

return Service
