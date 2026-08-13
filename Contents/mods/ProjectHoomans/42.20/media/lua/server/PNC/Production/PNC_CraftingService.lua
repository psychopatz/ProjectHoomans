if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}
local Service = PNC.CraftingService
local Registry = PNC.RecipeKnowledgeRegistry
Service.Commands = Service.Commands or {}
Service.Queries = Service.Queries or {}

local function context(player)
    return PNC.ProductionContext.ForPlayer(player)
end

function Service.Commands.QueueCraft(player, recipeId, quantity)
    local ctx, reason = context(player)
    recipeId = math.floor(tonumber(recipeId) or 0)
    quantity = math.max(1, math.floor(tonumber(quantity) or 1))
    if not ctx then return nil, reason end
    if not PNC.ResearchService.Queries.HasRecipe(ctx.colony.id, recipeId) then
        return nil, "RECIPE_UNKNOWN"
    end
    local resolved = Registry.Queries.Resolve(recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return nil, "RECIPE_UNAVAILABLE"
    end
    local requirements = {}
    for index = 1, #resolved.descriptor.inputs do
        local row = resolved.descriptor.inputs[index]
        if row.consumed == false then requirements[#requirements + 1] = row end
    end
    for copyIndex = 1, quantity do
        for index = 1, #resolved.descriptor.inputs do
            local row = resolved.descriptor.inputs[index]
            if row.consumed ~= false then requirements[#requirements + 1] = row end
        end
    end
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
        ctx.storage.id, requirements, "craft:" .. tostring(recipeId))
    if not reservation then return nil, reason or "MISSING_MATERIALS" end
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "CRAFT",
        colonyId = ctx.colony.id, factionId = ctx.faction.id, baseId = ctx.base.id,
        recipeId = recipeId, quantity = quantity,
        requiredWork = math.max(20, resolved.descriptor.craftTime * quantity),
        requiredSkills = resolved.descriptor.requiredSkills,
        payload = { storageId = ctx.storage.id,
            reservationId = reservation.id, requirements = requirements } })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

function Service.Commands.QueueDisassembly(player, recordIndex)
    local ctx, reason = context(player)
    if not ctx then return nil, reason end
    local info
    info, reason = PNC.ColonyStorageService.ReadProductionRecord(
        ctx.storage.id, recordIndex)
    if not info then return nil, reason end
    local recipeId = info.metadata and info.metadata.PNC
        and info.metadata.PNC.production
        and tonumber(info.metadata.PNC.production.rid) or nil
    local resolved = recipeId and Registry.Queries.Resolve(recipeId) or nil
    if not resolved or resolved.status ~= "AVAILABLE" then
        local producers = PNC.RecipeCatalog.Queries.GetProducerKeys(info.fullType)
        if #producers == 0 then return nil, "DISASSEMBLY_UNSUPPORTED" end
        if #producers > 1 then return nil, "DISASSEMBLY_AMBIGUOUS" end
        recipeId = PNC.KnowledgeRepository.GetOrCreateId(producers[1])
        resolved = Registry.Queries.Resolve(recipeId)
    end
    local reservation
    reservation, reason = PNC.ColonyStorageService.ReserveProductionRecord(
        ctx.storage.id, recordIndex, 1, "disassemble:" .. tostring(recipeId))
    if not reservation then return nil, reason end
    local order
    order, reason = PNC.WorkService.Commands.Queue({ operation = "DISASSEMBLE",
        colonyId = ctx.colony.id, factionId = ctx.faction.id, baseId = ctx.base.id,
        recipeId = recipeId, requiredWork = math.max(20,
            resolved.descriptor.craftTime * 0.6),
        requiredSkills = resolved.descriptor.requiredSkills,
        payload = { storageId = ctx.storage.id,
            reservationId = reservation.id, specimenFullType = info.fullType } })
    if not order then
        PNC.ColonyStorageService.ReleaseProductionReservation(reservation.id)
    end
    return order, reason
end

local function craftCompletion(order)
    local payload = order.payload or {}
    local resolved = Registry.Queries.Resolve(order.recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return false, "RECIPE_UNAVAILABLE"
    end
    if payload.inputsCommitted ~= true then
        local ok, reason
        if payload.inputsStaged == true then
            local worker = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(order.workerId) or nil
            local commands = PNC.SupplyInventory and PNC.SupplyInventory.Commands
            if commands and commands.RemoveCoreItemIds then
                ok, reason = commands.RemoveCoreItemIds(worker,
                    payload.stagedItemIds or {}, "craft_input_consumption")
            else
                ok, reason = false, "worker_inventory_unavailable"
            end
        else
            ok, reason = PNC.ColonyStorageService.CommitProductionReservation(
                payload.reservationId, order.id, "craft_inputs", payload.storageId)
        end
        if not ok then return false, reason end
        payload.inputsCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    if payload.outputCommitted ~= true then
        local products = {}
        for index = 1, #resolved.descriptor.outputs do
            local output = resolved.descriptor.outputs[index]
            products[#products + 1] = { fullType = output.itemTypes[1],
                quantity = output.amount * order.quantity }
        end
        local ok, reason = PNC.ColonyStorageService.DepositProductionItems(
            payload.storageId, products, { recipeId = order.recipeId },
            order.id, "craft_output")
        if not ok then return false, reason end
        payload.outputCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    return true
end

local function disassemblyCompletion(order)
    local payload = order.payload or {}
    local resolved = Registry.Queries.Resolve(order.recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return false, "RECIPE_UNAVAILABLE"
    end
    if payload.specimenCommitted ~= true then
        local ok, reason
        if payload.inputsStaged == true then
            local worker = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(order.workerId) or nil
            local commands = PNC.SupplyInventory and PNC.SupplyInventory.Commands
            if commands and commands.RemoveCoreItemIds then
                ok, reason = commands.RemoveCoreItemIds(worker,
                    payload.stagedItemIds or {},
                    "disassembly_specimen_consumption")
            else
                ok, reason = false, "worker_inventory_unavailable"
            end
        else
            ok, reason = PNC.ColonyStorageService.CommitProductionReservation(
                payload.reservationId, order.id, "disassembly_specimen",
                payload.storageId)
        end
        if not ok then return false, reason end
        payload.specimenCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    if payload.salvageCommitted ~= true then
        local products = payload.salvagePlan
        if type(products) ~= "table" then
            products = {}
            local worker = PNC.Registry and PNC.Registry.Get
                and PNC.Registry.Get(order.workerId) or nil
            local fraction = PNC.WorkDefinitions.SalvageFraction(worker,
                order.requiredSkills)
            local seed = 0
            for index = 1, #order.id do
                seed = (seed * 33 + string.byte(order.id, index)) % 1000003
            end
            for index = 1, #resolved.descriptor.inputs do
                local input = resolved.descriptor.inputs[index]
                if input.consumed and input.itemTypes[1] then
                    local exact = input.amount * fraction
                    local quantity = math.floor(exact)
                    local roll = ((seed + index * 7919) % 10000) / 10000
                    if roll < exact - quantity then quantity = quantity + 1 end
                    if quantity > 0 then products[#products + 1] = {
                        fullType = input.itemTypes[1], quantity = quantity } end
                end
            end
            payload.salvagePlan = products
            PNC.WorkRepository.MarkDirty()
        end
        if #products > 0 then
            local ok, reason = PNC.ColonyStorageService.DepositProductionItems(
                payload.storageId, products, nil, order.id,
                "disassembly_salvage")
            if not ok then return false, reason end
        end
        payload.salvageCommitted = true
        PNC.WorkRepository.MarkDirty()
    end
    return true
end

local function cancellation(order)
    local payload = order.payload or {}
    if payload.inputsStaged == true and payload.stagedItemIds
        and order.workerId
    then
        local worker = PNC.Registry and PNC.Registry.Get
            and PNC.Registry.Get(order.workerId) or nil
        local returned = PNC.ColonyStorageService.ReturnCollectedProductionRecords(
            payload.storageId, worker, payload.stagedItemIds,
            payload.stagedRecords or {})
        if returned then
            PNC.ColonyStorageService.ForgetProductionTransaction(
                payload.storageId, order.id)
            payload.inputsStaged = false
            payload.stagedItemIds, payload.stagedRecords = nil, nil
            payload.reservationId = nil
        end
    elseif payload.reservationId and payload.inputsCommitted ~= true
        and payload.specimenCommitted ~= true
    then PNC.ColonyStorageService.ReleaseProductionReservation(payload.reservationId) end
end

local function collect(order, worker)
    local payload = order.payload or {}
    if payload.inputsStaged == true then return true end
    local stage = order.operation == "CRAFT" and "craft_inputs"
        or "disassembly_specimen"
    local ok, details = PNC.ColonyStorageService.CollectProductionReservation(
        payload.reservationId, order.id, stage, payload.storageId, worker)
    if not ok then return false, details end
    payload.inputsStaged = true
    payload.stagedItemIds = details.itemIds or {}
    payload.stagedRecords = details.records or {}
    PNC.WorkRepository.MarkDirty()
    return true
end

local function prepare(order)
    local payload = order.payload or {}
    if order.operation == "CRAFT" and PNC.ColonyStorageService
        .HasProductionTransactionStage(payload.storageId, order.id, "craft_inputs")
    then
        if payload.stagedItemIds then payload.inputsStaged = true
        else payload.inputsCommitted = true end
        return true
    end
    if order.operation == "DISASSEMBLE" and PNC.ColonyStorageService
        .HasProductionTransactionStage(payload.storageId, order.id,
            "disassembly_specimen")
    then
        if payload.stagedItemIds then payload.inputsStaged = true
        else payload.specimenCommitted = true end
        return true
    end
    if payload.inputsCommitted == true or payload.specimenCommitted == true then
        return true
    end
    if payload.reservationId
        and PNC.ColonyStorageService.GetProductionReservation(payload.reservationId)
    then return true end
    local reservation, reason
    if order.operation == "CRAFT" then
        reservation, reason = PNC.ColonyStorageService.ReserveProductionMaterials(
            payload.storageId, payload.requirements, "craft:" .. order.id)
    else
        reservation, reason = PNC.ColonyStorageService.ReserveProductionMatchingRecord(
            payload.storageId, { fullType = payload.specimenFullType }, 1,
            "disassemble:" .. order.id)
    end
    if not reservation then return false, reason end
    payload.reservationId = reservation.id
    PNC.WorkRepository.MarkDirty()
    return true
end

PNC.WorkService.CancellationHandlers = PNC.WorkService.CancellationHandlers or {}
PNC.WorkService.CancellationHandlers.CRAFT = cancellation
PNC.WorkService.CancellationHandlers.DISASSEMBLE = cancellation
PNC.WorkService.RegisterPreparation("CRAFT", prepare)
PNC.WorkService.RegisterPreparation("DISASSEMBLE", prepare)
PNC.WorkService.RegisterCollection("CRAFT", collect)
PNC.WorkService.RegisterCollection("DISASSEMBLE", collect)
PNC.WorkService.RegisterCompletion("CRAFT", craftCompletion)
PNC.WorkService.RegisterCompletion("DISASSEMBLE", disassemblyCompletion)

function Service.Queries.KnownRecipes(colonyId, storageId)
    local state = PNC.ResearchRepository.Get(colonyId, false)
    local output = {}
    for index = 1, #(state and state.learnedRecipeIds or {}) do
        local resolved = Registry.Queries.Resolve(state.learnedRecipeIds[index])
        if resolved and resolved.descriptor and storageId then
            resolved.availability = {}
            for inputIndex = 1, #resolved.descriptor.inputs do
                local input = resolved.descriptor.inputs[inputIndex]
                resolved.availability[inputIndex] =
                    PNC.ColonyStorageService.CountProductionAvailable(
                        storageId, input.itemTypes)
            end
        end
        output[#output + 1] = resolved
    end
    return output
end
function Service.Queries.BuildSnapshot(colonyId)
    local contextStorage = PNC.ColonyStorageRepository
        and PNC.ColonyStorageRepository.GetForSettlement
        and PNC.ColonyStorageRepository.GetForSettlement(colonyId) or nil
    return { knownRecipes = Service.Queries.KnownRecipes(colonyId,
            contextStorage and contextStorage.id),
        orders = PNC.WorkService.Queries.List(colonyId),
        diagnostics = PNC.WorkService.Queries.Diagnostics(),
        inventoryDiagnostics = PNC.ColonyStorageService.GetProductionDiagnostics(
            contextStorage and contextStorage.id) }
end

return Service
