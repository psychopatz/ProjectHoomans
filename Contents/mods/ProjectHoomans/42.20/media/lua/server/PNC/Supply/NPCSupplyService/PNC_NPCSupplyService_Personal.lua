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
        local availableUses = request.resourceKind == "HYDRATION"
            and math.max(1, candidates[index].descriptor.remainingUses)
            or math.max(1, math.floor(
                tonumber(candidates[index].stack) or 1
            ))
        local candidateUses = 0
        while candidateUses < availableUses
            and used < maxUses
            and remaining > 0
        do
            local ok, reason, effect = SupplyCommands.Consume(
                record, candidates[index].itemID, request
            )
            if not ok then
                state.lastUseFailure = reason
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
    local amount = request.resourceKind == "FOOD"
        and tonumber(request.required.hunger)
        or request.resourceKind == "HYDRATION"
            and tonumber(request.required.thirst) or 1
    local candidates = SupplyQueries.FindPersonal(
        record, request, math.max(0.001, amount or 0.001))
    return #candidates > 0,
        candidates[1] and candidates[1].descriptor
            and candidates[1].descriptor.fullType or nil
end

Service.Internal.UpdateNeed = updateNeed
Service.Internal.UsePersonal = usePersonal

return Service
