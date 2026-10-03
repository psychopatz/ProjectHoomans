-- Work progress accounting provider.
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
local now = Internal.now
local terminal = Internal.terminal
local copy = Internal.copy
local requirementsMet = Internal.requirementsMet
local complete = Internal.Complete

local function addProgress(orderId, workerId, amount)
    local order = Repository.Get(orderId)
    if not order or terminal(order) then return false, "WORK_ORDER_UNAVAILABLE" end
    if tostring(order.workerId or "") ~= tostring(workerId or "") then
        return false, "WORKER_NOT_ASSIGNED"
    end
    if order.status == Status.PAUSED then return false, "WORK_ORDER_PAUSED" end
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if order.operation == "CRAFT"
        and PNC.RecipeKnowledge and PNC.RecipeKnowledge.Queries
        and PNC.RecipeKnowledge.Queries.CanCraft
    then
        local researched = PNC.ResearchService and PNC.ResearchService.Queries
            and PNC.ResearchService.Queries.HasRecipe
            and PNC.ResearchService.Queries.HasRecipe(order.colonyId,
                order.recipeId)
        if not researched then
            local known = PNC.RecipeKnowledge.Queries.CanCraft(
                worker, order.recipeId)
            if not known then
                order.status, order.blockedReason = Status.BLOCKED,
                    "RECIPE_BOOK_REQUIRED"
                Repository.MarkDirty()
                return false, order.blockedReason
            end
        end
    end
    local eligible, reason = requirementsMet(worker, order.requiredSkills)
    if not eligible then
        order.status, order.blockedReason = Status.BLOCKED, reason
        Repository.MarkDirty(); return false, reason
    end
    order.status = Status.WORKING
    local before = order.progress
    order.progress = math.min(order.requiredWork,
        order.progress + math.max(0, tonumber(amount) or 0))
    if order.progress > before then
        order.lastProgressAt = now()
        order.recoveryAttempts = nil
        order.lastRecoveryAt = nil
        order.lastRecoveryReason = nil
        order.recoveryQuarantined = nil
    end
    order.updatedAt, order.revision = now(), order.revision + 1
    Repository.MarkDirty()
    if order.progress >= order.requiredWork then return complete(order) end
    return true, copy(order)
end

local function addElapsed(orderId, workerId, elapsedSeconds)
    local order = Repository.Get(orderId)
    local worker = PNC.Registry and PNC.Registry.Get and PNC.Registry.Get(workerId)
    if not order or not worker then return false, "WORKER_UNAVAILABLE" end
    if Definitions.MANUAL_PROGRESS
        and Definitions.MANUAL_PROGRESS[order.operation]
    then
        return false, "MANUAL_PROGRESS_OPERATION"
    end
    local rate, reason = Definitions.WorkRate(worker, order.requiredSkills, 1, 1)
    if rate <= 0 then return false, reason end
    local elapsed = math.max(0, math.min(Definitions.BALANCE.maxElapsedSeconds,
        tonumber(elapsedSeconds) or 0))
    return Service.Commands.AddProgress(orderId, workerId, rate * elapsed)
end

Internal.AddProgress = addProgress
Internal.AddElapsed = addElapsed
