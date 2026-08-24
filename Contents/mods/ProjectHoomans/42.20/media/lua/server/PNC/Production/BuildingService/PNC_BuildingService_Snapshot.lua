if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}
PNC.BuildingServiceInternal = PNC.BuildingServiceInternal or {}

local Service = PNC.BuildingService
local H = PNC.BuildingServiceInternal
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions

function Service.BuildSnapshot(player, storage, colony)
    local storageId = storage and storage.id or nil
    local recipes = {}
    for _, descriptor in ipairs(Catalog.Build() or {}) do
        recipes[#recipes + 1] = H.PublicDescriptor(descriptor, storageId)
    end
    local queue = {}
    if colony and PNC.WorkService then
        for _, order in ipairs(PNC.WorkService.Queries.List(colony.id)) do
            if H.Active(order) and order.operation == "BUILD_OBJECT" then
                local required = math.max(1, tonumber(order.requiredWork) or 1)
                local progress = math.max(0, math.min(required,
                    tonumber(order.progress) or 0))
                local worker = order.workerId and PNC.Registry
                    and PNC.Registry.Get
                    and PNC.Registry.Get(order.workerId) or nil
                local payload = order.payload or {}
                local blueprint = payload.blueprint or {}
                local descriptor = Catalog.Get(blueprint.objectInfoName)
                queue[#queue + 1] = {
                    id = order.id,
                    operation = order.operation,
                    status = order.status,
                    blockedReason = order.blockedReason,
                    progress = progress,
                    requiredWork = required,
                    percent = math.floor(progress / required * 100 + 0.5),
                    priority = order.priority,
                    workerId = order.workerId,
                    workerName = worker and tostring(worker.name or worker.id)
                        or nil,
                    recipeKey = blueprint.recipeKey,
                    objectInfoName = blueprint.objectInfoName,
                    displayName = descriptor and descriptor.displayName
                        or blueprint.objectInfoName,
                    blueprint = H.Copy(blueprint),
                    materials = H.RequirementSnapshot(storageId,
                        payload.materialRequirements),
                    createdAt = order.createdAt,
                    updatedAt = order.updatedAt,
                }
            end
        end
    end
    return { recipes = recipes, queue = queue,
        generation = Catalog.Generation }
end

