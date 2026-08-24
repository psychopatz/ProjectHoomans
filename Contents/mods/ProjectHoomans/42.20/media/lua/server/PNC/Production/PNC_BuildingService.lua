if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.BuildingService = PNC.BuildingService or {}

local Service = PNC.BuildingService
local Catalog = PNC.BuildRecipeCatalog
local Repository = PNC.WorkRepository
local Definitions = PNC.WorkDefinitions
local Zones = require "PsychopatzCore/World/PC_ZoneRegistry"
local GridRegion = require "PsychopatzCore/World/PC_GridRegion"

local function copy(value)
    return PNC.Core and PNC.Core.DeepCopy and PNC.Core.DeepCopy(value) or value
end

local function active(order)
    return order and order.status ~= "COMPLETED"
        and order.status ~= "CANCELLED" and order.status ~= "FAILED"
end

local function contextFor(player)
    local context, reason = PNC.ProductionContext.ForPlayer(player)
    if not context then return nil, reason end
    if not PNC.BaseValidationService.CanUse(player, context.base) then
        return nil, "NO_PERMISSION"
    end
    if not context.storage then return nil, "STORAGE_REQUIRED" end
    return context
end

local function blueprintFor(order)
    local payload = order and order.payload or {}
    return payload and payload.blueprint or nil
end

local function targetValid(base, blueprint)
    if not base or not blueprint then return false end
    local zone = Zones.get(base.baseZoneId)
    return zone and zone.geometry
        and GridRegion.containsXY(zone.geometry,
            math.floor(tonumber(blueprint.x) or 0),
            math.floor(tonumber(blueprint.y) or 0)) == true
end

local function duplicateAt(colonyId, blueprint)
    for _, order in pairs(Repository.State.byId or {}) do
        local other = blueprintFor(order)
        if active(order) and order.operation == "BUILD_OBJECT"
            and tostring(order.colonyId) == tostring(colonyId)
            and other and tonumber(other.x) == tonumber(blueprint.x)
            and tonumber(other.y) == tonumber(blueprint.y)
            and tonumber(other.z) == tonumber(blueprint.z)
        then return true end
    end
    return false
end

local function requirementSnapshot(storageId, requirements)
    local output = {}
    for _, requirement in ipairs(requirements or {}) do
        local available = PNC.ColonyStorageService.CountProductionAvailable(
            storageId, requirement.itemTypes)
        local names = {}
        for _, fullType in ipairs(requirement.itemTypes or {}) do
            names[#names + 1] = tostring(fullType)
        end
        output[#output + 1] = {
            itemTypes = copy(requirement.itemTypes or {}),
            names = names,
            amount = tonumber(requirement.amount) or 1,
            consumed = requirement.consumed ~= false,
            available = available,
            ready = available >= (tonumber(requirement.amount) or 1),
        }
    end
    return output
end

local function publicDescriptor(descriptor, storageId)
    descriptor = descriptor or {}
    return {
        id = descriptor.id,
        recipeKey = descriptor.recipeKey,
        objectInfoName = descriptor.objectInfoName,
        displayName = descriptor.displayName,
        recipeName = descriptor.recipeName,
        category = descriptor.category,
        iconName = descriptor.iconName,
        buildWork = descriptor.buildWork,
        requiredSkills = copy(descriptor.requiredSkills or {}),
        requirements = copy(descriptor.requirements or {}),
        materials = requirementSnapshot(storageId, descriptor.requirements),
    }
end

function Service.BuildSnapshot(player, storage, colony)
    local storageId = storage and storage.id or nil
    local recipes = {}
    for _, descriptor in ipairs(Catalog.Build() or {}) do
        recipes[#recipes + 1] = publicDescriptor(descriptor, storageId)
    end
    local queue = {}
    if colony and PNC.WorkService then
        for _, order in ipairs(PNC.WorkService.Queries.List(colony.id)) do
            if active(order) and order.operation == "BUILD_OBJECT" then
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
                    blueprint = copy(blueprint),
                    materials = requirementSnapshot(storageId,
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

function Service.Queue(player, args)
    args = type(args) == "table" and args or {}
    local context, reason = contextFor(player)
    if not context then return nil, reason end
    local descriptor = Catalog.Get(args.recipeKey or args.objectInfoName)
    if not descriptor then return nil, "BUILD_RECIPE_NOT_FOUND" end
    local x, y, z = tonumber(args.x), tonumber(args.y), tonumber(args.z)
    if not x or not y or not z then return nil, "BUILD_TARGET_REQUIRED" end
    local blueprint = {
        recipeKey = descriptor.recipeKey,
        objectInfoName = descriptor.objectInfoName,
        x = math.floor(x), y = math.floor(y), z = math.floor(z),
        nSprite = math.max(1, math.min(4, math.floor(
            tonumber(args.nSprite) or 1))),
        north = args.north == true,
        sprite = args.sprite and tostring(args.sprite) or nil,
    }
    if not targetValid(context.base, blueprint) then
        return nil, "BUILD_TARGET_OUTSIDE_BASE"
    end
    Repository.Load()
    if duplicateAt(context.colony.id, blueprint) then
        return nil, "BUILD_TARGET_ALREADY_QUEUED"
    end
    local requirements = copy(descriptor.requirements or {})
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        context.storage.id, requirements,
        "blueprint:" .. tostring(blueprint.objectInfoName))
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local payload = {
        mode = "object_build",
        materialKind = "build_object",
        storageId = context.storage.id,
        materialRequirements = requirements,
        blueprint = blueprint,
        requesterOnlineID = player and player.getOnlineID
            and tonumber(player:getOnlineID()) or nil,
    }
    payload = PNC.WorkInputService.Bind(payload, context.storage.id,
        reservation.id, "building_materials")
    local order
    order, reason = PNC.WorkService.Commands.Queue({
        operation = Definitions.OPERATION.BUILD_OBJECT,
        colonyId = context.colony.id, factionId = context.faction.id,
        baseId = context.base.id, requiredWork = descriptor.buildWork,
        requiredSkills = descriptor.requiredSkills,
        recipeRevision = 1, payload = payload, funded = false,
    })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
        return nil, reason or "BUILD_QUEUE_FAILED"
    end
    return order
end

function Service.DebugGrantMaterials(player, args)
    args = type(args) == "table" and args or {}
    local storage, reason = PNC.ColonyStorageService.ResolveForPlayer(player)
    if not storage then return nil, reason end
    local descriptor = Catalog.Get(args.recipeKey or args.objectInfoName)
    if not descriptor then return nil, "BUILD_RECIPE_NOT_FOUND" end

    -- Use the first valid alternative for each recipe input.  This mirrors
    -- the stockpile reservation policy and gives the tester a complete set
    -- of inputs without creating a second build/materials pipeline.
    local products = {}
    for _, requirement in ipairs(descriptor.requirements or {}) do
        local fullType = requirement.fullType
            or requirement.itemTypes and requirement.itemTypes[1]
        local quantity = math.max(1, math.floor(
            tonumber(requirement.amount) or 1))
        if fullType then
            products[#products + 1] = {
                fullType = tostring(fullType), quantity = quantity,
            }
        end
    end
    if #products == 0 then return nil, "BUILD_RECIPE_HAS_NO_MATERIALS" end

    local transactionId = args.requestId and tostring(args.requestId) or nil
    local deposited, depositReason, _, depositDetails =
        PNC.ColonyStorageService.DebugAction(player, {
            debugAction = "add_many",
            storageId = storage.id,
            products = products,
            requestId = transactionId,
            transactionLogging = args.transactionLogging,
        })
    if not deposited then return nil, depositReason end
    return {
        recipeKey = descriptor.recipeKey,
        storageId = storage.id,
        products = products,
        storageDetails = depositDetails,
    }, "MATERIALS_GRANTED"
end

local function resolveTarget(order)
    local blueprint = blueprintFor(order)
    local base = PNC.BaseService.Get(order.baseId)
    if not blueprint or not targetValid(base, blueprint) then
        return { ok = false, reason = "BUILD_TARGET_INVALID" }
    end
    return { ok = true, componentId = "build:" .. tostring(order.id),
        facilityId = "build:" .. tostring(order.id),
        target = { x = blueprint.x, y = blueprint.y, z = blueprint.z } }
end

local function prepare(order)
    local blueprint = blueprintFor(order)
    if not blueprint or not Catalog.Get(blueprint.objectInfoName) then
        return false, "BUILD_RECIPE_NOT_FOUND"
    end
    local base = PNC.BaseService.Get(order.baseId)
    if not targetValid(base, blueprint) then
        return false, "BUILD_TARGET_INVALID"
    end
    local input = order.payload and order.payload.input or nil
    if input and tonumber(order.progress) and tonumber(order.progress) > 0
        and not order.funded and input.funded ~= true
        and input.committed ~= true and (input.storageId == nil
            or input.storageId == "") and (input.reservationId == nil
            or input.reservationId == "")
    then
        order.funded = true
        input.funded, input.committed, input.legacyRecovered = true, true, true
        Repository.MarkDirty()
        return true
    end
    if order.funded == true or input and (input.funded == true
        or input.committed == true)
    then order.funded = true; return true end
    if input and PNC.WorkInputService.IsReady(order) then return true end
    return false, input and "BUILDING_INPUTS_UNAVAILABLE"
        or "BUILDING_INPUTS_MISSING"
end

local function builderFor(order)
    local live = order.workerId and PNC.Registry
        and PNC.Registry.GetLiveZombie
        and PNC.Registry.GetLiveZombie(order.workerId) or nil
    if live and type(live.isBuildCheat) == "function"
        and type(live.getPerkLevel) == "function"
    then return live end
    local onlineID = order.payload and order.payload.requesterOnlineID
    if onlineID and getPlayerByOnlineID then
        local ok, player = pcall(getPlayerByOnlineID, onlineID)
        if ok and player then return player end
    end
    if getSpecificPlayer then return getSpecificPlayer(0) end
    return nil
end

local function playerNumberFor(builder)
    if builder and type(builder.getPlayerNum) == "function" then
        local ok, playerNumber = pcall(builder.getPlayerNum, builder)
        if ok and playerNumber ~= nil then
            return tonumber(playerNumber) or 0
        end
    end
    return 0
end

local function fakeRecipeData(builder, descriptor)
    local recorded = ArrayList and ArrayList.new and ArrayList.new() or nil
    local seen = {}
    local inventory = builder and builder.getInventory
        and builder:getInventory() or nil
    local items = inventory and inventory.getItems
        and inventory:getItems() or nil
    if recorded and items and items.size and items.get then
        for _, requirement in ipairs(descriptor.requirements or {}) do
            local needed = math.max(1, math.floor(
                tonumber(requirement.amount) or 1))
            for index = 0, items:size() - 1 do
                if needed <= 0 then break end
                local item = items:get(index)
                local fullType = item and item.getFullType
                    and tostring(item:getFullType()) or ""
                local matches = false
                for _, candidate in ipairs(requirement.itemTypes or {}) do
                    if fullType == tostring(candidate) then
                        matches = true; break
                    end
                end
                if matches and not seen[item] then
                    seen[item] = true
                    recorded:add(item)
                    needed = needed - 1
                end
            end
        end
    end
    return {
        luaCallOnCreate = function() end,
        processDestroyAndUsedItems = function() end,
        getAllRecordedConsumedItems = function() return recorded end,
        getAllConsumedItems = function() return recorded end,
        getAllInputItems = function() return recorded end,
        getRecipe = function() return descriptor.nativeRecipe end,
    }
end

local function place(order)
    local payload = order.payload or {}
    local blueprint = payload.blueprint or {}
    if payload.placed == true then return true end
    local descriptor = Catalog.Get(blueprint.objectInfoName)
    local info = descriptor and descriptor.nativeObjectInfo or nil
    local builder = builderFor(order)
    if not info or not builder then return false, "BUILD_REQUIRES_LIVE_BUILDER" end
    if not ISBuildIsoEntity then
        pcall(require, "BuildingObjects/ISBuildIsoEntity")
    end
    if not ISBuildIsoEntity then return false, "BUILD_ENGINE_UNAVAILABLE" end
    local data = fakeRecipeData(builder, descriptor)
    local logic = {
        startCraftAction = function() end,
        performCurrentRecipe = function() return true end,
        getRecipeDataInProgress = function() return data end,
        getRecipeData = function() return data end,
        getAllConsumedItems = function() return nil end,
    }
    local ok, cursor = pcall(ISBuildIsoEntity.new, ISBuildIsoEntity,
        builder, info, blueprint.nSprite or 1, nil, logic)
    if not ok or not cursor then return false, "BUILD_CURSOR_CREATE_FAILED" end
    -- ISBuildIsoEntity uses character on the server and player on the client
    -- when calculating the completed object's health. Keep both contexts
    -- valid because this completion path can cross the vanilla boundary.
    cursor.character = builder
    if cursor.player == nil or cursor.player == false then
        cursor.player = playerNumberFor(builder)
    end
    cursor.modData = {}
    cursor.updateModData = function() end
    cursor.blockBuild = false
    cursor.nSprite = blueprint.nSprite or 1
    cursor:getSprite()
    local created, result = pcall(cursor.create, cursor, blueprint.x,
        blueprint.y, blueprint.z, blueprint.north == true, blueprint.sprite)
    if not created or result == false then
        return false, "BUILD_PLACEMENT_FAILED"
    end
    payload.placed = true
    Repository.MarkDirty()
    return true
end

local function awardBuildXP(order, descriptor)
    local payload = order.payload or {}
    local awards = descriptor and descriptor.xpAwards or {}
    local awarded = payload.xpAwarded or {}
    local record

    if payload.xpGranted == true then return true end
    if #awards == 0 then
        payload.xpAwarded = awarded
        payload.xpGranted = true
        Repository.MarkDirty()
        return true
    end

    record = order.workerId and PNC.Registry and PNC.Registry.Get
        and PNC.Registry.Get(order.workerId) or nil
    if not record or not PNC.Skills
        or type(PNC.Skills.AddXP) ~= "function"
    then
        return false, "BUILD_XP_WORKER_UNAVAILABLE"
    end

    for index, award in ipairs(awards) do
        local key = tostring(index)
        if awarded[key] ~= true then
            local ok = PNC.Skills.AddXP(record, award.skillId,
                tonumber(award.amount) or 0)
            if ok ~= true then
                return false, "BUILD_XP_NOT_APPLIED"
            end
            -- Persist each entry separately so a retry after a partial
            -- failure cannot award an earlier recipe entry twice.
            awarded[key] = true
            payload.xpAwarded = awarded
            Repository.MarkDirty()
        end
    end

    payload.xpGranted = true
    Repository.MarkDirty()
    return true
end

local function complete(order)
    local placed, reason = place(order)
    if not placed then return false, reason end
    local committed
    committed, reason = PNC.WorkInputService.Commit(order,
        "building_material_consumption")
    if not committed then return false, reason end
    local blueprint = blueprintFor(order)
    local descriptor = Catalog.Get(blueprint and blueprint.objectInfoName)
    return awardBuildXP(order, descriptor)
end

local function refund(order)
    local payload = order.payload or {}
    local input = payload.input or {}
    if input.consume == true and input.committed ~= true then
        return true
    end
    local required = math.max(1, tonumber(order.requiredWork) or 1)
    local remaining = math.max(0, (required - math.min(required,
        tonumber(order.progress) or 0)) / required)
    local products = {}
    for _, requirement in ipairs(payload.materialRequirements or {}) do
        if requirement.consumed ~= false then
            local fullType = requirement.fullType
                or requirement.itemTypes and requirement.itemTypes[1]
            local quantity = math.floor((tonumber(requirement.amount) or 0)
                * remaining + 0.000001)
            if fullType and quantity > 0 then
                products[#products + 1] = { fullType = fullType,
                    quantity = quantity }
            end
        end
    end
    if #products == 0 then return true end
    local storageId = payload.storageId or input.storageId
    local ok, reason = PNC.ColonyStorageService.DepositProductionItems(
        storageId, products, nil, order.id, "building_cancellation_refund")
    return ok, reason
end

local function cancel(order)
    local ok, reason = refund(order)
    if not ok then return false, reason end
    return PNC.WorkInputService.Cancel(order)
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.BUILD_OBJECT = cancel
PNC.WorkService.RegisterTargetProvider("BUILD_OBJECT", resolveTarget)
PNC.WorkService.RegisterPreparation("BUILD_OBJECT", prepare)
PNC.WorkService.RegisterCompletion("BUILD_OBJECT", complete)

return Service
