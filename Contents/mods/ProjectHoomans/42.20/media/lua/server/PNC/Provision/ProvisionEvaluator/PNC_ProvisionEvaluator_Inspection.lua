if PsychopatzCore and PsychopatzCore.RuntimeRole
    and not PsychopatzCore.RuntimeRole.AllowsServerCode() then return end

local Evaluator = PNC.ProvisionEvaluator
local H = Evaluator.Internal
local Registry = PNC.ProvisionRuleRegistry
local SupplyInventory = PNC.SupplyInventory
local SupplyQueries = SupplyInventory.Queries or SupplyInventory
local Access = PNC.StorageAccessPolicy
local Selector = PNC.SupplySelector

function H.PersonalItems(record, definition)
    local output = {}
    H.EnsurePersonalInventory(record)
    local candidates = SupplyQueries.FindPersonal(
        record, H.RequestFor(definition), 999999
    )
    for index = 1, math.min(#candidates, 12) do
        local descriptor = candidates[index].descriptor
        output[#output + 1] = {
            fullType = descriptor.fullType,
            quantity = descriptor.quantity,
            hunger = descriptor.hunger,
            thirst = descriptor.thirst,
            remainingUses = descriptor.remainingUses,
            bandage = descriptor.bandage == true,
            unsafe = descriptor.unsafe == true,
        }
    end
    return output
end

function H.Queued(record, ruleID)
    local scheduler = PNC.ProvisionScheduler
    for _, entry in ipairs(scheduler and scheduler.Queue or {}) do
        if tostring(entry.npcID) == tostring(record.id)
            and tostring(entry.ruleID) == tostring(ruleID)
        then
            return true, entry.readyAt
        end
    end
    return false, nil
end

function Evaluator.Inspect(record)
    if not record or record.alive == false then return nil, "npc_missing" end
    local storage, accessReason, community = Access.Resolve(record)
    if not community and PNC.Communities and PNC.Communities.GetNPCCommunity then
        community = PNC.Communities.GetNPCCommunity(record.id)
    end
    local home = community and community.home or nil
    local homeDistance
    if home and tonumber(record.x) and tonumber(record.y) and tonumber(record.z) then
        local dx = tonumber(record.x) - tonumber(home.x)
        local dy = tonumber(record.y) - tonumber(home.y)
        local dz = tonumber(record.z) - tonumber(home.z)
        homeDistance = math.sqrt(dx * dx + dy * dy + dz * dz)
    end
    local output = {
        npcID = record.id,
        name = tostring(record.name or record.id),
        inventoryRevision = record.inventory and record.inventory.revision or 0,
        inventoryMode = PNC.Inventory.GetPersistenceMode(record),
        storageAccess = storage ~= nil,
        storageAccessReason = storage and "allowed"
            or tostring(accessReason or "unknown"),
        storageAccessMode = Access.GetAccessMode
            and Access.GetAccessMode() or "unknown",
        storageID = storage and storage.id or nil,
        location = { x = record.x, y = record.y, z = record.z },
        home = home,
        homeDistance = homeDistance,
        storageSummary = Evaluator.MeasureStorage(storage),
        rules = {},
        generatedAt = PNC.NeedsUtils.WorldAgeHours(),
    }
    for _, definition in ipairs(Registry.List()) do
        local evaluation, evaluationReason = Evaluator.Evaluate(
            record, definition
        )
        local isQueued, readyAt = H.Queued(record, definition.id)
        local laneKind = definition.resourceKind or definition.selector
        local supply = record.runtime and record.runtime.supply
        local lane = supply and supply.byKind and supply.byKind[laneKind] or {}
        local rule = {
            id = definition.id,
            measure = definition.measure,
            evaluationReason = evaluationReason,
            enabled = evaluation and evaluation.enabled == true,
            onHand = evaluation and evaluation.onHand or 0,
            refillBelow = evaluation and evaluation.refillBelow or 0,
            target = evaluation and evaluation.target or 0,
            deficit = evaluation and evaluation.deficit or 0,
            refilling = evaluation and evaluation.refilling == true,
            queued = isQueued,
            readyAt = readyAt,
            personalItems = H.PersonalItems(record, definition),
            phase = lane.phase,
            lastResult = lane.lastResult,
            lastFailureReason = lane.lastFailureReason,
            nextRetry = lane.nextRetry,
            personalCandidateCount = lane.personalCandidateCount,
            storageCandidateCount = 0,
            selected = {},
        }
        if storage and evaluation and evaluation.deficit > 0 then
            local request = Evaluator.BuildRequest(
                record, definition, evaluation
            )
            if request then
                local selected, candidateCount = Selector.SelectFromStorage(
                    storage, request
                )
                rule.storageCandidateCount = candidateCount
                for index = 1, math.min(#selected, 8) do
                    rule.selected[#rule.selected + 1] = {
                        fullType = selected[index].descriptor.fullType,
                        quantity = selected[index].quantity,
                        hunger = selected[index].descriptor.hunger,
                        thirst = selected[index].descriptor.thirst,
                        remainingUses = selected[index].descriptor.remainingUses,
                        bandage = selected[index].descriptor.bandage == true,
                        unsafe = selected[index].descriptor.unsafe == true,
                    }
                end
            end
        end
        output.rules[#output.rules + 1] = rule
    end
    return output
end
