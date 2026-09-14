-- Personal supply discovery, consumption, and need mutation.

if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

PNC = PNC or {}
PNC.NPCSupplyService = PNC.NPCSupplyService or {}
local Service = PNC.NPCSupplyService
local Request = PNC.SupplyRequest
local SupplyInventory = PNC.SupplyInventory
local SupplyCommands = SupplyInventory.Commands or SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Utility = PNC.ItemUtility

local function updateNeed(record, request, effect)
    if request.resourceKind == "FOOD" then
        return PNC.IndividualNeeds.Commands.ApplyFood(
            record, effect, "consumed_food")
    end
    if request.resourceKind == "HYDRATION" then
        return PNC.IndividualNeeds.Commands.ApplyDrink(
            record, effect, "consumed_hydration")
    end
    return nil
end

local function usePersonal(record, request, state, options)
    local required = request.resourceKind == "FOOD"
        and tonumber(request.required.hunger)
        or request.resourceKind == "HYDRATION"
            and tonumber(request.required.thirst) or 1
    required = math.max(0.001, required or 0.001)
    state.lastUseFailure = nil
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
    local candidates = SupplyQueries.FindPersonal(record, request, required)
    state.personalCandidateCount = #candidates
    state.personalCandidates = {}
    for index = 1, math.min(#candidates, 8) do
        state.personalCandidates[index] = {
            itemID = candidates[index].itemID,
            fullType = candidates[index].descriptor.fullType,
            score = candidates[index].score,
        }
    end
    if #candidates <= 0 then return false, "personal_missing", required end
    if options.acquireOnly then return true, "personal_available", required end
    if request.resourceKind == "MEDICAL" then
        local partID = request.required and request.required.partId
        local ok, reason = PNC.Treatment.TryNPCBandage(record, partID)
        return ok, reason, ok and 0 or required
    end
    local remaining = required
    local used = 0
    local maxUses = request.resourceKind == "HYDRATION"
        and (tonumber(PNC.NeedsDefinitions.SUPPLY_MAX_USES) or 8)
        or PNC.NeedsDefinitions.SUPPLY_MAX_SELECTIONS
    if request.purpose == "NEED" then
        maxUses = math.max(maxUses,
            tonumber(PNC.NeedsDefinitions.SUPPLY_MAX_STATE_AWARE_SELECTIONS)
                or 64)
    end
    for index = 1, #candidates do
        if used >= maxUses
            or remaining <= 0
        then break end
        local availableUses
        if request.resourceKind == "HYDRATION"
            and candidates[index].descriptor.fluidHydration == true
        then
            -- A fluid container can provide multiple partial sips. Its
            -- remaining uses are still the upper bound for the loop; the
            -- requested volume is computed below for each transaction.
            availableUses = math.max(1,
                tonumber(candidates[index].descriptor.remainingUses) or 1)
        else
            availableUses = math.max(1, math.floor(
                tonumber(candidates[index].stack) or 1
            ))
        end
        local candidateUses = 0
        while candidateUses < availableUses
            and used < maxUses
            and remaining > 0
        do
            if request.resourceKind == "HYDRATION"
                and candidates[index].descriptor.fluidHydration == true
            then
                local descriptor = candidates[index].descriptor
                local perLiter = math.max(0.001,
                    tonumber(descriptor.hydrationYieldPerLiter) or 0.50)
                local available = math.max(0,
                    tonumber(descriptor.fluidAmount) or 0)
                request.consumeAmount = math.min(available,
                    remaining / perLiter)
            else
                request.consumeAmount = nil
            end
            local ok, reason, effect = SupplyCommands.Consume(
                record, candidates[index].itemID, request
            )
            if not ok then
                state.lastUseFailure = reason
                request.consumeAmount = nil
                break
            end
            updateNeed(record, request, effect)
            local contribution = request.resourceKind == "FOOD"
                and effect.hunger or effect.thirst
            remaining = remaining - contribution
            used = used + 1
            candidateUses = candidateUses + 1
            state.lastUsedItem = effect
        end
    end
    request.consumeAmount = nil
    return used > 0, used > 0 and "personal_used" or "personal_use_failed",
        math.max(0, remaining)
end

function Service.HasPersonalSupply(record, resourceKind, required)
    if not record or record.alive == false then return false end
    local request = Request.Create({
        requesterId = record.id,
        purpose = "NEED",
        resourceKind = resourceKind,
        required = type(required) == "table" and required or {},
        fulfillment = "INSTANT",
    })
    if not request then return false end
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
    local amount = request.resourceKind == "FOOD"
        and tonumber(request.required.hunger)
        or request.resourceKind == "HYDRATION"
            and tonumber(request.required.thirst) or 1
    local candidates = SupplyQueries.FindPersonal(
        record, request, math.max(0.001, amount or 0.001))
    return #candidates > 0,
        candidates[1] and candidates[1].descriptor
            and candidates[1].descriptor.fullType or nil,
        candidates[1] and candidates[1].itemID or nil
end

-- Consume the exact item selected by a personal need route. The normal supply
-- processor remains the authority for physical/compact inventory mutation;
-- this narrow entry point prevents a later selector pass from using a
-- different item than the one the NPC equipped and displayed.
function Service.ConsumePersonalItem(record, itemID, required, resourceKind)
    local inv
    local item
    local descriptor
    local request
    local amount
    local perLiter
    local ok
    local reason
    local effect
    resourceKind = resourceKind == "FOOD" and "FOOD" or "HYDRATION"
    required = math.max(0.001, tonumber(required) or 0.001)
    if not record or not itemID or tostring(itemID) == "" then
        return false, "PERSONAL_ITEM_MISSING"
    end
    if SupplyCommands.EnsurePersonalInventory then
        SupplyCommands.EnsurePersonalInventory(record)
    end
    inv = SupplyCommands.EnsureRecordInventory
        and SupplyCommands.EnsureRecordInventory(record)
        or record.inventory
    item = inv and inv.items and inv.items[tostring(itemID)] or nil
    if not item then return false, "PERSONAL_ITEM_MISSING" end
    descriptor = Utility and Utility.DescribeNPCItem
        and Utility.DescribeNPCItem(item) or nil
    request = Request.Create({
        requesterId = record.id,
        purpose = "NEED",
        resourceKind = resourceKind,
        required = {
            hunger = resourceKind == "FOOD" and required or 0,
            thirst = resourceKind == "HYDRATION" and required or 0,
        },
        fulfillment = "INSTANT",
    })
    if not request then
        return false, resourceKind == "FOOD"
            and "FOOD_REQUEST_INVALID" or "HYDRATION_REQUEST_INVALID"
    end
    if not Utility or not Utility.Supports
        or not Utility.Supports(descriptor, request)
    then return false, "PERSONAL_ITEM_NOT_SUITABLE" end
    if resourceKind == "HYDRATION" and descriptor.fluidHydration == true then
        amount = math.max(0, tonumber(descriptor.fluidAmount) or 0)
        perLiter = math.max(0.001,
            tonumber(descriptor.hydrationYieldPerLiter) or 0.50)
        request.consumeAmount = math.min(amount, required / perLiter)
    end
    ok, reason, effect = SupplyCommands.Consume(record, item.id, request)
    if not ok then return false, reason or "PERSONAL_ITEM_CONSUME_FAILED" end
    updateNeed(record, request, effect)
    return true, "PERSONAL_ITEM_CONSUMED", effect
end

Service.Internal.UpdateNeed = updateNeed
Service.Internal.UsePersonal = usePersonal

return Service
