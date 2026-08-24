if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.CraftingService = PNC.CraftingService or {}
PNC.CraftingServiceInternal = PNC.CraftingServiceInternal or {}

local Service = PNC.CraftingService
local H = PNC.CraftingServiceInternal
local Registry = PNC.RecipeKnowledgeRegistry

function H.CraftCompletion(order)
    local payload = order.payload or {}
    local resolved = Registry.Queries.Resolve(order.recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return false, "RECIPE_UNAVAILABLE"
    end
    if payload.inputsCommitted ~= true then
        local ok, reason
        if payload.input then
            ok, reason = PNC.WorkInputService.Commit(order,
                "craft_input_consumption")
        elseif payload.inputsStaged == true then
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

function H.DisassemblyCompletion(order)
    local payload = order.payload or {}
    local resolved = Registry.Queries.Resolve(order.recipeId)
    if not resolved or resolved.status ~= "AVAILABLE" then
        return false, "RECIPE_UNAVAILABLE"
    end
    if payload.specimenCommitted ~= true then
        local ok, reason
        if payload.input then
            ok, reason = PNC.WorkInputService.Commit(order,
                "disassembly_specimen_consumption")
        elseif payload.inputsStaged == true then
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

